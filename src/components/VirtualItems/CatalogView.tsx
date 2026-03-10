import { useState, useEffect } from 'react';
import { Search, Filter, Sparkles, TrendingUp, Package, Gift, Coins } from 'lucide-react';
import { getRarityColor, getCategoryLabel } from '../../data/virtualItems';
import { supabase } from '../../lib/supabase';
import { xpService, RARITY_COIN_COST } from '../../services/xpService';
import type { Database } from '../../lib/database.types';

type VirtualItem = Database['public']['Tables']['virtual_items']['Row'];

function getItemCost(item: VirtualItem): number {
  if (item.price && item.price > 0) return item.price;
  return RARITY_COIN_COST[item.rarity] ?? 10;
}

export function CatalogView() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [selectedRarity, setSelectedRarity] = useState<string>('all');
  const [sortBy, setSortBy] = useState<'rarity' | 'name'>('rarity');
  const [items, setItems] = useState<VirtualItem[]>([]);
  const [coinBalance, setCoinBalance] = useState(0);

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (user) xpService.getCoinBalance(user.id).then(setCoinBalance);
    });
  }, []);

  const categories = ['all', 'emoji', 'drink', 'gift', 'celebration', 'sticker'];
  const rarities = ['all', 'common', 'rare', 'epic', 'legendary'];

  useEffect(() => {
    supabase
      .from('virtual_items')
      .select('*')
      .eq('is_active', true)
      .order('rarity')
      .then(({ data }) => { if (data) setItems(data); });
  }, []);

  const filteredItems = items
    .filter(item => {
      const matchesSearch = item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          item.description?.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesCategory = selectedCategory === 'all' || item.category === selectedCategory;
      const matchesRarity = selectedRarity === 'all' || item.rarity === selectedRarity;
      return matchesSearch && matchesCategory && matchesRarity;
    })
    .sort((a, b) => {
      if (sortBy === 'name') return a.name.localeCompare(b.name);
      const rarityOrder: Record<string, number> = { common: 1, rare: 2, epic: 3, legendary: 4 };
      return (rarityOrder[b.rarity] ?? 0) - (rarityOrder[a.rarity] ?? 0);
    });

  const stats = {
    total: items.length,
    legendary: items.filter(i => i.rarity === 'legendary').length,
    epic: items.filter(i => i.rarity === 'epic').length,
    rare: items.filter(i => i.rarity === 'rare').length,
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#FFF5F0] to-white pb-24">
      <div className="bg-gradient-to-br from-[#E91E63] via-rose-500 to-[#FF6B6B] text-white px-6 pt-8 pb-6">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-12 h-12 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center">
            <Gift className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-2xl font-bold">Virtual Gifts</h1>
            <p className="text-white/80 text-sm">Send gifts using Lush Coins</p>
          </div>
        </div>

        <div className="mt-3 flex items-center justify-between gap-2 bg-white/15 backdrop-blur-sm rounded-2xl px-4 py-3">
          <div className="flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-white/90" />
            <p className="text-sm text-white font-medium">
              Earn coins by checking in, streaks &amp; challenges
            </p>
          </div>
          <div className="flex items-center gap-1.5 px-3 py-1.5 bg-white/20 rounded-full">
            <Coins className="w-4 h-4 text-yellow-300" />
            <span className="text-sm font-bold text-white">{coinBalance} LC</span>
          </div>
        </div>

        <div className="grid grid-cols-4 gap-3 mt-5">
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
            <div className="flex items-center justify-center gap-1 mb-1">
              <Package className="w-4 h-4" />
              <span className="text-xl font-bold">{stats.total}</span>
            </div>
            <p className="text-xs text-white/80">Total Gifts</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
            <div className="flex items-center justify-center gap-1 mb-1">
              <TrendingUp className="w-4 h-4" />
              <span className="text-xl font-bold">{stats.legendary}</span>
            </div>
            <p className="text-xs text-white/80">Legendary</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
            <div className="flex items-center justify-center gap-1 mb-1">
              <Sparkles className="w-4 h-4" />
              <span className="text-xl font-bold">{stats.epic}</span>
            </div>
            <p className="text-xs text-white/80">Epic</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
            <div className="flex items-center justify-center gap-1 mb-1">
              <Filter className="w-4 h-4" />
              <span className="text-xl font-bold">{stats.rare}</span>
            </div>
            <p className="text-xs text-white/80">Rare</p>
          </div>
        </div>
      </div>

      <div className="px-6 -mt-4 space-y-4">
        <div className="bg-white rounded-2xl shadow-lg p-4">
          <div className="relative mb-3">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search gifts..."
              className="w-full pl-10 pr-4 py-3 bg-gray-50 rounded-xl border border-gray-200 focus:ring-2 focus:ring-[#E91E63] focus:border-transparent outline-none text-gray-900 placeholder:text-gray-400"
            />
          </div>

          <div className="flex items-center gap-2 mb-3">
            <Filter className="w-4 h-4 text-gray-500" />
            <span className="text-sm font-medium text-gray-700">Category:</span>
          </div>
          <div className="flex gap-2 overflow-x-auto pb-2">
            {categories.map(category => (
              <button
                key={category}
                onClick={() => setSelectedCategory(category)}
                className={`px-4 py-2 rounded-xl text-xs font-medium whitespace-nowrap transition-all ${
                  selectedCategory === category
                    ? 'bg-gradient-to-r from-[#E91E63] to-[#FF6B6B] text-white shadow-md'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {category === 'all' ? 'All Gifts' : getCategoryLabel(category as any)}
              </button>
            ))}
          </div>

          <div className="flex items-center gap-2 mt-4 mb-3">
            <Sparkles className="w-4 h-4 text-gray-500" />
            <span className="text-sm font-medium text-gray-700">Rarity:</span>
          </div>
          <div className="flex gap-2 overflow-x-auto pb-2">
            {rarities.map(rarity => (
              <button
                key={rarity}
                onClick={() => setSelectedRarity(rarity)}
                className={`px-4 py-2 rounded-xl text-xs font-medium whitespace-nowrap capitalize transition-all ${
                  selectedRarity === rarity
                    ? 'bg-gradient-to-r from-[#E91E63] to-[#FF6B6B] text-white shadow-md'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {rarity}
              </button>
            ))}
          </div>

          <div className="flex items-center gap-2 mt-4">
            <span className="text-sm font-medium text-gray-700">Sort by:</span>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as any)}
              className="flex-1 px-3 py-2 bg-gray-50 rounded-lg border border-gray-200 text-sm text-gray-900 outline-none focus:ring-2 focus:ring-[#E91E63]"
            >
              <option value="rarity">Rarity</option>
              <option value="name">Name (A-Z)</option>
            </select>
          </div>
        </div>

        <div className="text-sm text-gray-600 px-1">
          Showing {filteredItems.length} of {items.length} gifts
        </div>

        <div className="grid grid-cols-2 gap-4">
          {filteredItems.map(item => {
            const cost = getItemCost(item);
            const canAfford = coinBalance >= cost;
            return (
            <div
              key={item.id}
              className={`bg-white rounded-2xl shadow-md overflow-hidden border-2 transition-all hover:scale-105 hover:shadow-xl ${
                canAfford ? 'border-gray-100' : 'border-gray-100 opacity-60'
              }`}
            >
              <div className={`bg-gradient-to-br ${getRarityColor(item.rarity)} p-4 text-white text-center relative`}>
                <div className="absolute inset-0 bg-white/10 backdrop-blur-sm"></div>
                <div className="relative z-10">
                  <div className="text-5xl mb-2">{item.emoji}</div>
                  <div className="text-xs font-medium px-2 py-1 bg-white/20 rounded-full inline-block capitalize mb-1">
                    {item.rarity}
                  </div>
                </div>
              </div>
              <div className="p-3">
                <h3 className="font-bold text-gray-900 mb-1">{item.name}</h3>
                <p className="text-xs text-gray-600 mb-3 line-clamp-2">{item.description}</p>
                <div className="flex items-center justify-between">
                  <span className="text-xs text-gray-500 capitalize">{item.category}</span>
                  <div className={`flex items-center gap-0.5 text-sm font-bold ${canAfford ? 'text-purple-600' : 'text-gray-400'}`}>
                    <span>🪙</span>
                    <span>{cost}</span>
                  </div>
                </div>
              </div>
            </div>
            );
          })}
        </div>

        {filteredItems.length === 0 && (
          <div className="text-center py-12">
            <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Package className="w-10 h-10 text-gray-400" />
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">No gifts found</h3>
            <p className="text-gray-500 text-sm">Try adjusting your filters</p>
          </div>
        )}
      </div>
    </div>
  );
}
