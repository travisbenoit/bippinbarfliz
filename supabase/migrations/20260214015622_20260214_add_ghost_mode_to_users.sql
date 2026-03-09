/*
  # Add Ghost Mode to Users

  This migration adds a ghost_mode field to the users table for privacy control in bar presence features.

  ## Changes
  - Add `ghost_mode` boolean column to `users` table
  - Default value is `false` (users are visible by default)
  - Ghost mode users count in bar population but don't appear in user lists

  ## Privacy Behavior
  - When `ghost_mode = true`: User counts in bar population but is NOT shown in bar_people endpoint
  - When `ghost_mode = false`: User is visible in bar_people endpoint (default)
*/

-- Add ghost_mode column to users table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'ghost_mode'
  ) THEN
    ALTER TABLE users ADD COLUMN ghost_mode boolean DEFAULT false;
  END IF;
END $$;

-- Create index for ghost_mode queries
CREATE INDEX IF NOT EXISTS idx_users_ghost_mode ON users(ghost_mode);
