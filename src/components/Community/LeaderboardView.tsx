import { useState, useEffect } from 'react';
import { ChevronLeft, Trophy, Flame, Medal } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

interface LeaderboardEntry {
  user_id: string;
  total_xp: number;
  current_streak: number;
  total_checkins: number;
  name: string;
  username: string | null;
  avatar_url: string | null;
}

export function LeaderboardView() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [entries, setEntries] = useState<LeaderboardEntry[]>([]);
  const [tab, setTab] = useState<'xp' | 'streak' | 'checkins'>('xp');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    load();
  }, []);

  const load = async () => {
    setLoading(true);
    // Get top 50 by XP, join with user profiles
    const { data } = await supabase
      .from('user_stats')
      .select('user_id, total_xp, current_streak, total_checkins')
      .order('total_xp', { ascending: false })
      .limit(50);

    if (!data || data.length === 0) { setLoading(false); return; }

    const userIds = data.map((r: any) => r.user_id);
    const { data: profiles } = await supabase
      .from('users')
      .select('id, name, username, avatar_url')
      .in('id', userIds);

    const profileMap = new Map((profiles || []).map((p: any) => [p.id, p]));

    const merged: LeaderboardEntry[] = data
      .map((r: any) => {
        const p = profileMap.get(r.user_id);
        if (!p) return null;
        return { ...r, name: p.name, username: p.username, avatar_url: p.avatar_url };
      })
      .filter(Boolean) as LeaderboardEntry[];

    setEntries(merged);
    setLoading(false);
  };

  const sorted = [...entries].sort((a, b) => {
    if (tab === 'xp') return b.total_xp - a.total_xp;
    if (tab === 'streak') return b.current_streak - a.current_streak;
    return b.total_checkins - a.total_checkins;
  });

  const rankEmoji = (i: number) => {
    if (i === 0) return '🥇';
    if (i === 1) return '🥈';
    if (i === 2) return '🥉';
    return `#${i + 1}`;
  };

  const statValue = (entry: LeaderboardEntry) => {
    if (tab === 'xp') return `${entry.total_xp} XP`;
    if (tab === 'streak') return `🔥 ${entry.current_streak}`;
    return `${entry.total_checkins} check-ins`;
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-white border-b border-gray-200 px-4 py-4 flex items-center gap-4 sticky top-0 z-10">
        <button onClick={() => navigate(-1)} className="p-2 hover:bg-gray-100 rounded-full">
          <ChevronLeft className="w-6 h-6" />
        </button>
        <div className="flex items-center gap-2">
          <Trophy className="w-6 h-6 text-yellow-500" />
          <h1 className="text-xl font-bold">Leaderboard</h1>
        </div>
      </div>

      {/* Tab selector */}
      <div className="bg-white border-b border-gray-100 px-4 py-3 flex gap-2">
        {([
          { key: 'xp',       label: 'XP',       icon: <Medal size={14} /> },
          { key: 'streak',   label: 'Streak',   icon: <Flame size={14} /> },
          { key: 'checkins', label: 'Check-ins', icon: <span className="text-xs">📍</span> },
        ] as const).map(({ key, label, icon }) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={`flex-1 py-2 rounded-xl text-sm font-semibold flex items-center justify-center gap-1.5 transition-colors ${
              tab === key ? 'bg-[#E91E63] text-white' : 'bg-gray-100 text-gray-700'
            }`}
          >
            {icon} {label}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-64">
          <div className="w-10 h-10 border-4 border-[#E91E63]/30 border-t-[#E91E63] rounded-full animate-spin" />
        </div>
      ) : sorted.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <Trophy size={48} className="mx-auto mb-3 opacity-30" />
          <p>No data yet — start checking in!</p>
        </div>
      ) : (
        <div className="p-4 space-y-2">
          {/* Top 3 podium */}
          {sorted.length >= 3 && (
            <div className="bg-white rounded-2xl p-5 shadow-sm mb-4">
              <div className="flex items-end justify-center gap-4">
                {/* 2nd */}
                <div className="flex flex-col items-center flex-1">
                  <div className="w-14 h-14 rounded-full overflow-hidden border-4 border-gray-300 mb-2 bg-gray-200">
                    {sorted[1].avatar_url
                      ? <img src={sorted[1].avatar_url} alt={sorted[1].name} className="w-full h-full object-cover" />
                      : <div className="w-full h-full bg-gray-400 flex items-center justify-center text-white font-bold">{sorted[1].name[0]}</div>
                    }
                  </div>
                  <p className="text-xs font-semibold text-gray-700 truncate w-full text-center">{sorted[1].name.split(' ')[0]}</p>
                  <p className="text-xs text-gray-500">{statValue(sorted[1])}</p>
                  <div className="w-full h-12 bg-gray-200 rounded-t-lg mt-2 flex items-center justify-center">
                    <span className="text-2xl">🥈</span>
                  </div>
                </div>
                {/* 1st */}
                <div className="flex flex-col items-center flex-1">
                  <div className="w-18 h-18 rounded-full overflow-hidden border-4 border-yellow-400 mb-2 bg-yellow-50 relative" style={{ width: 72, height: 72 }}>
                    {sorted[0].avatar_url
                      ? <img src={sorted[0].avatar_url} alt={sorted[0].name} className="w-full h-full object-cover" />
                      : <div className="w-full h-full bg-yellow-400 flex items-center justify-center text-white font-bold text-xl">{sorted[0].name[0]}</div>
                    }
                    <div className="absolute -top-3 left-1/2 -translate-x-1/2 text-xl">👑</div>
                  </div>
                  <p className="text-sm font-bold text-gray-900 truncate w-full text-center">{sorted[0].name.split(' ')[0]}</p>
                  <p className="text-xs text-gray-500 font-semibold">{statValue(sorted[0])}</p>
                  <div className="w-full h-20 bg-yellow-400 rounded-t-lg mt-2 flex items-center justify-center">
                    <span className="text-2xl">🥇</span>
                  </div>
                </div>
                {/* 3rd */}
                <div className="flex flex-col items-center flex-1">
                  <div className="w-14 h-14 rounded-full overflow-hidden border-4 border-amber-600 mb-2 bg-amber-100">
                    {sorted[2].avatar_url
                      ? <img src={sorted[2].avatar_url} alt={sorted[2].name} className="w-full h-full object-cover" />
                      : <div className="w-full h-full bg-amber-500 flex items-center justify-center text-white font-bold">{sorted[2].name[0]}</div>
                    }
                  </div>
                  <p className="text-xs font-semibold text-gray-700 truncate w-full text-center">{sorted[2].name.split(' ')[0]}</p>
                  <p className="text-xs text-gray-500">{statValue(sorted[2])}</p>
                  <div className="w-full h-8 bg-amber-600 rounded-t-lg mt-2 flex items-center justify-center">
                    <span className="text-xl">🥉</span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Full list (rank 4+) */}
          {sorted.slice(3).map((entry, i) => {
            const isMe = entry.user_id === user?.id;
            return (
              <div
                key={entry.user_id}
                className={`flex items-center gap-3 p-4 rounded-2xl ${
                  isMe ? 'bg-[#E91E63]/10 border border-[#E91E63]/30' : 'bg-white shadow-sm'
                }`}
              >
                <span className="w-8 text-center text-sm font-bold text-gray-500">{rankEmoji(i + 3)}</span>
                <div className="w-10 h-10 rounded-full overflow-hidden flex-shrink-0 bg-gray-200">
                  {entry.avatar_url
                    ? <img src={entry.avatar_url} alt={entry.name} className="w-full h-full object-cover" />
                    : <div className="w-full h-full bg-gradient-to-br from-[#E91E63] to-[#C2185B] flex items-center justify-center text-white font-bold">{entry.name[0]}</div>
                  }
                </div>
                <div className="flex-1 min-w-0">
                  <p className={`font-semibold truncate ${isMe ? 'text-[#E91E63]' : 'text-gray-900'}`}>
                    {entry.name}{isMe ? ' (You)' : ''}
                  </p>
                  {entry.username && <p className="text-xs text-gray-400 truncate">{entry.username}</p>}
                </div>
                <p className="text-sm font-bold text-gray-700 flex-shrink-0">{statValue(entry)}</p>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
