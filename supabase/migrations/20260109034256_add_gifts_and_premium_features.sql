/*
  # Add Gifts and Premium Features

  1. New Tables
    - `gifts`
      - `id` (uuid, primary key)
      - `from_user_id` (uuid, references users)
      - `to_user_id` (uuid, references users)
      - `drink_type` (text)
      - `amount` (numeric)
      - `message` (text, nullable)
      - `status` (text: pending, redeemed, expired)
      - `venue_id` (uuid, nullable, references venues)
      - `redeemed_at` (timestamptz, nullable)
      - `created_at` (timestamptz)

    - `subscriptions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references users)
      - `plan_type` (text: monthly, yearly)
      - `status` (text: active, cancelled, expired)
      - `stripe_subscription_id` (text, nullable)
      - `current_period_start` (timestamptz)
      - `current_period_end` (timestamptz)
      - `created_at` (timestamptz)

  2. Changes
    - Add columns to `users` table:
      - `is_premium` (boolean, default false)
      - `age` (integer, nullable)
      - `avatar_url` (text, nullable)

    - Add columns to `venues` table:
      - `photo_url` (text, nullable)
      - `place_id` (text, nullable)
      - `rating` (numeric, nullable)
      - `user_ratings_total` (integer, nullable)

  3. Security
    - Enable RLS on new tables
    - Add policies for authenticated users
*/

-- Add missing columns to users table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'is_premium'
  ) THEN
    ALTER TABLE users ADD COLUMN is_premium boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'age'
  ) THEN
    ALTER TABLE users ADD COLUMN age integer;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'avatar_url'
  ) THEN
    ALTER TABLE users ADD COLUMN avatar_url text;
  END IF;
END $$;

-- Add missing columns to venues table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'photo_url'
  ) THEN
    ALTER TABLE venues ADD COLUMN photo_url text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'place_id'
  ) THEN
    ALTER TABLE venues ADD COLUMN place_id text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'rating'
  ) THEN
    ALTER TABLE venues ADD COLUMN rating numeric;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'user_ratings_total'
  ) THEN
    ALTER TABLE venues ADD COLUMN user_ratings_total integer;
  END IF;
END $$;

-- Create gifts table
CREATE TABLE IF NOT EXISTS gifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  drink_type text NOT NULL,
  amount numeric NOT NULL,
  message text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'redeemed', 'expired')),
  venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
  redeemed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE gifts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view gifts they sent"
  ON gifts FOR SELECT
  TO authenticated
  USING (auth.uid() = from_user_id);

CREATE POLICY "Users can view gifts they received"
  ON gifts FOR SELECT
  TO authenticated
  USING (auth.uid() = to_user_id);

CREATE POLICY "Users can create gifts"
  ON gifts FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = from_user_id);

CREATE POLICY "Recipients can update their gifts"
  ON gifts FOR UPDATE
  TO authenticated
  USING (auth.uid() = to_user_id)
  WITH CHECK (auth.uid() = to_user_id);

-- Create subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_type text NOT NULL CHECK (plan_type IN ('monthly', 'yearly')),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')),
  stripe_subscription_id text,
  current_period_start timestamptz NOT NULL,
  current_period_end timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, stripe_subscription_id)
);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscriptions"
  ON subscriptions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own subscriptions"
  ON subscriptions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscriptions"
  ON subscriptions FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_gifts_from_user ON gifts(from_user_id);
CREATE INDEX IF NOT EXISTS idx_gifts_to_user ON gifts(to_user_id);
CREATE INDEX IF NOT EXISTS idx_gifts_status ON gifts(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
