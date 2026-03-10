/*
  # Create Global Location Events Table

  Append-only audit log for all Radar geofence/place events across all regions.
  This replaces the Darwin-specific location_events concept that was previously
  tied to the `bars` table. All events now reference `venues.id` directly.

  ## New Tables

  ### `location_events`
  - `event_id` (uuid, primary key)
  - `user_id` (uuid, required) — user who triggered the event
  - `venue_id` (uuid, nullable FK → venues.id) — matched venue, null if no match found
  - `radar_place_id` (text, nullable) — Radar's internal place ID
  - `event_type` (text) — enter | exit | dwell
  - `occurred_at` (timestamptz) — when the event occurred
  - `lat` (double precision, nullable) — event latitude
  - `lng` (double precision, nullable) — event longitude
  - `accuracy_m` (double precision, nullable) — GPS accuracy in meters
  - `confidence` (double precision, nullable) — Radar confidence score
  - `raw_payload` (jsonb) — full Radar webhook payload for debugging

  ## Indexes
  - Composite indexes on common query patterns

  ## Security
  - RLS enabled
  - Users can only read their own events
  - Service role has full write access (webhook processing)

  ## Notes
  - No geographic bounds check — works globally for any market
  - venue_id is nullable so unmatched events are still recorded for analysis
*/

CREATE TABLE IF NOT EXISTS location_events (
  event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
  radar_place_id text,
  event_type text NOT NULL CHECK (event_type IN ('enter', 'exit', 'dwell')),
  occurred_at timestamptz NOT NULL,
  lat double precision,
  lng double precision,
  accuracy_m double precision,
  confidence double precision,
  raw_payload jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

-- Add venue_id column if it doesn't exist (table may have been created by an earlier migration)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'location_events' AND column_name = 'venue_id'
  ) THEN
    ALTER TABLE location_events ADD COLUMN venue_id uuid REFERENCES venues(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_location_events_user_occurred ON location_events(user_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_events_venue_occurred ON location_events(venue_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_events_radar_place ON location_events(radar_place_id);
CREATE INDEX IF NOT EXISTS idx_location_events_type_occurred ON location_events(event_type, occurred_at DESC);

ALTER TABLE location_events ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'location_events' AND policyname = 'Users can view own location events') THEN
    CREATE POLICY "Users can view own location events"
      ON location_events FOR SELECT TO authenticated USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'location_events' AND policyname = 'Service role full access to location_events') THEN
    CREATE POLICY "Service role full access to location_events"
      ON location_events FOR INSERT TO service_role WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'location_events' AND policyname = 'Service role can update location_events') THEN
    CREATE POLICY "Service role can update location_events"
      ON location_events FOR UPDATE TO service_role USING (true) WITH CHECK (true);
  END IF;
END $$;
