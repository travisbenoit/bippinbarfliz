import { useState, useEffect, useRef, useCallback } from 'react';
import { Send, Trash2, Flag, Beer, Flame, Music, User } from 'lucide-react';
import { roomService, RoomMessage, ReactionType } from '../../services/roomService';

const REACTION_MAP: { type: ReactionType; emoji: string }[] = [
  { type: 'fire', emoji: '🔥' },
  { type: 'beer', emoji: '🍺' },
  { type: 'cocktail', emoji: '🍸' },
  { type: 'dance', emoji: '💃' },
  { type: 'music', emoji: '🎧' },
  { type: 'whiskey', emoji: '🥃' },
  { type: 'heart', emoji: '❤️' },
  { type: 'laugh', emoji: '😂' },
];

const QUICK_PROMPTS = [
  "DJ is killing it tonight 🔥",
  "What's everyone drinking?",
  "Anyone celebrating tonight? 🥂",
  "Best song of the night so far?",
  "Table at the back is wild rn 😂",
  "Shots at the bar in 5 mins 🥃",
];

const DRINK_PROMPTS = [
  "Espresso Martini is insane here 🍸",
  "Try the mezcal margarita!",
  "House cocktails are 2-for-1 tonight",
  "The IPA on tap is 🔥",
];

interface RoomChatProps {
  venueId: string;
  isInsideVenue: boolean;
  currentUserId: string | null;
}

function timeLabel(iso: string): string {
  const now = Date.now();
  const diff = now - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  return `${Math.floor(mins / 60)}h ago`;
}

function groupReactions(reactions: { reaction: ReactionType; user_id: string }[]): Record<string, { count: number; hasOwn: boolean }> {
  const map: Record<string, { count: number; hasOwn: boolean }> = {};
  reactions.forEach((r) => {
    const em = REACTION_MAP.find((x) => x.type === r.reaction)?.emoji || r.reaction;
    if (!map[em]) map[em] = { count: 0, hasOwn: false };
    map[em].count++;
  });
  return map;
}

