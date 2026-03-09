-- Migration 000011: Vibe Pulse — one-tap venue mood voting

CREATE TABLE vibe_votes (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id   uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES auth.users(id),
  vibe       text NOT NULL CHECK (vibe IN ('lit', 'chill', 'vibing', 'dead', 'dancing')),
  created_at timestamptz DEFAULT now()
);

-- One vote per user per venue per calendar day
CREATE UNIQUE INDEX idx_vibe_votes_unique
  ON vibe_votes (venue_id, user_id, (created_at::date));

-- Fast lookup for recent votes (last 3 hours)
CREATE INDEX idx_vibe_votes_recent
  ON vibe_votes (venue_id, created_at DESC);

-- RLS
ALTER TABLE vibe_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read vibe votes"
  ON vibe_votes FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Users can cast vibe votes"
  ON vibe_votes FOR INSERT
  WITH CHECK (user_id = auth.uid());
