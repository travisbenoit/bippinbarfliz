/*
  # Add missing columns to users and venues tables

  1. Modified Tables
    - `users`
      - `payment_provider` (text, default 'venmo') - which payment provider the user uses
      - `payment_provider_username` (text, nullable) - username on that payment provider
      - `payment_provider_linked` (boolean, default false) - whether provider account is linked
    - `venues`
      - `vibes` (text[], default '{}') - vibe tags for the venue
      - `user_count` (integer, default 0) - current people count
      - `place_type` (text, nullable) - Google Places type
      - `google_place_id` (text, nullable) - Google Places ID for enrichment
      - `city` (text, nullable) - city name
      - `state` (text, nullable) - state/territory
      - `country` (text, default 'US') - country code
      - `postal_code` (text, nullable) - postal/zip code
      - `type` (text, default 'bar') - venue type classification
      - `metadata` (jsonb, default '{}') - flexible metadata store
      - `phone` (text, nullable) - venue phone number
      - `website` (text, nullable) - venue website
      - `hours` (jsonb, nullable) - opening hours
      - `price_level` (integer, nullable) - price level 1-4

  2. Important Notes
    - Uses IF NOT EXISTS checks for safety
    - No data loss - only adding new columns
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'payment_provider'
  ) THEN
    ALTER TABLE users ADD COLUMN payment_provider text DEFAULT 'venmo';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'payment_provider_username'
  ) THEN
    ALTER TABLE users ADD COLUMN payment_provider_username text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'payment_provider_linked'
  ) THEN
    ALTER TABLE users ADD COLUMN payment_provider_linked boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'vibes'
  ) THEN
    ALTER TABLE venues ADD COLUMN vibes text[] DEFAULT '{}';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'user_count'
  ) THEN
    ALTER TABLE venues ADD COLUMN user_count integer DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'place_type'
  ) THEN
    ALTER TABLE venues ADD COLUMN place_type text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'google_place_id'
  ) THEN
    ALTER TABLE venues ADD COLUMN google_place_id text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'city'
  ) THEN
    ALTER TABLE venues ADD COLUMN city text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'state'
  ) THEN
    ALTER TABLE venues ADD COLUMN state text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'country'
  ) THEN
    ALTER TABLE venues ADD COLUMN country text DEFAULT 'US';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'postal_code'
  ) THEN
    ALTER TABLE venues ADD COLUMN postal_code text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'type'
  ) THEN
    ALTER TABLE venues ADD COLUMN type text DEFAULT 'bar';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'metadata'
  ) THEN
    ALTER TABLE venues ADD COLUMN metadata jsonb DEFAULT '{}';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'phone'
  ) THEN
    ALTER TABLE venues ADD COLUMN phone text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'website'
  ) THEN
    ALTER TABLE venues ADD COLUMN website text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'hours'
  ) THEN
    ALTER TABLE venues ADD COLUMN hours jsonb;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'price_level'
  ) THEN
    ALTER TABLE venues ADD COLUMN price_level integer;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_venues_google_place_id ON venues(google_place_id) WHERE google_place_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_venues_city ON venues(city);
CREATE INDEX IF NOT EXISTS idx_venues_type ON venues(type);
