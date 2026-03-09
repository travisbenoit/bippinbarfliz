/*
  # Add Music Sharing Features

  1. New Tables
    - music_shares table for sending songs between users
      - id (uuid, primary key)
      - sender_id (uuid, references users)
      - recipient_id (uuid, references users)
      - song_id (text) - External music service song ID
      - song_title (text) - Song name
      - artist_name (text) - Artist name
      - album_art_url (text) - Album artwork URL
      - preview_url (text, nullable) - 30-second preview URL
      - external_url (text) - Full song URL on streaming service
      - platform (text) - spotify, apple_music, youtube_music
      - message (text, nullable) - Personal message with the song
      - status (text) - pending, played, saved, expired
      - swarm_id (uuid, nullable) - If shared with a swarm
      - venue_id (uuid, nullable) - Associated venue
      - created_at (timestamptz)
      - played_at (timestamptz, nullable)
      - expires_at (timestamptz)

  2. Security
    - Enable RLS on music_shares table
    - Add policies for authenticated users to view and create shares
*/

-- Create music_shares table
CREATE TABLE IF NOT EXISTS music_shares (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  recipient_id uuid REFERENCES users(id) ON DELETE CASCADE NOT NULL,
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
  created_at timestamptz DEFAULT now() NOT NULL,
  played_at timestamptz,
  expires_at timestamptz DEFAULT (now() + interval '30 days') NOT NULL
);

-- Enable RLS
ALTER TABLE music_shares ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view music they sent
CREATE POLICY "Users can view music they sent"
  ON music_shares
  FOR SELECT
  TO authenticated
  USING (auth.uid() = sender_id);

-- Policy: Users can view music they received
CREATE POLICY "Users can view music they received"
  ON music_shares
  FOR SELECT
  TO authenticated
  USING (auth.uid() = recipient_id);

-- Policy: Users can send music
CREATE POLICY "Users can send music"
  ON music_shares
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = sender_id);

-- Policy: Recipients can update status
CREATE POLICY "Recipients can update music status"
  ON music_shares
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = recipient_id)
  WITH CHECK (auth.uid() = recipient_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS music_shares_sender_id_idx ON music_shares(sender_id);
CREATE INDEX IF NOT EXISTS music_shares_recipient_id_idx ON music_shares(recipient_id);
CREATE INDEX IF NOT EXISTS music_shares_status_idx ON music_shares(status);
CREATE INDEX IF NOT EXISTS music_shares_created_at_idx ON music_shares(created_at DESC);