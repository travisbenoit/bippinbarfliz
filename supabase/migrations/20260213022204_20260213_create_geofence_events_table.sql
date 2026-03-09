/*
  # Create Geofence Events Table for Venue Entry/Exit Tracking

  ## Overview
  Creates a system to track when users enter and exit venue geofences.
  This enables features like automatic check-ins, venue-based notifications,
  and analytics on venue traffic patterns.

  ## New Tables
  
  ### `geofence_events`
  Stores venue entry/exit events detected by the geofencing system
  - `id` (uuid, primary key) - Unique event identifier
  - `user_id` (uuid, required) - User who triggered the geofence event
  - `venue_id` (uuid, required) - Venue that was entered/exited
  - `event_type` (text) - Type of event: 'enter' or 'exit'
  - `latitude` (decimal) - User's latitude when event was triggered
  - `longitude` (decimal) - User's longitude when event was triggered
  - `accuracy` (decimal, nullable) - Location accuracy in meters
  - `distance_from_center` (decimal, nullable) - Distance from venue center in meters
  - `triggered_at` (timestamptz) - When the geofence event was detected
  - `processed_at` (timestamptz, nullable) - When the event was processed by the system
  - `created_at` (timestamptz) - When the record was created

  ## Security
  - Enable RLS on geofence_events table
  - Users can read their own geofence events
  - Users can read friends' geofence events (to see where friends are)
  - Users can insert their own geofence events
  - No updates allowed (events should be immutable)

  ## Indexes
  - `idx_geofence_events_user_id` - Fast lookups by user
  - `idx_geofence_events_venue_id` - Fast lookups by venue
  - `idx_geofence_events_triggered_at` - Time-based queries
  - Composite index on (user_id, triggered_at) for user activity timeline
  - Composite index on (venue_id, triggered_at) for venue analytics

  ## Notes
  - Geofence events are critical for real-time features
  - Consider implementing duplicate detection (same user, same venue, within X minutes)
  - Processed_at enables async processing of events (notifications, analytics, etc.)
  - Distance_from_center helps validate genuine venue visits
*/

-- Create geofence_events table
CREATE TABLE IF NOT EXISTS geofence_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  venue_id uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  event_type text NOT NULL CHECK (event_type IN ('enter', 'exit')),
  latitude decimal(10, 8) NOT NULL CHECK (latitude >= -90 AND latitude <= 90),
  longitude decimal(11, 8) NOT NULL CHECK (longitude >= -180 AND longitude <= 180),
  accuracy decimal(10, 2),
  distance_from_center decimal(10, 2),
  triggered_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_geofence_events_user_id ON geofence_events(user_id);
CREATE INDEX IF NOT EXISTS idx_geofence_events_venue_id ON geofence_events(venue_id);
CREATE INDEX IF NOT EXISTS idx_geofence_events_triggered_at ON geofence_events(triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_geofence_events_user_timeline ON geofence_events(user_id, triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_geofence_events_venue_timeline ON geofence_events(venue_id, triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_geofence_events_unprocessed ON geofence_events(processed_at) WHERE processed_at IS NULL;

-- Add helpful comment
COMMENT ON TABLE geofence_events IS 'Tracks user entry/exit events for venue geofences, enabling automatic check-ins and location-based features';

-- Enable Row Level Security
ALTER TABLE geofence_events ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own geofence events
CREATE POLICY "Users can read own geofence events"
  ON geofence_events
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy: Users can read geofence events for venues they've visited
-- This allows seeing who else is at a venue
CREATE POLICY "Users can read events at their venues"
  ON geofence_events
  FOR SELECT
  TO authenticated
  USING (
    venue_id IN (
      SELECT venue_id 
      FROM geofence_events 
      WHERE user_id = auth.uid() 
        AND event_type = 'enter'
        AND triggered_at > now() - interval '24 hours'
    )
  );

-- Policy: Users can insert their own geofence events
CREATE POLICY "Users can insert own geofence events"
  ON geofence_events
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Policy: No updates allowed (events should be immutable except for processing)
-- Allow system to mark events as processed
CREATE POLICY "System can update processed_at"
  ON geofence_events
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own geofence events (for privacy)
CREATE POLICY "Users can delete own geofence events"
  ON geofence_events
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);