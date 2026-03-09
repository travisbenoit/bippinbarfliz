import { useState, useEffect } from 'react';
import { TrendingUp, Users, Star, MapPin, Flame } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

interface TrendingVenue {
  id: string;
  name: string;
  category: string;
  address: string | null;
  active_count: number;
  friend_count: number;
  avg_friend_rating: number | null;
}

interface Props {
  onVenueSelect?: (venueId: string, venueName: string) => void;
}

export function TrendingVenues({ onVenueSelect }: Props) {
  const { user } = useAuth();
  const [venues, setVenues] = useState<TrendingVenue[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    load();
    const interval = setInterval(load, 60000);
    return () => clearInterval(interval);
  }, []);

  const load = async () => {
    if (!user) { setLoading(false); return; }

    const { data: presences } = await supabase
      .from('user_venue_presence')
      .select('venue_id, venues(id, name, category, address)')
      .eq('status', 'IN_VENUE')
      .eq('is_visible_in_venue', true);

    if (!presences?.length) { setLoading(false); return; }

    const { data: friends } = await supabase
      .from('friendships')
      .select('user_id, friend_id')
      .eq('status', 'accepted')
      .or(`user_id.eq.${user.id},friend_id.eq.${user.id}`);

    const friendIds = new Set((friends || []).map(f => f.user_id === user.id ? f.friend_id : f.user_id));

    const venueMap: Record<string, TrendingVenue> = {};
    presences.forEach((p: any) => {
      const v = p.venues;
      if (!v) return;
      if (!venueMap[v.id]) {
        venueMap[v.id] = { id: v.id, name: v.name, category: v.category || 'bar', address: v.address, active_count: 0, friend_count: 0, avg_friend_rating: null };
      }
      venueMap[v.id].active_count++;
      if (friendIds.has(p.user_id)) venueMap[v.id].friend_count++;
    });

    const venueIds = Object.keys(venueMap);
    if (venueIds.length > 0) {
      const { data: ratings } = await supabase
        .from('venue_ratings')
        .select('venue_id, rating, user_id')
        .in('venue_id', venueIds);

      (ratings || []).forEach((r: any) => {
        if (friendIds.has(r.user_id) || r.user_id === user.id) {
          const v = venueMap[r.venue_id];
          if (v) {
            v.avg_friend_rating = v.avg_friend_rating === null ? r.rating : (v.avg_friend_rating + r.rating) / 2;
          }
        }
      });
    }

    const sorted = Object.values(venueMap)
      .sort((a, b) => (b.friend_count * 3 + b.active_count) - (a.friend_count * 3 + a.active_count))
      .slice(0, 8);

    setVenues(sorted);
    setLoading(false);
  };

  const categoryIcon = (cat: string) => {
    const icons: Record<string, string> = { club: '🎵', brewery: '🍺', rooftop: '🌆', lounge: '🍸', sports_bar: '🏈', bar: '🍻' };
    return icons[cat] || '🍻';
  };

  const heatColor = (count: number) => {
    if (count >= 10) return 'text-red-600 bg-red-50';
    if (count >= 5) return 'text-orange-600 bg-orange-50';
    if (count >= 2) return 'text-amber-600 bg-amber-50';
    return 'text-gray-500 bg-gray-50';
  };

  if (loading) {
    return (
      <div className="space-y-3">
        {[1, 2, 3].map(i => (
          <div key={i} className="h-20 bg-gray-100 rounded-2xl animate-pulse" />
        ))}
      </div>
    );
  }

  if (venues.length === 0) {
    return (
      <div className="text-center py-8">
        <TrendingUp className="w-8 h-8 text-gray-200 mx-auto mb-2" />
        <p className="text-sm text-gray-400">No active venues right now</p>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {venues.map((venue, index) => (
        <button
          key={venue.id}
          onClick={() => onVenueSelect?.(venue.id, venue.name)}
          className="w-full flex items-center gap-3 p-3 bg-white rounded-2xl shadow-sm hover:shadow-md transition-all text-left"
        >
          <div className="w-11 h-11 rounded-xl bg-gray-50 flex items-center justify-center text-xl flex-shrink-0">
            {index < 3 ? (
              <span className="text-base font-black text-gray-400">#{index + 1}</span>
            ) : (
              <span>{categoryIcon(venue.category)}</span>
            )}
          </div>
          <div className="flex-1 min-w-0">
            <p className="font-semibold text-gray-900 text-sm truncate">{venue.name}</p>
            <div className="flex items-center gap-2 mt-0.5">
              {venue.friend_count > 0 && (
                <span className="flex items-center gap-1 text-xs text-[#E91E63] font-medium">
                  <Users className="w-3 h-3" /> {venue.friend_count} friend{venue.friend_count > 1 ? 's' : ''}
                </span>
              )}
              {venue.avg_friend_rating && (
                <span className="flex items-center gap-1 text-xs text-amber-600">
                  <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                  {venue.avg_friend_rating.toFixed(1)}
                </span>
              )}
            </div>
          </div>
          <div className={`flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold ${heatColor(venue.active_count)}`}>
            <Flame className="w-3 h-3" />
            {venue.active_count}
          </div>
        </button>
      ))}
    </div>
  );
}
