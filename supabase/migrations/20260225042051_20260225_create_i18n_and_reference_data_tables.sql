/*
  # Create internationalization and reference data tables

  1. New Tables
    - `languages` - supported language definitions
    - `translation_keys` - translatable string keys
    - `translations` - actual translated text per language
    - `user_language_preferences` - per-user language/region settings
    - `vibe_tags` - predefined vibe tag reference data
    - `drink_categories` - drink category reference data
    - `mixed_drinks` - individual drink reference data
    - `interests` - user interest reference data
    - `looking_for_options` - "looking for" option reference data
    - `conversation_starters` - conversation starter prompts

  2. Security
    - RLS enabled on all tables
    - Reference/i18n tables are publicly readable for authenticated users
    - User preferences are private to each user

  3. Important Notes
    - These tables support the app's internationalization system
    - Reference data tables provide consistent option lists across the app
*/

CREATE TABLE IF NOT EXISTS languages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  name text NOT NULL,
  native_name text NOT NULL,
  is_active boolean DEFAULT true,
  is_default boolean DEFAULT false,
  locale_tag text NOT NULL,
  sort_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE languages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Languages are readable by authenticated users"
  ON languages FOR SELECT TO authenticated
  USING (is_active = true);

CREATE TABLE IF NOT EXISTS translation_keys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text UNIQUE NOT NULL,
  description text,
  category text,
  platform text DEFAULT 'shared',
  requires_context boolean DEFAULT false,
  context_example text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE translation_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Translation keys are readable by authenticated users"
  ON translation_keys FOR SELECT TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE TABLE IF NOT EXISTS translations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key_id uuid NOT NULL REFERENCES translation_keys(id) ON DELETE CASCADE,
  language_id uuid NOT NULL REFERENCES languages(id) ON DELETE CASCADE,
  translated_text text NOT NULL,
  is_complete boolean DEFAULT true,
  needs_review boolean DEFAULT false,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (key_id, language_id)
);

ALTER TABLE translations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Translations are readable by authenticated users"
  ON translations FOR SELECT TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE TABLE IF NOT EXISTS user_language_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  language_id uuid NOT NULL REFERENCES languages(id),
  region_id uuid NOT NULL REFERENCES regions(id),
  auto_detect boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (user_id)
);

ALTER TABLE user_language_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own language preferences"
  ON user_language_preferences FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own language preferences"
  ON user_language_preferences FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert own language preferences"
  ON user_language_preferences FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

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

ALTER TABLE vibe_tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vibe tags are readable by authenticated users"
  ON vibe_tags FOR SELECT TO authenticated
  USING (is_active = true);

CREATE TABLE IF NOT EXISTS drink_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  category_type text,
  sort_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE drink_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Drink categories are readable by authenticated users"
  ON drink_categories FOR SELECT TO authenticated
  USING (auth.uid() IS NOT NULL);

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

ALTER TABLE mixed_drinks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Mixed drinks are readable by authenticated users"
  ON mixed_drinks FOR SELECT TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE TABLE IF NOT EXISTS interests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  emoji text,
  sort_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE interests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Interests are readable by authenticated users"
  ON interests FOR SELECT TO authenticated
  USING (auth.uid() IS NOT NULL);

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

ALTER TABLE looking_for_options ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Looking for options are readable by authenticated users"
  ON looking_for_options FOR SELECT TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE TABLE IF NOT EXISTS conversation_starters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prompt_text text NOT NULL,
  category text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE conversation_starters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Conversation starters are readable by authenticated users"
  ON conversation_starters FOR SELECT TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE INDEX IF NOT EXISTS idx_languages_code ON languages(code);
CREATE INDEX IF NOT EXISTS idx_translations_key_language ON translations(key_id, language_id);
CREATE INDEX IF NOT EXISTS idx_user_lang_pref_user ON user_language_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_vibe_tags_sort ON vibe_tags(sort_order);
CREATE INDEX IF NOT EXISTS idx_drink_categories_sort ON drink_categories(sort_order);
CREATE INDEX IF NOT EXISTS idx_mixed_drinks_sort ON mixed_drinks(sort_order);
CREATE INDEX IF NOT EXISTS idx_interests_sort ON interests(sort_order);
CREATE INDEX IF NOT EXISTS idx_looking_for_sort ON looking_for_options(sort_order);
