/*
  # Create Location Pings Table

  ## Summary
  The useRealTimeLocation hook writes location pings to a `location_pings` table,
  but this table did not exist. This migration creates it with proper RLS.

  ## New Tables
  - `location_pings`
    - `id` (uuid, primary key)
    - `user_id` (uuid, FK to users)
    - `latitude` (float8)
    - `longitude` (float8)
    - `accuracy` (float8, nullable - GPS accuracy in meters)
    - `is_background` (boolean, whether ping came from background tracking)
    - `created_at` (timestamptz)

  ## Security
  - RLS enabled
  - Authenticated users can INSERT their own pings
  - Authenticated users can SELECT their own pings
  - Service role has full access for analytics
*/

CREATE TABLE IF NOT EXISTS location_pings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  accuracy double precision,
  is_background boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_location_pings_user_id ON location_pings(user_id);
CREATE INDEX IF NOT EXISTS idx_location_pings_created_at ON location_pings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_pings_user_time ON location_pings(user_id, created_at DESC);

ALTER TABLE location_pings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own location pings"
  ON location_pings
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own location pings"
  ON location_pings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
