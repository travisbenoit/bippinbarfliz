import { useState, useEffect, useCallback, useRef } from 'react';
import { supabase } from '../lib/supabase';
import type {
  Coordinates,
  Venue,
  NearbyVenue,
  UserVenuePresence,
  GeofenceState,
  GeofenceEvent,
  GeofenceEventListener,
  GeofenceConfig,
} from './types';
import {
  findActiveGeofence,
} from './utils';

const DEFAULT_CONFIG: GeofenceConfig = {
  minDwellTimeSeconds: 30,
  exitDelaySeconds: 30,
  highPrecisionThresholdMeters: 300,
  clusterProximityMeters: 750,
  updateIntervalLowPrecision: 60000,
  updateIntervalHighPrecision: 5000,
  venueGeofenceBufferMeters: 20,
  privacyMode: 'visible',
};

export function useGeofencing(config: Partial<GeofenceConfig> = {}) {
  const fullConfig = { ...DEFAULT_CONFIG, ...config };

  const [state, setState] = useState<GeofenceState>({
    nearbyVenues: [],
    nearbyClusters: [],
    isTracking: false,
  });

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const eventListenersRef = useRef<GeofenceEventListener[]>([]);
  const dwellTimerRef = useRef<NodeJS.Timeout | null>(null);
  const exitTimerRef = useRef<NodeJS.Timeout | null>(null);
  const updateIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const lastLocationRef = useRef<Coordinates | null>(null);
  const currentVenueRef = useRef<Venue | null>(null);
  const currentPresenceRef = useRef<UserVenuePresence | null>(null);

  const emitEvent = useCallback((event: GeofenceEvent) => {
    eventListenersRef.current.forEach((listener) => listener(event));
  }, []);

  const addEventListener = useCallback((listener: GeofenceEventListener) => {
    eventListenersRef.current.push(listener);
    return () => {
      eventListenersRef.current = eventListenersRef.current.filter(
        (l) => l !== listener
      );
    };
  }, []);

  const fetchNearbyVenues = useCallback(
    async (location: Coordinates): Promise<NearbyVenue[]> => {
      try {
        const { data, error: queryError } = await supabase.rpc(
          'find_nearby_venues',
          {
            user_lat: location.lat,
            user_lng: location.lng,
            radius_meters: fullConfig.clusterProximityMeters,
          }
        );

        if (queryError) throw queryError;

        return (data || []).map((v: any) => ({
          id: v.venue_id,
          name: v.venue_name,
          type: v.venue_type,
          lat: v.venue_lat,
          lng: v.venue_lng,
          geofence_radius_meters: v.venue_geofence_radius_meters || 80,
          geofence_shape: v.venue_geofence_shape || null,
          distance_meters: v.distance_meters,
          is_in_geofence: v.is_in_geofence,
          city: '',
          country: '',
          is_active: true,
          created_at: '',
        }));
      } catch (err) {
        console.error('Error fetching nearby venues:', err);
        return [];
      }
    },
    [fullConfig.clusterProximityMeters]
  );

  const enterVenue = useCallback(
    async (
      venue: Venue,
      location: Coordinates
    ): Promise<UserVenuePresence | null> => {
      try {
        const { data: sessionData } = await supabase.auth.getSession();
        if (!sessionData.session) {
          throw new Error('Not authenticated');
        }

        const response = await fetch(
          `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/enter-venue`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${sessionData.session.access_token}`,
            },
            body: JSON.stringify({
              venue_id: venue.id,
              user_lat: location.lat,
              user_lng: location.lng,
              is_visible: fullConfig.privacyMode !== 'invisible',
              entry_method: 'AUTO_GEOFENCE',
            }),
          }
        );

        const result = await response.json();

        if (!result.success) {
          throw new Error(result.error || 'Failed to enter venue');
        }

        return result.presence_id
          ? {
              id: result.presence_id,
              user_id: sessionData.session.user.id,
              venue_id: venue.id,
              status: 'IN_VENUE',
              entered_at: new Date().toISOString(),
              last_seen_at: new Date().toISOString(),
              is_visible_in_venue: fullConfig.privacyMode !== 'invisible',
              dwell_seconds: 0,
              entry_method: 'AUTO_GEOFENCE',
              created_at: new Date().toISOString(),
            }
          : null;
      } catch (err) {
        console.error('Error entering venue:', err);
        throw err;
      }
    },
    [fullConfig.privacyMode]
  );

  const leaveVenue = useCallback(
    async (
      presenceId: string,
      location?: Coordinates
    ): Promise<void> => {
      try {
        const { data: sessionData } = await supabase.auth.getSession();
        if (!sessionData.session) {
          throw new Error('Not authenticated');
        }

        const response = await fetch(
          `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/leave-venue`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${sessionData.session.access_token}`,
            },
            body: JSON.stringify({
              presence_id: presenceId,
              user_lat: location?.lat,
              user_lng: location?.lng,
            }),
          }
        );

        const result = await response.json();

        if (!result.success) {
          throw new Error(result.error || 'Failed to leave venue');
        }
      } catch (err) {
        console.error('Error leaving venue:', err);
        throw err;
      }
    },
    []
  );

  const processLocationUpdate = useCallback(
    async (location: Coordinates) => {
      lastLocationRef.current = location;

      const venues = await fetchNearbyVenues(location);

      setState((prev) => ({
        ...prev,
        nearbyVenues: venues,
        nearbyClusters: [],
        lastLocation: location,
        lastUpdateTime: Date.now(),
      }));

      const activeGeofence = findActiveGeofence(
        location,
        venues.map((v) => ({ ...v }))
      );

      if (activeGeofence && !currentVenueRef.current) {
        if (dwellTimerRef.current) {
          clearTimeout(dwellTimerRef.current);
        }

        dwellTimerRef.current = setTimeout(async () => {
          try {
            const presence = await enterVenue(activeGeofence, location);
            if (presence) {
              currentVenueRef.current = activeGeofence;
              currentPresenceRef.current = presence;

              setState((prev) => ({
                ...prev,
                currentVenue: activeGeofence,
                currentPresence: presence,
              }));

              emitEvent({
                type: 'ENTER',
                venue: activeGeofence,
                presence,
                timestamp: Date.now(),
                coordinates: location,
              });
            }
          } catch (err) {
            console.error('Failed to enter venue:', err);
          }
        }, fullConfig.minDwellTimeSeconds * 1000);
      } else if (!activeGeofence && currentVenueRef.current) {
        if (dwellTimerRef.current) {
          clearTimeout(dwellTimerRef.current);
          dwellTimerRef.current = null;
        }

        if (!exitTimerRef.current) {
          exitTimerRef.current = setTimeout(async () => {
            if (currentPresenceRef.current) {
              try {
                await leaveVenue(currentPresenceRef.current.id, location);

                emitEvent({
                  type: 'EXIT',
                  venue: currentVenueRef.current!,
                  presence: currentPresenceRef.current,
                  timestamp: Date.now(),
                  coordinates: location,
                });

                currentVenueRef.current = null;
                currentPresenceRef.current = null;

                setState((prev) => ({
                  ...prev,
                  currentVenue: undefined,
                  currentPresence: undefined,
                }));
              } catch (err) {
                console.error('Failed to leave venue:', err);
              }
            }
            exitTimerRef.current = null;
          }, fullConfig.exitDelaySeconds * 1000);
        }
      } else if (activeGeofence && currentVenueRef.current) {
        if (exitTimerRef.current) {
          clearTimeout(exitTimerRef.current);
          exitTimerRef.current = null;
        }
      }
    },
    [
      fetchNearbyVenues,
      enterVenue,
      leaveVenue,
      emitEvent,
      fullConfig.minDwellTimeSeconds,
      fullConfig.exitDelaySeconds,
    ]
  );

  const startTracking = useCallback(() => {
    setState((prev) => ({ ...prev, isTracking: true }));
  }, []);

  const stopTracking = useCallback(() => {
    setState((prev) => ({ ...prev, isTracking: false }));

    if (dwellTimerRef.current) {
      clearTimeout(dwellTimerRef.current);
      dwellTimerRef.current = null;
    }

    if (exitTimerRef.current) {
      clearTimeout(exitTimerRef.current);
      exitTimerRef.current = null;
    }

    if (updateIntervalRef.current) {
      clearInterval(updateIntervalRef.current);
      updateIntervalRef.current = null;
    }
  }, []);

  const updateLocation = useCallback(
    async (location: Coordinates) => {
      if (!state.isTracking) return;
      await processLocationUpdate(location);
    },
    [state.isTracking, processLocationUpdate]
  );

  const getCurrentPresence = useCallback((): UserVenuePresence | undefined => {
    return state.currentPresence;
  }, [state.currentPresence]);

  const getCurrentVenue = useCallback((): Venue | undefined => {
    return state.currentVenue;
  }, [state.currentVenue]);

  useEffect(() => {
    return () => {
      stopTracking();
    };
  }, [stopTracking]);

  return {
    state,
    isLoading,
    error,
    startTracking,
    stopTracking,
    updateLocation,
    getCurrentPresence,
    getCurrentVenue,
    addEventListener,
  };
}
