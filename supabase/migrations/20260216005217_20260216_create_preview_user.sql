/*
  # Create Preview User for Demo Mode

  1. New Data
    - Creates a demo user with UUID `00000000-0000-0000-0000-000000000001`
    - Populates with realistic demo data for testing and preview

  2. Purpose
    - Allows app to work in preview mode without authentication
    - Provides sample data for demos and testing
*/

-- Insert demo user into auth.users first
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = '00000000-0000-0000-0000-000000000001') THEN
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      aud,
      role
    ) VALUES (
      '00000000-0000-0000-0000-000000000001',
      '00000000-0000-0000-0000-000000000000',
      'demo@swarm.app',
      '',
      now(),
      now(),
      now(),
      'authenticated',
      'authenticated'
    );
  END IF;
END $$;

-- Insert or update user profile
INSERT INTO public.users (
  id,
  name,
  dob,
  is_21_plus_confirmed,
  photos,
  bio,
  vibe_tags,
  favorite_drinks,
  tonight_status,
  home_city,
  privacy_mode,
  last_known_lat,
  last_known_lng,
  last_active_at,
  venmo_linked,
  preferred_radius_meters,
  weather_enabled,
  looking_for,
  fun_fact,
  go_to_karaoke_song,
  ideal_night_out,
  conversation_starters,
  interests,
  occupation,
  education,
  first_drink_on_me,
  verified_profile,
  ghost_mode,
  avatar_url,
  is_premium,
  lush_coin_balance
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Demo User',
  '1995-06-15',
  true,
  ARRAY[]::text[],
  'Hey there! I love exploring new bars and meeting cool people. Always down for a good time.',
  ARRAY['Chill Vibes', 'Live Music', 'Rooftop Scene'],
  ARRAY['Old Fashioned', 'IPA', 'Margarita'],
  'staying_in',
  'Los Angeles, CA',
  'nearby',
  34.0522,
  -118.2437,
  now(),
  false,
  5000,
  true,
  'New Friends',
  'I once sang karaoke in 5 different countries in one month!',
  'Don''t Stop Believin''',
  'Starting at a cozy bar with great cocktails, then moving to a place with live music.',
  ARRAY['What''s your favorite bar in the city?', 'Been to any good concerts lately?'],
  ARRAY['Music', 'Travel', 'Food & Cooking'],
  'Software Engineer',
  'UCLA',
  true,
  true,
  false,
  null,
  false,
  0
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  dob = EXCLUDED.dob,
  is_21_plus_confirmed = EXCLUDED.is_21_plus_confirmed,
  photos = EXCLUDED.photos,
  bio = EXCLUDED.bio,
  vibe_tags = EXCLUDED.vibe_tags,
  favorite_drinks = EXCLUDED.favorite_drinks,
  home_city = EXCLUDED.home_city,
  last_active_at = now();
