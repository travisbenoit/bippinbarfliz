/*
  # Create emoji_reactions table

  1. New Tables
    - `emoji_reactions`
      - `id` (uuid, primary key) - unique reaction identifier
      - `user_id` (uuid, FK to users) - who reacted
      - `target_type` (text) - what was reacted to (message, post, profile, venue, swarm)
      - `target_id` (uuid) - ID of the target entity
      - `emoji` (text) - the emoji used
      - `created_at` (timestamptz) - when the reaction was created
    - Unique constraint on (user_id, target_type, target_id) to prevent duplicate reactions

  2. Security
    - RLS enabled
    - Authenticated users can view all reactions
    - Users can add their own reactions
    - Users can remove their own reactions

  3. Indexes
    - target_type + target_id for querying reactions on an entity
    - user_id for user's reactions
    - created_at for chronological ordering
*/

CREATE TABLE IF NOT EXISTS emoji_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_type text NOT NULL CHECK (target_type IN ('message', 'post', 'profile', 'venue', 'swarm')),
  target_id uuid NOT NULL,
  emoji text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE (user_id, target_type, target_id)
);

ALTER TABLE emoji_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view reactions"
  ON emoji_reactions FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can add their own reactions"
  ON emoji_reactions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own reactions"
  ON emoji_reactions FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_emoji_reactions_target ON emoji_reactions(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_emoji_reactions_user ON emoji_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_emoji_reactions_created ON emoji_reactions(created_at DESC);
