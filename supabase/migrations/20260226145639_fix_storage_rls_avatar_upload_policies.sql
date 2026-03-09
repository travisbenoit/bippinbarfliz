/*
  # Fix storage RLS policies for avatar uploads

  ## Problem
  - The INSERT policy checks `(storage.foldername(name))[2] = auth.uid()::text`
    which requires path `avatars/{userId}/filename.ext`
  - The UPDATE and DELETE policies also use foldername[2] check
  - EditProfile.tsx was using a flat path `avatars/{userId}-timestamp.ext`
    which doesn't match the subfolder-based policy
  - This caused uploads from EditProfile to fail silently

  ## Fix
  - Drop and recreate all avatar storage policies using a consistent check:
    path must be `avatars/{userId}/...` where userId = auth.uid()
  - Uses `(storage.foldername(name))[1] = 'avatars'` to ensure correct folder
  - Uses `(storage.foldername(name))[2] = auth.uid()::text` for ownership
  - SELECT remains public (bucket is public)

  ## Notes
  - ProfileSetup.tsx already uses the correct subfolder path
  - EditProfile.tsx will be updated in the frontend code to match
*/

DO $$
BEGIN
  -- Drop existing policies if they exist
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can upload their own avatar' AND tablename = 'objects' AND schemaname = 'storage') THEN
    DROP POLICY "Users can upload their own avatar" ON storage.objects;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own avatar' AND tablename = 'objects' AND schemaname = 'storage') THEN
    DROP POLICY "Users can update their own avatar" ON storage.objects;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete their own avatar' AND tablename = 'objects' AND schemaname = 'storage') THEN
    DROP POLICY "Users can delete their own avatar" ON storage.objects;
  END IF;
END $$;

CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'profiles'
    AND (storage.foldername(name))[1] = 'avatars'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'profiles'
    AND (storage.foldername(name))[1] = 'avatars'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

CREATE POLICY "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'profiles'
    AND (storage.foldername(name))[1] = 'avatars'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );