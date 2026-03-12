import { useEffect, useRef, useState, useCallback } from 'react';
import { supabase } from '../lib/supabase';

const MIN_UPDATE_INTERVAL_MS = 3000;
const MIN_DISTANCE_METERS = 5;

function haversineDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371000;
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLng = (lng2 - lng1) * (Math.PI / 180);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export function useRealTimeLocation() {
  const [location, setLocation] = useState<{ lat: number; lng: number } | null>(null);
  const watchIdRef = useRef<number | null>(null);
  const lastWriteRef = useRef<{ lat: number; lng: number; time: number } | null>(null);
  const userIdRef = useRef<string | null>(null);

  const writeToDb = useCallback(async (lat: number, lng: number, accuracy: number) => {
    if (!userIdRef.current) return;

    const now = Date.now();
    const last = lastWriteRef.current;
    if (last) {
      const timeDelta = now - last.time;
      const distDelta = haversineDistance(last.lat, last.lng, lat, lng);
      if (timeDelta < MIN_UPDATE_INTERVAL_MS && distDelta < MIN_DISTANCE_METERS) return;
    }

    lastWriteRef.current = { lat, lng, time: now };

    try {
      await supabase.from('users').update({
        last_known_lat: lat,
        last_known_lng: lng,
        last_active_at: new Date().toISOString(),
      }).eq('id', userIdRef.current);

      await supabase.from('location_pings').insert({
        user_id: userIdRef.current,
        latitude: lat,
        longitude: lng,
        accuracy,
        is_background: false,
      });
    } catch (error) {
      console.error('Location write error:', error);
    }
  }, []);

  useEffect(() => {
    if (!('geolocation' in navigator)) return;

    (async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;
      userIdRef.current = user.id;
    })();

    watchIdRef.current = navigator.geolocation.watchPosition(
      (position) => {
        const { latitude, longitude, accuracy } = position.coords;
        setLocation({ lat: latitude, lng: longitude });
        writeToDb(latitude, longitude, accuracy);
      },
      (error) => {
        console.error('Geolocation error:', error);
      },
      {
        enableHighAccuracy: true,
        maximumAge: 5000,
        timeout: 15000,
      }
    );

    return () => {
      if (watchIdRef.current !== null) {
        navigator.geolocation.clearWatch(watchIdRef.current);
      }
    };
  }, [writeToDb]);

  return location;
}
