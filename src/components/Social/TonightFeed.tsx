import { useState, useEffect } from 'react';
import { Users, Car, MapPin, Flame, User as UserIcon } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

interface TonightUser {
  id: string;
  name: string;
  avatar_url: string | null;
  tonight_status: string | null;
  vibe_tags: string[];
  is_dd_tonight: boolean;
  current_venue_name?: string;
}

interface Props {
  onSelectUser?: (userId: string) => void;
}

export function TonightFeed({ onSelectUser }: Props) {
  const { user } = useAuth();
  const [users, setUsers] = useState<TonightUser[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    load();
    const channel = supabase
      .channel('tonight_status_changes')
      .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'users' }, () => {
        load();
      })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, []);

  const load = async () => {
    if (!user) return;
    const { data: friends } = await supabase
      .from('friendships')
      .select('user_id, friend_id')
      .eq('status', 'accepted')
      .or(`user_id.eq.${user.id},friend_id.eq.${user.id}`);

    if (!friends || friends.length === 0) { setLoading(false); return; }

    const friendIds = friends.map(f => f.user_id === user.id ? f.friend_id : f.user_id);

    const { data } = await supabase
      .from('users')
      .select('id, name, avatar_url, tonight_status, vibe_tags, is_dd_tonight')
      .in('id', friendIds)
      .in('tonight_status', ['out_now', 'going_out_soon'])
      .order('tonight_status');

    if (data) {
      const enriched: TonightUser[] = await Promise.all(data.map(async (u) => {
        const { data: presence } = await supabase
          .from('user_venue_presence')
          .select('venue_id, venues(name)')
          .eq('user_id', u.id)
          .eq('status', 'IN_VENUE')
          .eq('is_visible_in_venue', true)
          .maybeSingle();
        return {
          ...u,
          current_venue_name: (presence?.venues as any)?.name,
        };
      }));
      setUsers(enriched);
    }
    setLoading(false);
  };

  const statusLabel = (s: string | null) => {
    if (s === 'out_now') return { text: 'Out now', color: 'text-emerald-600', dot: 'bg-emerald-500' };
    if (s === 'going_out_soon') return { text: 'Going out soon', color: 'text-amber-600', dot: 'bg-amber-400' };
    return { text: 'Staying in', color: 'text-gray-400', dot: 'bg-gray-300' };
  };

  if (loading) {
    return (
      <div className="space-y-3">
        {[1, 2, 3].map(i => (
          <div key={i} className="flex items-center gap-3 animate-pulse">
            <div className="w-12 h-12 bg-gray-200 rounded-full flex-shrink-0" />
            <div className="flex-1 space-y-2">
              <div className="h-3.5 bg-gray-200 rounded w-1/2" />
              <div className="h-2.5 bg-gray-100 rounded w-1/3" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (users.length === 0) {
    return (
      <div className="text-center py-10">
        <Users className="w-10 h-10 text-gray-200 mx-auto mb-3" />
        <p className="text-gray-400 font-medium text-sm">None of your friends are going out tonight</p>
        <p className="text-gray-300 text-xs mt-1">Be the first to set your status!</p>
      </div>
    );
  }

  const outNow = users.filter(u => u.tonight_status === 'out_now');
  const goingSoon = users.filter(u => u.tonight_status === 'going_out_soon');

  const renderUser = (u: TonightUser) => {
    const s = statusLabel(u.tonight_status);
    return (
      <button
        key={u.id}
        onClick={() => onSelectUser?.(u.id)}
        className="w-full flex items-center gap-3 p-3 rounded-2xl hover:bg-gray-50 transition-colors text-left"
      >
        <div className="relative flex-shrink-0">
          <div className="w-12 h-12 bg-gradient-to-br from-[#E91E63]/20 to-[#C2185B]/20 rounded-full flex items-center justify-center">
            {u.avatar_url ? (
              <img src={u.avatar_url} alt={u.name} className="w-full h-full object-cover rounded-full" />
            ) : (
              <UserIcon className="w-6 h-6 text-[#E91E63]" />
            )}
          </div>
          <div className={`absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 ${s.dot} rounded-full border-2 border-white`} />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <p className="font-semibold text-gray-900 text-sm">{u.name}</p>
            {u.is_dd_tonight && (
              <span className="flex items-center gap-1 bg-blue-100 text-blue-700 text-[10px] font-bold px-1.5 py-0.5 rounded-full">
                <Car className="w-2.5 h-2.5" /> DD
              </span>
            )}
          </div>
          <p className={`text-xs font-medium ${s.color}`}>{s.text}</p>
          {u.current_venue_name && (
            <p className="text-xs text-gray-500 flex items-center gap-1 mt-0.5">
              <MapPin className="w-3 h-3" /> {u.current_venue_name}
            </p>
          )}
        </div>
        {u.vibe_tags[0] && (
          <span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded-full flex-shrink-0">
            {u.vibe_tags[0]}
          </span>
        )}
      </button>
    );
  };

  return (
    <div className="space-y-4">
      {outNow.length > 0 && (
        <div>
          <div className="flex items-center gap-2 mb-2 px-1">
            <div className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
            <p className="text-xs font-semibold text-emerald-700 uppercase tracking-wide">Out right now ({outNow.length})</p>
          </div>
          <div className="bg-white rounded-2xl shadow-sm overflow-hidden divide-y divide-gray-50">
            {outNow.map(renderUser)}
          </div>
        </div>
      )}
      {goingSoon.length > 0 && (
        <div>
          <div className="flex items-center gap-2 mb-2 px-1">
            <div className="w-2 h-2 bg-amber-400 rounded-full" />
            <p className="text-xs font-semibold text-amber-700 uppercase tracking-wide">Going out soon ({goingSoon.length})</p>
          </div>
          <div className="bg-white rounded-2xl shadow-sm overflow-hidden divide-y divide-gray-50">
            {goingSoon.map(renderUser)}
          </div>
        </div>
      )}
    </div>
  );
}

export function DDModeToggle() {
  const { user } = useAuth();
  const [isDd, setIsDd] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!user) return;
    supabase.from('users').select('is_dd_tonight').eq('id', user.id).maybeSingle().then(({ data }) => {
      if (data) setIsDd(data.is_dd_tonight ?? false);
    });
  }, [user]);

  const toggle = async () => {
    if (!user) return;
    setLoading(true);
    const next = !isDd;
    await supabase.from('users').update({
      is_dd_tonight: next,
      dd_expires_at: next ? new Date(Date.now() + 12 * 3600 * 1000).toISOString() : null,
    }).eq('id', user.id);
    setIsDd(next);
    setLoading(false);
  };

  return (
    <button
      onClick={toggle}
      disabled={loading}
      className={`flex items-center gap-3 w-full p-4 rounded-2xl border-2 transition-all ${
        isDd
          ? 'bg-blue-50 border-blue-400 text-blue-700'
          : 'bg-white border-gray-200 text-gray-700 hover:border-blue-300'
      }`}
    >
      <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${isDd ? 'bg-blue-100' : 'bg-gray-100'}`}>
        <Car className={`w-5 h-5 ${isDd ? 'text-blue-600' : 'text-gray-500'}`} />
      </div>
      <div className="flex-1 text-left">
        <p className="font-semibold text-sm">{isDd ? 'DD Mode Active' : 'Enable DD Mode'}</p>
        <p className="text-xs opacity-70">{isDd ? 'Friends can see you\'re the driver tonight' : 'Let friends know you can give rides'}</p>
      </div>
      <div className={`w-11 h-6 rounded-full transition-all ${isDd ? 'bg-blue-500' : 'bg-gray-300'} relative`}>
        <div className={`absolute top-1 w-4 h-4 bg-white rounded-full shadow transition-all ${isDd ? 'left-6' : 'left-1'}`} />
      </div>
    </button>
  );
}

export function CheckInStreakBadge({ userId }: { userId: string }) {
  const [streak, setStreak] = useState<{ current: number; longest: number; total: number } | null>(null);

  useEffect(() => {
    supabase
      .from('check_in_streaks')
      .select('current_streak, longest_streak, total_checkins')
      .eq('user_id', userId)
      .maybeSingle()
      .then(({ data }) => {
        if (data) setStreak({ current: data.current_streak, longest: data.longest_streak, total: data.total_checkins });
      });
  }, [userId]);

  if (!streak || streak.total === 0) return null;

  return (
    <div className="flex items-center gap-3">
      <div className="flex items-center gap-1.5 bg-orange-50 border border-orange-200 px-3 py-1.5 rounded-full">
        <Flame className="w-4 h-4 text-orange-500" />
        <span className="text-sm font-bold text-orange-700">{streak.current} night streak</span>
      </div>
      {streak.total > 0 && (
        <span className="text-xs text-gray-400">{streak.total} total nights out</span>
      )}
    </div>
  );
}
