import { useEffect, useState } from 'react';

interface VenueEntryAnimationProps {
  venueName: string;
  stats: { messageCount: number; activeUsers: number; topDrink: string | null; topMusic: string | null };
  onEnter: () => void;
  onDismiss: () => void;
}

export function VenueEntryAnimation({ venueName, stats, onEnter, onDismiss }: VenueEntryAnimationProps) {
  const [phase, setPhase] = useState<'enter' | 'card' | 'visible'>('enter');

  useEffect(() => {
    const t1 = setTimeout(() => setPhase('card'), 400);
    const t2 = setTimeout(() => setPhase('visible'), 800);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, []);

  return (
    <div
      className="fixed inset-0 z-[9999] flex items-center justify-center"
      style={{ background: 'radial-gradient(ellipse at center, rgba(245,124,0,0.15) 0%, rgba(0,0,0,0.92) 100%)' }}
    >
      <div
        className={`flex flex-col items-center gap-6 px-8 transition-all duration-700 ${
          phase === 'enter' ? 'opacity-0 scale-90' : 'opacity-100 scale-100'
        }`}
      >
        <div className="relative">
          <div className="w-20 h-20 rounded-full bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center shadow-2xl shadow-amber-500/40">
            <span className="text-4xl">🚪</span>
          </div>
          <div className="absolute -inset-3 rounded-full border border-amber-500/30 animate-ping" style={{ animationDuration: '2s' }} />
          <div className="absolute -inset-6 rounded-full border border-amber-500/10 animate-ping" style={{ animationDuration: '2.5s', animationDelay: '0.5s' }} />
        </div>

        <div className="text-center space-y-2">
          <p className="text-gray-400 text-sm font-medium uppercase tracking-[0.2em]">You just entered</p>
          <h1 className="text-3xl font-black text-white leading-tight">{venueName}</h1>
        </div>

        <div
          className={`w-full transition-all duration-500 delay-300 ${
            phase === 'visible' ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
          }`}
        >
          <div className="bg-gray-900/80 border border-amber-500/30 rounded-2xl p-5 space-y-3 backdrop-blur-sm">
            <div className="flex items-center gap-2 pb-2 border-b border-gray-800">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
              <p className="text-amber-400 font-bold text-sm tracking-wider uppercase">The Room is now open</p>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="bg-gray-800/60 rounded-xl p-3 text-center">
                <p className="text-2xl font-black text-white">{stats.activeUsers || 0}</p>
                <p className="text-xs text-gray-400 mt-0.5">🔥 here now</p>
              </div>
              <div className="bg-gray-800/60 rounded-xl p-3 text-center">
                <p className="text-2xl font-black text-white">{stats.messageCount || 0}</p>
                <p className="text-xs text-gray-400 mt-0.5">💬 messages</p>
              </div>
            </div>

            {(stats.topDrink || stats.topMusic) && (
              <div className="space-y-1.5">
                {stats.topDrink && (
                  <div className="flex items-center gap-2 text-sm">
                    <span className="text-gray-500">🍸 Top drink:</span>
                    <span className="text-white font-semibold capitalize">{stats.topDrink.replace(/_/g, ' ')}</span>
                  </div>
                )}
                {stats.topMusic && (
                  <div className="flex items-center gap-2 text-sm">
                    <span className="text-gray-500">🎵 Vibe:</span>
                    <span className="text-white font-semibold capitalize">{stats.topMusic.replace(/_/g, ' ')}</span>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>

        <div
          className={`w-full space-y-3 transition-all duration-500 delay-500 ${
            phase === 'visible' ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
          }`}
        >
          <button
            onClick={onEnter}
            className="w-full py-4 bg-gradient-to-r from-amber-500 to-orange-500 text-black font-black text-lg rounded-2xl hover:from-amber-400 hover:to-orange-400 active:scale-95 transition-all shadow-xl shadow-amber-500/30"
          >
            Enter The Room
          </button>
          <button
            onClick={onDismiss}
            className="w-full py-2.5 text-gray-500 text-sm hover:text-gray-400 transition-colors"
          >
            Maybe later
          </button>
        </div>
      </div>
    </div>
  );
}
