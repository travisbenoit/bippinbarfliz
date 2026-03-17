export interface VirtualItem {
  id: string;
  name: string;
  category: 'emoji' | 'drink' | 'gift' | 'sticker' | 'celebration' | 'seasonal';
  emoji: string;
  price: number;
  is_premium: boolean;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
  description?: string;
  animation_url?: string;
  is_active: boolean;
}

export interface UserGift {
  id: string;
  from_user_id: string;
  to_user_id: string;
  item_id: string;
  message?: string;
  status: 'sent' | 'viewed' | 'reacted';
  reaction?: string;
  context_type: 'direct_message' | 'profile' | 'swarm' | 'venue';
  context_id?: string;
  viewed_at?: string;
  created_at: string;
  item?: VirtualItem;
  from_user?: {
    name: string;
    avatar_url?: string;
  };
}

export const MOCK_VIRTUAL_ITEMS: VirtualItem[] = [
  { id: '1', name: 'Heart Eyes', category: 'emoji', emoji: '\ud83d\ude0d', price: 0, is_premium: false, rarity: 'common', description: 'Show some love', is_active: true },
  { id: '2', name: 'Fire', category: 'emoji', emoji: '\ud83d\udd25', price: 0, is_premium: false, rarity: 'common', description: 'That is fire!', is_active: true },
  { id: '3', name: 'Sparkles', category: 'emoji', emoji: '\u2728', price: 0, is_premium: false, rarity: 'common', description: 'Magical vibes', is_active: true },
  { id: '4', name: 'Dancing', category: 'emoji', emoji: '\ud83d\udc83', price: 0, is_premium: false, rarity: 'common', description: 'Let\'s dance!', is_active: true },
  { id: '5', name: 'Cheers', category: 'emoji', emoji: '\ud83e\udd42', price: 0, is_premium: false, rarity: 'common', description: 'Cheers to that!', is_active: true },
  { id: '6', name: 'Party', category: 'emoji', emoji: '\ud83c\udf89', price: 0, is_premium: false, rarity: 'common', description: 'Party time!', is_active: true },
  { id: '7', name: 'Sunglasses', category: 'emoji', emoji: '\ud83d\ude0e', price: 0, is_premium: false, rarity: 'common', description: 'Looking cool', is_active: true },
  { id: '8', name: 'Laughing', category: 'emoji', emoji: '\ud83d\ude02', price: 0, is_premium: false, rarity: 'common', description: 'Too funny!', is_active: true },

  { id: '9', name: 'Beer', category: 'drink', emoji: '\ud83c\udf7a', price: 0, is_premium: false, rarity: 'common', description: 'Classic beer on me', is_active: true },
  { id: '10', name: 'Wine', category: 'drink', emoji: '\ud83c\udf77', price: 0, is_premium: false, rarity: 'common', description: 'Glass of wine', is_active: true },
  { id: '11', name: 'Cocktail', category: 'drink', emoji: '\ud83c\udf79', price: 0, is_premium: false, rarity: 'rare', description: 'Fancy cocktail', is_active: true },
  { id: '12', name: 'Champagne', category: 'drink', emoji: '\ud83c\udf7e', price: 0, is_premium: false, rarity: 'epic', description: 'Celebration time!', is_active: true },
  { id: '13', name: 'Whiskey', category: 'drink', emoji: '\ud83e\udd43', price: 0, is_premium: false, rarity: 'rare', description: 'Smooth whiskey', is_active: true },
  { id: '14', name: 'Martini', category: 'drink', emoji: '\ud83c\udf78', price: 0, is_premium: false, rarity: 'rare', description: 'Classy martini', is_active: true },

  { id: '15', name: 'Rose', category: 'gift', emoji: '\ud83c\udf39', price: 0, is_premium: false, rarity: 'rare', description: 'A romantic gesture', is_active: true },
  { id: '16', name: 'Bouquet', category: 'gift', emoji: '\ud83d\udc90', price: 0, is_premium: false, rarity: 'epic', description: 'Beautiful bouquet', is_active: true },
  { id: '17', name: 'Gift Box', category: 'gift', emoji: '\ud83c\udf81', price: 0, is_premium: false, rarity: 'rare', description: 'Surprise gift!', is_active: true },
  { id: '18', name: 'Crown', category: 'gift', emoji: '\ud83d\udc51', price: 0, is_premium: false, rarity: 'legendary', description: 'You\'re royalty', is_active: true },
  { id: '19', name: 'Diamond', category: 'gift', emoji: '\ud83d\udc8e', price: 0, is_premium: false, rarity: 'legendary', description: 'You shine bright', is_active: true },

  { id: '20', name: 'Balloon', category: 'celebration', emoji: '\ud83c\udf88', price: 0, is_premium: false, rarity: 'common', description: 'Celebrate good times', is_active: true },
  { id: '21', name: 'Confetti', category: 'celebration', emoji: '\ud83c\udf8a', price: 0, is_premium: false, rarity: 'common', description: 'Party vibes', is_active: true },
  { id: '22', name: 'Fireworks', category: 'celebration', emoji: '\ud83c\udf86', price: 0, is_premium: false, rarity: 'rare', description: 'Spectacular celebration', is_active: true },
  { id: '23', name: 'Trophy', category: 'celebration', emoji: '\ud83c\udfc6', price: 0, is_premium: false, rarity: 'epic', description: 'You\'re a winner!', is_active: true },
  { id: '24', name: 'Star', category: 'celebration', emoji: '\u2b50', price: 0, is_premium: false, rarity: 'rare', description: 'You\'re a star', is_active: true },

  { id: '25', name: 'Disco Ball', category: 'sticker', emoji: '\ud83e\udea9', price: 0, is_premium: false, rarity: 'rare', description: 'Let\'s groove', is_active: true },
  { id: '26', name: 'Rainbow', category: 'sticker', emoji: '\ud83c\udf08', price: 0, is_premium: false, rarity: 'epic', description: 'Good vibes only', is_active: true },
  { id: '27', name: 'Lightning', category: 'sticker', emoji: '\u26a1', price: 0, is_premium: false, rarity: 'rare', description: 'Electrifying energy', is_active: true },
  { id: '28', name: 'Moon', category: 'sticker', emoji: '\ud83c\udf19', price: 0, is_premium: false, rarity: 'rare', description: 'Night out vibes', is_active: true },
  { id: '29', name: 'Sunrise', category: 'sticker', emoji: '\ud83c\udf05', price: 0, is_premium: false, rarity: 'rare', description: 'New beginnings', is_active: true },
];

export const getRarityColor = (rarity: VirtualItem['rarity']) => {
  switch (rarity) {
    case 'common':
      return 'from-gray-400 to-gray-500';
    case 'rare':
      return 'from-blue-400 to-blue-600';
    case 'epic':
      return 'from-purple-400 to-purple-600';
    case 'legendary':
      return 'from-yellow-400 to-orange-500';
  }
};

export const getCategoryLabel = (category: VirtualItem['category']) => {
  switch (category) {
    case 'emoji':
      return 'Quick Reactions';
    case 'drink':
      return 'Drinks';
    case 'gift':
      return 'Gifts';
    case 'sticker':
      return 'Stickers';
    case 'celebration':
      return 'Celebrations';
    case 'seasonal':
      return 'Seasonal';
  }
};
