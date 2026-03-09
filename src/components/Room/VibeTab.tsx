import { useState, useEffect } from 'react';
import { roomService, VibePollResults, UserVotes, PollType } from '../../services/roomService';

const MUSIC_OPTIONS = [
  { value: 'house', label: 'House', emoji: '🎛️' },
  { value: 'hiphop', label: 'Hip Hop', emoji: '🎤' },
  { value: 'top40', label: 'Top 40', emoji: '🌟' },
  { value: 'edm', label: 'EDM', emoji: '⚡' },
  { value: 'throwbacks', label: 'Throwbacks', emoji: '📼' },
  { value: 'rnb', label: 'R&B', emoji: '🎶' },
  { value: 'latin', label: 'Latin', emoji: '💃' },
  { value: 'rock', label: 'Rock', emoji: '🎸' },
];

const ENERGY_OPTIONS = [
  { value: 'chill', label: 'Chill', emoji: '😎' },
  { value: 'lively', label: 'Lively', emoji: '🎉' },
  { value: 'wild', label: 'Wild', emoji: '🔥' },
  { value: 'packed', label: 'Packed', emoji: '🤯' },
];

const DRINK_OPTIONS = [
  { value: 'espresso_martini', label: 'Espresso Martini', emoji: '☕' },
  { value: 'margarita', label: 'Margarita', emoji: '🍹' },
  { value: 'beer', label: 'Beer', emoji: '🍺' },
  { value: 'vodka_soda', label: 'Vodka Soda', emoji: '🥂' },
  { value: 'whiskey', label: 'Whiskey', emoji: '🥃' },
  { value: 'shots', label: 'Shots', emoji: '🎯' },
  { value: 'wine', label: 'Wine', emoji: '🍷' },
  { value: 'negroni', label: 'Negroni', emoji: '🍸' },
];

function PollSection({
  title,
  options,
  results,
  userVote,
  onVote,
  isInsideVenue,
  votingPoll,
  totalVotes,
}: {
  title: string;
  options: { value: string; label: string; emoji: string }[];
  results: Record<string, number>;
  userVote: string | null;
  onVote: (value: string) => void;
  isInsideVenue: boolean;
  votingPoll: boolean;
  totalVotes: number;
}) {
  const maxCount = Math.max(...Object.values(results), 1);

  return (
    <div className="space-y-3">
      <h3 className="text-sm font-bold text-gray-300 uppercase tracking-wider">{title}</h3>
      <div className="space-y-2">
        {options.map((opt) => {
          const count = results[opt.value] || 0;
          const pct = totalVotes > 0 ? Math.round((count / totalVotes) * 100) : 0;
          const isWinner = count === maxCount && totalVotes > 0;
          const isVoted = userVote === opt.value;

          return (
            <button
              key={opt.value}
              onClick={() => isInsideVenue && onVote(opt.value)}
              disabled={!isInsideVenue || votingPoll}
              className={`w-full relative overflow-hidden rounded-xl border transition-all ${
                isVoted
                  ? 'border-amber-500 bg-amber-500/10'
                  : isWinner && totalVotes > 0
                  ? 'border-gray-600 bg-gray-800/80'
                  : 'border-gray-700/50 bg-gray-800/40 hover:border-gray-600'
              } disabled:cursor-default`}
            >
              <div
                className={`absolute inset-y-0 left-0 transition-all duration-500 rounded-xl ${
                  isVoted ? 'bg-amber-500/20' : 'bg-gray-700/30'
                }`}
                style={{ width: totalVotes > 0 ? `${pct}%` : '0%' }}
              />
              <div className="relative flex items-center gap-3 px-3 py-2.5">
                <span className="text-xl">{opt.emoji}</span>
                <span className={`flex-1 text-left text-sm font-medium ${isVoted ? 'text-amber-400' : 'text-white'}`}>
                  {opt.label}
                </span>
                {totalVotes > 0 && (
                  <div className="flex items-center gap-2">
                    {isWinner && (
                      <span className="text-xs text-amber-400 font-bold">WINNING</span>
                    )}
                    <span className="text-xs text-gray-400 font-medium w-8 text-right">{pct}%</span>
                  </div>
                )}
                {isVoted && <span className="text-amber-400 text-xs">✓</span>}
              </div>
            </button>
          );
        })}
      </div>
      <p className="text-xs text-gray-600 text-right">{totalVotes} vote{totalVotes !== 1 ? 's' : ''}</p>
    </div>
  );
}

interface VibeTabProps {
  venueId: string;
  isInsideVenue: boolean;
}

export function VibeTab({ venueId, isInsideVenue }: VibeTabProps) {
  const [results, setResults] = useState<VibePollResults>({ music: {}, energy: {}, drink: {} });
  const [userVotes, setUserVotes] = useState<UserVotes>({ music: null, energy: null, drink: null });
  const [loading, setLoading] = useState(true);
  const [votingPoll, setVotingPoll] = useState<string | null>(null);

  const load = async () => {
    try {
      const [r, v] = await Promise.all([
        roomService.getVibePollResults(venueId),
        roomService.getUserVotes(venueId),
      ]);
      setResults(r);
      setUserVotes(v);
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    const sub = roomService.subscribeToVibePolls(venueId, load);
    return () => { sub.unsubscribe(); };
  }, [venueId]);

  const handleVote = async (pollType: PollType, value: string) => {
    if (votingPoll) return;
    setVotingPoll(pollType);
    try {
      await roomService.castVibePollVote(venueId, pollType, value);
      setUserVotes((prev) => ({ ...prev, [pollType]: value }));
      const r = await roomService.getVibePollResults(venueId);
      setResults(r);
    } catch {
      // silent
    } finally {
      setVotingPoll(null);
    }
  };

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-amber-400/30 border-t-amber-400 rounded-full animate-spin" />
      </div>
    );
  }

  const totalMusic = Object.values(results.music).reduce((a, b) => a + b, 0);
  const totalEnergy = Object.values(results.energy).reduce((a, b) => a + b, 0);
  const totalDrink = Object.values(results.drink).reduce((a, b) => a + b, 0);

  return (
    <div className="flex-1 overflow-y-auto p-4 space-y-8">
      {!isInsideVenue && (
        <div className="px-4 py-2 bg-gray-800/60 rounded-xl border border-gray-700 text-center text-xs text-gray-400">
          Check in to vote on the vibe
        </div>
      )}

      <PollSection
        title="Music Vibe"
        options={MUSIC_OPTIONS}
        results={results.music}
        userVote={userVotes.music}
        onVote={(v) => handleVote('music', v)}
        isInsideVenue={isInsideVenue}
        votingPoll={votingPoll === 'music'}
        totalVotes={totalMusic}
      />

      <PollSection
        title="Crowd Energy"
        options={ENERGY_OPTIONS}
        results={results.energy}
        userVote={userVotes.energy}
        onVote={(v) => handleVote('energy', v)}
        isInsideVenue={isInsideVenue}
        votingPoll={votingPoll === 'energy'}
        totalVotes={totalEnergy}
      />

      <PollSection
        title="Drink of the Night"
        options={DRINK_OPTIONS}
        results={results.drink}
        userVote={userVotes.drink}
        onVote={(v) => handleVote('drink', v)}
        isInsideVenue={isInsideVenue}
        votingPoll={votingPoll === 'drink'}
        totalVotes={totalDrink}
      />
    </div>
  );
}
