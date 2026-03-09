import { useState, useEffect } from 'react';
import { Gift, Inbox, Send as SendIcon, TrendingUp, Sparkles, Package } from 'lucide-react';
import { GiftCard } from '../VirtualItems/GiftCard';
import { CatalogView } from '../VirtualItems/CatalogView';
import type { Database } from '../../lib/database.types';
import { giftsService } from '../../services/giftsService';

type VirtualItem = Database['public']['Tables']['virtual_items']['Row'];

interface DisplayGift {
  id: string;
  from_user_id: string;
  from_user_name: string;
  from_user_avatar?: string;
  item: VirtualItem;
  message?: string;
  status: 'sent' | 'viewed' | 'reacted';
  reaction?: string;
  created_at: string;
}

export function GiftsInbox() {
  const [activeTab, setActiveTab] = useState<'received' | 'sent' | 'catalog'>('received');
  const [receivedGifts, setReceivedGifts] = useState<DisplayGift[]>([]);
  const [sentGifts, setSentGifts] = useState<DisplayGift[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadGifts();
  }, [activeTab]);

  const mapGift = (gift: any, nameField: 'from_user' | 'to_user'): DisplayGift => ({
    id: gift.id,
    from_user_id: gift.from_user_id,
    from_user_name: gift[nameField]?.name || 'Unknown',
    from_user_avatar: gift[nameField]?.avatar_url,
    item: gift.item as VirtualItem,
    message: gift.message,
    status: gift.status || 'sent',
    reaction: gift.reaction,
    created_at: gift.created_at,
  });

  const loadGifts = async () => {
    try {
      setLoading(true);
      setError(null);

      if (activeTab === 'received') {
        const dbGifts = await giftsService.getReceivedGifts();
        setReceivedGifts(dbGifts.map((g: any) => mapGift(g, 'from_user')));
      } else if (activeTab === 'sent') {
        const dbGifts = await giftsService.getSentGifts();
        setSentGifts(dbGifts.map((g: any) => mapGift(g, 'to_user')));
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load gifts');
    } finally {
      setLoading(false);
    }
  };

  const handleReact = async (giftId: string, emoji: string) => {
    try {
      setError(null);
      await giftsService.updateGiftStatus(giftId, 'reacted', emoji);
      await loadGifts();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update gift');
    }
  };

  const gifts = activeTab === 'sent' ? sentGifts : receivedGifts;
  const totalValue = gifts.reduce((sum, gift) => sum + gift.item.price, 0);
  const unviewedCount = gifts.filter(g => g.status === 'sent').length;

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#FFF5F0] to-white pb-24">
      <div className="bg-gradient-to-br from-[#E91E63] to-[#FF6B6B] text-white px-6 pt-8 pb-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-12 h-12 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center">
            <Gift className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-2xl font-bold">Gifts</h1>
            <p className="text-white/80 text-sm">Your virtual treasures</p>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-3 mt-6">
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
            <div className="flex items-center justify-center gap-1 mb-1">
              <Inbox className="w-4 h-4" />
              <span className="text-2xl font-bold">{gifts.length}</span>
            </div>
            <p className="text-xs text-white/80">Received</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
            <div className="flex items-center justify-center gap-1 mb-1">
              <Sparkles className="w-4 h-4" />
              <span className="text-2xl font-bold">{unviewedCount}</span>
            </div>
            <p className="text-xs text-white/80">New</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
            <div className="flex items-center justify-center gap-1 mb-1">
              <TrendingUp className="w-4 h-4" />
              <span className="text-2xl font-bold">{totalValue}</span>
            </div>
            <p className="text-xs text-white/80">Total Value</p>
          </div>
        </div>
      </div>

      <div className="px-6 -mt-4">
        <div className="bg-white rounded-2xl shadow-lg p-1 inline-flex gap-1">
          <button
            onClick={() => setActiveTab('received')}
            className={`px-4 py-2.5 rounded-xl font-medium text-sm transition-all flex items-center gap-1.5 ${
              activeTab === 'received'
                ? 'bg-gradient-to-r from-[#E91E63] to-[#FF6B6B] text-white shadow-md'
                : 'text-gray-600 hover:bg-gray-50'
            }`}
          >
            <Inbox className="w-4 h-4" />
            Received
          </button>
          <button
            onClick={() => setActiveTab('sent')}
            className={`px-4 py-2.5 rounded-xl font-medium text-sm transition-all flex items-center gap-1.5 ${
              activeTab === 'sent'
                ? 'bg-gradient-to-r from-[#E91E63] to-[#FF6B6B] text-white shadow-md'
                : 'text-gray-600 hover:bg-gray-50'
            }`}
          >
            <SendIcon className="w-4 h-4" />
            Sent
          </button>
          <button
            onClick={() => setActiveTab('catalog')}
            className={`px-4 py-2.5 rounded-xl font-medium text-sm transition-all flex items-center gap-1.5 ${
              activeTab === 'catalog'
                ? 'bg-gradient-to-r from-[#E91E63] to-[#FF6B6B] text-white shadow-md'
                : 'text-gray-600 hover:bg-gray-50'
            }`}
          >
            <Package className="w-4 h-4" />
            Catalog
          </button>
        </div>
      </div>

      {activeTab === 'catalog' ? (
        <CatalogView />
      ) : (
        <div className="px-6 mt-6">
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-3 text-red-700 text-sm mb-4">
              {error}
            </div>
          )}
          {loading ? (
            <div className="text-center py-12">
              <p className="text-gray-400">Loading gifts...</p>
            </div>
          ) : gifts.length > 0 ? (
            <div className="space-y-4">
              {gifts.map(gift => (
                <GiftCard
                  key={gift.id}
                  item={gift.item}
                  fromUserName={gift.from_user_name}
                  fromUserAvatar={gift.from_user_avatar}
                  message={gift.message}
                  timestamp={gift.created_at}
                  status={gift.status}
                  reaction={gift.reaction}
                  onReact={(emoji) => handleReact(gift.id, emoji)}
                />
              ))}
            </div>
          ) : (
            <div className="text-center py-12">
              <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                {activeTab === 'received' ? (
                  <Inbox className="w-10 h-10 text-gray-400" />
                ) : (
                  <SendIcon className="w-10 h-10 text-gray-400" />
                )}
              </div>
              <h3 className="text-lg font-semibold text-gray-900 mb-2">
                {activeTab === 'received' ? 'No gifts yet' : 'No sent gifts'}
              </h3>
              <p className="text-gray-500 text-sm">
                {activeTab === 'received'
                  ? 'When someone sends you a gift, it will appear here'
                  : 'Send gifts to friends through messages or profiles'}
              </p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
