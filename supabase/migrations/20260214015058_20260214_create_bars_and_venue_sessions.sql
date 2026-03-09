/*
  # Darwin Bars and Venue Sessions System
  
  This migration creates the core tables for Radar-based bar presence tracking in Darwin, Australia.
  
  ## New Tables
  
  ### `bars`
  Stores bar/venue information for Darwin locations only.
  - `bar_id` (uuid, primary key) - Unique identifier for each bar
  - `name` (text, required) - Bar name
  - `lat` (double precision, required) - Latitude coordinate
  - `lng` (double precision, required) - Longitude coordinate
  - `city` (text) - Defaults to 'Darwin'
  - `state` (text) - Defaults to 'NT'
  - `country` (text) - Defaults to 'AU'
  - `radar_place_id` (text, nullable) - Radar's place identifier
  - `google_place_id` (text, nullable) - Google's place identifier
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp
  - CHECK constraint ensures coordinates are within Darwin bounds
  
  ### `venue_sessions`
  Tracks user check-ins and sessions at bars.
  - `session_id` (uuid, primary key) - Unique session identifier
  - `user_id` (uuid, required) - User who checked in
  - `bar_id` (uuid, required) - Bar where user checked in
  - `status` (text, required) - Session status: open, closed, invalid, closed_timeout
  - `checkin_method` (text, required) - How check-in occurred (radar_auto, manual, etc)
  - `confidence` (double precision, nullable) - Radar confidence score
  - `start_at` (timestamptz, required) - Session start time
  - `end_at` (timestamptz, nullable) - Session end time (null if still open)
  - `last_event_at` (timestamptz, required) - Last activity timestamp
  - `dedupe_key` (text, required, unique) - Deduplication key
  
  ### `location_events`
  Append-only audit log of all Radar events.
  - `event_id` (uuid, primary key) - Unique event identifier
  - `user_id` (uuid, required) - User who triggered event
  - `bar_id` (uuid, nullable) - Associated bar (if matched)
  - `radar_place_id` (text, nullable) - Radar's place ID
  - `event_type` (text, required) - Event type: enter, exit, dwell
  - `occurred_at` (timestamptz, required) - When event occurred
  - `lat` (double precision, nullable) - Event latitude
  - `lng` (double precision, nullable) - Event longitude
  - `accuracy_m` (double precision, nullable) - GPS accuracy in meters
  - `confidence` (double precision, nullable) - Radar confidence score
  - `raw_payload` (jsonb, required) - Full Radar webhook payload
  
  ## Security
  - RLS enabled on all tables
  - Users can read their own venue_sessions and location_events
  - Only authenticated users can access bars data
  - Service role has full access for webhook processing
  
  ## Indexes
  - Performance indexes on common query patterns
  - Unique constraint on dedupe_key for session deduplication
*/

-- Drop existing conflicting tables if they exist from previous iterations
DROP TABLE IF EXISTS location_events CASCADE;

-- Create bars table
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
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT darwin_bounds_check CHECK (
    lat BETWEEN -12.55 AND -12.35 AND
    lng BETWEEN 130.75 AND 131.05
  )
);

-- Create index on radar_place_id for fast lookups
CREATE INDEX IF NOT EXISTS idx_bars_radar_place_id ON bars(radar_place_id);
CREATE INDEX IF NOT EXISTS idx_bars_location ON bars(lat, lng);

-- Create venue_sessions table
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

-- Create indexes for venue_sessions
CREATE INDEX IF NOT EXISTS idx_venue_sessions_bar_status ON venue_sessions(bar_id, status);
CREATE INDEX IF NOT EXISTS idx_venue_sessions_user_status ON venue_sessions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_venue_sessions_bar_last_event ON venue_sessions(bar_id, last_event_at DESC);
CREATE INDEX IF NOT EXISTS idx_venue_sessions_user_last_event ON venue_sessions(user_id, last_event_at DESC);

-- Create location_events table (append-only audit log)
CREATE TABLE IF NOT EXISTS location_events (
  event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  bar_id uuid REFERENCES bars(bar_id) ON DELETE SET NULL,
  radar_place_id text,
  event_type text NOT NULL CHECK (event_type IN ('enter', 'exit', 'dwell')),
  occurred_at timestamptz NOT NULL,
  lat double precision,
  lng double precision,
  accuracy_m double precision,
  confidence double precision,
  raw_payload jsonb NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for location_events
CREATE INDEX IF NOT EXISTS idx_location_events_user_occurred ON location_events(user_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_events_bar_occurred ON location_events(bar_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_events_radar_place ON location_events(radar_place_id);

-- Enable Row Level Security
ALTER TABLE bars ENABLE ROW LEVEL SECURITY;
ALTER TABLE venue_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE location_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies for bars
CREATE POLICY "Authenticated users can view all bars"
  ON bars FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Service role has full access to bars"
  ON bars FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- RLS Policies for venue_sessions
CREATE POLICY "Users can view their own sessions"
  ON venue_sessions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view sessions at bars they're at"
  ON venue_sessions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM venue_sessions vs
      WHERE vs.user_id = auth.uid()
        AND vs.bar_id = venue_sessions.bar_id
        AND vs.status = 'open'
    )
  );

CREATE POLICY "Service role has full access to venue_sessions"
  ON venue_sessions FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- RLS Policies for location_events
CREATE POLICY "Users can view their own location events"
  ON location_events FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Service role has full access to location_events"
  ON location_events FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS bars_updated_at ON bars;
CREATE TRIGGER bars_updated_at
  BEFORE UPDATE ON bars
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS venue_sessions_updated_at ON venue_sessions;
CREATE TRIGGER venue_sessions_updated_at
  BEFORE UPDATE ON venue_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
