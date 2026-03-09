/*
  # Add Phone Number and Country Fields for User Registration

  1. New Columns on `users` table
    - `phone_number` (text) - Full international phone number with country code (e.g., +1-555-123-4567)
    - `phone_country_code` (text) - ISO 3166-1 alpha-2 country code (e.g., US, AU, GB)
    - `registration_country` (text) - Country detected at registration time via IP geolocation

  2. Purpose
    - Store complete phone numbers with country codes for user authentication
    - Track user's country for age verification (21+ for US, 18+ elsewhere)
    - Enable proper phone number formatting based on detected country

  3. Security
    - No changes to RLS policies needed - existing user policies cover these columns
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'phone_number'
  ) THEN
    ALTER TABLE users ADD COLUMN phone_number text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'phone_country_code'
  ) THEN
    ALTER TABLE users ADD COLUMN phone_country_code text DEFAULT 'US';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'registration_country'
  ) THEN
    ALTER TABLE users ADD COLUMN registration_country text;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_users_phone_number ON users(phone_number);
