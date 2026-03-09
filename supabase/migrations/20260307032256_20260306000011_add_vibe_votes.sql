/*
  # Vibe Pulse — one-tap mood voting for venues

  1. New Tables
    - `vibe_votes`
      - `id` (uuid, primary key)
      - `venue_id` (uuid, references venues)
      - `user_id` (uuid, references auth.users)
      - `vibe` (text: 'lit', 'chill', 'vibing', 'dead', 'dancing')
      - `created_at` (timestamptz)
  
  2. Indexes
    - `idx_vibe_votes_recent` on (venue_id, created_at DESC)
      for fast lookup of recent votes (last 3 hours)
  
  3. Security
    - RLS enabled
    - Select: authenticated users can read all vibe votes
    - Insert: users can cast their own votes
  
  Note: One-vote-per-user-per-venue-per-day constraint is enforced at application layer.
*/

CREATE TABLE IF NOT EXISTS vibe_votes (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id   uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES auth.users(id),
  vibe       text NOT NULL CHECK (vibe IN ('lit', 'chill', 'vibing', 'dead', 'dancing')),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vibe_votes_recent
  ON vibe_votes (venue_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_vibe_votes_user_venue
  ON vibe_votes (user_id, venue_id, created_at DESC);

ALTER TABLE vibe_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read vibe votes"
  ON vibe_votes FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Users can cast vibe votes"
  ON vibe_votes FOR INSERT
  WITH CHECK (user_id = auth.uid());