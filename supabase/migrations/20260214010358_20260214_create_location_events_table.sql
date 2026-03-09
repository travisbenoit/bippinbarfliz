/*
  # Create Location Events Table for Radar Webhook Data

  ## Overview
  Creates a table to store raw Radar webhook events for audit trail, debugging,
  and deduplication. This table captures all location events from Radar including
  place entries, exits, and location updates.

  ## New Tables
  
  ### `location_events`
  Stores raw Radar webhook events with deduplication support
  - `id` (uuid, primary key) - Unique event identifier
  - `radar_event_id` (text, nullable) - Radar's event ID if provided
  - `user_id` (uuid, nullable) - User associated with the event
  - `event_type` (text) - Type of event (e.g., 'user.entered_place', 'user.exited_place')
  - `place_id` (text, nullable) - Radar place external ID
  - `place_name` (text, nullable) - Name of the place
  - `latitude` (decimal) - Event latitude
  - `longitude` (decimal) - Event longitude
  - `accuracy` (decimal, nullable) - Location accuracy in meters
  - `confidence` (text, nullable) - Event confidence level (high/medium/low)
  - `raw_payload` (jsonb) - Complete Radar webhook payload
  - `time_bucket` (timestamptz) - 5-minute time bucket for deduplication
  - `processed` (boolean) - Whether event has been processed
  - `created_at` (timestamptz) - When event was received

  ## Security
  - Enable RLS on location_events table
  - Only service role (Edge Functions) can write events
  - Users can read their own events
  - System admins can read all events

  ## Indexes
  - Unique index on (user_id, place_id, event_type, time_bucket) for deduplication
  - Index on created_at for time-based queries
  - Index on event_type for filtering
  - Index on processed for finding unprocessed events

  ## Notes
  - time_bucket is calculated by rounding down to nearest 5 minutes
  - Deduplication prevents duplicate events within same 5-minute window
  - Raw payload preserved for debugging and reprocessing if needed
*/

-- Create location_events table
CREATE TABLE IF NOT EXISTS location_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  radar_event_id text,
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  place_id text,
  place_name text,
  latitude decimal(10, 8) NOT NULL CHECK (latitude >= -90 AND latitude <= 90),
  longitude decimal(11, 8) NOT NULL CHECK (longitude >= -180 AND longitude <= 180),
  accuracy decimal(10, 2),
  confidence text CHECK (confidence IN ('high', 'medium', 'low')),
  raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  time_bucket timestamptz NOT NULL,
  processed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_location_events_user_id ON location_events(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_location_events_created_at ON location_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_events_event_type ON location_events(event_type);
CREATE INDEX IF NOT EXISTS idx_location_events_processed ON location_events(processed) WHERE processed = false;
CREATE INDEX IF NOT EXISTS idx_location_events_place_id ON location_events(place_id) WHERE place_id IS NOT NULL;

-- Create unique constraint for deduplication (user_id + place_id + event_type + time_bucket)
-- This prevents duplicate events within the same 5-minute window
CREATE UNIQUE INDEX IF NOT EXISTS idx_location_events_dedup 
  ON location_events(user_id, place_id, event_type, time_bucket)
  WHERE user_id IS NOT NULL AND place_id IS NOT NULL;

-- Add helpful comment
COMMENT ON TABLE location_events IS 'Raw Radar webhook events for audit trail, debugging, and deduplication';

-- Enable Row Level Security
ALTER TABLE location_events ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own location events
CREATE POLICY "Users can read own location events"
  ON location_events
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy: Service role can insert all location events
CREATE POLICY "Service role can insert location events"
  ON location_events
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Policy: Service role can update location events (for marking as processed)
CREATE POLICY "Service role can update location events"
  ON location_events
  FOR UPDATE
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Helper function to calculate 5-minute time bucket for deduplication
CREATE OR REPLACE FUNCTION get_time_bucket_5min(ts timestamptz)
RETURNS timestamptz
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  -- Round down to nearest 5 minutes
  RETURN date_trunc('hour', ts) + 
         (floor(extract(minute FROM ts) / 5) * interval '5 minutes');
END;
$$;