import { useState, useEffect, useRef, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import locationService, { RealTimeUser, RealTimeVenue } from '../services/locationService';
import type { VibeTag } from '../data/dummyData';
import { logger } from '../lib/logger';

export interface MapSwarm {
  id: string;
  name: string;
  venueId: string;
  venueName: string;
  lat: number;
  lng: number;
  vibes: VibeTag[];
  memberCount: number;
  maxSize: number;
  hostId: string;
  hostName: string;
  startTime: string;
  description: string;
  isPublic: boolean;
}

export interface MapUserProfile extends RealTimeUser {
  avatar_url?: string;
}

export function useMapData(
  userLocation: { lat: number; lng: number } | null,
  distanceFilter: number,
  searchCenter?: { lat: number; lng: number } | null,
) {
  const [swarms, setSwarms] = useState<MapSwarm[]>([]);
  const [users, setUsers] = useState<MapUserProfile[]>([]);
  const [venues, setVenues] = useState<RealTimeVenue[]>([]);
  const unsubscribeRef = useRef<(() => void) | null>(null);

  const enrichUserProfiles = useCallback(async (rawUsers: RealTimeUser[]): Promise<MapUserProfile[]> => {
    const userIds = rawUsers.map(u => u.id);
    if (userIds.length === 0) return [];

    const { data: profiles } = await supabase
      .from('users')
      .select('id, avatar_url')
      .in('id', userIds);

    const profileMap = new Map((profiles || []).map(p => [p.id, p]));

    return rawUsers.map(user => ({
      ...user,
      avatar_url: profileMap.get(user.id)?.avatar_url,
    }));
  }, []);

  const fetchSwarms = async () => {
    try {
      const { data } = await supabase
        .from('swarms')
        .select(`
          id,
          title,
          description,
          vibe_tags,
          start_time,
          end_time,
          max_attendees,
          join_mode,
          status,
          host_user_id,
          venue_id,
          host:users!swarms_host_user_id_fkey(name),
          venue:venues!swarms_venue_id_fkey(name, lat, lng),
          swarm_members(count)
        `)
        .eq('status', 'active');

      if (data) {
        const now = new Date();
        const expiredIds: string[] = [];

        const mapped: MapSwarm[] = data
          .filter((s: Record<string, unknown>) => {
            const endTime = s.end_time ? new Date(s.end_time as string) : null;
            if (endTime && endTime < now) {
              expiredIds.push(s.id as string);
              return false;
            }
            return true;
          })
          .map((s: Record<string, unknown>) => {
            const venue = s.venue as { name?: string; lat?: number; lng?: number } | null;
            const host = s.host as { name?: string } | null;
            const startDate = s.start_time ? new Date(s.start_time as string) : null;
            const timeStr = startDate
              ? startDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true })
              : 'Tonight';
            const membersArr = s.swarm_members as { count: number }[] | null;
            const memberCount = membersArr?.[0]?.count ?? 1;
            return {
              id: s.id as string,
              name: s.title as string,
              venueId: (s.venue_id as string) || '',
              venueName: venue?.name || 'Unknown Venue',
              lat: venue?.lat || 0,
              lng: venue?.lng || 0,
              vibes: (s.vibe_tags as VibeTag[]) || [],
              memberCount,
              maxSize: (s.max_attendees as number) || 8,
              hostId: s.host_user_id as string,
              hostName: host?.name || 'Anonymous',
              startTime: timeStr,
              description: (s.description as string) || '',
              isPublic: s.join_mode === 'open',
            };
          });

        if (expiredIds.length > 0) {
          supabase
            .from('swarms')
            .update({ status: 'completed' })
            .in('id', expiredIds)
            .then(({ error: expErr }) => {
              if (expErr) logger.error('Error expiring swarms:', expErr);
            });
        }

        setSwarms(mapped);
      }
    } catch (err) {
      logger.error('Error fetching swarms:', err);
    }
  };

  const fetchVenuesAndUsers = async () => {
    try {
      const fetchCenter = searchCenter || userLocation;
      if (fetchCenter) {
        const countryCode = localStorage.getItem('userCountryCode') || 'US';
        const nearbyVenues = await locationService.fetchNearbyVenues(fetchCenter.lat, fetchCenter.lng, distanceFilter, countryCode);
        setVenues(nearbyVenues);
      }

      const [venueUsers, nearbyUsers] = await Promise.all([
        locationService.fetchUsersAtVenues(),
        (searchCenter || userLocation)
          ? locationService.fetchNearbyUsers(
              (searchCenter || userLocation)!.lat,
              (searchCenter || userLocation)!.lng,
              distanceFilter,
            )
          : Promise.resolve([]),
      ]);

      const venueUserIds = new Set(venueUsers.map(u => u.id));
      const merged = [
        ...venueUsers,
        ...nearbyUsers.filter(u => !venueUserIds.has(u.id)),
      ];

      const enriched = await enrichUserProfiles(merged);
      setUsers(enriched);
    } catch (err) {
      logger.error('Error fetching venues and users:', err);
    }
  };

  const userLocationRef = useRef(userLocation);
  const distanceFilterRef = useRef(distanceFilter);
  userLocationRef.current = userLocation;
  distanceFilterRef.current = distanceFilter;

  useEffect(() => {
    fetchSwarms();

    const unsubscribePresence = locationService.subscribeToVenuePresence(async (venueUsers) => {
      const loc = userLocationRef.current;
      const dist = distanceFilterRef.current;
      const nearbyUsers = loc
        ? await locationService.fetchNearbyUsers(loc.lat, loc.lng, dist)
        : [];
      const venueUserIds = new Set(venueUsers.map(u => u.id));
      const merged = [...venueUsers, ...nearbyUsers.filter(u => !venueUserIds.has(u.id))];
      const enriched = await enrichUserProfiles(merged);
      setUsers(enriched);
    });

    const unsubscribeLocation = locationService.subscribeToUserLocation((location) => {
      if (location) {
        const countryCode = localStorage.getItem('userCountryCode') || 'US';
        locationService.fetchNearbyVenues(location.lat, location.lng, distanceFilterRef.current, countryCode).then(setVenues);
      }
    });

    unsubscribeRef.current = () => {
      unsubscribePresence();
      unsubscribeLocation();
    };

    return () => { unsubscribeRef.current?.(); };
  }, [enrichUserProfiles]);

  useEffect(() => {
    const interval = setInterval(fetchVenuesAndUsers, 10000);
    fetchVenuesAndUsers();
    return () => clearInterval(interval);
  }, [userLocation, distanceFilter, searchCenter?.lat, searchCenter?.lng]);

  return { swarms, users, venues };
}
