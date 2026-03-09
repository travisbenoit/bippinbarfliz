/*
  # Create bars, venue_sessions, google_api_logs, and google_place_cache tables

  1. New Tables
    - `bars` - Darwin/regional bar data with Google Places integration
      - `bar_id` (uuid, primary key)
      - `name` (text) - bar name
      - `lat`, `lng` (double precision) - coordinates
      - `city`, `state`, `country` - location info
      - `radar_place_id`, `google_place_id` - external IDs
      - `rating`, `review_count` - Google rating data
      - `photo_urls` (text[]) - cached photo URLs
      - `address`, `opening_hours` - detail fields
      - Various Google sync timestamps

    - `venue_sessions` - tracks user check-in sessions at bars
      - `session_id` (uuid, primary key)
      - `user_id`, `bar_id` - who and where
      - `status` - open, closed, invalid, closed_timeout
      - `checkin_method` - how the session started
      - `start_at`, `end_at` - session duration
      - `dedupe_key` (unique) - prevents duplicate sessions

    - `google_api_logs` - logs Google API calls for monitoring
      - `log_id` (uuid, primary key)
      - `user_id`, `bar_id` - context
      - `success`, `place_id`, `details` - result data

    - `google_place_cache` - caches Google Place details
      - `cache_id` (uuid, primary key)
      - `bar_id` (unique) - one cache per bar
      - `place_id`, `cached_data`, `cached_at`

  2. Security
    - RLS enabled on all tables
    - Authenticated users can view bars
    - Users can view their own sessions
    - Service role has full access for background jobs

  3. Indexes
    - Location, Google Place ID, and session status indexes
*/

CREATE TABLE IF NOT EXISTS bars (
  bar_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  lat double precision NOT NULL,
  lng double precision NOT NULL,
  city text DEFAULT 'Darwin',
  state text DEFAULT 'NT',
  country text DEFAULT 'AU',
  radar_place_id text,
  google_place_id text,
  google_last_fetched_at timestamptz,
  google_last_linked_at timestamptz,
  rating numeric DEFAULT NULL,
  review_count integer DEFAULT 0,
  photo_urls text[] DEFAULT '{}',
  address text DEFAULT NULL,
  opening_hours jsonb DEFAULT NULL,
  google_last_synced_at timestamptz DEFAULT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE bars ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view all bars"
  ON bars FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Service role has full access to bars"
  ON bars FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE TABLE IF NOT EXISTS venue_sessions (
  session_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  bar_id uuid NOT NULL REFERENCES bars(bar_id) ON DELETE CASCADE,
  status text NOT NULL CHECK (status IN ('open', 'closed', 'invalid', 'closed_timeout')),
  checkin_method text NOT NULL DEFAULT 'radar_auto',
  confidence double precision,
  start_at timestamptz NOT NULL,
  end_at timestamptz,
  last_event_at timestamptz NOT NULL,
  dedupe_key text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE venue_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own sessions"
  ON venue_sessions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Service role has full access to venue_sessions"
  ON venue_sessions FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE TABLE IF NOT EXISTS google_api_logs (
  log_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  bar_id uuid NOT NULL REFERENCES bars(bar_id) ON DELETE CASCADE,
  success boolean NOT NULL DEFAULT false,
  place_id text,
  details jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE google_api_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own API logs"
  ON google_api_logs FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Service role has full access to API logs"
  ON google_api_logs FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE TABLE IF NOT EXISTS google_place_cache (
  cache_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bar_id uuid NOT NULL UNIQUE REFERENCES bars(bar_id) ON DELETE CASCADE,
  place_id text NOT NULL,
  cached_data jsonb NOT NULL,
  cached_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE google_place_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view cache"
  ON google_place_cache FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Service role has full access to cache"
  ON google_place_cache FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_bars_radar_place_id ON bars(radar_place_id);
CREATE INDEX IF NOT EXISTS idx_bars_location ON bars(lat, lng);
CREATE INDEX IF NOT EXISTS idx_bars_google_place_id ON bars(google_place_id);
CREATE INDEX IF NOT EXISTS idx_venue_sessions_bar_status ON venue_sessions(bar_id, status);
CREATE INDEX IF NOT EXISTS idx_venue_sessions_user_status ON venue_sessions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_venue_sessions_user ON venue_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_venue_sessions_bar ON venue_sessions(bar_id);
CREATE INDEX IF NOT EXISTS idx_google_api_logs_bar ON google_api_logs(bar_id);
CREATE INDEX IF NOT EXISTS idx_google_api_logs_created ON google_api_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_google_place_cache_cached ON google_place_cache(cached_at);

CREATE OR REPLACE FUNCTION update_updated_at()
  RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'bars_updated_at'
  ) THEN
    CREATE TRIGGER bars_updated_at
      BEFORE UPDATE ON bars
      FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'venue_sessions_updated_at'
  ) THEN
    CREATE TRIGGER venue_sessions_updated_at
      BEFORE UPDATE ON venue_sessions
      FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  END IF;
END $$;
