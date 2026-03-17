import { supabase } from '../lib/supabase';
import { logger } from '../lib/logger';
import { RealtimeChannel } from '@supabase/supabase-js';

export interface RealTimeUser {
  id: string;
  name: string;
  visibilityMode: 'public' | 'friends' | 'private';
  tonightStatus: 'going_out' | 'maybe' | 'staying_in';
  tonightVenue: string | null;
  lat: number;
  lng: number;
  favoriteDrinks: string[];
  vibes: string[];
  currentVenueId?: string;
  dwellSeconds?: number;
}

export interface RealTimeVenue {
  id: string;
  name: string;
  lat: number;
  lng: number;
  category: string;
  rating?: number;
  price_level?: string;
  address?: string;
  vibes: string[];
  user_count: number;
  is_active: boolean;
  photo_url?: string;
  phone?: string;
  website?: string;
  hours?: any;
  user_ratings_total?: number;
}

export interface LocationData {
  users: RealTimeUser[];
  venues: RealTimeVenue[];
  userLocation?: { lat: number; lng: number };
}

class LocationService {
  private presenceChannel: RealtimeChannel | null = null;
  private userLocationChannel: RealtimeChannel | null = null;

  async fetchNearbyVenues(centerLat: number, centerLng: number, radiusKm: number, countryCode?: string): Promise<RealTimeVenue[]> {
    try {
      let query = supabase
        .from('venues')
        .select('*')
        .eq('is_active', true);

      const country = countryCode || localStorage.getItem('userCountryCode') || 'US';
      const countryMap: Record<string, string> = {
        'AU': 'AU',
        'US': 'US',
        'GB': 'GB',
        'CA': 'CA',
        'DE': 'DE',
        'NZ': 'NZ',
      };

      const mappedCountry = countryMap[country] || 'US';
      query = query.eq('country', mappedCountry);

      const { data: venues, error } = await query.limit(500);

      if (error) {
        logger.error('Error fetching venues:', error);
        return [];
      }

      const validVenues = venues?.filter(venue => venue.lat != null && venue.lng != null) || [];

      if (validVenues.length === 0) return [];

      const venueIds = validVenues.map(v => v.id);
      const { data: counts } = await supabase
        .from('user_venue_presence')
        .select('venue_id')
        .in('venue_id', venueIds)
        .eq('status', 'IN_VENUE')
        .eq('is_visible_in_venue', true);

      const countMap: Record<string, number> = {};
      (counts || []).forEach((c: any) => {
        countMap[c.venue_id] = (countMap[c.venue_id] || 0) + 1;
      });

      return validVenues.map((venue: any) => ({
        id: venue.id,
        name: venue.name,
        lat: venue.lat as number,
        lng: venue.lng as number,
        category: venue.category || venue.type || 'bar',
        rating: venue.rating,
        price_level: venue.price_level,
        address: venue.address || venue.name,
        vibes: venue.vibes || [],
        user_count: countMap[venue.id] || 0,
        is_active: venue.is_active ?? true,
        photo_url: venue.photo_url,
        phone: venue.phone,
        website: venue.website,
        hours: venue.hours,
        user_ratings_total: venue.user_ratings_total,
      }));
    } catch (error) {
      logger.error('Error in fetchNearbyVenues:', error);
      return [];
    }
  }

  async fetchNearbyUsers(centerLat: number, centerLng: number, radiusKm: number): Promise<RealTimeUser[]> {
    try {
      const { data: { user: currentUser } } = await supabase.auth.getUser();
      const { data: users, error } = await supabase
        .from('users')
        .select('id, name, avatar_url, privacy_mode, favorite_drinks, vibe_tags, tonight_status, last_known_lat, last_known_lng, ghost_mode')
        .neq('ghost_mode', true)
        .in('tonight_status', ['out_now', 'going_out_soon'])
        .not('last_known_lat', 'is', null)
        .not('last_known_lng', 'is', null)
        .limit(100);

      if (error) {
        logger.error('Error fetching nearby users:', error);
        return [];
      }

      return (users || [])
        .filter(u => {
          if (currentUser && u.id === currentUser.id) return false;
          if (!u.last_known_lat || !u.last_known_lng) return false;
          const dist = this.calculateDistance(centerLat, centerLng, u.last_known_lat, u.last_known_lng);
          return dist <= radiusKm;
        })
        .map(u => ({
          id: u.id,
          name: u.name,
          visibilityMode: (u.privacy_mode === 'invisible' ? 'private' : u.privacy_mode === 'friends_only' ? 'friends' : 'public') as RealTimeUser['visibilityMode'],
          tonightStatus: (u.tonight_status === 'out_now' ? 'going_out' : u.tonight_status === 'going_out_soon' ? 'going_out' : 'staying_in') as RealTimeUser['tonightStatus'],
          tonightVenue: null,
          lat: u.last_known_lat!,
          lng: u.last_known_lng!,
          favoriteDrinks: u.favorite_drinks || [],
          vibes: u.vibe_tags || [],
        }));
    } catch (error) {
      logger.error('Error in fetchNearbyUsers:', error);
      return [];
    }
  }

