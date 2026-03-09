/*
  # Content and Reference Data Tables - Final

  1. New Tables
    - `vibe_tags` - Mood/activity tags for swarms and profiles
    - `drink_categories` - Drink types/spirits
    - `mixed_drinks` - Specific cocktail/mixed drink options
    - `interests` - User interest categories
    - `looking_for_options` - Relationship/connection intent options
    - `conversation_starters` - Template conversation starter prompts

  2. Features
    - All content translatable via i18n system
    - Sort order for consistent UI ordering
    - Pricing support already in virtual_items table

  3. Security
    - Enable RLS on all tables
    - Public read access for reference data
*/

CREATE TABLE IF NOT EXISTS vibe_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  description text,
  icon_name text,
  sort_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

COMMENT ON TABLE vibe_tags IS 'Mood/activity tags for swarms and user profiles (Happy Hour, Dance Party, etc)';
COMMENT ON COLUMN vibe_tags.name IS 'Translatable vibe name (Happy Hour, Big Game, Chill Night, Dance Party, etc)';
COMMENT ON COLUMN vibe_tags.icon_name IS 'Lucide icon name for UI display';

CREATE TABLE IF NOT EXISTS drink_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  category_type text,
  sort_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

COMMENT ON TABLE drink_categories IS 'Drink types: Whiskey, Vodka, Beer, Wine, Tequila, etc';

CREATE TABLE IF NOT EXISTS mixed_drinks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  category_id uuid REFERENCES drink_categories(id) ON DELETE SET NULL,
  description text,
  is_popular boolean DEFAULT false,
  sort_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

COMMENT ON TABLE mixed_drinks IS 'Specific cocktails and mixed drinks (Margarita, Mojito, Old Fashioned, etc)';

CREATE TABLE IF NOT EXISTS interests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  emoji text,
  sort_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

COMMENT ON TABLE interests IS 'User interest categories (Music, Sports, Travel, Food & Cooking, etc)';

CREATE TABLE IF NOT EXISTS looking_for_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  description text,
  emoji text,
  sort_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

COMMENT ON TABLE looking_for_options IS 'Relationship/connection intent (New Friends, Dating, Networking, etc)';

CREATE TABLE IF NOT EXISTS conversation_starters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prompt_text text NOT NULL,
  category text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

COMMENT ON TABLE conversation_starters IS 'Template conversation starter prompts for user profiles';

ALTER TABLE vibe_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE drink_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE mixed_drinks ENABLE ROW LEVEL SECURITY;
ALTER TABLE interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE looking_for_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_starters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vibe tags are publicly readable"
  ON vibe_tags FOR SELECT
  TO public
  USING (is_active = true);

CREATE POLICY "Drink categories are publicly readable"
  ON drink_categories FOR SELECT
  TO public
  USING (is_active = true);

CREATE POLICY "Mixed drinks are publicly readable"
  ON mixed_drinks FOR SELECT
  TO public
  USING (is_active = true);

CREATE POLICY "Interests are publicly readable"
  ON interests FOR SELECT
  TO public
  USING (is_active = true);

CREATE POLICY "Looking for options are publicly readable"
  ON looking_for_options FOR SELECT
  TO public
  USING (is_active = true);

CREATE POLICY "Conversation starters are publicly readable"
  ON conversation_starters FOR SELECT
  TO public
  USING (is_active = true);

CREATE INDEX IF NOT EXISTS idx_vibe_tags_sort ON vibe_tags(sort_order);
CREATE INDEX IF NOT EXISTS idx_drink_categories_sort ON drink_categories(sort_order);
CREATE INDEX IF NOT EXISTS idx_mixed_drinks_sort ON mixed_drinks(sort_order);
CREATE INDEX IF NOT EXISTS idx_interests_sort ON interests(sort_order);
CREATE INDEX IF NOT EXISTS idx_looking_for_sort ON looking_for_options(sort_order);

