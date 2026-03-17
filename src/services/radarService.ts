import { supabase } from '../lib/supabase';
import { logger } from '../lib/logger';
import type { Coordinates, Venue } from '../geolocation/types';

type RadarSDK = typeof import('radar-sdk-js').default;
let _radar: RadarSDK | null = null;

async function getRadar(): Promise<RadarSDK> {
  if (!_radar) {
    const mod = await import('radar-sdk-js');
    _radar = mod.default;
  }
  return _radar;
}

interface RadarLocation {
  latitude: number;
  longitude: number;
  accuracy: number;
}

interface RadarGeofence {
  _id: string;
  tag?: string;
  externalId?: string;
  description: string;
  metadata?: Record<string, any>;
}

interface RadarEvent {
  type: 'user.entered_geofence' | 'user.exited_geofence' | 'user.dwelled_in_geofence';
  geofence?: RadarGeofence;
  location?: RadarLocation;
  confidence: 'high' | 'medium' | 'low';
}

class RadarService {
  private initialized = false;
  private userId: string | null = null;
  private eventHandlers: Map<string, (event: RadarEvent) => void> = new Map();

  async initialize() {
    if (this.initialized) return;

    const publishableKey = import.meta.env.VITE_RADAR_PUBLISHABLE_KEY;
    if (!publishableKey) {
      throw new Error('Radar publishable key not configured');
    }

    const Radar = await getRadar();
    Radar.initialize(publishableKey);
    this.initialized = true;

    const { data: { session } } = await supabase.auth.getSession();
    if (session?.user) {
      await this.setUserId(session.user.id);
    }
  }

  async setUserId(userId: string) {
    if (!this.initialized) {
      throw new Error('Radar not initialized');
    }
    this.userId = userId;
    const Radar = await getRadar();
    Radar.setUserId(userId);
  }

  async trackOnce(location?: Coordinates): Promise<RadarLocation | null> {
    if (!this.initialized) {
      await this.initialize();
    }

    try {
      const Radar = await getRadar();
      let result;

      if (location) {
        result = await Radar.trackOnce({
          latitude: location.lat,
          longitude: location.lng,
        });
      } else {
        result = await Radar.trackOnce();
      }

      if (result?.location) {
        this.processRadarEvents(result.events || []);
        return result.location;
      }

      return null;
    } catch (error) {
      logger.error('Radar trackOnce error:', error);
      return null;
    }
  }

  async startTracking(options?: {
    desiredStoppedUpdateInterval?: number;
    desiredMovingUpdateInterval?: number;
    desiredSyncInterval?: number;
  }) {
    if (!this.initialized) {
      throw new Error('Radar not initialized');
    }

    const Radar = await getRadar();
    Radar.startTrackingContinuous({
      desiredStoppedUpdateInterval: options?.desiredStoppedUpdateInterval || 60,
      desiredMovingUpdateInterval: options?.desiredMovingUpdateInterval || 30,
      desiredSyncInterval: options?.desiredSyncInterval || 60,
    });
  }

  async stopTracking() {
    if (!this.initialized) return;
    const Radar = await getRadar();
    Radar.stopTracking();
  }

