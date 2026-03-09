/*
  # Fix User Creation Trigger

  1. Problem
    - The handle_new_user() trigger function was inserting 'public' for privacy_mode
    - The privacy_mode CHECK constraint only allows: 'invisible', 'friends_only', 'nearby'
    - This caused "Database error saving new user" during phone verification signup
  
  2. Solution
    - Update handle_new_user() to use 'nearby' as the default privacy_mode
    - This is a reasonable default that allows users to be discovered by others nearby
*/

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.users (
    id,
    name,
    dob,
    is_21_plus_confirmed,
    bio,
    home_city,
    vibe_tags,
    favorite_drinks,
    venue_preferences,
    ghost_mode,
    privacy_mode,
    tonight_status,
    created_at
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    '2000-01-01',
    false,
    '',
    '',
    ARRAY[]::text[],
    ARRAY[]::text[],
    ARRAY[]::text[],
    false,
    'nearby',  -- Changed from 'public' to 'nearby' to match CHECK constraint
    'staying_in',
    now()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$function$;