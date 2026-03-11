import { useState, useEffect } from 'react';
import { User, MapPin, Gift, MessageCircle } from 'lucide-react';
import { roomService, RoomPresenceUser } from '../../services/roomService';
import { giftsService } from '../../services/giftsService';
import { useAuth } from '../../contexts/AuthContext';

const DRINK_EMOJIS: Record<string, string> = {
  beer: '🍺',
  wine: '🍷',
  cocktail: '🍸',
  whiskey: '🥃',
  vodka: '🍾',
  tequila: '🥂',
  shots: '🥃',
  soda: '🥤',
};

function getDrinkEmoji(drinks: string[] | null): string {
  if (!drinks || drinks.length === 0) return '🍻';
  const lower = drinks[0].toLowerCase();
  for (const [key, emoji] of Object.entries(DRINK_EMOJIS)) {
    if (lower.includes(key)) return emoji;
  }
  return '🍻';
}

function getStatusBadge(status: string | null) {
  if (status === 'out_now') return { label: 'Out Now', color: 'bg-green-500/20 text-green-400 border-green-500/30' };
  if (status === 'going_out_soon') return { label: 'Heading Out', color: 'bg-amber-500/20 text-amber-400 border-amber-500/30' };
  return null;
}

interface WhoIsHereProps {
  venueId: string;
  onMessageUser?: (userId: string) => void;
  currentUserId: string | null;
}

const QUICK_GIFT_ITEM = 'beer'; // fallback item ID — resolved below
const QUICK_GIFT_EMOJI = '🍺';

export function WhoIsHere({ venueId, onMessageUser, currentUserId }: WhoIsHereProps) {
  const { user } = useAuth();
  const [presence, setPresence] = useState<RoomPresenceUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [giftingUserId, setGiftingUserId] = useState<string | null>(null);
  const [giftItemId, setGiftItemId] = useState<string | null>(null);

  useEffect(() => {
    // Fetch the beer virtual item ID once
    import('../../lib/supabase').then(({ supabase }) => {
      supabase.from('virtual_items').select('id').eq('name', 'Beer').maybeSingle().then(({ data }) => {
        if (data) setGiftItemId(data.id);
      });
    });
  }, []);

  const load = async () => {
    try {
      const data = await roomService.getPresence(venueId);
      setPresence(data);
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    const sub = roomService.subscribeToPresence(venueId, load);
    return () => { sub.unsubscribe(); };
  }, [venueId]);

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-amber-400/30 border-t-amber-400 rounded-full animate-spin" />
      </div>
    );
  }

  if (presence.length === 0) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center gap-4 p-8">
        <div className="text-5xl">👻</div>
        <p className="text-gray-400 font-semibold">No one in The Room yet</p>
        <p className="text-gray-500 text-sm text-center">Be the first to join and start the night</p>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto p-4 space-y-3">
      <p className="text-xs text-gray-500 font-medium uppercase tracking-wider">
        {presence.length} {presence.length === 1 ? 'person' : 'people'} in The Room
      </p>

      {presence.map((p) => {
        const u = p.user;
        if (!u) return null;
        const isMe = u.id === currentUserId;
        const badge = getStatusBadge(u.tonight_status);
        const drinkEmoji = getDrinkEmoji(u.favorite_drinks);

        return (
          <div
            key={p.id}
            className="flex items-center gap-3 p-3 bg-gray-800/60 border border-gray-700/50 rounded-2xl hover:border-amber-500/30 transition-all"
          >
            <div className="relative flex-shrink-0">
              <div className="w-12 h-12 rounded-full overflow-hidden border-2 border-gray-700">
                {u.avatar_url ? (
                  <img src={u.avatar_url} alt={u.name} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center">
                    <User className="w-5 h-5 text-white" />
                  </div>
                )}
              </div>
              <span className="absolute -bottom-0.5 -right-0.5 w-4 h-4 bg-green-500 border-2 border-gray-900 rounded-full" />
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="font-semibold text-white truncate">
                  {u.name}{isMe && <span className="text-gray-500 font-normal"> (you)</span>}
                </span>
                {badge && (
                  <span className={`text-xs px-2 py-0.5 rounded-full border font-medium ${badge.color}`}>
                    {badge.label}
                  </span>
                )}
              </div>
              <div className="flex items-center gap-2 mt-0.5">
                {u.home_city && (
                  <span className="text-xs text-gray-500 flex items-center gap-1">
                    <MapPin className="w-3 h-3" />
                    {u.home_city}
                  </span>
                )}
                <span className="text-xs text-gray-500">{drinkEmoji} drinking</span>
              </div>
            </div>

            {!isMe && (
              <div className="flex gap-2 flex-shrink-0">
                {onMessageUser && (
                  <button
                    onClick={() => onMessageUser(u.id)}
                    className="w-9 h-9 bg-gray-700 hover:bg-gray-600 rounded-xl flex items-center justify-center transition-colors"
                    title="Message"
                  >
                    <MessageCircle className="w-4 h-4 text-gray-300" />
                  </button>
                )}
                <button
                  disabled={giftingUserId === u.id || !giftItemId}
                  onClick={async () => {
                    if (!giftItemId || giftingUserId) return;
                    setGiftingUserId(u.id);
                    try {
                      await giftsService.sendGift(u.id, giftItemId, undefined, 'venue', venueId);
                    } catch { /* silent */ } finally {
                      setGiftingUserId(null);
                    }
                  }}
                  className="w-9 h-9 bg-amber-500/20 hover:bg-amber-500/30 rounded-xl flex items-center justify-center transition-colors border border-amber-500/30 disabled:opacity-40"
                  title={`Send ${QUICK_GIFT_EMOJI} beer`}
                >
                  {giftingUserId === u.id
                    ? <div className="w-3 h-3 border-2 border-amber-400/30 border-t-amber-400 rounded-full animate-spin" />
                    : <Gift className="w-4 h-4 text-amber-400" />
                  }
                </button>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
