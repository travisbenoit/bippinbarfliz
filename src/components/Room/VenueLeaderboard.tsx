import { useState, useEffect } from 'react';
import { User, Crown } from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface Regular {
  user_id: string;
  visit_count: number;
  name: string;
  avatar_url: string | null;
}

interface VenueLeaderboardProps {
  venueId: string;
  currentUserId: string | null;
}

const MEDALS = ['🥇', '🥈', '🥉'];

export function VenueLeaderboard({ venueId, currentUserId }: VenueLeaderboardProps) {
  const [regulars, setRegulars] = useState<Regular[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    load();
  }, [venueId]);

  const load = async () => {
    try {
      // Count presence rows per user at this venue
      const { data: rows } = await supabase
        .from('user_venue_presence')
        .select('user_id')
        .eq('venue_id', venueId);

      if (!rows || rows.length === 0) { setLoading(false); return; }

      // Count per user_id client-side
      const counts: Record<string, number> = {};
      rows.forEach(({ user_id }) => { counts[user_id] = (counts[user_id] || 0) + 1; });

      const topIds = Object.entries(counts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 20)
        .map(([id]) => id);

      const { data: profiles } = await supabase
        .from('users')
        .select('id, name, avatar_url')
        .in('id', topIds);

      const profileMap = new Map((profiles || []).map((p: any) => [p.id, p]));

      const merged: Regular[] = topIds
        .map((id) => {
          const p = profileMap.get(id);
          if (!p) return null;
          return { user_id: id, visit_count: counts[id], name: p.name, avatar_url: p.avatar_url };
        })
        .filter(Boolean) as Regular[];

      setRegulars(merged);
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-amber-400/30 border-t-amber-400 rounded-full animate-spin" />
      </div>
    );
  }

  if (regulars.length === 0) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center gap-4 p-8">
        <div className="text-5xl">🏆</div>
        <p className="text-gray-400 font-semibold">No regulars yet</p>
        <p className="text-gray-500 text-sm text-center">Check in here to claim your spot</p>
      </div>
    );
  }

  const top3 = regulars.slice(0, 3);
  const rest = regulars.slice(3);

  return (
    <div className="flex-1 overflow-y-auto p-4 space-y-4">
      <div className="flex items-center gap-2 mb-1">
        <Crown className="w-4 h-4 text-amber-400" />
        <p className="text-xs text-gray-400 font-bold uppercase tracking-wider">Most check-ins here</p>
      </div>

      {/* Podium */}
      {top3.length >= 2 && (
        <div className="bg-gray-800/60 border border-gray-700/50 rounded-2xl p-4">
          <div className="flex items-end justify-center gap-4">
            {/* 2nd */}
            {top3[1] && (
              <div className="flex flex-col items-center flex-1">
                <div className="w-14 h-14 rounded-full overflow-hidden border-2 border-gray-500 mb-2">
                  {top3[1].avatar_url
                    ? <img src={top3[1].avatar_url} alt={top3[1].name} className="w-full h-full object-cover" />
                    : <div className="w-full h-full bg-gray-600 flex items-center justify-center"><User className="w-5 h-5 text-white" /></div>
                  }
                </div>
                <p className="text-xs font-semibold text-gray-300 truncate w-full text-center">{top3[1].name.split(' ')[0]}</p>
                <p className="text-xs text-amber-500 font-bold">{top3[1].visit_count}x</p>
                <div className="w-full h-10 bg-gray-600 rounded-t-lg mt-1 flex items-center justify-center">
                  <span className="text-xl">🥈</span>
                </div>
              </div>
            )}
            {/* 1st */}
            <div className="flex flex-col items-center flex-1 relative">
              <div className="text-xl absolute -top-3">👑</div>
              <div className="w-16 h-16 rounded-full overflow-hidden border-2 border-amber-400 mb-2 mt-2">
                {top3[0].avatar_url
                  ? <img src={top3[0].avatar_url} alt={top3[0].name} className="w-full h-full object-cover" />
                  : <div className="w-full h-full bg-amber-600 flex items-center justify-center"><User className="w-6 h-6 text-white" /></div>
                }
              </div>
              <p className="text-sm font-bold text-white truncate w-full text-center">{top3[0].name.split(' ')[0]}</p>
              <p className="text-xs text-amber-400 font-bold">{top3[0].visit_count}x</p>
              <div className="w-full h-16 bg-amber-500/30 border border-amber-500/40 rounded-t-lg mt-1 flex items-center justify-center">
                <span className="text-2xl">🥇</span>
              </div>
            </div>
            {/* 3rd */}
            {top3[2] && (
              <div className="flex flex-col items-center flex-1">
                <div className="w-14 h-14 rounded-full overflow-hidden border-2 border-orange-700 mb-2">
                  {top3[2].avatar_url
                    ? <img src={top3[2].avatar_url} alt={top3[2].name} className="w-full h-full object-cover" />
                    : <div className="w-full h-full bg-orange-800 flex items-center justify-center"><User className="w-5 h-5 text-white" /></div>
                  }
                </div>
                <p className="text-xs font-semibold text-gray-300 truncate w-full text-center">{top3[2].name.split(' ')[0]}</p>
                <p className="text-xs text-amber-600 font-bold">{top3[2].visit_count}x</p>
                <div className="w-full h-7 bg-orange-800/50 rounded-t-lg mt-1 flex items-center justify-center">
                  <span className="text-lg">🥉</span>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Ranks 4+ */}
      {rest.map((r, i) => {
        const isMe = r.user_id === currentUserId;
        return (
          <div
            key={r.user_id}
            className={`flex items-center gap-3 p-3 rounded-2xl ${
              isMe ? 'bg-amber-500/10 border border-amber-500/30' : 'bg-gray-800/60 border border-gray-700/50'
            }`}
          >
            <span className="w-6 text-center text-xs font-bold text-gray-500">#{i + 4}</span>
            <div className="w-10 h-10 rounded-full overflow-hidden flex-shrink-0 bg-gray-700">
              {r.avatar_url
                ? <img src={r.avatar_url} alt={r.name} className="w-full h-full object-cover" />
                : <div className="w-full h-full flex items-center justify-center"><User className="w-4 h-4 text-gray-400" /></div>
              }
            </div>
            <div className="flex-1 min-w-0">
              <p className={`font-semibold text-sm truncate ${isMe ? 'text-amber-400' : 'text-white'}`}>
                {r.name}{isMe ? ' (you)' : ''}
              </p>
            </div>
            <p className="text-xs font-bold text-amber-500 flex-shrink-0">{r.visit_count}x visits</p>
          </div>
        );
      })}
    </div>
  );
}
