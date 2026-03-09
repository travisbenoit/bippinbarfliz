/*
  # Add unit preference columns to users table

  ## Summary
  Adds persistent unit preference storage directly on the user profile so settings
  survive across devices and sessions, not just localStorage.

  ## New Columns
  - `distance_unit` (text) - User's preferred distance unit: 'miles' or 'kilometers'. Defaults to null (use regional default).
  - `temperature_unit` (text) - User's preferred temperature unit: 'F' or 'C'. Defaults to null (use regional default).

  ## Notes
  - NULL means "use region default" — allows per-user overrides without breaking regional defaults
  - No RLS changes needed; existing user RLS policies already cover these columns
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'distance_unit'
  ) THEN
    ALTER TABLE users ADD COLUMN distance_unit text DEFAULT NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'temperature_unit'
  ) THEN
    ALTER TABLE users ADD COLUMN temperature_unit text DEFAULT NULL;
  END IF;
END $$;