export function RoomChat({ venueId, isInsideVenue, currentUserId }: RoomChatProps) {
  const [messages, setMessages] = useState<RoomMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const [rateLimited, setRateLimited] = useState(false);
  const [showPrompts, setShowPrompts] = useState(false);
  const [showDrinkPrompts, setShowDrinkPrompts] = useState(false);
  const [activeReactionMsgId, setActiveReactionMsgId] = useState<string | null>(null);
  const [allReactions, setAllReactions] = useState<Record<string, { reaction: ReactionType; user_id: string; message_id: string }[]>>({});
  const bottomRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const loadMessages = useCallback(async () => {
    try {
      const msgs = await roomService.getMessages(venueId);
      setMessages(msgs);
      const ids = msgs.map((m) => m.id);
      if (ids.length > 0) {
        const reactions = await roomService.getReactionsForMessages(ids);
        const grouped: typeof allReactions = {};
        reactions.forEach((r) => {
          if (!grouped[r.message_id]) grouped[r.message_id] = [];
          grouped[r.message_id].push(r as any);
        });
        setAllReactions(grouped);
      }
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  }, [venueId]);

  useEffect(() => {
    loadMessages();
    const sub = roomService.subscribeToMessages(venueId, (msg) => {
      setMessages((prev) => [...prev, msg]);
      setTimeout(() => bottomRef.current?.scrollIntoView({ behavior: 'smooth' }), 50);
    });
    const reactSub = roomService.subscribeToReactions(venueId, () => loadMessages());
    return () => {
      sub.unsubscribe();
      reactSub.unsubscribe();
    };
  }, [venueId, loadMessages]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async (body?: string, type: 'text' | 'drink' | 'prompt' = 'text') => {
    const content = body || text.trim();
    if (!content || sending) return;
    setSending(true);
    setShowPrompts(false);
    setShowDrinkPrompts(false);
    try {
      await roomService.postMessage(venueId, content, type);
      setText('');
    } catch (err: any) {
      if (err.message === 'rate_limit') {
        setRateLimited(true);
        setTimeout(() => setRateLimited(false), 5000);
      }
    } finally {
      setSending(false);
    }
  };

  const handleReaction = async (messageId: string, reaction: ReactionType) => {
    setActiveReactionMsgId(null);
    await roomService.addReaction(messageId, reaction);
    await loadMessages();
  };

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-amber-400/30 border-t-amber-400 rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      {!isInsideVenue && (
        <div className="mx-3 mt-2 mb-1 px-4 py-2 bg-gray-800/80 rounded-xl border border-gray-700 text-center text-xs text-gray-400">
          Viewing remotely — check in at the venue to join the conversation
        </div>
      )}

      <div className="flex-1 overflow-y-auto px-3 py-3 space-y-2">
        {messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full gap-4 pb-8">
            <div className="text-5xl">🎉</div>
            <p className="text-gray-400 font-semibold text-center">You're the first one here tonight.</p>
            <p className="text-gray-500 text-sm text-center">Start the vibe.</p>
            {isInsideVenue && (
              <button
                onClick={() => handleSend("I just arrived — who's here? 👋", 'prompt')}
                className="px-5 py-2.5 bg-amber-500 text-black font-bold rounded-xl text-sm hover:bg-amber-400 transition-colors"
              >
                Break the ice
              </button>
            )}
          </div>
        ) : (
          messages.map((msg) => {
            const isOwn = msg.user_id === currentUserId;
            const msgReactions = allReactions[msg.id] || [];
            const grouped = groupReactions(msgReactions);
            const hasReactions = Object.keys(grouped).length > 0;

            return (
              <div key={msg.id} className={`flex gap-2 items-end ${isOwn ? 'flex-row-reverse' : ''}`}>
                <div className="flex-shrink-0 mb-1">
                  {msg.user?.avatar_url ? (
                    <img src={msg.user.avatar_url} alt={msg.user.name} className="w-7 h-7 rounded-full object-cover" />
                  ) : (
                    <div className="w-7 h-7 rounded-full bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center">
                      <User className="w-3.5 h-3.5 text-white" />
                    </div>
                  )}
                </div>

                <div className={`max-w-[72%] group relative`}>
                  {!isOwn && (
                    <p className="text-xs text-gray-500 mb-1 ml-1 font-medium">
                      {msg.user?.name || 'Someone'}
                      {msg.user?.home_city ? ` · ${msg.user.home_city}` : ''}
                    </p>
                  )}

                  <div
                    className={`relative px-3.5 py-2.5 rounded-2xl ${
                      isOwn
                        ? 'bg-amber-500 text-black rounded-br-sm'
                        : msg.message_type === 'drink'
                        ? 'bg-gradient-to-br from-[#1a1a2e] to-[#16213e] border border-amber-500/30 text-white rounded-bl-sm'
                        : msg.message_type === 'prompt'
                        ? 'bg-gradient-to-br from-[#1a1a2e] to-[#16213e] border border-pink-500/30 text-white rounded-bl-sm'
                        : 'bg-gray-800 text-white rounded-bl-sm'
                    }`}
                  >
                    {msg.message_type === 'drink' && <span className="text-amber-400 mr-1">🍸</span>}
                    {msg.message_type === 'prompt' && <span className="text-pink-400 mr-1">💬</span>}
                    <span className="text-sm leading-snug">{msg.body}</span>

                    <div className={`flex items-center gap-2 mt-1 ${isOwn ? 'justify-end' : 'justify-start'}`}>
                      <span className="text-xs opacity-50">{timeLabel(msg.created_at)}</span>
                    </div>

                    <div className="absolute -right-1 -top-1 opacity-0 group-hover:opacity-100 transition-opacity flex gap-1">
                      <button
                        onClick={() => setActiveReactionMsgId(activeReactionMsgId === msg.id ? null : msg.id)}
                        className="w-6 h-6 bg-gray-700 rounded-full flex items-center justify-center text-xs hover:bg-gray-600"
                      >
                        😊
                      </button>
                      {isOwn && (
                        <button
                          onClick={() => {
                            roomService.deleteMessage(msg.id);
                            setMessages((prev) => prev.filter((m) => m.id !== msg.id));
                          }}
                          className="w-6 h-6 bg-red-900/80 rounded-full flex items-center justify-center hover:bg-red-800"
                        >
                          <Trash2 className="w-3 h-3 text-red-400" />
                        </button>
                      )}
                      {!isOwn && (
                        <button
                          onClick={() => {
                            roomService.reportMessage(msg.id);
                            setMessages((prev) => prev.filter((m) => m.id !== msg.id));
                          }}
                          className="w-6 h-6 bg-orange-900/80 rounded-full flex items-center justify-center hover:bg-orange-800"
                        >
                          <Flag className="w-3 h-3 text-orange-400" />
                        </button>
                      )}
                    </div>
                  </div>

                  {activeReactionMsgId === msg.id && (
                    <div className={`absolute z-20 ${isOwn ? 'right-0' : 'left-0'} mt-1 flex gap-1 bg-gray-900 border border-gray-700 rounded-2xl p-2 shadow-xl`}>
                      {REACTION_MAP.map((r) => (
                        <button
                          key={r.type}
                          onClick={() => handleReaction(msg.id, r.type)}
                          className="text-lg hover:scale-125 transition-transform"
                        >
                          {r.emoji}
                        </button>
                      ))}
                    </div>
                  )}

                  {hasReactions && (
                    <div className={`flex gap-1 mt-1 flex-wrap ${isOwn ? 'justify-end' : 'justify-start'}`}>
                      {Object.entries(grouped).map(([emoji, { count }]) => (
                        <span key={emoji} className="inline-flex items-center gap-0.5 bg-gray-800 border border-gray-700 rounded-full px-2 py-0.5 text-xs">
                          {emoji} <span className="text-gray-400">{count}</span>
                        </span>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            );
          })
        )}
        <div ref={bottomRef} />
      </div>

      {isInsideVenue && (
        <div className="border-t border-gray-800 bg-gray-900/80 px-3 pt-2 pb-3 space-y-2">
          {showPrompts && (
            <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-none">
              {QUICK_PROMPTS.map((p) => (
                <button
                  key={p}
                  onClick={() => handleSend(p, 'prompt')}
                  className="flex-shrink-0 px-3 py-1.5 bg-gray-800 border border-gray-700 text-white text-xs rounded-full hover:border-amber-500/50 hover:bg-gray-700 transition-colors"
                >
                  {p}
                </button>
              ))}
            </div>
          )}

          {showDrinkPrompts && (
            <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-none">
              {DRINK_PROMPTS.map((p) => (
                <button
                  key={p}
                  onClick={() => handleSend(p, 'drink')}
                  className="flex-shrink-0 px-3 py-1.5 bg-amber-900/40 border border-amber-500/30 text-amber-300 text-xs rounded-full hover:bg-amber-900/60 transition-colors"
                >
                  {p}
                </button>
              ))}
            </div>
          )}

          <div className="flex items-center gap-2">
            <button
              onClick={() => { setShowPrompts(!showPrompts); setShowDrinkPrompts(false); }}
              className={`p-2 rounded-xl transition-colors ${showPrompts ? 'bg-pink-500/20 text-pink-400' : 'bg-gray-800 text-gray-400 hover:text-white'}`}
              title="Quick prompts"
            >
              <Flame className="w-4 h-4" />
            </button>
            <button
              onClick={() => { setShowDrinkPrompts(!showDrinkPrompts); setShowPrompts(false); }}
              className={`p-2 rounded-xl transition-colors ${showDrinkPrompts ? 'bg-amber-500/20 text-amber-400' : 'bg-gray-800 text-gray-400 hover:text-white'}`}
              title="Drink recs"
            >
              <Beer className="w-4 h-4" />
            </button>

            <input
              ref={inputRef}
              type="text"
              value={text}
              onChange={(e) => setText(e.target.value.slice(0, 280))}
              onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleSend()}
              placeholder={rateLimited ? 'Slow down a little... ⏳' : 'Say something...'}
              disabled={rateLimited || sending}
              className="flex-1 px-4 py-2.5 bg-gray-800 border border-gray-700 rounded-xl text-white text-sm placeholder-gray-500 focus:outline-none focus:border-amber-500/50 disabled:opacity-50 transition-colors"
            />

            <button
              onClick={() => handleSend()}
              disabled={!text.trim() || sending || rateLimited}
              className="p-2.5 bg-amber-500 text-black rounded-xl disabled:opacity-30 hover:bg-amber-400 transition-all active:scale-95"
            >
              <Send className="w-4 h-4" />
            </button>
          </div>
          <p className="text-right text-xs text-gray-600 pr-1">{text.length}/280</p>
        </div>
      )}
    </div>
  );
}
