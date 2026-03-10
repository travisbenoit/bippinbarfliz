import { createContext, useContext, useEffect, useState, useCallback, ReactNode } from 'react';
import { useGeofencing } from './useGeofencing';
import { activityService } from '../services/activityService';
import { xpService } from '../services/xpService';
import { supabase } from '../lib/supabase';
import type {
  Coordinates,
  Venue,
  UserVenuePresence,
  GeofenceState,
  GeofenceEvent,
  GeofenceConfig,
} from './types';

interface GeofenceContextValue {
  state: GeofenceState;
  currentLocation: Coordinates | null;
  isLoading: boolean;
  error: string | null;
  isLocationEnabled: boolean;
  startTracking: () => void;
  stopTracking: () => void;
  updateLocation: (location: Coordinates) => Promise<void>;
  getCurrentPresence: () => UserVenuePresence | undefined;
  getCurrentVenue: () => Venue | undefined;
  requestLocationPermission: () => Promise<boolean>;
  addEventListener: (listener: (event: GeofenceEvent) => void) => () => void;
}

const GeofenceContext = createContext<GeofenceContextValue | null>(null);

export function useGeofenceContext() {
  const context = useContext(GeofenceContext);
  if (!context) {
    throw new Error('useGeofenceContext must be used within GeofenceProvider');
  }
  return context;
}

interface GeofenceProviderProps {
  children: ReactNode;
  config?: Partial<GeofenceConfig>;
  autoStart?: boolean;
  ghostMode?: boolean;
}

export function GeofenceProvider({
  children,
  config = {},
  autoStart = false,
  ghostMode = false,
}: GeofenceProviderProps) {
  const geofencing = useGeofencing(config);
  const [isLocationEnabled, setIsLocationEnabled] = useState(false);
  const [currentLocation, setCurrentLocation] = useState<Coordinates | null>(null);
  const [watchId, setWatchId] = useState<number | null>(null);

  const requestLocationPermission = useCallback(async (): Promise<boolean> => {
    if (!navigator.geolocation) {
      console.error('Geolocation is not supported by this browser');
      return false;
    }

    try {
      const result = await navigator.permissions.query({ name: 'geolocation' });

      if (result.state === 'granted') {
        setIsLocationEnabled(true);
        return true;
      } else if (result.state === 'prompt') {
        return new Promise((resolve) => {
          navigator.geolocation.getCurrentPosition(
            () => {
              setIsLocationEnabled(true);
              resolve(true);
            },
            (error) => {
              console.error('Location permission denied:', error);
              setIsLocationEnabled(false);
              resolve(false);
            }
          );
        });
      } else {
        setIsLocationEnabled(false);
        return false;
      }
    } catch (error) {
      console.error('Error checking location permission:', error);

      return new Promise((resolve) => {
        navigator.geolocation.getCurrentPosition(
          () => {
            setIsLocationEnabled(true);
            resolve(true);
          },
          (error) => {
            console.error('Location permission denied:', error);
            setIsLocationEnabled(false);
            resolve(false);
          }
        );
      });
    }
  }, []);

  const startLocationWatching = useCallback(() => {
    if (!navigator.geolocation) {
      console.error('Geolocation is not supported');
      return;
    }

    if (watchId !== null) {
      return;
    }

    const id = navigator.geolocation.watchPosition(
      (position) => {
        const location: Coordinates = {
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        };
        setCurrentLocation(location);
        geofencing.updateLocation(location);
      },
      (error) => {
        console.error('Location error:', error);
      },
      {
        enableHighAccuracy: true,
        maximumAge: 10000,
        timeout: 30000,
      }
    );

    setWatchId(id);
  }, [watchId, geofencing]);

  const stopLocationWatching = useCallback(() => {
    if (watchId !== null) {
      navigator.geolocation.clearWatch(watchId);
      setWatchId(null);
    }
  }, [watchId]);

  const handleStartTracking = useCallback(async () => {
    const hasPermission = await requestLocationPermission();
    if (hasPermission) {
      geofencing.startTracking();
      startLocationWatching();
    }
  }, [requestLocationPermission, geofencing, startLocationWatching]);

  useEffect(() => {
    const removeListener = geofencing.addEventListener(async (event: GeofenceEvent) => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      if (event.type === 'ENTER' && event.venue) {
        await activityService.logActivity('venue_enter', {
          venueId: event.venue.id,
          metadata: { venue_name: event.venue.name },
        });

        const { data: profile } = await supabase
          .from('users')
          .select('name, ghost_mode')
          .eq('id', user.id)
          .maybeSingle();

        const isGhost = ghostMode || (profile?.ghost_mode === true);

        if (!isGhost) {
          const actorName = profile?.name || 'Someone';
          await activityService.createNotificationsForFriends(
            user.id,
            'friend_venue_enter',
            `${actorName} is at ${event.venue.name}`,
            `Your friend just arrived at ${event.venue.name}`,
            { venueId: event.venue.id }
          );
        }

        const today = new Date().toISOString().split('T')[0];
        const { data: existing } = await supabase
          .from('check_in_streaks')
          .select('current_streak, longest_streak, total_checkins, last_checkin_date')
          .eq('user_id', user.id)
          .maybeSingle();
        // Sync check_in_streaks table (legacy)
        if (!existing || existing.last_checkin_date !== today) {
          const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
          const streak = existing?.last_checkin_date === yesterday ? (existing.current_streak || 0) + 1 : 1;
          const longest = Math.max(streak, existing?.longest_streak || 0);
          await supabase.from('check_in_streaks').upsert({
            user_id: user.id,
            current_streak: streak,
            longest_streak: longest,
            last_checkin_date: today,
            total_checkins: (existing?.total_checkins || 0) + 1,
            updated_at: new Date().toISOString(),
          }, { onConflict: 'user_id' });
        }

        // XP, coins, badges, challenges
        try {
          const result = await xpService.recordCheckin(
            user.id,
            event.venue.id,
            (event.venue as any).category
          );

          // Dispatch custom event so UI can show toasts without prop-drilling
          window.dispatchEvent(new CustomEvent('barfliz:checkin', { detail: result }));
        } catch {
          // Non-critical — don't block the check-in flow
        }
      } else if (event.type === 'EXIT' && event.venue) {
        await activityService.logActivity('venue_leave', {
          venueId: event.venue.id,
          metadata: { venue_name: event.venue.name },
        });
      }
    });

    return removeListener;
  }, [geofencing, ghostMode]);

  const handleStopTracking = useCallback(() => {
    geofencing.stopTracking();
    stopLocationWatching();
  }, [geofencing, stopLocationWatching]);

  useEffect(() => {
    if (autoStart) {
      handleStartTracking();
    }

    return () => {
      stopLocationWatching();
    };
  }, [autoStart]);

  const value: GeofenceContextValue = {
    state: geofencing.state,
    currentLocation,
    isLoading: geofencing.isLoading,
    error: geofencing.error,
    isLocationEnabled,
    startTracking: handleStartTracking,
    stopTracking: handleStopTracking,
    updateLocation: geofencing.updateLocation,
    getCurrentPresence: geofencing.getCurrentPresence,
    getCurrentVenue: geofencing.getCurrentVenue,
    requestLocationPermission,
    addEventListener: geofencing.addEventListener,
  };

  return (
    <GeofenceContext.Provider value={value}>
      {children}
    </GeofenceContext.Provider>
  );
}
