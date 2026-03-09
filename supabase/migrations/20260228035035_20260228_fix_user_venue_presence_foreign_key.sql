/*
  # Fix user_venue_presence foreign key relationship

  1. Problem
    - PostgREST cannot find the relationship between user_venue_presence and venues
    - The foreign key exists but needs to be named explicitly for PostgREST's schema cache

  2. Solution
    - Drop and recreate the foreign key with an explicit name
    - This allows PostgREST's embedding syntax `venue:venues()` to work correctly

  3. Changes
    - Recreate foreign key constraint with explicit naming
*/

-- Drop the existing anonymous foreign key constraint
DO $$
BEGIN
  -- First, find and drop any existing foreign key on venue_id
  EXECUTE (
    SELECT 'ALTER TABLE user_venue_presence DROP CONSTRAINT ' || quote_ident(conname)
    FROM pg_constraint
    WHERE conrelid = 'user_venue_presence'::regclass
    AND contype = 'f'
    AND conkey::text = (SELECT array_position(array_agg(attnum), attnum)::text 
                        FROM pg_attribute 
                        WHERE attrelid = 'user_venue_presence'::regclass 
                        AND attname = 'venue_id')::text
    LIMIT 1
  );
EXCEPTION
  WHEN OTHERS THEN
    -- Constraint might not exist, continue
    NULL;
END $$;

-- Recreate the foreign key with an explicit name that PostgREST can recognize
ALTER TABLE user_venue_presence
ADD CONSTRAINT user_venue_presence_venue_id_fkey 
FOREIGN KEY (venue_id) 
REFERENCES venues(id) 
ON DELETE CASCADE;

-- Verify the constraint exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'user_venue_presence_venue_id_fkey'
  ) THEN
    RAISE EXCEPTION 'Foreign key constraint was not created successfully';
  END IF;
END $$;