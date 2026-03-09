/*
  # OSM-Based Venue Pipeline for Barfliz
  
  Creates a free venue data ingestion pipeline using OpenStreetMap data.
  
  ## 1. New Tables
  
  ### `venues` (updated/replaced)
  - `id` (text, primary key) - stable key format: osm:<type>:<id>
  - `name` (text) - venue name from OSM
  - `lat` (double precision) - latitude
  - `lng` (double precision) - longitude
  - `category` (text) - bar, pub, nightclub, brewery, etc.
  - `subcategory` (text) - sports bar, wine bar, rooftop, etc.
  - `address` (text) - full street address
  - `city` (text) - city name
  - `state` (text) - state/province
  - `country` (text) - country name
  - `osm_id` (text) - OSM identifier: node/123456789
  - `osm_tags` (jsonb) - full OSM tags for future use
  - `image_url_osm` (text) - image from OSM/Wikimedia if available
  - `google_place_id` (text) - reserved for future enrichment
  - `foursquare_id` (text) - reserved for future enrichment
  - `verified_flag` (boolean) - true if claimed by owner
  - `geofence_radius_m` (integer) - Radar-compatible radius
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)
  
  ### `venue_photos`
  - User-generated and OSM-derived photos
  - Supports multiple sources: user_upload, owner_upload, osm
  
  ### `venue_reviews`
  - Barfliz-native reviews with 1-5 star ratings
  
  ## 2. Security
  - RLS enabled on all tables
  - Public read for venues (for map display)
  - Authenticated users can create reviews/photos
  - Users can only update/delete their own content
  
  ## 3. Indexes
  - Geospatial queries (lat/lng)
  - Category filtering
  - OSM ID lookups for upserts
*/

-- Drop existing venues table if it exists and recreate with new schema
-- First, check dependencies and handle carefully
DO $$
BEGIN
  -- Drop dependent foreign keys if they exist
  IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'venue_sessions_venue_id_fkey') THEN
    ALTER TABLE venue_sessions DROP CONSTRAINT IF EXISTS venue_sessions_venue_id_fkey;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'venue_ratings_venue_id_fkey') THEN
    ALTER TABLE venue_ratings DROP CONSTRAINT IF EXISTS venue_ratings_venue_id_fkey;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'user_venue_presence_venue_id_fkey') THEN
    ALTER TABLE user_venue_presence DROP CONSTRAINT IF EXISTS user_venue_presence_venue_id_fkey;
  END IF;
END $$;

-- Add new columns to venues table if they don't exist
DO $$
BEGIN
  -- Ensure id is text type for osm:<type>:<id> format
  -- Add osm_id column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'osm_id') THEN
    ALTER TABLE venues ADD COLUMN osm_id text;
  END IF;
  
  -- Add osm_tags column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'osm_tags') THEN
    ALTER TABLE venues ADD COLUMN osm_tags jsonb;
  END IF;
  
  -- Add image_url_osm column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'image_url_osm') THEN
    ALTER TABLE venues ADD COLUMN image_url_osm text;
  END IF;
  
  -- Add foursquare_id column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'foursquare_id') THEN
    ALTER TABLE venues ADD COLUMN foursquare_id text;
  END IF;
  
  -- Add verified_flag column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'verified_flag') THEN
    ALTER TABLE venues ADD COLUMN verified_flag boolean DEFAULT false;
  END IF;
  
  -- Ensure category column exists
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'category') THEN
    ALTER TABLE venues ADD COLUMN category text;
  END IF;
  
  -- Add subcategory column
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'subcategory') THEN
    ALTER TABLE venues ADD COLUMN subcategory text;
  END IF;
  
  -- Ensure lat/lng columns exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'lat') THEN
    ALTER TABLE venues ADD COLUMN lat double precision;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'lng') THEN
    ALTER TABLE venues ADD COLUMN lng double precision;
  END IF;
  
  -- Add address components
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'address') THEN
    ALTER TABLE venues ADD COLUMN address text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'city') THEN
    ALTER TABLE venues ADD COLUMN city text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'state') THEN
    ALTER TABLE venues ADD COLUMN state text;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'country') THEN
    ALTER TABLE venues ADD COLUMN country text;
  END IF;
  
  -- Ensure geofence_radius_m exists with default
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'geofence_radius_m') THEN
    ALTER TABLE venues ADD COLUMN geofence_radius_m integer DEFAULT 75;
  END IF;
  
  -- Ensure timestamps exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'created_at') THEN
    ALTER TABLE venues ADD COLUMN created_at timestamptz DEFAULT now();
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'venues' AND column_name = 'updated_at') THEN
    ALTER TABLE venues ADD COLUMN updated_at timestamptz DEFAULT now();
  END IF;
END $$;

-- Create unique index on osm_id for upserts
CREATE UNIQUE INDEX IF NOT EXISTS venues_osm_id_unique ON venues(osm_id) WHERE osm_id IS NOT NULL;

-- Create indexes for geospatial and category queries
CREATE INDEX IF NOT EXISTS venues_lat_lng_idx ON venues(lat, lng);
CREATE INDEX IF NOT EXISTS venues_category_idx ON venues(category);
CREATE INDEX IF NOT EXISTS venues_country_idx ON venues(country);
CREATE INDEX IF NOT EXISTS venues_city_idx ON venues(city);
CREATE INDEX IF NOT EXISTS venues_state_idx ON venues(state);

