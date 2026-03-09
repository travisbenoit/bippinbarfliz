/*
  # Add User Radius and Weather Preferences
  
  ## Overview
  Adds user preferences for venue search radius and location for weather

  ## 1. New Columns
  
  ### `users` table modifications
  - `preferred_radius_meters` (integer) - User's preferred search radius for venues (default: 5000m = 5km)
  - `weather_location` (text) - City name for weather forecast
  - `weather_enabled` (boolean) - Whether user wants weather displayed
  
  ## 2. Constraints
  - Radius must be between 500m and 50000m (50km)
  
  ## 3. Notes
  - Users can adjust radius to see more/fewer venues
  - Weather helps users plan their night out
  - Default radius is 5km (reasonable walking/rideshare distance)
*/

-- Add preferred radius column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'preferred_radius_meters') THEN
    ALTER TABLE users ADD COLUMN preferred_radius_meters integer DEFAULT 5000
      CONSTRAINT valid_preferred_radius CHECK (preferred_radius_meters >= 500 AND preferred_radius_meters <= 50000);
  END IF;
END $$;

-- Add weather location column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'weather_location') THEN
    ALTER TABLE users ADD COLUMN weather_location text;
  END IF;
END $$;

-- Add weather enabled flag
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'weather_enabled') THEN
    ALTER TABLE users ADD COLUMN weather_enabled boolean DEFAULT true;
  END IF;
END $$;

-- Create index on preferred_radius_meters for analytics
CREATE INDEX IF NOT EXISTS idx_users_preferred_radius ON users (preferred_radius_meters) WHERE preferred_radius_meters IS NOT NULL;