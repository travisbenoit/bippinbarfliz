/*
  # Add Emojis and Virtual Items System

  1. New Tables
    - `virtual_items`
      - `id` (uuid, primary key)
      - `name` (text) - Display name of the item
      - `category` (text) - emoji, drink, gift, sticker, celebration
      - `emoji` (text) - The emoji character or icon identifier
      - `price` (integer) - Cost in coins/points
      - `is_premium` (boolean) - Requires premium subscription
      - `rarity` (text) - common, rare, epic, legendary
      - `description` (text, nullable)
      - `animation_url` (text, nullable) - URL for animated versions
      - `is_active` (boolean) - Can be purchased/sent
      - `created_at` (timestamptz)

    - `user_gifts`
      - `id` (uuid, primary key)
      - `from_user_id` (uuid, references users)
      - `to_user_id` (uuid, references users)
      - `item_id` (uuid, references virtual_items)
      - `message` (text, nullable) - Personal message with the gift
      - `status` (text) - sent, viewed, reacted
      - `reaction` (text, nullable) - Recipient's reaction emoji
      - `context_type` (text) - direct_message, profile, swarm, venue
      - `context_id` (uuid, nullable) - ID of the context (swarm_id, venue_id, etc)
      - `viewed_at` (timestamptz, nullable)
      - `created_at` (timestamptz)

    - `emoji_reactions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references users)
      - `target_type` (text) - message, post, profile, venue
      - `target_id` (uuid)
      - `emoji` (text) - The reaction emoji
      - `created_at` (timestamptz)

    - `user_inventory`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references users)
      - `item_id` (uuid, references virtual_items)
      - `quantity` (integer) - How many of this item the user owns
      - `acquired_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Users can view items they sent/received
    - Users can manage their own inventory
    - Virtual items catalog is publicly readable
*/

-- Create virtual_items table
CREATE TABLE IF NOT EXISTS virtual_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category text NOT NULL CHECK (category IN ('emoji', 'drink', 'gift', 'sticker', 'celebration', 'seasonal')),
  emoji text NOT NULL,
  price integer NOT NULL DEFAULT 0,
  is_premium boolean DEFAULT false,
  rarity text DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
  description text,
  animation_url text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE virtual_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Virtual items are viewable by everyone"
  ON virtual_items FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Create user_gifts table
CREATE TABLE IF NOT EXISTS user_gifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_id uuid NOT NULL REFERENCES virtual_items(id) ON DELETE CASCADE,
  message text,
  status text NOT NULL DEFAULT 'sent' CHECK (status IN ('sent', 'viewed', 'reacted')),
  reaction text,
  context_type text NOT NULL CHECK (context_type IN ('direct_message', 'profile', 'swarm', 'venue')),
  context_id uuid,
  viewed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE user_gifts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view gifts they sent"
  ON user_gifts FOR SELECT
  TO authenticated
  USING (auth.uid() = from_user_id);

CREATE POLICY "Users can view gifts they received"
  ON user_gifts FOR SELECT
  TO authenticated
  USING (auth.uid() = to_user_id);

CREATE POLICY "Users can send gifts"
  ON user_gifts FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = from_user_id);

CREATE POLICY "Recipients can update received gifts"
  ON user_gifts FOR UPDATE
  TO authenticated
  USING (auth.uid() = to_user_id)
  WITH CHECK (auth.uid() = to_user_id);

-- Create emoji_reactions table
CREATE TABLE IF NOT EXISTS emoji_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_type text NOT NULL CHECK (target_type IN ('message', 'post', 'profile', 'venue', 'swarm')),
  target_id uuid NOT NULL,
  emoji text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, target_type, target_id)
);

ALTER TABLE emoji_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all reactions"
  ON emoji_reactions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can add their own reactions"
  ON emoji_reactions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own reactions"
  ON emoji_reactions FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create user_inventory table
