import { useState, useEffect } from 'react';
import { ChevronLeft, Coins, Flame, Sparkles, Gift, Users, Wine, Wallet } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { xpService, COIN_REWARDS } from '../../services/xpService';
import { CRYPTO_ENABLED } from '../../lib/featureFlags';
import { useWallet } from '../../hooks/useWallet';

interface EarnRow { icon: React.ReactNode; action: string; coins: number; desc: string; }

export function LushCoinPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const wallet = useWallet();
  const [balance, setBalance] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;
    if (CRYPTO_ENABLED && wallet.address) {
      // Use on-chain balance when crypto is enabled
      setBalance(wallet.balances.lush);
      setLoading(wallet.loading);
    } else {
      xpService.getCoinBalance(user.id).then(b => { setBalance(b); setLoading(false); });
    }
  }, [user, wallet.address, wallet.balances.lush, wallet.loading]);

  const earnRows: EarnRow[] = [
    { icon: <span className="text-2xl">📍</span>,   action: 'Check in to a venue',         coins: COIN_REWARDS.checkin,            desc: 'Every time you auto check-in' },
    { icon: <span className="text-2xl">🌙</span>,   action: 'First venue of the night',     coins: COIN_REWARDS.first_checkin_night, desc: 'Bonus for your first check-in each night' },
    { icon: <Flame size={24} className="text-orange-400" />, action: '7-night streak',      coins: COIN_REWARDS.checkin_streak_7,   desc: 'Check in 7 nights in a row' },
    { icon: <Flame size={24} className="text-red-500" />,    action: '14-night streak',     coins: COIN_REWARDS.checkin_streak_14,  desc: '14 nights straight' },
    { icon: <Flame size={24} className="text-red-700" />,    action: '30-night streak',     coins: COIN_REWARDS.checkin_streak_30,  desc: 'Legendary 30-night run' },
    { icon: <Sparkles size={24} className="text-purple-400" />, action: 'Complete a challenge', coins: 25, desc: 'Up to 75 coins depending on challenge' },
    { icon: <Users size={24} className="text-blue-400" />,   action: 'Join a swarm',        coins: COIN_REWARDS.swarm_joined,       desc: 'Join any active swarm' },
    { icon: <Users size={24} className="text-pink-500" />,   action: 'Create a swarm',      coins: COIN_REWARDS.swarm_created,      desc: 'Host a swarm with 3+ people' },
    { icon: <Wine size={24} className="text-amber-400" />,   action: 'Send Cheers',         coins: COIN_REWARDS.cheer_sent,         desc: 'Raise a glass to someone at a venue' },
  ];

  const spendRows = [
    { icon: '😍', rarity: 'Common emoji / sticker', coins: 10 },
    { icon: '🍺', rarity: 'Common drink gift',      coins: 10 },
    { icon: '🍹', rarity: 'Rare gift',               coins: 25 },
    { icon: '🏆', rarity: 'Epic gift',               coins: 50 },
    { icon: '👑', rarity: 'Legendary gift',          coins: 150 },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-white border-b border-gray-200 px-4 py-4 flex items-center gap-4">
        <button onClick={() => navigate('/payments/settings')} className="p-2 hover:bg-gray-100 rounded-full">
          <ChevronLeft className="w-6 h-6" />
        </button>
        <h1 className="text-xl font-bold">Lush Coin</h1>
      </div>

      <div className="p-4 space-y-5">
        {/* Balance hero */}
        <div className="bg-gradient-to-br from-purple-600 to-blue-600 rounded-3xl p-8 text-center text-white shadow-lg">
          <div className="text-6xl mb-3">🪙</div>
          {loading ? (
            <div className="w-8 h-8 border-4 border-white/30 border-t-white rounded-full animate-spin mx-auto" />
          ) : (
            <>
              <p className="text-5xl font-black">{balance}</p>
              <p className="text-purple-200 mt-1 text-lg">Lush Coins</p>
            </>
          )}
          <p className="text-sm text-purple-200 mt-4 leading-relaxed">
            {CRYPTO_ENABLED
              ? 'LUSH is a Solana SPL token. Earn by going out, spend on gifts for friends.'
              : 'Earn coins by going out and spending them on gifts for friends. No real money — just vibes.'}
          </p>
          {CRYPTO_ENABLED && wallet.address && (
            <div className="mt-3 flex items-center justify-center gap-2 text-purple-300 text-xs">
              <Wallet className="w-3.5 h-3.5" />
              <span className="truncate max-w-[200px]">{wallet.address}</span>
            </div>
          )}
        </div>

        {/* How to earn */}
        <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
          <div className="px-5 py-4 border-b border-gray-100 flex items-center gap-2">
            <Coins className="w-5 h-5 text-yellow-500" />
            <h2 className="font-bold text-gray-900">How to Earn</h2>
          </div>
          <div className="divide-y divide-gray-50">
            {earnRows.map((row, i) => (
              <div key={i} className="flex items-center gap-4 px-5 py-4">
                <div className="w-10 h-10 bg-gray-50 rounded-xl flex items-center justify-center flex-shrink-0">
                  {row.icon}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-gray-900 text-sm">{row.action}</p>
                  <p className="text-xs text-gray-500 truncate">{row.desc}</p>
                </div>
                <div className="flex-shrink-0 flex items-center gap-1 bg-yellow-50 px-3 py-1.5 rounded-full">
                  <span className="text-sm">🪙</span>
                  <span className="font-bold text-yellow-700 text-sm">+{row.coins}</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* How to spend */}
        <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
          <div className="px-5 py-4 border-b border-gray-100 flex items-center gap-2">
            <Gift className="w-5 h-5 text-pink-500" />
            <h2 className="font-bold text-gray-900">Spend on Gifts</h2>
          </div>
          <div className="divide-y divide-gray-50">
            {spendRows.map((row, i) => (
              <div key={i} className="flex items-center gap-4 px-5 py-4">
                <span className="text-3xl w-10 text-center flex-shrink-0">{row.icon}</span>
                <div className="flex-1">
                  <p className="font-semibold text-gray-900 text-sm">{row.rarity}</p>
                </div>
                <div className="flex-shrink-0 flex items-center gap-1 bg-pink-50 px-3 py-1.5 rounded-full">
                  <span className="text-sm">🪙</span>
                  <span className="font-bold text-pink-700 text-sm">{row.coins}</span>
                </div>
              </div>
            ))}
          </div>
          <div className="px-5 py-4 bg-gray-50">
            <button
              onClick={() => navigate('/gifts')}
              className="w-full py-3 bg-gradient-to-r from-[#E91E63] to-[#FF6B6B] text-white rounded-xl font-semibold"
            >
              Browse Gift Shop
            </button>
          </div>
        </div>

        <p className="text-xs text-gray-400 text-center px-4">
          {CRYPTO_ENABLED
            ? 'LUSH is a utility token on Solana used for in-app gifting. Not an investment.'
            : 'Lush Coins have no real-world monetary value and cannot be exchanged for cash. They exist entirely within Barfliz for community gifting.'}
        </p>
      </div>
    </div>
  );
}
