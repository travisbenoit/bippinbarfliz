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
  const winner = totalVotes > 0
    ? options.find(o => (results[o.value] || 0) === maxCount)
    : null;

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <h3 className="text-xs font-bold text-gray-400 uppercase tracking-widest">{title}</h3>
        {totalVotes > 0 && <span className="text-xs text-gray-600">{totalVotes} vote{totalVotes !== 1 ? 's' : ''}</span>}
      </div>

      {/* Winner hero (only when votes exist) */}
      {winner && (
        <div className="flex items-center gap-3 px-4 py-3 rounded-2xl bg-amber-500/10 border border-amber-500/30">
          <span className="text-3xl">{winner.emoji}</span>
          <div className="flex-1">
            <p className="font-bold text-amber-300 text-sm">{winner.label}</p>
            <p className="text-xs text-amber-500/70">
              {Math.round(((results[winner.value] || 0) / totalVotes) * 100)}% of votes
            </p>
          </div>
          <span className="text-lg">🏆</span>
        </div>
      )}

      {/* Option grid */}
      <div className="grid grid-cols-4 gap-2">
        {options.map((opt) => {
          const count = results[opt.value] || 0;
          const pct = totalVotes > 0 ? Math.round((count / totalVotes) * 100) : 0;
          const isVoted = userVote === opt.value;
          const isWinner = winner?.value === opt.value;

          return (
            <button
              key={opt.value}
              onClick={() => isInsideVenue && onVote(opt.value)}
              disabled={!isInsideVenue || votingPoll}
              className={`relative flex flex-col items-center gap-1.5 py-3 px-1 rounded-2xl border transition-all active:scale-95 disabled:cursor-default ${
                isVoted
                  ? 'border-amber-500 bg-amber-500/15 shadow-[0_0_12px_rgba(245,158,11,0.2)]'
                  : isWinner && totalVotes > 0
                  ? 'border-amber-500/40 bg-amber-500/5'
                  : 'border-gray-700/50 bg-gray-800/40 hover:border-gray-600 hover:bg-gray-800/60'
              }`}
            >
              <span className="text-2xl leading-none">{opt.emoji}</span>
              <span className={`text-[10px] font-semibold leading-tight text-center ${isVoted ? 'text-amber-400' : 'text-gray-400'}`}>
                {opt.label}
              </span>
              {totalVotes > 0 && (
                <span className={`text-[10px] font-bold ${isVoted ? 'text-amber-300' : 'text-gray-600'}`}>
                  {pct}%
                </span>
              )}
              {isVoted && (
                <span className="absolute top-1.5 right-1.5 w-3.5 h-3.5 rounded-full bg-amber-500 flex items-center justify-center">
                  <span className="text-[8px] text-black font-bold">✓</span>
                </span>
              )}
            </button>
          );
        })}
      </div>
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
        <div className="px-4 py-3 bg-gray-800/60 rounded-2xl border border-gray-700/50 text-center">
          <span className="text-2xl">📍</span>
          <p className="text-xs text-gray-400 mt-1 font-medium">Check in to cast your vote</p>
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
