import { useState, useEffect } from 'react';
import { Trophy, Flame, Target, Medal } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { xpService, UserStats, Badge, Challenge } from '../../services/xpService';
import { supabase } from '../../lib/supabase';

interface XPProfileProps {
  userId?: string;
}

export function XPProfile({ userId: propUserId }: XPProfileProps) {
  const navigate = useNavigate();
  const [userId, setUserId] = useState<string | null>(propUserId || null);
  const [stats, setStats] = useState<UserStats | null>(null);
  const [badges, setBadges] = useState<Badge[]>([]);
  const [challenges, setChallenges] = useState<Challenge[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'stats' | 'badges' | 'challenges'>('stats');

  useEffect(() => {
    const getUser = async () => {
      if (!propUserId) {
        const { data: session } = await supabase.auth.getSession();
        setUserId(session?.user?.id || null);
      }
    };
    getUser();
  }, [propUserId]);

  useEffect(() => {
    const loadData = async () => {
      if (!userId) return;

      try {
        const [userStats, userBadges, activeChallenges] = await Promise.all([
          xpService.getUserStats(userId),
          xpService.getUserBadges(userId),
          xpService.getActiveChallenges(userId),
        ]);

        setStats(userStats);
        setBadges(userBadges);
        setChallenges(activeChallenges);
      } catch (error) {
        console.error('Failed to load XP data:', error);
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, [userId]);

  if (loading) {
    return (
      <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-lg p-6 border border-blue-100">
        <div className="animate-pulse text-center text-gray-400">
          Loading XP profile...
        </div>
      </div>
    );
  }

  if (!stats) {
    return null;
  }

  const xpPercent = (stats.total_xp % 1000) / 10;
  const nextLevelXp = Math.ceil(stats.total_xp / 1000) * 1000;

  return (
    <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-lg border border-blue-100 overflow-hidden">
      <div className="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-6 py-4">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold">Nightlife XP</h2>
          <div className="flex items-center gap-3">
            <span className="text-3xl font-bold">{stats.total_xp} XP</span>
            <button
              onClick={() => navigate('/leaderboard')}
              className="p-2 bg-white/20 rounded-full hover:bg-white/30 transition-colors"
              title="Leaderboard"
            >
              <Medal className="w-5 h-5 text-white" />
            </button>
          </div>
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <span>Next Level</span>
            <span className="text-xs opacity-90">
              {stats.total_xp % 1000} / 1000
            </span>
          </div>
          <div className="w-full bg-white/20 rounded-full h-2 overflow-hidden">
            <div
              className="h-full bg-white transition-all duration-300"
              style={{ width: `${xpPercent}%` }}
            />
          </div>
        </div>
      </div>

      <div className="p-6 space-y-6">
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white rounded-lg p-4 border border-gray-200">
            <div className="flex items-center gap-2 mb-2">
              <Flame className="text-orange-500" size={20} />
              <span className="text-sm text-gray-600">Current Streak</span>
            </div>
            <p className="text-3xl font-bold text-orange-600">
              {stats.current_streak}
            </p>
            <p className="text-xs text-gray-500 mt-1">
              {stats.current_streak === 1 ? 'night' : 'nights'}
            </p>
          </div>

          <div className="bg-white rounded-lg p-4 border border-gray-200">
            <div className="flex items-center gap-2 mb-2">
              <Trophy className="text-yellow-500" size={20} />
              <span className="text-sm text-gray-600">Longest Streak</span>
            </div>
            <p className="text-3xl font-bold text-yellow-600">
              {stats.longest_streak}
            </p>
            <p className="text-xs text-gray-500 mt-1">all-time best</p>
          </div>

          <div className="bg-white rounded-lg p-4 border border-gray-200">
            <div className="flex items-center gap-2 mb-2">
              <Target className="text-blue-500" size={20} />
              <span className="text-sm text-gray-600">Check-ins</span>
            </div>
            <p className="text-3xl font-bold text-blue-600">
              {stats.total_checkins}
            </p>
            <p className="text-xs text-gray-500 mt-1">
              {stats.unique_venues} unique {stats.unique_venues === 1 ? 'venue' : 'venues'}
            </p>
          </div>

          <div className="bg-white rounded-lg p-4 border border-gray-200">
            <div className="flex items-center gap-2 mb-2">
              <span className="text-xl">🏆</span>
              <span className="text-sm text-gray-600">Badges</span>
            </div>
            <p className="text-3xl font-bold text-purple-600">{badges.length}</p>
            <p className="text-xs text-gray-500 mt-1">earned</p>
          </div>
        </div>

        <div className="border-t border-gray-200 pt-6">
          <div className="flex gap-2 mb-4">
            <button
              onClick={() => setActiveTab('stats')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                activeTab === 'stats'
                  ? 'bg-blue-600 text-white'
                  : 'bg-white text-gray-700 border border-gray-200 hover:bg-gray-50'
              }`}
            >
              Stats
            </button>
            <button
              onClick={() => setActiveTab('badges')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                activeTab === 'badges'
                  ? 'bg-blue-600 text-white'
                  : 'bg-white text-gray-700 border border-gray-200 hover:bg-gray-50'
              }`}
            >
              Badges ({badges.length})
            </button>
            <button
              onClick={() => setActiveTab('challenges')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                activeTab === 'challenges'
                  ? 'bg-blue-600 text-white'
                  : 'bg-white text-gray-700 border border-gray-200 hover:bg-gray-50'
              }`}
            >
              Challenges
            </button>
          </div>

          {activeTab === 'stats' && (
            <div className="space-y-3">
              <div className="bg-white rounded-lg p-4 border border-gray-200">
                <p className="text-xs text-gray-500 uppercase font-semibold mb-2">
                  About Your Progress
                </p>
                <ul className="text-sm text-gray-700 space-y-2">
                  <li>✓ You've checked in {stats.total_checkins} times</li>
                  <li>✓ You've visited {stats.unique_venues} unique venues</li>
                  <li>✓ Current streak: {stats.current_streak} {stats.current_streak === 1 ? 'night' : 'nights'}</li>
                  <li>✓ Best streak ever: {stats.longest_streak} {stats.longest_streak === 1 ? 'night' : 'nights'}</li>
                </ul>
              </div>
            </div>
          )}

          {activeTab === 'badges' && (
            <div>
              {badges.length === 0 ? (
                <p className="text-center text-gray-500 py-8">
                  No badges earned yet. Keep checking in!
                </p>
              ) : (
                <div className="grid grid-cols-3 gap-3">
                  {badges.map((badge) => {
                    const def = xpService.getBadgeDefinition(badge.badge_key);
                    return (
                      <div
                        key={badge.id}
                        className="bg-white rounded-lg p-4 border border-gray-200 text-center hover:shadow-md transition-shadow"
                      >
                        <div className="text-3xl mb-2">{def?.emoji}</div>
                        <p className="text-xs font-semibold text-gray-900">
                          {def?.name}
                        </p>
                        <p className="text-xs text-gray-500 mt-1">
                          {new Date(badge.earned_at).toLocaleDateString()}
                        </p>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}

          {activeTab === 'challenges' && (
            <div>
              {challenges.length === 0 ? (
                <p className="text-center text-gray-500 py-8">
                  No active challenges. Come back next week!
                </p>
              ) : (
                <div className="space-y-3">
                  {challenges.map((challenge) => {
                    const def = xpService.getChallengeDef(challenge.challenge_key);
                    const progress = Math.min(
                      (challenge.progress / challenge.target) * 100,
                      100
                    );
                    return (
                      <div
                        key={challenge.id}
                        className="bg-white rounded-lg p-4 border border-gray-200"
                      >
                        <div className="flex items-start justify-between mb-2">
                          <div>
                            <p className="font-semibold text-gray-900">
                              {def?.name}
                            </p>
                            <p className="text-xs text-gray-600 mt-1">
                              {def?.description}
                            </p>
                          </div>
                          <span className="text-sm font-bold text-purple-600">
                            +{challenge.reward_xp} XP
                          </span>
                        </div>
                        <div className="mt-3">
                          <div className="flex items-center justify-between mb-1">
                            <span className="text-xs text-gray-500">
                              Progress
                            </span>
                            <span className="text-xs font-semibold text-gray-700">
                              {challenge.progress}/{challenge.target}
                            </span>
                          </div>
                          <div className="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
                            <div
                              className="h-full bg-gradient-to-r from-blue-500 to-purple-500 transition-all duration-300"
                              style={{ width: `${progress}%` }}
                            />
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
