/*
  # Venue Buzz — Live ephemeral chat rooms for venues

  1. New Tables
    - `venue_buzz`
      - `id` (uuid, primary key)
      - `venue_id` (uuid, references venues)
      - `user_id` (uuid, references auth.users)
      - `body` (text, max 280 chars)
      - `report_count` (int, defaults to 0)
      - `created_at` (timestamptz)
      - `expires_at` (timestamptz, auto-set to 4 hours from creation)
  
  2. Indexes
    - `idx_venue_buzz_venue` on (venue_id, created_at DESC) for fast venue chat lookup
    - `idx_venue_buzz_cleanup` on (expires_at) for cleanup jobs
  
  3. Security
    - Enable RLS on `venue_buzz`
    - Read policy: authenticated users can read non-reported buzz
    - Insert policy: users can post their own messages
    - Delete policy: users can delete their own messages
  
  4. Utility Functions
    - `report_buzz(uuid)` RPC to increment report_count

  Messages auto-expire after 4 hours via database function or Edge Function cleanup job.
*/

CREATE TABLE IF NOT EXISTS venue_buzz (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id      uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  user_id       uuid NOT NULL REFERENCES auth.users(id),
  body          text NOT NULL CHECK (char_length(body) BETWEEN 1 AND 280),
  report_count  int DEFAULT 0,
  created_at    timestamptz DEFAULT now(),
  expires_at    timestamptz DEFAULT (now() + interval '4 hours')
);

CREATE INDEX IF NOT EXISTS idx_venue_buzz_venue
  ON venue_buzz (venue_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_venue_buzz_cleanup
  ON venue_buzz (expires_at);

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