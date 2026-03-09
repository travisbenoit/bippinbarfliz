/*
  # Add Safety Features

  1. New Tables
    - `safety_friends`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `friend_name` (text) - Name of the safety contact
      - `friend_phone` (text) - Phone number of the safety contact
      - `created_at` (timestamp)
    - `safety_alerts`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `latitude` (numeric) - Location latitude
      - `longitude` (numeric) - Location longitude
      - `location_url` (text) - Google Maps link
      - `alert_type` (text) - Type of alert (location_share, emergency)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on both tables
    - Users can only access their own safety friends and alerts
*/

CREATE TABLE IF NOT EXISTS safety_friends (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  friend_name text NOT NULL,
  friend_phone text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS safety_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude numeric,
  longitude numeric,
  location_url text,
  alert_type text NOT NULL DEFAULT 'location_share',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE safety_friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own safety friends"
  ON safety_friends
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own safety friends"
  ON safety_friends
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own safety friends"
  ON safety_friends
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own safety friends"
  ON safety_friends
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own safety alerts"
  ON safety_alerts
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own safety alerts"
  ON safety_alerts
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);
