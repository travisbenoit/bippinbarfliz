/*
  # Add Geofencing Capabilities to Existing Venues Table
  
  ## Overview
  Extends the existing `venues` table with geofencing and location tracking capabilities.
  Creates new tables for user presence tracking and venue clustering.
  
  ## 1. Table Modifications
  
  ### `venues` (existing table - adding columns)
  Adds geofencing fields:
  - `city`, `state`, `country`, `postal_code` - Location metadata
  - `type` - Bar, club, lounge, etc. (replaces/aliases category)
  - `geofence_shape` - JSON polygon or circle definition
  - `geofence_radius_meters` - Radius for circular geofences  
  - `is_active` - Active status flag
  - `metadata` - Additional flexible data
  - `updated_at` - Auto-updating timestamp
  
  ### `user_venue_presence` (new table)
  Tracks when users are in venues with privacy controls
  - Only updates via Edge Functions (service role)
  - Privacy flag controls visibility to other users
  - Records entry/exit times and dwell duration
  
  ### `venue_clusters` (new table)
  Groups nearby venues for efficient low-precision monitoring
  
  ## 2. Security
  - Existing venues RLS extended to include new columns
  - user_venue_presence has strict RLS - only visible presence shown
  - All writes must go through Edge Functions
  
  ## 3. Important Privacy Notes
  - NO raw GPS stored for users outside venues
  - Presence verification happens server-side
  - Users only "locatable" when inside venue geofences
*/

-- Add new columns to existing venues table
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'venues' AND column_name = 'city') THEN
    ALTER TABLE venues ADD COLUMN city text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'venues' AND column_name = 'state') THEN
    ALTER TABLE venues ADD COLUMN state text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'venues' AND column_name = 'country') THEN
    ALTER TABLE venues ADD COLUMN country text DEFAULT 'US';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'venues' AND column_name = 'postal_code') THEN
    ALTER TABLE venues ADD COLUMN postal_code text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'venues' AND column_name = 'type') THEN
    ALTER TABLE venues ADD COLUMN type text DEFAULT 'bar';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'venues' AND column_name = 'geofence_shape') THEN
    ALTER TABLE venues ADD COLUMN geofence_shape jsonb;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'venues' AND column_name = 'geofence_radius_meters') THEN
    ALTER TABLE venues ADD COLUMN geofence_radius_meters integer DEFAULT 50
      CONSTRAINT valid_radius CHECK (geofence_radius_meters > 0 AND geofence_radius_meters <= 500);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'venues' AND column_name = 'is_active') THEN
    ALTER TABLE venues ADD COLUMN is_active boolean DEFAULT true;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'venues' AND column_name = 'metadata') THEN
    ALTER TABLE venues ADD COLUMN metadata jsonb DEFAULT '{}';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'venues' AND column_name = 'updated_at') THEN
    ALTER TABLE venues ADD COLUMN updated_at timestamptz DEFAULT now();
  END IF;
END $$;

-- Add indexes for geofencing queries
CREATE INDEX IF NOT EXISTS idx_venues_city ON venues (city);
CREATE INDEX IF NOT EXISTS idx_venues_active ON venues (is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_venues_lat_lng ON venues (lat, lng);

-- Create user_venue_presence table
CREATE TABLE IF NOT EXISTS user_venue_presence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  venue_id uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'IN_VENUE',
  entered_at timestamptz NOT NULL DEFAULT now(),
  left_at timestamptz,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  is_visible_in_venue boolean DEFAULT true,
  dwell_seconds integer DEFAULT 0,
  entry_method text DEFAULT 'AUTO_GEOFENCE',
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  CONSTRAINT valid_status CHECK (status IN ('IN_VENUE', 'LEFT_VENUE')),
  CONSTRAINT valid_dwell CHECK (dwell_seconds >= 0),
  CONSTRAINT valid_dates CHECK (left_at IS NULL OR left_at >= entered_at)
);

CREATE INDEX IF NOT EXISTS idx_presence_user_id ON user_venue_presence (user_id);
CREATE INDEX IF NOT EXISTS idx_presence_venue_id ON user_venue_presence (venue_id);
CREATE INDEX IF NOT EXISTS idx_presence_status ON user_venue_presence (status);
CREATE INDEX IF NOT EXISTS idx_presence_active ON user_venue_presence (user_id, venue_id, status) 
  WHERE status = 'IN_VENUE' AND left_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_presence_visible ON user_venue_presence (venue_id, is_visible_in_venue, status)
  WHERE is_visible_in_venue = true AND status = 'IN_VENUE';

-- Create venue_clusters table
CREATE TABLE IF NOT EXISTS venue_clusters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  city text NOT NULL,
  center_lat double precision NOT NULL,
  center_lng double precision NOT NULL,
  radius_meters integer NOT NULL DEFAULT 500,
  venue_ids uuid[] DEFAULT '{}',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  CONSTRAINT valid_cluster_lat CHECK (center_lat >= -90 AND center_lat <= 90),
  CONSTRAINT valid_cluster_lng CHECK (center_lng >= -180 AND center_lng <= 180),
  CONSTRAINT valid_cluster_radius CHECK (radius_meters > 0 AND radius_meters <= 5000)
);

