/*
  # The Room Feature - Venue Community System

  ## Overview
  Creates a real-time, geofence-gated venue community system called "The Room".
  Each venue has a live social layer accessible only to physically present users.
  Note: bars table uses bar_id as primary key (not id).

  ## New Tables

  ### venue_room_messages
  - Real-time chat messages scoped to a venue, expires after 24 hours
  - Supports text, drink, music, prompt, gif message types
  - Hidden after 3 reports

  ### venue_room_reactions
  - Emoji reactions on room messages (nightlife-themed: beer, cocktail, fire, dance, music, whiskey, heart, laugh)

  ### venue_room_moments
  - Temporary photo/video/text posts, expire after 24 hours

  ### venue_room_vibe_polls
  - Crowdsourced live polls: music vibe, crowd energy, drink of the night
  - One vote per user per poll_type per venue (upsertable)

  ### venue_room_presence
  - Tracks who is active in The Room (refreshed every 30 min)

  ## Security
  - RLS enabled on all tables
  - Read: any authenticated user (supports remote read-only view)
  - Write: authenticated users only
  - Expiry and report filtering handled in RLS SELECT policies

  ## Functions
  - upsert_room_presence: atomic join/refresh
  - report_room_message / report_room_moment: increment report count
  - get_room_stats: aggregate stats for entry card
*/

-- venue_room_messages
CREATE TABLE IF NOT EXISTS venue_room_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id uuid NOT NULL REFERENCES bars(bar_id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body text NOT NULL CHECK (char_length(body) <= 280),
  message_type text NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'drink', 'music', 'prompt', 'gif')),
  metadata jsonb DEFAULT NULL,
  report_count integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '24 hours')
);

ALTER TABLE venue_room_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone authenticated can read room messages"
  ON venue_room_messages FOR SELECT
  TO authenticated
  USING (report_count < 3 AND expires_at > now());

CREATE POLICY "Authenticated users can post room messages"
  ON venue_room_messages FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own room messages"
  ON venue_room_messages FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_room_messages_venue_created
  ON venue_room_messages(venue_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_room_messages_expires
  ON venue_room_messages(expires_at);

-- venue_room_reactions
CREATE TABLE IF NOT EXISTS venue_room_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id uuid NOT NULL REFERENCES venue_room_messages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reaction text NOT NULL CHECK (reaction IN ('beer', 'cocktail', 'fire', 'dance', 'music', 'whiskey', 'heart', 'laugh')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(message_id, user_id, reaction)
);

ALTER TABLE venue_room_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone authenticated can read reactions"
  ON venue_room_reactions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can add reactions"
  ON venue_room_reactions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove own reactions"
  ON venue_room_reactions FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_room_reactions_message
  ON venue_room_reactions(message_id);

-- venue_room_moments
CREATE TABLE IF NOT EXISTS venue_room_moments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id uuid NOT NULL REFERENCES bars(bar_id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  media_url text DEFAULT NULL,
  caption text CHECK (char_length(caption) <= 150),
  moment_type text NOT NULL DEFAULT 'text' CHECK (moment_type IN ('photo', 'video', 'text')),
  like_count integer NOT NULL DEFAULT 0,
  report_count integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '24 hours')
);

ALTER TABLE venue_room_moments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone authenticated can read moments"
  ON venue_room_moments FOR SELECT
  TO authenticated
  USING (report_count < 3 AND expires_at > now());

CREATE POLICY "Authenticated users can post moments"
  ON venue_room_moments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own moments"
  ON venue_room_moments FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_room_moments_venue_created
  ON venue_room_moments(venue_id, created_at DESC);

-- venue_room_vibe_polls
CREATE TABLE IF NOT EXISTS venue_room_vibe_polls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id uuid NOT NULL REFERENCES bars(bar_id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  poll_type text NOT NULL CHECK (poll_type IN ('music', 'energy', 'drink')),
  vote_value text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(venue_id, user_id, poll_type)
);

ALTER TABLE venue_room_vibe_polls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone authenticated can read vibe polls"
  ON venue_room_vibe_polls FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can vote"
  ON venue_room_vibe_polls FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own vote"
  ON venue_room_vibe_polls FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove own vote"
  ON venue_room_vibe_polls FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_room_vibe_polls_venue
  ON venue_room_vibe_polls(venue_id, poll_type);

-- venue_room_presence
CREATE TABLE IF NOT EXISTS venue_room_presence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id uuid NOT NULL REFERENCES bars(bar_id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at timestamptz NOT NULL DEFAULT now(),
  last_active_at timestamptz NOT NULL DEFAULT now(),
  last_post_at timestamptz DEFAULT NULL,
  UNIQUE(venue_id, user_id)
);

ALTER TABLE venue_room_presence ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone authenticated can read room presence"
  ON venue_room_presence FOR SELECT
  TO authenticated
  USING (last_active_at > now() - interval '30 minutes');

CREATE POLICY "Authenticated users can join room"
  ON venue_room_presence FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own presence"
  ON venue_room_presence FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave room"
  ON venue_room_presence FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_room_presence_venue_active
  ON venue_room_presence(venue_id, last_active_at DESC);

-- Function: upsert_room_presence
CREATE OR REPLACE FUNCTION upsert_room_presence(p_venue_id uuid, p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO venue_room_presence (venue_id, user_id, joined_at, last_active_at)
  VALUES (p_venue_id, p_user_id, now(), now())
  ON CONFLICT (venue_id, user_id)
  DO UPDATE SET last_active_at = now();
END;
$$;

-- Function: report_room_message
CREATE OR REPLACE FUNCTION report_room_message(p_message_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE venue_room_messages
  SET report_count = report_count + 1
  WHERE id = p_message_id;
END;
$$;

-- Function: report_room_moment
CREATE OR REPLACE FUNCTION report_room_moment(p_moment_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE venue_room_moments
  SET report_count = report_count + 1
  WHERE id = p_moment_id;
END;
$$;

-- Function: get_room_stats
CREATE OR REPLACE FUNCTION get_room_stats(p_venue_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_message_count integer;
  v_active_users integer;
  v_top_drink text;
  v_top_music text;
BEGIN
  SELECT COUNT(*) INTO v_message_count
  FROM venue_room_messages
  WHERE venue_id = p_venue_id
    AND expires_at > now()
    AND report_count < 3;

  SELECT COUNT(*) INTO v_active_users
  FROM venue_room_presence
  WHERE venue_id = p_venue_id
    AND last_active_at > now() - interval '30 minutes';

  SELECT vote_value INTO v_top_drink
  FROM venue_room_vibe_polls
  WHERE venue_id = p_venue_id AND poll_type = 'drink'
  GROUP BY vote_value ORDER BY COUNT(*) DESC LIMIT 1;

  SELECT vote_value INTO v_top_music
  FROM venue_room_vibe_polls
  WHERE venue_id = p_venue_id AND poll_type = 'music'
  GROUP BY vote_value ORDER BY COUNT(*) DESC LIMIT 1;

  RETURN jsonb_build_object(
    'message_count', v_message_count,
    'active_users', v_active_users,
    'top_drink', COALESCE(v_top_drink, null),
    'top_music', COALESCE(v_top_music, null)
  );
END;
$$;
