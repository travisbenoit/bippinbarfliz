-- Migration 000009: Venue Buzz (ephemeral venue chat rooms)
-- Messages auto-expire after 4 hours. Cleanup via pg_cron or Edge Function.

CREATE TABLE venue_buzz (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id      uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  user_id       uuid NOT NULL REFERENCES auth.users(id),
  body          text NOT NULL CHECK (char_length(body) BETWEEN 1 AND 280),
  report_count  int DEFAULT 0,
  created_at    timestamptz DEFAULT now(),
  expires_at    timestamptz DEFAULT (now() + interval '4 hours')
);

CREATE INDEX idx_venue_buzz_venue
  ON venue_buzz (venue_id, created_at DESC)
  WHERE report_count < 3;

CREATE INDEX idx_venue_buzz_cleanup
  ON venue_buzz (expires_at)
  WHERE expires_at < now();

-- RLS
ALTER TABLE venue_buzz ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read non-reported buzz"
  ON venue_buzz FOR SELECT
  USING (auth.role() = 'authenticated' AND report_count < 3);

CREATE POLICY "Users can post buzz"
  ON venue_buzz FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own buzz"
  ON venue_buzz FOR DELETE
  USING (user_id = auth.uid());

-- RPC to report a message (increment report_count)
CREATE OR REPLACE FUNCTION report_buzz(buzz_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE venue_buzz SET report_count = report_count + 1 WHERE id = buzz_id;
END;
$$;
