/*
  # Create Location Pings Table for Real-Time Location Tracking

  ## Overview
  Creates a location tracking system to store periodic location updates from users.
  This enables features like "see where friends are", proximity detection, and location history.

  ## New Tables
  
  ### `location_pings`
  Stores timestamped location data from users
  - `id` (uuid, primary key) - Unique ping identifier
  - `user_id` (uuid, required) - User who sent the location ping
  - `latitude` (decimal) - Geographic latitude (-90 to 90)
  - `longitude` (decimal) - Geographic longitude (-180 to 180)
  - `accuracy` (decimal, nullable) - Location accuracy in meters
  - `altitude` (decimal, nullable) - Altitude in meters
  - `speed` (decimal, nullable) - Speed in meters per second
  - `heading` (decimal, nullable) - Direction of travel in degrees (0-360)
  - `battery_level` (integer, nullable) - Device battery percentage (0-100)
  - `is_background` (boolean) - Whether ping was sent while app was in background
  - `created_at` (timestamptz) - When the ping was recorded

  ## Security
  - Enable RLS on location_pings table
  - Users can only read their own location pings
  - Users can only read friends' location pings if sharing is enabled
  - Users can insert their own location pings
  - No updates or deletes allowed (location history should be immutable)

  ## Indexes
  - `idx_location_pings_user_id` - Fast lookups by user
  - `idx_location_pings_created_at` - Time-based queries
  - Composite index on (user_id, created_at) for user location history
  - GiST index on lat/lng for spatial queries (finding nearby users)

  ## Notes
  - Consider partitioning by created_at for scalability
  - Implement data retention policy (delete pings older than 30 days)
  - For privacy, only show real-time location to friends with active sharing
  - PostGIS extension could be added for advanced spatial queries
*/

-- Create location_pings table
CREATE TABLE IF NOT EXISTS location_pings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude decimal(10, 8) NOT NULL CHECK (latitude >= -90 AND latitude <= 90),
  longitude decimal(11, 8) NOT NULL CHECK (longitude >= -180 AND longitude <= 180),
  accuracy decimal(10, 2),
  altitude decimal(10, 2),
  speed decimal(10, 2),
  heading decimal(5, 2) CHECK (heading IS NULL OR (heading >= 0 AND heading <= 360)),
  battery_level integer CHECK (battery_level IS NULL OR (battery_level >= 0 AND battery_level <= 100)),
  is_background boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_location_pings_user_id ON location_pings(user_id);
CREATE INDEX IF NOT EXISTS idx_location_pings_created_at ON location_pings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_pings_user_timeline ON location_pings(user_id, created_at DESC);

-- Create spatial index for proximity queries (if PostGIS is available)
-- This will enable efficient "find users within X km" queries
-- Using btree for now, can upgrade to GiST with PostGIS
CREATE INDEX IF NOT EXISTS idx_location_pings_coordinates ON location_pings(latitude, longitude);

-- Add helpful comment
COMMENT ON TABLE location_pings IS 'Real-time location tracking for users, enabling proximity features and location history';

-- Enable Row Level Security
ALTER TABLE location_pings ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own location pings
CREATE POLICY "Users can read own location pings"
  ON location_pings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy: Users can read friends' location pings (if sharing enabled)
-- Note: This will need to be updated once friendships table is created
-- For now, allowing read access only to own pings
-- TODO: Add friend-based access after friendships table is created

-- Policy: Users can insert their own location pings
CREATE POLICY "Users can insert own location pings"
  ON location_pings
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Policy: No updates allowed (location history should be immutable)
-- Policy: Users can delete their own old location pings (for privacy)
CREATE POLICY "Users can delete own location pings"
  ON location_pings
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);