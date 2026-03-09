/*
  # Internationalization (i18n) Infrastructure

  1. New Tables
    - `languages` - Supported languages and variants
    - `regions` - Regional configurations for date/time/currency formats
    - `translation_keys` - All translatable string keys across platforms
    - `translations` - Actual translated content
    - `user_language_preferences` - User language and region selections

  2. Features
    - Support for language variants (e.g., en-US, en-GB, es-MX, es-ES)
    - Comprehensive regional configuration for localization
    - Shared translation keys across web and mobile platforms
    - User language/region preferences
    - Default fallback language support

  3. Security
    - Enable RLS on all tables
    - Public read access for languages and regions
    - User-specific access for preferences
    - Admin-only write access for translations (for now)

  4. Important Notes
    - Translation keys use dot notation (e.g., "navigation.explore")
    - Regions include format strings for dates, times, currencies
    - Platform field supports: "web", "mobile", "shared" (both platforms)
    - Fallback chain: user language → language default → en (English)
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

COMMENT ON TABLE languages IS 'Supported languages: en, es, fr, de, it, pt, ja, zh, etc';
COMMENT ON COLUMN languages.code IS 'Language code (en, es, fr, de, etc)';
COMMENT ON COLUMN languages.locale_tag IS 'Full locale tag (en-US, es-MX, pt-BR, etc)';

CREATE TABLE IF NOT EXISTS regions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  language_id uuid NOT NULL REFERENCES languages(id) ON DELETE CASCADE,
  code text NOT NULL,
  name text NOT NULL,
  locale_tag text NOT NULL,
  country_code text,
  is_default_for_language boolean DEFAULT false,
  date_format text DEFAULT 'MM/DD/YYYY',
  time_format text DEFAULT 'h:mm A',
  datetime_format text DEFAULT 'MM/DD/YYYY h:mm A',
  currency_code text DEFAULT 'USD',
  currency_symbol text DEFAULT '$',
  currency_position text DEFAULT 'before',
  decimal_separator text DEFAULT '.',
  thousands_separator text DEFAULT ',',
  temperature_unit text DEFAULT 'F',
  distance_unit text DEFAULT 'miles',
  week_start_day integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(language_id, code)
);

COMMENT ON TABLE regions IS 'Regional configurations for localization (US, UK, Mexico, Spain, Brazil, etc)';
COMMENT ON COLUMN regions.date_format IS 'Date format pattern (MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD)';
COMMENT ON COLUMN regions.time_format IS 'Time format pattern (h:mm A, HH:mm, h:mm:ss A)';
COMMENT ON COLUMN regions.week_start_day IS '0=Sunday, 1=Monday';

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

COMMENT ON TABLE translation_keys IS 'Master list of all translation keys used across platforms';
COMMENT ON COLUMN translation_keys.key IS 'Dot-notation key (e.g., navigation.explore, payment.send_money)';
COMMENT ON COLUMN translation_keys.platform IS 'web, mobile, or shared (both platforms)';
COMMENT ON COLUMN translation_keys.requires_context IS 'Whether key has interpolation variables';

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
  UNIQUE(key_id, language_id)
);

COMMENT ON TABLE translations IS 'Translated content for each key-language combination';
COMMENT ON COLUMN translations.is_complete IS 'False if translation is placeholder or needs work';
COMMENT ON COLUMN translations.needs_review IS 'Flag for translation review/QA';

CREATE TABLE IF NOT EXISTS user_language_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  language_id uuid NOT NULL REFERENCES languages(id),
  region_id uuid NOT NULL REFERENCES regions(id),
  auto_detect boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

COMMENT ON TABLE user_language_preferences IS 'User-specific language and region preferences';

ALTER TABLE languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE translation_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE translations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_language_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Languages are publicly readable"
  ON languages FOR SELECT
  TO public
  USING (is_active = true);

CREATE POLICY "Regions are publicly readable"
  ON regions FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Translation keys are publicly readable"
  ON translation_keys FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Translations are publicly readable"
  ON translations FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can read own language preferences"
  ON user_language_preferences FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own language preferences"
  ON user_language_preferences FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert own language preferences"
  ON user_language_preferences FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_languages_code ON languages(code);
CREATE INDEX idx_languages_locale ON languages(locale_tag);
CREATE INDEX idx_regions_language ON regions(language_id);
CREATE INDEX idx_translation_keys_category ON translation_keys(category);
CREATE INDEX idx_translations_key_language ON translations(key_id, language_id);
CREATE INDEX idx_user_lang_pref_user ON user_language_preferences(user_id);

INSERT INTO languages (code, name, native_name, locale_tag, is_active, is_default, sort_order) VALUES
  ('en', 'English', 'English', 'en-US', true, true, 1),
  ('es', 'Spanish', 'Español', 'es-ES', true, false, 2),
  ('fr', 'French', 'Français', 'fr-FR', true, false, 3),
  ('de', 'German', 'Deutsch', 'de-DE', true, false, 4),
  ('it', 'Italian', 'Italiano', 'it-IT', true, false, 5),
  ('pt', 'Portuguese', 'Português', 'pt-BR', true, false, 6),
  ('ja', 'Japanese', '日本語', 'ja-JP', true, false, 7),
  ('zh', 'Chinese', '中文', 'zh-CN', true, false, 8),
  ('ko', 'Korean', '한국어', 'ko-KR', true, false, 9),
  ('ru', 'Russian', 'Русский', 'ru-RU', true, false, 10);

INSERT INTO regions (language_id, code, name, locale_tag, country_code, is_default_for_language, date_format, time_format, datetime_format, currency_code, currency_symbol, currency_position, decimal_separator, thousands_separator, temperature_unit, distance_unit, week_start_day) 
SELECT id, 'US', 'United States', 'en-US', 'US', true, 'MM/DD/YYYY', 'h:mm A', 'MM/DD/YYYY h:mm A', 'USD', '$', 'before', '.', ',', 'F', 'miles', 0 FROM languages WHERE code = 'en'
UNION ALL
SELECT id, 'GB', 'United Kingdom', 'en-GB', 'GB', false, 'DD/MM/YYYY', 'HH:mm', 'DD/MM/YYYY HH:mm', 'GBP', '£', 'before', '.', ',', 'C', 'miles', 1 FROM languages WHERE code = 'en'
UNION ALL
SELECT id, 'CA', 'Canada', 'en-CA', 'CA', false, 'YYYY-MM-DD', 'h:mm A', 'YYYY-MM-DD h:mm A', 'CAD', '$', 'before', '.', ',', 'C', 'kilometers', 0 FROM languages WHERE code = 'en'
UNION ALL
SELECT id, 'AU', 'Australia', 'en-AU', 'AU', false, 'DD/MM/YYYY', 'h:mm A', 'DD/MM/YYYY h:mm A', 'AUD', '$', 'before', '.', ',', 'C', 'kilometers', 1 FROM languages WHERE code = 'en'
UNION ALL
SELECT id, 'ES', 'Spain', 'es-ES', 'ES', true, 'DD/MM/YYYY', 'HH:mm', 'DD/MM/YYYY HH:mm', 'EUR', '€', 'after', ',', '.', 'C', 'kilometers', 1 FROM languages WHERE code = 'es'
UNION ALL
SELECT id, 'MX', 'Mexico', 'es-MX', 'MX', false, 'DD/MM/YYYY', 'HH:mm', 'DD/MM/YYYY HH:mm', 'MXN', '$', 'before', '.', ',', 'C', 'kilometers', 0 FROM languages WHERE code = 'es'
UNION ALL
SELECT id, 'BR', 'Brazil', 'pt-BR', 'BR', true, 'DD/MM/YYYY', 'HH:mm', 'DD/MM/YYYY HH:mm', 'BRL', 'R$', 'before', ',', '.', 'C', 'kilometers', 0 FROM languages WHERE code = 'pt'
UNION ALL
SELECT id, 'FR', 'France', 'fr-FR', 'FR', true, 'DD/MM/YYYY', 'HH:mm', 'DD/MM/YYYY HH:mm', 'EUR', '€', 'after', ',', '.', 'C', 'kilometers', 1 FROM languages WHERE code = 'fr'
UNION ALL
SELECT id, 'DE', 'Germany', 'de-DE', 'DE', true, 'DD.MM.YYYY', 'HH:mm', 'DD.MM.YYYY HH:mm', 'EUR', '€', 'after', ',', '.', 'C', 'kilometers', 1 FROM languages WHERE code = 'de'
UNION ALL
SELECT id, 'JP', 'Japan', 'ja-JP', 'JP', true, 'YYYY/MM/DD', 'HH:mm', 'YYYY/MM/DD HH:mm', 'JPY', '¥', 'before', '.', ',', 'C', 'kilometers', 0 FROM languages WHERE code = 'ja';
