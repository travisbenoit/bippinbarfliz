/*
  # Auto-create User Profile on Signup

  1. Purpose
    - Automatically creates a user profile in the public.users table when a new user signs up
    - Ensures that every authenticated user has a corresponding profile record
    - Prevents "profile not found" errors in the application

  2. Changes
    - Creates a trigger function `handle_new_user()` that:
      - Inserts a basic user profile with default values
      - Uses the user's email metadata if available
      - Sets sensible defaults for all required fields
    - Adds a trigger on `auth.users` that fires after insert

  3. Security
    - Function executes with security definer privileges
    - Only creates profiles for new auth users
    - Uses default values that can be updated later by the user
*/

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
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
    venue_preferences
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'New User'),
    '2000-01-01',
    true,
    'New to Barfliz!',
    'Los Angeles',
    ARRAY['Happy Hour']::text[],
    ARRAY['Beer']::text[],
    ARRAY[]::text[]
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