CREATE TABLE IF NOT EXISTS user_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_id uuid NOT NULL REFERENCES virtual_items(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 1 CHECK (quantity >= 0),
  acquired_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, item_id)
);

ALTER TABLE user_inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own inventory"
  ON user_inventory FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own inventory"
  ON user_inventory FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own inventory"
  ON user_inventory FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_virtual_items_category ON virtual_items(category);
CREATE INDEX IF NOT EXISTS idx_virtual_items_rarity ON virtual_items(rarity);
CREATE INDEX IF NOT EXISTS idx_user_gifts_from_user ON user_gifts(from_user_id);
CREATE INDEX IF NOT EXISTS idx_user_gifts_to_user ON user_gifts(to_user_id);
CREATE INDEX IF NOT EXISTS idx_user_gifts_created ON user_gifts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_emoji_reactions_target ON emoji_reactions(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_user_inventory_user ON user_inventory(user_id);

-- Insert default virtual items
INSERT INTO virtual_items (name, category, emoji, price, rarity, description, is_active) VALUES
  -- Free Emojis
  ('Heart Eyes', 'emoji', '😍', 0, 'common', 'Show some love', true),
  ('Fire', 'emoji', '🔥', 0, 'common', 'That is fire!', true),
  ('Sparkles', 'emoji', '✨', 0, 'common', 'Magical vibes', true),
  ('Dancing', 'emoji', '💃', 0, 'common', 'Let''s dance!', true),
  ('Cheers', 'emoji', '🥂', 0, 'common', 'Cheers to that!', true),
  ('Party', 'emoji', '🎉', 0, 'common', 'Party time!', true),
  ('Sunglasses', 'emoji', '😎', 0, 'common', 'Looking cool', true),
  ('Laughing', 'emoji', '😂', 0, 'common', 'Too funny!', true),
  
  -- Drinks
  ('Beer', 'drink', '🍺', 50, 'common', 'Classic beer on me', true),
  ('Wine', 'drink', '🍷', 75, 'common', 'Glass of wine', true),
  ('Cocktail', 'drink', '🍹', 100, 'rare', 'Fancy cocktail', true),
  ('Champagne', 'drink', '🍾', 200, 'epic', 'Celebration time!', true),
  ('Whiskey', 'drink', '🥃', 150, 'rare', 'Smooth whiskey', true),
  ('Martini', 'drink', '🍸', 125, 'rare', 'Classy martini', true),
  
  -- Gifts
  ('Rose', 'gift', '🌹', 100, 'rare', 'A romantic gesture', true),
  ('Bouquet', 'gift', '💐', 250, 'epic', 'Beautiful bouquet', true),
  ('Gift Box', 'gift', '🎁', 150, 'rare', 'Surprise gift!', true),
  ('Crown', 'gift', '👑', 500, 'legendary', 'You''re royalty', true),
  ('Diamond', 'gift', '💎', 1000, 'legendary', 'You shine bright', true),
  
  -- Celebrations
  ('Balloon', 'celebration', '🎈', 25, 'common', 'Celebrate good times', true),
  ('Confetti', 'celebration', '🎊', 50, 'common', 'Party vibes', true),
  ('Fireworks', 'celebration', '🎆', 150, 'rare', 'Spectacular celebration', true),
  ('Trophy', 'celebration', '🏆', 200, 'epic', 'You''re a winner!', true),
  ('Star', 'celebration', '⭐', 75, 'rare', 'You''re a star', true),
  
  -- Premium Stickers
  ('Disco Ball', 'sticker', '🪩', 100, 'rare', 'Let''s groove', true),
  ('Rainbow', 'sticker', '🌈', 150, 'epic', 'Good vibes only', true),
  ('Lightning', 'sticker', '⚡', 100, 'rare', 'Electrifying energy', true),
  ('Moon', 'sticker', '🌙', 75, 'rare', 'Night out vibes', true),
  ('Sunrise', 'sticker', '🌅', 75, 'rare', 'New beginnings', true)
ON CONFLICT DO NOTHING;
