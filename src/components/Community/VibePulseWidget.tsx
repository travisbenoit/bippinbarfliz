import { useState, useEffect, useRef } from 'react';
import { vibeService, VibeType, VibeStats } from '../../services/vibeService';

interface VibePulseWidgetProps {
  venueId: string;
}

const VIBE_OPTIONS: { type: VibeType; emoji: string; label: string }[] = [
  { type: 'lit', emoji: '🔥', label: 'Lit' },
  { type: 'chill', emoji: '😎', label: 'Chill' },
  { type: 'vibing', emoji: '🎶', label: 'Vibing' },
  { type: 'dead', emoji: '🥱', label: 'Dead' },
  { type: 'dancing', emoji: '💃', label: 'Dancing' },
];

export function VibePulseWidget({ venueId }: VibePulseWidgetProps) {
  const [stats, setStats] = useState<VibeStats | null>(null);
  const [userVote, setUserVote] = useState<VibeType | null>(null);
  const [loading, setLoading] = useState(true);
  const [voting, setVoting] = useState(false);
  const subscriptionRef = useRef<ReturnType<typeof vibeService.subscribeToVibeStats> | null>(null);

  useEffect(() => {
    const loadVibeData = async () => {
      try {
        const [vibeStats, currentUserVote] = await Promise.all([
          vibeService.getVibeStats(venueId),
          vibeService.getUserVoteForToday(venueId),
        ]);
        setStats(vibeStats);
        setUserVote(currentUserVote);
        setLoading(false);
      } catch (error) {
        console.error('Failed to load vibe data:', error);
        setLoading(false);
      }
    };

    loadVibeData();

    subscriptionRef.current = vibeService.subscribeToVibeStats(venueId, (updatedStats) => {
      setStats(updatedStats);
    });

    return () => {
      subscriptionRef.current?.unsubscribe();
    };
  }, [venueId]);

  const handleVote = async (vibe: VibeType) => {
    setVoting(true);
    try {
      await vibeService.castVote(venueId, vibe);
      setUserVote(vibe);
      const newStats = await vibeService.getVibeStats(venueId);
      setStats(newStats);
    } catch (error) {
      console.error('Failed to cast vibe vote:', error);
    } finally {
      setVoting(false);
    }
  };

  const getPercentage = (count: number, total: number) => {
    if (total === 0) return 0;
    return Math.round((count / total) * 100);
  };

  const getDominantVibe = () => {
    if (!stats || stats.total === 0) return null;
    const vibes = [
      { type: 'lit' as const, count: stats.lit },
      { type: 'chill' as const, count: stats.chill },
      { type: 'vibing' as const, count: stats.vibing },
      { type: 'dead' as const, count: stats.dead },
      { type: 'dancing' as const, count: stats.dancing },
    ];
    return vibes.reduce((prev, current) =>
      prev.count > current.count ? prev : current
    );
  };

  const dominantVibe = getDominantVibe();
  const dominantEmoji = VIBE_OPTIONS.find((v) => v.type === dominantVibe?.type)
    ?.emoji;

  if (loading) {
    return (
      <div className="bg-gradient-to-r from-purple-50 to-pink-50 p-4 rounded-lg border border-purple-100">
        <div className="animate-pulse text-center text-gray-400">
          Loading vibe...
        </div>
      </div>
    );
  }

  return (
    <div className="bg-gradient-to-r from-purple-50 to-pink-50 p-4 rounded-lg border border-purple-100">
      <div className="flex items-center justify-between mb-3">
        <h3 className="font-semibold text-gray-900 text-sm">
          What's the vibe? {dominantEmoji}
        </h3>
        <span className="text-xs font-medium text-gray-500">
          {stats?.total || 0} votes
        </span>
      </div>

      <div className="space-y-2 mb-3">
        {VIBE_OPTIONS.map((option) => {
          const count = stats?.[option.type] || 0;
          const percentage = getPercentage(count, stats?.total || 0);

          return (
            <div key={option.type} className="space-y-1">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-gray-700">
                  {option.emoji} {option.label}
                </span>
                <span className="text-xs text-gray-500">{percentage}%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2 overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-purple-500 to-pink-500 transition-all duration-300"
                  style={{ width: `${percentage}%` }}
                />
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-5 gap-2">
        {VIBE_OPTIONS.map((option) => (
          <button
            key={option.type}
            onClick={() => handleVote(option.type)}
            disabled={voting}
            className={`py-2 px-1 rounded-lg text-lg font-medium transition-all duration-200 ${
              userVote === option.type
                ? 'bg-white shadow-md ring-2 ring-purple-500 scale-105'
                : 'hover:bg-white/60 active:scale-95'
            } disabled:opacity-50 disabled:cursor-not-allowed`}
            title={option.label}
          >
            {option.emoji}
          </button>
        ))}
      </div>
    </div>
  );
}
