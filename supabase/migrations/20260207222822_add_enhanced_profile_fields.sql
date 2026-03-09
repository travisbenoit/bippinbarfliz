/*
  # Enhanced Profile Fields

  1. Purpose
    - Add engaging profile fields to help users stand out and connect
    - Profile enhancement fields for better social discovery
    - Personality and interest fields for better matching

  2. New Fields
    - `looking_for` (text, nullable) - What user is seeking (friends, dates, networking)
    - `fun_fact` (text, nullable) - Interesting conversation starter
    - `go_to_karaoke_song` (text, nullable) - Their karaoke jam
    - `ideal_night_out` (text, nullable) - Description of perfect night
    - `conversation_starters` (text[], default empty) - Things they love talking about
    - `interests` (text[], default empty) - Hobbies and interests
    - `occupation` (text, nullable) - What they do for work
    - `education` (text, nullable) - Educational background
    - `spotify_username` (text, nullable) - Spotify profile
    - `instagram_username` (text, nullable) - Instagram handle
    - `first_drink_on_me` (boolean, default false) - Willing to buy first round
    - `verified_profile` (boolean, default false) - Profile verification status

  3. Notes
    - All fields are nullable to allow gradual profile completion
    - Array fields default to empty arrays
    - These fields make profiles more engaging and help with social connections
*/

-- Add enhanced profile fields to users table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'looking_for'
  ) THEN
    ALTER TABLE users ADD COLUMN looking_for text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'fun_fact'
  ) THEN
    ALTER TABLE users ADD COLUMN fun_fact text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'go_to_karaoke_song'
  ) THEN
    ALTER TABLE users ADD COLUMN go_to_karaoke_song text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'ideal_night_out'
  ) THEN
    ALTER TABLE users ADD COLUMN ideal_night_out text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'conversation_starters'
  ) THEN
    ALTER TABLE users ADD COLUMN conversation_starters text[] DEFAULT ARRAY[]::text[];
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'interests'
  ) THEN
    ALTER TABLE users ADD COLUMN interests text[] DEFAULT ARRAY[]::text[];
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'occupation'
  ) THEN
    ALTER TABLE users ADD COLUMN occupation text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'education'
  ) THEN
    ALTER TABLE users ADD COLUMN education text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'spotify_username'
  ) THEN
    ALTER TABLE users ADD COLUMN spotify_username text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'instagram_username'
  ) THEN
    ALTER TABLE users ADD COLUMN instagram_username text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'first_drink_on_me'
  ) THEN
    ALTER TABLE users ADD COLUMN first_drink_on_me boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'verified_profile'
  ) THEN
    ALTER TABLE users ADD COLUMN verified_profile boolean DEFAULT false;
  END IF;
END $$;