CREATE INDEX IF NOT EXISTS idx_clusters_lat_lng ON venue_clusters (center_lat, center_lng);
CREATE INDEX IF NOT EXISTS idx_clusters_city ON venue_clusters (city);
CREATE INDEX IF NOT EXISTS idx_clusters_active ON venue_clusters (is_active) WHERE is_active = true;

-- Enable Row Level Security
ALTER TABLE user_venue_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE venue_clusters ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_venue_presence table

-- Users can view their own presence records
CREATE POLICY "Users can view own presence"
  ON user_venue_presence FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can view other users' presence ONLY if visible and currently in venue
CREATE POLICY "Users can view visible presence of others"
  ON user_venue_presence FOR SELECT
  TO authenticated
  USING (
    is_visible_in_venue = true 
    AND status = 'IN_VENUE'
    AND left_at IS NULL
    AND last_seen_at > now() - interval '24 hours'
  );

-- Only service role (Edge Functions) can insert presence records
CREATE POLICY "Service role can insert presence"
  ON user_venue_presence FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Only service role (Edge Functions) can update presence records
CREATE POLICY "Service role can update presence"
  ON user_venue_presence FOR UPDATE
  TO service_role
  USING (true)
  WITH CHECK (true);

-- RLS Policies for venue_clusters table

-- All authenticated users can read active clusters
CREATE POLICY "Users can view active clusters"
  ON venue_clusters FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Only service role can write clusters
CREATE POLICY "Service role can manage clusters"
  ON venue_clusters FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Helper function to calculate distance between two points using Haversine formula
CREATE OR REPLACE FUNCTION calculate_distance_meters(
  lat1 double precision,
  lng1 double precision,
  lat2 double precision,
  lng2 double precision
)
RETURNS double precision
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  earth_radius_meters constant double precision := 6371000.0;
  lat1_rad double precision;
  lat2_rad double precision;
  delta_lat double precision;
  delta_lng double precision;
  a double precision;
  c double precision;
BEGIN
  lat1_rad := radians(lat1);
  lat2_rad := radians(lat2);
  delta_lat := radians(lat2 - lat1);
  delta_lng := radians(lng2 - lng1);
  
  a := sin(delta_lat / 2.0) * sin(delta_lat / 2.0) +
       cos(lat1_rad) * cos(lat2_rad) *
       sin(delta_lng / 2.0) * sin(delta_lng / 2.0);
  c := 2.0 * atan2(sqrt(a), sqrt(1.0 - a));
  
  RETURN earth_radius_meters * c;
END;
$$;

-- Helper function to find venues within radius of a point
CREATE OR REPLACE FUNCTION find_nearby_venues(
  user_lat double precision,
  user_lng double precision,
  radius_meters integer DEFAULT 500
)
RETURNS TABLE (
  venue_id uuid,
  venue_name text,
  venue_type text,
  distance_meters double precision,
  is_in_geofence boolean
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    v.id,
    v.name,
    COALESCE(v.type, v.category) as venue_type,
    calculate_distance_meters(user_lat, user_lng, v.lat::double precision, v.lng::double precision) as distance,
    (calculate_distance_meters(user_lat, user_lng, v.lat::double precision, v.lng::double precision) <= COALESCE(v.geofence_radius_meters, 50)) as in_geofence
  FROM venues v
  WHERE 
    COALESCE(v.is_active, true) = true
    AND calculate_distance_meters(user_lat, user_lng, v.lat::double precision, v.lng::double precision) <= radius_meters
  ORDER BY distance ASC;
END;
$$;

-- Helper function to get current presence count for a venue (privacy-friendly aggregate)
CREATE OR REPLACE FUNCTION get_venue_presence_count(
  p_venue_id uuid,
  include_invisible boolean DEFAULT false
)
RETURNS integer
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  presence_count integer;
BEGIN
  IF include_invisible THEN
    SELECT COUNT(*)
    INTO presence_count
    FROM user_venue_presence
    WHERE venue_id = p_venue_id
      AND status = 'IN_VENUE'
      AND left_at IS NULL
      AND last_seen_at > now() - interval '1 hour';
  ELSE
    SELECT COUNT(*)
    INTO presence_count
    FROM user_venue_presence
    WHERE venue_id = p_venue_id
      AND status = 'IN_VENUE'
      AND is_visible_in_venue = true
      AND left_at IS NULL
      AND last_seen_at > now() - interval '1 hour';
  END IF;
  
  RETURN COALESCE(presence_count, 0);
END;
$$;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_venues_updated_at') THEN
    CREATE TRIGGER update_venues_updated_at
      BEFORE UPDATE ON venues
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;

CREATE TRIGGER update_presence_updated_at
  BEFORE UPDATE ON user_venue_presence
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clusters_updated_at
  BEFORE UPDATE ON venue_clusters
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();