INSERT INTO vibe_tags (name, icon_name, sort_order) VALUES
  ('Happy Hour', 'wine-glass', 1),
  ('Big Game', 'TV', 2),
  ('Chill Night', 'coffee', 3),
  ('Dance Party', 'music', 4),
  ('Live Music', 'music-4', 5),
  ('Karaoke', 'mic', 6),
  ('Trivia Night', 'brain', 7),
  ('Sports Bar', 'target', 8),
  ('Rooftop', 'building', 9),
  ('Dive Bar', 'beer', 10)
ON CONFLICT DO NOTHING;

INSERT INTO drink_categories (name, category_type, sort_order) VALUES
  ('Whiskey', 'spirit', 1),
  ('Vodka', 'spirit', 2),
  ('Lager Beer', 'beer', 3),
  ('Craft Beer', 'beer', 4),
  ('Tequila', 'spirit', 5),
  ('Gin', 'spirit', 6),
  ('Wine', 'wine', 7),
  ('Rum', 'spirit', 8),
  ('Mezcal', 'spirit', 9),
  ('Mixed Drinks', 'cocktail', 10)
ON CONFLICT DO NOTHING;

INSERT INTO mixed_drinks (name, description, is_popular, sort_order) VALUES
  ('Margarita', 'Tequila, lime, orange liqueur', true, 1),
  ('Mojito', 'Rum, mint, lime, sugar, soda water', true, 2),
  ('Old Fashioned', 'Whiskey, sugar, bitters, orange peel', true, 3),
  ('Martini', 'Gin or vodka, vermouth, olive', true, 4),
  ('Cosmopolitan', 'Vodka, cranberry, lime, orange liqueur', true, 5),
  ('Long Island Iced Tea', 'Multiple spirits, citrus, simple syrup', false, 6),
  ('Pina Colada', 'Rum, coconut cream, pineapple', true, 7),
  ('Mai Tai', 'Rum, lime, orgeat, orange liqueur', false, 8),
  ('Daiquiri', 'Rum, lime, simple syrup', true, 9),
  ('Moscow Mule', 'Vodka, ginger beer, lime', true, 10)
ON CONFLICT DO NOTHING;

INSERT INTO interests (name, emoji, sort_order) VALUES
  ('Music', '🎵', 1),
  ('Sports', '⚽', 2),
  ('Travel', '✈️', 3),
  ('Food & Cooking', '🍽️', 4),
  ('Movies', '🎬', 5),
  ('Gaming', '🎮', 6),
  ('Fitness', '💪', 7),
  ('Art', '🎨', 8),
  ('Tech', '💻', 9),
  ('Fashion', '👗', 10),
  ('Photography', '📸', 11),
  ('Books', '📚', 12),
  ('Outdoor Activities', '🏔️', 13),
  ('Comedy', '😂', 14),
  ('Dancing', '💃', 15),
  ('Entrepreneurship', '💼', 16)
ON CONFLICT DO NOTHING;

INSERT INTO looking_for_options (name, description, emoji, sort_order) VALUES
  ('New Friends', 'Looking to expand my social circle', '👫', 1),
  ('Dating', 'Interested in romantic connections', '💕', 2),
  ('Networking', 'Professional connections and collaboration', '🤝', 3),
  ('Activity Partners', 'Friends for specific activities', '🎯', 4),
  ('Just Vibing', 'No pressure, just good times', '✌️', 5)
ON CONFLICT DO NOTHING;

INSERT INTO conversation_starters (prompt_text, category) VALUES
  ('What''s your go-to drink order?', 'drinks'),
  ('Favorite venue in the city?', 'venues'),
  ('What''s your ideal night out?', 'fun'),
  ('Any concert you''re excited about?', 'events'),
  ('What''s your karaoke song?', 'fun'),
  ('Best bar story you have?', 'stories'),
  ('Where''s the best happy hour?', 'venues'),
  ('What music are you into?', 'music'),
  ('Favorite cuisine?', 'food'),
  ('What''s on your bucket list?', 'travel')
ON CONFLICT DO NOTHING;
