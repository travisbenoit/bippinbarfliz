/*
  # Create music_shares table

  1. New Tables
    - `music_shares`
      - `id` (uuid, primary key) - unique share identifier
      - `sender_id` (uuid, FK to users) - who shared the music
      - `recipient_id` (uuid, FK to users) - who receives the share
      - `song_id` (text) - external song identifier
      - `song_title` (text) - display title of the song
      - `artist_name` (text) - artist name
      - `album_art_url` (text, nullable) - album artwork URL
      - `preview_url` (text, nullable) - audio preview URL
      - `external_url` (text) - link to play the song
      - `platform` (text) - music platform (spotify, apple_music, youtube_music)
      - `message` (text, nullable) - personal message with the share
      - `status` (text) - pending, played, saved, or expired
      - `swarm_id` (uuid, nullable, FK to swarms) - shared in a swarm context
      - `venue_id` (uuid, nullable, FK to venues) - shared at a venue
      - `played_at` (timestamptz, nullable) - when the recipient played it
      - `expires_at` (timestamptz) - auto-expiry after 30 days
      - `created_at` (timestamptz) - share timestamp

  2. Security
    - RLS enabled
    - Users can view music they sent or received
    - Users can send music (insert as sender)
    - Recipients can update music status
    - Senders can delete their shares

  3. Indexes
    - sender_id, recipient_id, status, created_at for efficient queries
*/

CREATE TABLE IF NOT EXISTS music_shares (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  song_id text NOT NULL,
  song_title text NOT NULL,
  artist_name text NOT NULL,
  album_art_url text,
  preview_url text,
  external_url text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('spotify', 'apple_music', 'youtube_music')),
  message text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'played', 'saved', 'expired')),
  swarm_id uuid REFERENCES swarms(id) ON DELETE SET NULL,
  venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
  played_at timestamptz,
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '30 days'),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE music_shares ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view music they sent"
  ON music_shares FOR SELECT
  TO authenticated
  USING (auth.uid() = sender_id);

CREATE POLICY "Users can view music they received"
  ON music_shares FOR SELECT
  TO authenticated
  USING (auth.uid() = recipient_id);

CREATE POLICY "Users can send music"
  ON music_shares FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Recipients can update music status"
  ON music_shares FOR UPDATE
  TO authenticated
  USING (auth.uid() = recipient_id)
  WITH CHECK (auth.uid() = recipient_id);

CREATE POLICY "Senders can delete their shares"
  ON music_shares FOR DELETE
  TO authenticated
  USING (auth.uid() = sender_id);

CREATE INDEX IF NOT EXISTS idx_music_shares_sender ON music_shares(sender_id);
CREATE INDEX IF NOT EXISTS idx_music_shares_recipient ON music_shares(recipient_id);
CREATE INDEX IF NOT EXISTS idx_music_shares_status ON music_shares(status);
CREATE INDEX IF NOT EXISTS idx_music_shares_created ON music_shares(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_music_shares_swarm ON music_shares(swarm_id) WHERE swarm_id IS NOT NULL;
