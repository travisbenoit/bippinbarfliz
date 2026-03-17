/*
  # Venue Photo Wall — User Posts

  ## Overview
  Permanent user-posted photo feed per venue. Unlike the ephemeral room_moments (24h),
  these photos persist and build social proof over time — e.g. "Friday night at The Wharf".

  The existing `venue_photos` table stores Google/admin images. This new table is
  specifically for user-generated content (UGC) displayed in a photo wall.

  ## New Tables

  ### `venue_wall_photos`
  Stores user-submitted photos for the venue photo wall.
  - `id` (uuid, PK)
  - `venue_id` (text, NOT NULL)
  - `user_id` (uuid, FK → auth.users)
  - `photo_url` (text, NOT NULL) — Supabase storage public URL
  - `caption` (text, nullable, ≤200 chars)
  - `like_count` (int, default 0)
  - `report_count` (int, default 0)
  - `created_at` (timestamptz)

  ### `venue_wall_photo_likes`
  One row per (photo, user) pair to prevent duplicate likes.
  - `id` (uuid, PK)
  - `photo_id` (uuid, FK → venue_wall_photos)
  - `user_id` (uuid, FK → auth.users)
  - `created_at` (timestamptz)
  - UNIQUE (photo_id, user_id)

  ## Security
  - RLS enabled on both tables
  - Authenticated users can read all non-reported photos
  - Users can only post/delete their own content
  - Like operations handled via SECURITY DEFINER function to safely update counters

  ## Functions
  - `toggle_wall_photo_like(p_photo_id, p_user_id)` — atomic like/unlike with counter
  - `report_wall_photo(p_photo_id)` — increment report count

  ## Indexes
  - `(venue_id, created_at DESC)` — primary feed query
  - `(user_id, photo_id)` — likes lookup
*/

-- ── venue_wall_photos ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS venue_wall_photos (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id     text        NOT NULL,
  user_id      uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  photo_url    text        NOT NULL,
  caption      text        CHECK (char_length(caption) <= 200),
  like_count   integer     NOT NULL DEFAULT 0,
  report_count integer     NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_venue_wall_photos_feed
  ON venue_wall_photos (venue_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_venue_wall_photos_user
  ON venue_wall_photos (user_id);

ALTER TABLE venue_wall_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view wall photos"
  ON venue_wall_photos FOR SELECT
  TO authenticated
  USING (report_count < 5);

CREATE POLICY "Users can insert own wall photos"
  ON venue_wall_photos FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own wall photos"
  ON venue_wall_photos FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ── venue_wall_photo_likes ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS venue_wall_photo_likes (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  photo_id   uuid        NOT NULL REFERENCES venue_wall_photos(id) ON DELETE CASCADE,
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (photo_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_venue_wall_photo_likes_user
  ON venue_wall_photo_likes (user_id, photo_id);

ALTER TABLE venue_wall_photo_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view wall photo likes"
  ON venue_wall_photo_likes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own wall photo likes"
  ON venue_wall_photo_likes FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own wall photo likes"
  ON venue_wall_photo_likes FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ── toggle_wall_photo_like ────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION toggle_wall_photo_like(p_photo_id uuid, p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_existing uuid;
  v_liked    boolean;
BEGIN
  SELECT id INTO v_existing
  FROM venue_wall_photo_likes
  WHERE photo_id = p_photo_id AND user_id = p_user_id;

  IF v_existing IS NOT NULL THEN
    DELETE FROM venue_wall_photo_likes WHERE id = v_existing;
    UPDATE venue_wall_photos
    SET like_count = GREATEST(like_count - 1, 0)
    WHERE id = p_photo_id;
    v_liked := false;
  ELSE
    INSERT INTO venue_wall_photo_likes (photo_id, user_id) VALUES (p_photo_id, p_user_id);
    UPDATE venue_wall_photos
    SET like_count = like_count + 1
    WHERE id = p_photo_id;
    v_liked := true;
  END IF;

  RETURN jsonb_build_object('liked', v_liked);
END;
$$;

-- ── report_wall_photo ─────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION report_wall_photo(p_photo_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE venue_wall_photos
  SET report_count = report_count + 1
  WHERE id = p_photo_id;
END;
$$;
