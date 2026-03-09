/*
  # Storage bucket for profile photos + Friendships RLS fix

  ## Changes

  ### 1. Storage bucket: profiles
  - Creates a public `profiles` bucket for avatar uploads
  - Users can upload/update/delete only their own avatars (path starts with their user ID)
  - Anyone can read (public avatars)

  ### 2. Friendships RLS policies
  - SELECT: users can see friendships they are part of
  - INSERT: authenticated user can send a friend request (user_id must be their own)
  - UPDATE: the recipient (friend_id) can accept/decline; sender can cancel
  - DELETE: either party can remove the friendship row
*/

-- Create the profiles storage bucket (public so avatar URLs work without auth)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profiles',
  'profiles',
  true,
  5242880,
  ARRAY['image/jpeg','image/png','image/webp','image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for the profiles bucket
CREATE POLICY "Public can read profile photos"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'profiles');

CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'profiles'
    AND (storage.foldername(name))[1] = 'avatars'
    AND auth.uid()::text = split_part(split_part(name, '/', 2), '-', 1)
  );

CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'profiles'
    AND auth.uid()::text = split_part(split_part(name, '/', 2), '-', 1)
  );

CREATE POLICY "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'profiles'
    AND auth.uid()::text = split_part(split_part(name, '/', 2), '-', 1)
  );

-- Friendships table RLS (table already exists, just add policies)
DO $$
BEGIN
  -- SELECT: see your own friendships
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'friendships' AND policyname = 'Users can view their friendships'
  ) THEN
    CREATE POLICY "Users can view their friendships"
      ON friendships FOR SELECT
      TO authenticated
      USING (auth.uid() = user_id OR auth.uid() = friend_id);
  END IF;

  -- INSERT: send friend request
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'friendships' AND policyname = 'Users can send friend requests'
  ) THEN
    CREATE POLICY "Users can send friend requests"
      ON friendships FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;

  -- UPDATE: recipient can accept/decline; sender can cancel
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'friendships' AND policyname = 'Users can respond to friend requests'
  ) THEN
    CREATE POLICY "Users can respond to friend requests"
      ON friendships FOR UPDATE
      TO authenticated
      USING (auth.uid() = user_id OR auth.uid() = friend_id)
      WITH CHECK (auth.uid() = user_id OR auth.uid() = friend_id);
  END IF;

  -- DELETE: either party can remove
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'friendships' AND policyname = 'Users can remove friendships'
  ) THEN
    CREATE POLICY "Users can remove friendships"
      ON friendships FOR DELETE
      TO authenticated
      USING (auth.uid() = user_id OR auth.uid() = friend_id);
  END IF;
END $$;
