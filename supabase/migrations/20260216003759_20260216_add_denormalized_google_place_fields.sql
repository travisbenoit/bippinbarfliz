/*
  # Add Denormalized Google Place Fields to Bars Table

  This migration adds denormalized Google Place data directly to the bars table
  for optimal performance when displaying ratings, photos, and details on the map.

  ## Changes

  1. New Columns on `bars` table
    - `rating` (numeric) - Bar rating from Google Places (0-5)
    - `review_count` (integer) - Total number of reviews
    - `photo_urls` (text[]) - Array of photo references for fetching images
    - `address` (text) - Formatted address from Google Places
    - `opening_hours` (jsonb) - Opening hours data
    - `google_last_synced_at` (timestamptz) - When denormalized data was last synced

  2. Purpose
    - Flutter map queries can fetch all needed data directly from bars table
    - No joins needed to google_place_cache for basic bar details
    - Reduced API latency for map view
    - Photos array allows apps to fetch images without separate query

  ## Security
    - RLS policies unchanged (authenticated users can view all bars)
    - Data is read-only from app perspective (only updated via edge functions)
    - Service role maintains full access for cache sync operations
*/

-- Add denormalized Google Place fields to bars table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bars' AND column_name = 'rating'
  ) THEN
    ALTER TABLE bars ADD COLUMN rating numeric DEFAULT NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bars' AND column_name = 'review_count'
  ) THEN
    ALTER TABLE bars ADD COLUMN review_count integer DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bars' AND column_name = 'photo_urls'
  ) THEN
    ALTER TABLE bars ADD COLUMN photo_urls text[] DEFAULT ARRAY[]::text[];
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bars' AND column_name = 'address'
  ) THEN
    ALTER TABLE bars ADD COLUMN address text DEFAULT NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bars' AND column_name = 'opening_hours'
  ) THEN
    ALTER TABLE bars ADD COLUMN opening_hours jsonb DEFAULT NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bars' AND column_name = 'google_last_synced_at'
  ) THEN
    ALTER TABLE bars ADD COLUMN google_last_synced_at timestamptz DEFAULT NULL;
  END IF;
END $$;

-- Add helpful comments
COMMENT ON COLUMN bars.rating IS 'Rating from Google Places (0-5 scale)';
COMMENT ON COLUMN bars.review_count IS 'Total number of reviews on Google Places';
COMMENT ON COLUMN bars.photo_urls IS 'Array of photo references for displaying bar photos';
COMMENT ON COLUMN bars.address IS 'Formatted address from Google Places';
COMMENT ON COLUMN bars.opening_hours IS 'Opening hours JSON data from Google Places';
COMMENT ON COLUMN bars.google_last_synced_at IS 'When Google Place denormalized data was last synced to bars table';
