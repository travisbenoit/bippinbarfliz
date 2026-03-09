/*
  # Create User Activity History Table
  
  1. New Tables
    - `user_activity_history`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references users)
      - `activity_type` (text: 'uber_ride', 'venue_visit', 'swarm_join', 'gift_sent', 'message_sent', 'music_shared')
      - `activity_data` (jsonb: flexible data storage)
      - `location_lat` (numeric, nullable)
      - `location_lng` (numeric, nullable)
      - `venue_id` (uuid, nullable, references venues)
      - `related_user_id` (uuid, nullable, references users)
      - `created_at` (timestamptz)
      
  2. Security
    - Enable RLS on table
    - Users can only view their own activity
    - Users can delete their own activity
    
  3. Indexes
    - Created on user_id, activity_type, created_at for fast queries
*/

CREATE TABLE IF NOT EXISTS user_activity_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_type text NOT NULL CHECK (activity_type IN ('uber_ride', 'venue_visit', 'swarm_join', 'gift_sent', 'message_sent', 'music_shared', 'other')),
  activity_data jsonb NOT NULL DEFAULT '{}',
  location_lat numeric,
  location_lng numeric,
  venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
  related_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE user_activity_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own activity history"
  ON user_activity_history FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own activity history"
  ON user_activity_history FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own activity history"
  ON user_activity_history FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_activity_history_user_id ON user_activity_history(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_history_activity_type ON user_activity_history(activity_type);
CREATE INDEX IF NOT EXISTS idx_activity_history_created_at ON user_activity_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_history_user_created ON user_activity_history(user_id, created_at DESC);