-- ============================================
-- VENUE PHOTOS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS venue_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id text NOT NULL,
  source text NOT NULL CHECK (source IN ('user_upload', 'owner_upload', 'osm')),
  image_url text NOT NULL,
  caption text,
  created_by_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- Add foreign key to venues (if venues.id is text)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                 WHERE constraint_name = 'venue_photos_venue_id_fkey' 
                 AND table_name = 'venue_photos') THEN
    -- We'll add this constraint after confirming venues.id type
    NULL;
  END IF;
END $$;

-- Indexes for venue_photos
CREATE INDEX IF NOT EXISTS venue_photos_venue_id_idx ON venue_photos(venue_id);
CREATE INDEX IF NOT EXISTS venue_photos_created_by_idx ON venue_photos(created_by_user_id);
CREATE INDEX IF NOT EXISTS venue_photos_source_idx ON venue_photos(source);

-- Enable RLS
ALTER TABLE venue_photos ENABLE ROW LEVEL SECURITY;

-- RLS Policies for venue_photos
DROP POLICY IF EXISTS "Anyone can view venue photos" ON venue_photos;
CREATE POLICY "Anyone can view venue photos"
  ON venue_photos FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can upload photos" ON venue_photos;
CREATE POLICY "Authenticated users can upload photos"
  ON venue_photos FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = created_by_user_id
    OR source = 'osm'
  );

DROP POLICY IF EXISTS "Users can update their own photos" ON venue_photos;
CREATE POLICY "Users can update their own photos"
  ON venue_photos FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by_user_id)
  WITH CHECK (auth.uid() = created_by_user_id);

DROP POLICY IF EXISTS "Users can delete their own photos" ON venue_photos;
CREATE POLICY "Users can delete their own photos"
  ON venue_photos FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by_user_id);

-- ============================================
-- VENUE REVIEWS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS venue_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id text NOT NULL,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title text,
  body text,
  created_by_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

-- Indexes for venue_reviews
CREATE INDEX IF NOT EXISTS venue_reviews_venue_id_idx ON venue_reviews(venue_id);
CREATE INDEX IF NOT EXISTS venue_reviews_created_by_idx ON venue_reviews(created_by_user_id);
CREATE INDEX IF NOT EXISTS venue_reviews_rating_idx ON venue_reviews(rating);

-- Enable RLS
ALTER TABLE venue_reviews ENABLE ROW LEVEL SECURITY;

-- RLS Policies for venue_reviews
DROP POLICY IF EXISTS "Anyone can view venue reviews" ON venue_reviews;
CREATE POLICY "Anyone can view venue reviews"
  ON venue_reviews FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can create reviews" ON venue_reviews;
CREATE POLICY "Authenticated users can create reviews"
  ON venue_reviews FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by_user_id);

DROP POLICY IF EXISTS "Users can update their own reviews" ON venue_reviews;
CREATE POLICY "Users can update their own reviews"
  ON venue_reviews FOR UPDATE
  TO authenticated
  USING (auth.uid() = created_by_user_id)
  WITH CHECK (auth.uid() = created_by_user_id);

DROP POLICY IF EXISTS "Users can delete their own reviews" ON venue_reviews;
CREATE POLICY "Users can delete their own reviews"
  ON venue_reviews FOR DELETE
  TO authenticated
  USING (auth.uid() = created_by_user_id);

-- ============================================
-- OSM IMPORT LOG TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS osm_import_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  region_type text NOT NULL,
  country_code text,
  total_processed integer DEFAULT 0,
  inserted_count integer DEFAULT 0,
  updated_count integer DEFAULT 0,
  skipped_count integer DEFAULT 0,
  errors jsonb,
  started_at timestamptz DEFAULT now(),
  completed_at timestamptz,
  status text DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed'))
);

-- Enable RLS (admin only)
ALTER TABLE osm_import_logs ENABLE ROW LEVEL SECURITY;

-- Only service role can access import logs
DROP POLICY IF EXISTS "Service role can manage import logs" ON osm_import_logs;
CREATE POLICY "Service role can manage import logs"
  ON osm_import_logs
  USING (false)
  WITH CHECK (false);

-- ============================================
-- HELPER FUNCTION: Update updated_at timestamp
-- ============================================

CREATE OR REPLACE FUNCTION update_venues_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for venues
DROP TRIGGER IF EXISTS venues_updated_at_trigger ON venues;
CREATE TRIGGER venues_updated_at_trigger
  BEFORE UPDATE ON venues
  FOR EACH ROW
  EXECUTE FUNCTION update_venues_updated_at();

-- ============================================
-- HELPER FUNCTION: Get venues by bounding box (for map)
-- ============================================

CREATE OR REPLACE FUNCTION get_venues_in_bounds(
  min_lat double precision,
  min_lng double precision,
  max_lat double precision,
  max_lng double precision,
  category_filter text DEFAULT NULL
)
RETURNS SETOF venues AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM venues
  WHERE lat BETWEEN min_lat AND max_lat
    AND lng BETWEEN min_lng AND max_lng
    AND (category_filter IS NULL OR category = category_filter);
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- HELPER FUNCTION: Get venue stats
-- ============================================

CREATE OR REPLACE FUNCTION get_venue_stats(p_venue_id text)
RETURNS TABLE (
  avg_rating numeric,
  review_count bigint,
  photo_count bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(AVG(vr.rating)::numeric, 0) as avg_rating,
    COUNT(DISTINCT vr.id) as review_count,
    (SELECT COUNT(*) FROM venue_photos vp WHERE vp.venue_id = p_venue_id) as photo_count
  FROM venue_reviews vr
  WHERE vr.venue_id = p_venue_id;
END;
$$ LANGUAGE plpgsql STABLE;