  async createGeofenceForVenue(venue: Venue): Promise<boolean> {
    try {
      const { data: sessionData } = await supabase.auth.getSession();
      if (!sessionData.session) {
        logger.error('No active session');
        return false;
      }

      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/radar-geofences`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${sessionData.session.access_token}`,
          },
          body: JSON.stringify({
            action: 'create',
            venue: {
              id: venue.id,
              name: venue.name,
              lat: venue.lat,
              lng: venue.lng,
              type: venue.type,
              city: venue.city,
              state: venue.state,
              geofence_radius_meters: venue.geofence_radius_meters || 50,
            },
          }),
        }
      );

      if (!response.ok) {
        const error = await response.json();
        logger.error('Failed to create Radar geofence:', error);
        return false;
      }

      const result = await response.json();
      return result.success;
    } catch (error) {
      logger.error('Error creating Radar geofence:', error);
      return false;
    }
  }

  async syncVenuesToRadar(venues: Venue[]): Promise<{ success: number; failed: number }> {
    let success = 0;
    let failed = 0;

    for (const venue of venues) {
      const created = await this.createGeofenceForVenue(venue);
      if (created) {
        success++;
      } else {
        failed++;
      }
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    return { success, failed };
  }

  async deleteGeofence(venueId: string): Promise<boolean> {
    try {
      const { data: sessionData } = await supabase.auth.getSession();
      if (!sessionData.session) {
        logger.error('No active session');
        return false;
      }

      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/radar-geofences`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${sessionData.session.access_token}`,
          },
          body: JSON.stringify({
            action: 'delete',
            venue_id: venueId,
          }),
        }
      );

      if (!response.ok) {
        return false;
      }

      const result = await response.json();
      return result.success;
    } catch (error) {
      logger.error('Error deleting Radar geofence:', error);
      return false;
    }
  }

  async searchPlaces(
    location: Coordinates,
    radius: number = 1000,
    chains?: string[]
  ): Promise<any[]> {
    if (!this.initialized) {
      await this.initialize();
    }

    try {
      const Radar = await getRadar();
      const result = await Radar.searchPlaces({
        near: {
          latitude: location.lat,
          longitude: location.lng,
        },
        radius,
        chains,
        limit: 100,
      });

      return result?.places || [];
    } catch (error) {
      logger.error('Radar searchPlaces error:', error);
      return [];
    }
  }

  onGeofenceEvent(
    eventType: 'enter' | 'exit' | 'dwell',
    handler: (event: RadarEvent) => void
  ): () => void {
    const key = `${eventType}_${Date.now()}`;
    this.eventHandlers.set(key, handler);

    return () => {
      this.eventHandlers.delete(key);
    };
  }

  private async processRadarEvents(events: RadarEvent[]) {
    for (const event of events) {
      if (event.type === 'user.entered_geofence') {
        this.notifyHandlers('enter', event);
        await this.handleVenueEntry(event);
      } else if (event.type === 'user.exited_geofence') {
        this.notifyHandlers('exit', event);
        await this.handleVenueExit(event);
      } else if (event.type === 'user.dwelled_in_geofence') {
        this.notifyHandlers('dwell', event);
      }
    }
  }

  private notifyHandlers(eventType: 'enter' | 'exit' | 'dwell', event: RadarEvent) {
    this.eventHandlers.forEach((handler, key) => {
      if (key.startsWith(eventType)) {
        handler(event);
      }
    });
  }

  private async handleVenueEntry(event: RadarEvent) {
    if (!event.geofence?.externalId || !event.location) return;

    try {
      const { data: sessionData } = await supabase.auth.getSession();
      if (!sessionData.session) return;

      await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/enter-venue`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${sessionData.session.access_token}`,
          },
          body: JSON.stringify({
            venue_id: event.geofence.externalId,
            user_lat: event.location.latitude,
            user_lng: event.location.longitude,
            source: 'radar',
            confidence: event.confidence,
          }),
        }
      );
    } catch (error) {
      logger.error('Error handling venue entry:', error);
    }
  }

  private async handleVenueExit(event: RadarEvent) {
    if (!event.geofence?.externalId) return;

    try {
      const { data: sessionData } = await supabase.auth.getSession();
      if (!sessionData.session) return;

      const { data: presence } = await supabase
        .from('user_venue_presence')
        .select('id')
        .eq('user_id', sessionData.session.user.id)
        .eq('venue_id', event.geofence.externalId)
        .eq('status', 'IN_VENUE')
        .maybeSingle();

      if (presence) {
        await fetch(
          `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/leave-venue`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${sessionData.session.access_token}`,
            },
            body: JSON.stringify({
              presence_id: presence.id,
              user_lat: event.location?.latitude,
              user_lng: event.location?.longitude,
              source: 'radar',
            }),
          }
        );
      }
    } catch (error) {
      logger.error('Error handling venue exit:', error);
    }
  }

  async getGeofences(): Promise<any[]> {
    try {
      const { data: sessionData } = await supabase.auth.getSession();
      if (!sessionData.session) {
        logger.error('No active session');
        return [];
      }

      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/radar-geofences`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${sessionData.session.access_token}`,
          },
          body: JSON.stringify({
            action: 'list',
          }),
        }
      );

      if (!response.ok) {
        throw new Error('Failed to fetch geofences');
      }

      const data = await response.json();
      return data.geofences || [];
    } catch (error) {
      logger.error('Error fetching geofences:', error);
      return [];
    }
  }

  async getUserLocation(): Promise<Coordinates | null> {
    const location = await this.trackOnce();
    if (location) {
      return {
        lat: location.latitude,
        lng: location.longitude,
      };
    }
    return null;
  }

  isInitialized(): boolean {
    return this.initialized;
  }
}

export const radarService = new RadarService();
