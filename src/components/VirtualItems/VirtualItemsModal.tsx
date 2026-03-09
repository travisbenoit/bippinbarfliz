import { useState, useEffect } from 'react';
import { X, Send, Sparkles } from 'lucide-react';
import { getRarityColor, getCategoryLabel } from '../../data/virtualItems';
import { supabase } from '../../lib/supabase';
import type { Database } from '../../lib/database.types';

type VirtualItem = Database['public']['Tables']['virtual_items']['Row'];

interface VirtualItemsModalProps {
  isOpen: boolean;
  onClose: () => void;
  recipientId: string;
  recipientName: string;
  onSend?: (item: VirtualItem, message: string) => void;
}

const categories = ['emoji', 'drink', 'gift', 'celebration', 'sticker'] as const;

export function VirtualItemsModal({ isOpen, onClose, recipientId, recipientName, onSend }: VirtualItemsModalProps) {
  const [selectedCategory, setSelectedCategory] = useState<typeof categories[number]>('emoji');
  const [selectedItem, setSelectedItem] = useState<VirtualItem | null>(null);
  const [message, setMessage] = useState('');
  const [allItems, setAllItems] = useState<VirtualItem[]>([]);

  useEffect(() => {
    if (!isOpen) return;
    supabase
      .from('virtual_items')
      .select('*')
      .eq('is_active', true)
      .then(({ data }) => { if (data) setAllItems(data); });
  }, [isOpen]);

  if (!isOpen) return null;

  const filteredItems = allItems.filter(item => item.category === selectedCategory);

  const handleSend = () => {
    if (!selectedItem) return;
    if (onSend) {
      onSend(selectedItem, message);
    }
    onClose();
  };

  return (
    <div className="fixed inset-0 z-[3000] bg-black/60 backdrop-blur-sm flex items-end sm:items-center justify-center p-0 sm:p-4 animate-fade-in">
      <div className="bg-white w-full sm:max-w-2xl sm:rounded-2xl rounded-t-3xl max-h-[90vh] flex flex-col shadow-2xl animate-slide-up">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200">
          <div>
            <h2 className="text-xl font-bold text-gray-900">Send a Gift</h2>
            <p className="text-sm text-gray-500 mt-0.5">to {recipientName} — all free!</p>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1.5 px-3 py-1.5 bg-gradient-to-r from-[#E91E63] to-[#FF6B6B] rounded-full">
              <Sparkles className="w-4 h-4 text-white" />
              <span className="text-sm font-bold text-white">Free</span>
            </div>
            <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>
        </div>

        <div className="flex gap-2 px-6 py-3 border-b border-gray-200 overflow-x-auto">
          {categories.map(category => (
            <button
              key={category}
              onClick={() => {
                setSelectedCategory(category);
                setSelectedItem(null);
              }}
              className={`px-4 py-2 rounded-xl text-sm font-medium whitespace-nowrap transition-all ${
                selectedCategory === category
                  ? 'bg-gradient-to-r from-[#E91E63] to-[#FF6B6B] text-white shadow-md'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {getCategoryLabel(category)}
            </button>
          ))}
        </div>

        <div className="flex-1 overflow-y-auto p-6">
          <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
            {filteredItems.map(item => (
              <button
                key={item.id}
                onClick={() => setSelectedItem(item)}
                className={`relative aspect-square rounded-2xl p-3 flex flex-col items-center justify-center transition-all ${
                  selectedItem?.id === item.id
                    ? 'bg-gradient-to-br from-[#E91E63] to-[#FF6B6B] shadow-lg scale-105'
                    : 'bg-gray-50 hover:bg-gray-100 hover:scale-105'
                }`}
              >
                <div className="text-4xl mb-2">{item.emoji}</div>
                <div className={`text-xs font-medium text-center ${
                  selectedItem?.id === item.id ? 'text-white' : 'text-gray-700'
                }`}>
                  {item.name}
                </div>
                <div className={`text-xs font-medium mt-1 ${
                  selectedItem?.id === item.id ? 'text-white/80' : 'text-[#E91E63]'
                }`}>
                  Free
                </div>
              </button>
            ))}
          </div>
        </div>

        {selectedItem && (
          <div className="border-t border-gray-200 p-6 bg-gray-50">
            <div className={`mb-4 p-4 rounded-xl bg-gradient-to-br ${getRarityColor(selectedItem.rarity)} text-white`}>
              <div className="flex items-start gap-3">
                <div className="text-5xl">{selectedItem.emoji}</div>
                <div className="flex-1">
                  <h3 className="font-bold text-lg">{selectedItem.name}</h3>
                  <p className="text-sm text-white/90 mt-1">{selectedItem.description}</p>
                  <div className="flex items-center gap-3 mt-2">
                    <span className="text-xs font-medium px-2 py-0.5 bg-white/20 rounded-full capitalize">
                      {selectedItem.rarity}
                    </span>
                    <div className="flex items-center gap-1 text-sm font-bold">
                      <Sparkles className="w-4 h-4" />
                      <span>Free to send</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Add a personal message (optional)"
              className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#E91E63] focus:border-transparent outline-none resize-none text-gray-900 placeholder:text-gray-400"
              rows={2}
            />

            <button
              onClick={handleSend}
              className="w-full mt-3 px-6 py-3.5 bg-gradient-to-r from-[#E91E63] to-[#FF6B6B] text-white rounded-xl font-semibold hover:shadow-lg transition-all flex items-center justify-center gap-2"
            >
              <Send className="w-5 h-5" />
              <span>Send {selectedItem.name}</span>
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
