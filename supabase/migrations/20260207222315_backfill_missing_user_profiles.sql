/*
  # Backfill Missing User Profiles

  1. Purpose
    - Creates user profiles for any existing auth users who don't have profiles
    - Fixes the issue where users created before the auto-create trigger was added
    - Ensures all authenticated users have a profile record

  2. Changes
    - Inserts default profiles for auth users without corresponding public.users records
    - Uses sensible default values for all required fields
    - Safe to run multiple times (uses ON CONFLICT DO NOTHING)

  3. Notes
    - This is a one-time backfill migration
    - Future users will have profiles created automatically via trigger
*/

-- Create profiles for existing auth users who don't have profiles yet
INSERT INTO public.users (
  id,
  name,
  dob,
  is_21_plus_confirmed,
  bio,
  home_city,
  vibe_tags,
  favorite_drinks,
  venue_preferences
)
SELECT 
  au.id,
  COALESCE(au.raw_user_meta_data->>'name', au.email, 'User'),
  '2000-01-01',
  true,
  'New to Barfliz!',
  'Los Angeles',
  ARRAY['Happy Hour']::text[],
  ARRAY['Beer']::text[],
  ARRAY[]::text[]
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
ON CONFLICT (id) DO NOTHING;
