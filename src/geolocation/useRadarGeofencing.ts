import { useState, useEffect, useCallback, useRef } from 'react';
import { radarService } from '../services/radarService';
import { supabase } from '../lib/supabase';
import { logger } from '../lib/logger';
import type { Coordinates, Venue, GeofenceEvent } from './types';

interface RadarGeofenceState {
  isTracking: boolean;
  currentLocation: Coordinates | null;
  currentVenue: Venue | null;
  nearbyVenues: Venue[];
  lastUpdate: number | null;
}

interface RadarGeofenceConfig {
  autoStart?: boolean;
  updateIntervalStopped?: number;
  updateIntervalMoving?: number;
  searchRadius?: number;
}

export function useRadarGeofencing(config: RadarGeofenceConfig = {}) {
  const {
    autoStart = false,
    updateIntervalStopped = 60,
    updateIntervalMoving = 30,
    searchRadius = 1000,
  } = config;

  const [state, setState] = useState<RadarGeofenceState>({
    isTracking: false,
    currentLocation: null,
    currentVenue: null,
    nearbyVenues: [],
    lastUpdate: null,
  });

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const eventListenersRef = useRef<((event: GeofenceEvent) => void)[]>([]);
  const unsubscribersRef = useRef<(() => void)[]>([]);

  const emitEvent = useCallback((event: GeofenceEvent) => {
    eventListenersRef.current.forEach((listener) => listener(event));
  }, []);

  const addEventListener = useCallback(
    (listener: (event: GeofenceEvent) => void) => {
      eventListenersRef.current.push(listener);
      return () => {
        eventListenersRef.current = eventListenersRef.current.filter(
          (l) => l !== listener
        );
      };
    },
    []
  );

  const fetchNearbyVenues = useCallback(
    async (location: Coordinates): Promise<Venue[]> => {
      try {
        const degreeBuffer = (searchRadius / 1000) / 111;
        const { data, error: queryError } = await supabase
          .from('venues')
          .select('*')
          .eq('is_active', true)
          .gte('lat', location.lat - degreeBuffer)
          .lte('lat', location.lat + degreeBuffer)
          .gte('lng', location.lng - degreeBuffer)
          .lte('lng', location.lng + degreeBuffer)
          .limit(200);

        if (queryError) throw queryError;

        const venues = (data || [])
          .map((venue) => {
            const distance = calculateDistance(
              location.lat,
              location.lng,
              venue.lat,
              venue.lng
            );
            return { ...venue, distance };
          })
          .filter((venue) => venue.distance <= searchRadius)
          .sort((a, b) => a.distance - b.distance);

        return venues;
      } catch (err) {
        logger.error('Error fetching nearby venues:', err);
        return [];
      }
    },
    [searchRadius]
  );

  const updateLocation = useCallback(async () => {
    try {
      const location = await radarService.getUserLocation();
      if (!location) return;

      const venues = await fetchNearbyVenues(location);

      setState((prev) => ({
        ...prev,
        currentLocation: location,
        nearbyVenues: venues,
        lastUpdate: Date.now(),
      }));
    } catch (err) {
      logger.error('Error updating location:', err);
      setError('Failed to update location');
    }
  }, [fetchNearbyVenues]);

  const startTracking = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);

      await radarService.initialize();

      const { data: sessionData } = await supabase.auth.getSession();
      if (sessionData.session?.user) {
        radarService.setUserId(sessionData.session.user.id);
      }

      const unsubscribeEnter = radarService.onGeofenceEvent(
        'enter',
        (event) => {
          if (event.geofence?.externalId) {
            fetchVenueDetails(event.geofence.externalId).then((venue) => {
              if (venue) {
                setState((prev) => ({ ...prev, currentVenue: venue }));
                emitEvent({
                  type: 'ENTER',
                  venue,
                  timestamp: Date.now(),
                  coordinates: event.location
                    ? {
                        lat: event.location.latitude,
                        lng: event.location.longitude,
                      }
                    : undefined,
                });
              }
            });
          }
        }
      );

      const unsubscribeExit = radarService.onGeofenceEvent('exit', (event) => {
        setState((prev) => ({ ...prev, currentVenue: null }));
        if (event.geofence?.externalId) {
          fetchVenueDetails(event.geofence.externalId).then((venue) => {
            if (venue) {
              emitEvent({
                type: 'EXIT',
                venue,
                timestamp: Date.now(),
                coordinates: event.location
                  ? {
                      lat: event.location.latitude,
                      lng: event.location.longitude,
                    }
                  : undefined,
              });
            }
          });
        }
      });

      unsubscribersRef.current = [unsubscribeEnter, unsubscribeExit];

      radarService.startTracking({
        desiredStoppedUpdateInterval: updateIntervalStopped,
        desiredMovingUpdateInterval: updateIntervalMoving,
      });

      await updateLocation();

      setState((prev) => ({ ...prev, isTracking: true }));
    } catch (err) {
      logger.error('Error starting tracking:', err);
      setError('Failed to start tracking');
    } finally {
      setIsLoading(false);
    }
  }, [
    updateIntervalStopped,
    updateIntervalMoving,
    updateLocation,
    emitEvent,
  ]);

  const stopTracking = useCallback(() => {
    radarService.stopTracking();
    unsubscribersRef.current.forEach((unsub) => unsub());
    unsubscribersRef.current = [];
    setState((prev) => ({ ...prev, isTracking: false }));
  }, []);

  const syncVenueGeofences = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);

      const location = state.currentLocation;
      let query = supabase
        .from('venues')
        .select('*')
        .eq('is_active', true);

      if (location) {
        const degreeBuffer = (searchRadius / 1000) / 111;
        query = query
          .gte('lat', location.lat - degreeBuffer)
          .lte('lat', location.lat + degreeBuffer)
          .gte('lng', location.lng - degreeBuffer)
          .lte('lng', location.lng + degreeBuffer);
      }

      const { data: venues, error: queryError } = await query.limit(500);

      if (queryError) throw queryError;

      const result = await radarService.syncVenuesToRadar(venues || []);

      return result;
    } catch (err) {
      logger.error('Error syncing venues:', err);
      setError('Failed to sync venues');
      return { success: 0, failed: 0 };
    } finally {
      setIsLoading(false);
    }
  }, [state.currentLocation, searchRadius]);

  useEffect(() => {
    if (autoStart) {
      startTracking();
    }

    return () => {
      stopTracking();
    };
  }, []);

  return {
    state,
    isLoading,
    error,
    startTracking,
    stopTracking,
    updateLocation,
    syncVenueGeofences,
    addEventListener,
  };
}

async function fetchVenueDetails(venueId: string): Promise<Venue | null> {
  try {
    const { data, error } = await supabase
      .from('venues')
      .select('*')
      .eq('id', venueId)
      .maybeSingle();

    if (error) throw error;
    return data;
  } catch (err) {
    logger.error('Error fetching venue details:', err);
    return null;
  }
}

function calculateDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371e3;
  const \u03c61 = (lat1 * Math.PI) / 180;
  const \u03c62 = (lat2 * Math.PI) / 180;
  const \u0394\u03c6 = ((lat2 - lat1) * Math.PI) / 180;
  const \u0394\u03bb = ((lng2 - lng1) * Math.PI) / 180;

  const a =
    Math.sin(\u0394\u03c6 / 2) * Math.sin(\u0394\u03c6 / 2) +
    Math.cos(\u03c61) * Math.cos(\u03c62) * Math.sin(\u0394\u03bb / 2) * Math.sin(\u0394\u03bb / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}
