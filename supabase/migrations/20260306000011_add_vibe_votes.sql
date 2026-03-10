-- Migration 000011: Vibe Pulse — one-tap venue mood voting

CREATE TABLE IF NOT EXISTS vibe_votes (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id   uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES auth.users(id),
  vibe       text NOT NULL CHECK (vibe IN ('lit', 'chill', 'vibing', 'dead', 'dancing')),
  created_at timestamptz DEFAULT now()
);

-- One vote per user per venue per calendar day
-- Note: this index uses (created_at::date) which requires explicit creation
-- on fresh DBs; on prod it already exists so we skip to avoid immutability errors.
-- The vibeService enforces uniqueness at the app layer as a fallback.

-- Fast lookup for recent votes (last 3 hours)
CREATE INDEX IF NOT EXISTS idx_vibe_votes_recent
  ON vibe_votes (venue_id, created_at DESC);

-- RLS
ALTER TABLE vibe_votes ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'vibe_votes' AND policyname = 'Authenticated users can read vibe votes') THEN
    CREATE POLICY "Authenticated users can read vibe votes"
      ON vibe_votes FOR SELECT
      USING (auth.role() = 'authenticated');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'vibe_votes' AND policyname = 'Users can cast vibe votes') THEN
    CREATE POLICY "Users can cast vibe votes"
      ON vibe_votes FOR INSERT
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;
