/*
  # Badge Definitions, Challenge Definitions, and Moment Likes

  ## Overview
  Moves hardcoded badge and challenge definitions from frontend code into the
  database so they can be updated without code deployments, and adds moment
  likes support that was already expected by the frontend like_count column.

  ## New Tables

  ### badge_definitions
  - Stores badge metadata: key, display name, icon (emoji), requirement text, sort order
  - Seeded with all 9 existing badges

  ### challenge_definitions
  - Stores challenge metadata: key, display name, description, target count, reward XP, expiry days
  - Seeded with all 5 existing challenges

  ### venue_room_moment_likes
  - Tracks which users have liked which moments (one like per user per moment)
  - Paired with a DB function to atomically increment/decrement like_count on venue_room_moments

  ## Security
  - badge_definitions: public read (no auth required), no writes from client
  - challenge_definitions: public read (no auth required), no writes from client
  - venue_room_moment_likes: authenticated read/insert/delete, users can only manage own likes
*/

-- ─────────────────────────────────────────────────────────────────────────────
-- badge_definitions
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS badge_definitions (
  badge_key   text PRIMARY KEY,
  name        text NOT NULL,
  emoji       text NOT NULL DEFAULT '',
  requirement text NOT NULL DEFAULT '',
  sort_order  int  NOT NULL DEFAULT 0
);

ALTER TABLE badge_definitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read badge definitions"
  ON badge_definitions FOR SELECT
  TO anon, authenticated
  USING (true);

INSERT INTO badge_definitions (badge_key, name, emoji, requirement, sort_order) VALUES
  ('first_checkin',          'First Check-In',          '🎯', 'Check in once',               1),
  ('regular',                'Regular',                 '⭐', '10 check-ins',                2),
  ('night_owl',              'Night Owl',               '🦉', '25 check-ins',                3),
  ('venue_explorer',         'Venue Explorer',          '🗺️', 'Visit 10 unique venues',      4),
  ('social_butterfly',       'Social Butterfly',        '🦋', '5 swarms joined',             5),
  ('dive_bar_legend',        'Dive Bar Legend',         '🍺', 'Visit 5 pubs',                6),
  ('cocktail_connoisseur',   'Cocktail Connoisseur',    '🍸', 'Visit 5 lounges',             7),
  ('weekend_warrior',        'Weekend Warrior',         '🔥', '4-week streak',               8),
  ('barfliz_og',             'Barfliz OG',              '👑', '12-week streak',              9)
ON CONFLICT (badge_key) DO UPDATE SET
  name        = EXCLUDED.name,
  emoji       = EXCLUDED.emoji,
  requirement = EXCLUDED.requirement,
  sort_order  = EXCLUDED.sort_order;

-- ─────────────────────────────────────────────────────────────────────────────
-- challenge_definitions
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS challenge_definitions (
  challenge_key text    PRIMARY KEY,
  name          text    NOT NULL,
  description   text    NOT NULL DEFAULT '',
  target        int     NOT NULL DEFAULT 1,
  reward_xp     int     NOT NULL DEFAULT 0,
  expiry_days   int     NOT NULL DEFAULT 7,
  sort_order    int     NOT NULL DEFAULT 0
);

ALTER TABLE challenge_definitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read challenge definitions"
  ON challenge_definitions FOR SELECT
  TO anon, authenticated
  USING (true);

INSERT INTO challenge_definitions (challenge_key, name, description, target, reward_xp, expiry_days, sort_order) VALUES
  ('new_horizons',    'New Horizons',    'Visit 2 venues you''ve never been to',         2, 50,  7, 1),
  ('swarm_leader',    'Swarm Leader',    'Create a swarm with 3+ people',                1, 50,  7, 2),
  ('buzz_creator',    'Buzz Creator',    'Post 5 messages in Venue Buzz',                5, 25,  7, 3),
  ('friday_starter',  'Friday Starter',  'Check in before 9 PM on Friday',               1, 25,  7, 4),
  ('venue_hopper',    'Venue Hopper',    'Check in at 3 different venues in one night',  3, 75,  7, 5)
ON CONFLICT (challenge_key) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  target      = EXCLUDED.target,
  reward_xp   = EXCLUDED.reward_xp,
  expiry_days = EXCLUDED.expiry_days,
  sort_order  = EXCLUDED.sort_order;

-- ─────────────────────────────────────────────────────────────────────────────
-- venue_room_moment_likes
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS venue_room_moment_likes (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id  uuid        NOT NULL REFERENCES venue_room_moments(id) ON DELETE CASCADE,
  user_id    uuid        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(moment_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_moment_likes_moment ON venue_room_moment_likes(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_likes_user   ON venue_room_moment_likes(user_id);

ALTER TABLE venue_room_moment_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view moment likes"
  ON venue_room_moment_likes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can like moments"
  ON venue_room_moment_likes FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike their own likes"
  ON venue_room_moment_likes FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- DB function: toggle_moment_like
-- Atomically inserts or deletes a like and updates like_count on the moment
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION toggle_moment_like(p_moment_id uuid, p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_existing_id uuid;
  v_liked       boolean;
BEGIN
  SELECT id INTO v_existing_id
  FROM venue_room_moment_likes
  WHERE moment_id = p_moment_id AND user_id = p_user_id;

  IF v_existing_id IS NOT NULL THEN
    DELETE FROM venue_room_moment_likes WHERE id = v_existing_id;
    UPDATE venue_room_moments SET like_count = GREATEST(0, like_count - 1) WHERE id = p_moment_id;
    v_liked := false;
  ELSE
    INSERT INTO venue_room_moment_likes (moment_id, user_id) VALUES (p_moment_id, p_user_id);
    UPDATE venue_room_moments SET like_count = like_count + 1 WHERE id = p_moment_id;
    v_liked := true;
  END IF;

  RETURN jsonb_build_object('liked', v_liked);
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Fix buzzService gap: venue_buzz needs user join support
-- Add index for user_id foreign key (already has FK, ensure index exists)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_venue_buzz_user ON venue_buzz(user_id);