  async fetchUsersAtVenues(): Promise<RealTimeUser[]> {
    try {
      const { data: presences, error } = await supabase
        .from('user_venue_presence')
        .select(`
          user_id,
          venue_id,
          status,
          dwell_seconds,
          entered_at,
          is_visible_in_venue,
          users:user_id (
            id,
            name,
            privacy_mode,
            favorite_drinks,
            vibe_tags,
            tonight_status
          ),
          venues:venue_id (
            id,
            name,
            lat,
            lng
          )
        `)
        .eq('status', 'IN_VENUE')
        .eq('is_visible_in_venue', true);

      if (error) {
        logger.error('Error fetching venue presences:', error);
        return [];
      }

      return presences?.map((presence: any) => ({
        id: presence.users.id,
        name: presence.users.name,
        visibilityMode: presence.users.privacy_mode === 'invisible' ? 'private' : presence.users.privacy_mode === 'friends_only' ? 'friends' : 'public',
        tonightStatus: presence.users.tonight_status === 'out_now' ? 'going_out' : presence.users.tonight_status === 'going_out_soon' ? 'going_out' : 'staying_in',
        tonightVenue: presence.venues.name,
        lat: presence.venues.lat as number,
        lng: presence.venues.lng as number,
        favoriteDrinks: presence.users.favorite_drinks || [],
        vibes: presence.users.vibe_tags || [],
        currentVenueId: presence.venue_id,
        dwellSeconds: presence.dwell_seconds,
      })) || [];
    } catch (error) {
      logger.error('Error in fetchUsersAtVenues:', error);
      return [];
    }
  }

  async fetchCurrentUserLocation(): Promise<{ lat: number; lng: number } | null> {
    if (localStorage.getItem('demo_mode') === 'true') {
      const demoCountry = localStorage.getItem('userCountryCode') || 'US';
      return demoCountry === 'AU'
        ? { lat: -12.4634, lng: 130.8456 }
        : { lat: 26.1003, lng: -80.3882 };
    }

    if ('geolocation' in navigator) {
      try {
        const pos = await new Promise<GeolocationPosition>((resolve, reject) => {
          navigator.geolocation.getCurrentPosition(resolve, reject, { timeout: 5000, maximumAge: 30000 });
        });
        return { lat: pos.coords.latitude, lng: pos.coords.longitude };
      } catch {
        // fall through to DB lookup
      }
    }

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;

      const { data: profile } = await supabase
        .from('users')
        .select('last_known_lat, last_known_lng')
        .eq('id', user.id)
        .maybeSingle();

      if (profile?.last_known_lat && profile?.last_known_lng) {
        return {
          lat: profile.last_known_lat as number,
          lng: profile.last_known_lng as number,
        };
      }

      return null;
    } catch (error) {
      logger.error('Error fetching current user location:', error);
      return null;
    }
  }

  subscribeToVenuePresence(callback: (users: RealTimeUser[]) => void): () => void {
    this.presenceChannel = supabase
      .channel('venue_presence_changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'user_venue_presence',
        },
        async () => {
          const users = await this.fetchUsersAtVenues();
          callback(users);
        }
      )
      .subscribe();

    return () => {
      if (this.presenceChannel) {
        supabase.removeChannel(this.presenceChannel);
        this.presenceChannel = null;
      }
    };
  }

  subscribeToUserLocation(callback: (location: { lat: number; lng: number } | null) => void): () => void {
    this.userLocationChannel = supabase
      .channel('user_location_changes')
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'users',
        },
        async () => {
          const location = await this.fetchCurrentUserLocation();
          callback(location);
        }
      )
      .subscribe();

    return () => {
      if (this.userLocationChannel) {
        supabase.removeChannel(this.userLocationChannel);
        this.userLocationChannel = null;
      }
    };
  }

  async fetchVenueUserCount(venueId: string): Promise<number> {
    try {
      const { count, error } = await supabase
        .from('user_venue_presence')
        .select('*', { count: 'exact', head: true })
        .eq('venue_id', venueId)
        .eq('status', 'IN_VENUE')
        .eq('is_visible_in_venue', true);

      if (error) {
        logger.error('Error fetching venue user count:', error);
        return 0;
      }

      return count || 0;
    } catch (error) {
      logger.error('Error in fetchVenueUserCount:', error);
      return 0;
    }
  }

  calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371;
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLng = (lng2 - lng1) * (Math.PI / 180);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * (Math.PI / 180)) *
        Math.cos(lat2 * (Math.PI / 180)) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }
}

export default new LocationService();
