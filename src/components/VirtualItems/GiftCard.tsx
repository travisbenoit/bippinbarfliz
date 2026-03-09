import { Sparkles } from 'lucide-react';
import { getRarityColor } from '../../data/virtualItems';
import type { Database } from '../../lib/database.types';

type VirtualItem = Database['public']['Tables']['virtual_items']['Row'];

interface GiftCardProps {
  item: VirtualItem;
  fromUserName: string;
  fromUserAvatar?: string;
  message?: string;
  timestamp: string;
  status: 'sent' | 'viewed' | 'reacted';
  reaction?: string;
  onReact?: (emoji: string) => void;
  isInChat?: boolean;
}

const quickReactions = ['❤️', '😍', '🔥', '😂', '👍', '🙏'];

export function GiftCard({
  item,
  fromUserName,
  fromUserAvatar,
  message,
  timestamp,
  status,
  reaction,
  onReact,
  isInChat = false
}: GiftCardProps) {
  const formatTime = () => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;
    return date.toLocaleDateString();
  };

  return (
    <div className={`${
      isInChat
        ? 'bg-white rounded-2xl shadow-md border-2 border-purple-200 p-4 max-w-[280px]'
        : 'bg-white rounded-2xl shadow-lg p-5'
    }`}>
      <div className={`bg-gradient-to-br ${getRarityColor(item.rarity)} rounded-xl p-6 text-white text-center mb-3 relative overflow-hidden`}>
        <div className="absolute inset-0 bg-white/10 backdrop-blur-sm"></div>
        <div className="relative z-10">
          <div className="inline-flex items-center justify-center w-20 h-20 bg-white/20 rounded-full mb-3 animate-bounce">
            <div className="text-5xl">{item.emoji}</div>
          </div>
          <h3 className="font-bold text-lg">{item.name}</h3>
          <p className="text-xs text-white/90 mt-1">{item.description}</p>
        </div>
        <div className="absolute top-3 right-3 px-2 py-1 bg-white/20 backdrop-blur-sm rounded-full text-xs font-medium capitalize">
          {item.rarity}
        </div>
      </div>

      <div className="flex items-center gap-2 mb-3">
        {fromUserAvatar ? (
          <img src={fromUserAvatar} alt={fromUserName} className="w-8 h-8 rounded-full object-cover" />
        ) : (
          <div className="w-8 h-8 rounded-full bg-gradient-to-br from-pink-300 to-orange-300 flex items-center justify-center">
            <Sparkles className="w-4 h-4 text-white" />
          </div>
        )}
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium text-gray-900 truncate">From {fromUserName}</p>
          <p className="text-xs text-gray-500">{formatTime()}</p>
        </div>
      </div>

      {message && (
        <div className="bg-gray-50 rounded-xl p-3 mb-3">
          <p className="text-sm text-gray-700 italic">"{message}"</p>
        </div>
      )}

      {status === 'reacted' && reaction && (
        <div className="flex items-center gap-2 px-3 py-2 bg-gradient-to-r from-pink-50 to-purple-50 rounded-lg mb-3">
          <span className="text-xl">{reaction}</span>
          <span className="text-sm text-gray-600">You reacted</span>
        </div>
      )}

      {status !== 'reacted' && onReact && (
        <div>
          <p className="text-xs text-gray-500 mb-2">React with:</p>
          <div className="flex gap-2">
            {quickReactions.map(emoji => (
              <button
                key={emoji}
                onClick={() => onReact(emoji)}
                className="flex-1 aspect-square rounded-lg bg-gray-50 hover:bg-gray-100 transition-all hover:scale-110 text-xl flex items-center justify-center"
              >
                {emoji}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
