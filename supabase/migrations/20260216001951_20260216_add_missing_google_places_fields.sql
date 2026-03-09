/*
  # Add Missing Google Places Integration Fields

  1. Schema Changes
    - Add `google_last_linked_at` to bars table (other Google fields already exist)
    
  2. Data Integrity
    - Add CHECK constraint to enforce Darwin-only bars (lat/lng bounding box)
    - Bounding box: lat BETWEEN -12.55 AND -12.35, lng BETWEEN 130.75 AND 131.05
    
  Note: google_place_id, google_last_fetched_at, and google_place_cache table already exist
*/

-- Add google_last_linked_at column to bars table if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'bars' AND column_name = 'google_last_linked_at'
  ) THEN
    ALTER TABLE bars ADD COLUMN google_last_linked_at TIMESTAMPTZ NULL;
  END IF;
END $$;

-- Add Darwin bounding box constraint to bars table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'bars_darwin_bounds_check'
  ) THEN
    ALTER TABLE bars ADD CONSTRAINT bars_darwin_bounds_check 
      CHECK (lat BETWEEN -12.55 AND -12.35 AND lng BETWEEN 130.75 AND 131.05);
  END IF;
END $$;

-- Add helpful comments
COMMENT ON COLUMN bars.google_place_id IS 'Google Places API place_id for enriching venue data';
COMMENT ON COLUMN bars.google_last_linked_at IS 'Timestamp when this bar was linked to a Google Place';
COMMENT ON COLUMN bars.google_last_fetched_at IS 'Timestamp when Google Place details were last fetched';
