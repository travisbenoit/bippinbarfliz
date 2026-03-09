/*
  # Add Google Places Tracking to Bars Table
  
  This migration adds Google Places API integration fields to the existing bars table
  for the Darwin-only beta. Existing Radar logic remains unchanged.
  
  ## Changes to `bars` Table
  
  ### New Columns
  - `google_place_id` (text, nullable) - Google Places unique identifier for the venue
    * Allows linking bar records to Google Places API data
    * NULL if not yet linked to a Google Place
  
  - `google_last_fetched_at` (timestamptz, nullable) - Timestamp of last Google Places data fetch
    * Tracks when we last updated Google Places information
    * NULL if never fetched
    * Used to implement caching/refresh logic
  
  ## Notes
  - Uses IF NOT EXISTS pattern for safe idempotent execution
  - Does not modify existing Radar integration (`radar_place_id` remains unchanged)
  - Both columns are nullable to support gradual rollout
  - No RLS policy changes required (inherits existing bars table policies)
  
  ## Darwin Beta Context
  - This is part of the Darwin-only beta phase
  - Google Places data will supplement Radar geofencing data
  - Enables richer venue information (photos, reviews, hours, etc.)
*/

-- Add google_place_id column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bars' AND column_name = 'google_place_id'
  ) THEN
    ALTER TABLE bars ADD COLUMN google_place_id text;
  END IF;
END $$;

-- Add google_last_fetched_at column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bars' AND column_name = 'google_last_fetched_at'
  ) THEN
    ALTER TABLE bars ADD COLUMN google_last_fetched_at timestamptz;
  END IF;
END $$;

-- Create index on google_place_id for fast lookups
CREATE INDEX IF NOT EXISTS idx_bars_google_place_id ON bars(google_place_id);

-- Create index on google_last_fetched_at for cache invalidation queries
CREATE INDEX IF NOT EXISTS idx_bars_google_last_fetched_at ON bars(google_last_fetched_at);
