/*
  # Create Friendships Table for Friend Relationships

  ## Overview
  Creates a bidirectional friendship system to track connections between users.
  This enables features like friend lists, friend requests, location sharing between friends,
  and friend-only visibility settings.

  ## New Tables
  
  ### `friendships`
  Stores friend relationships between users
  - `id` (uuid, primary key) - Unique friendship identifier
  - `user_id` (uuid, required) - User who sent the friend request
  - `friend_id` (uuid, required) - User who received the friend request
  - `status` (text) - Friendship status: 'pending', 'accepted', 'declined', 'blocked'
  - `requested_at` (timestamptz) - When the friend request was sent
  - `responded_at` (timestamptz, nullable) - When the request was accepted/declined
  - `created_at` (timestamptz) - When the record was created
  - `updated_at` (timestamptz) - When the record was last updated

  ## Important Design Decisions
  
  ### Bidirectional Friendships
  When a friendship is accepted, we need BOTH directions to exist in the database:
  - user_id -> friend_id (original request)
  - friend_id -> user_id (reciprocal relationship)
  
  This makes queries much simpler (no need to check both directions) and enables
  efficient friend-based filtering.

  ## Security
  - Enable RLS on friendships table
  - Users can read their own friendships
  - Users can read friendships involving them (incoming requests)
  - Users can insert friend requests (to others)
  - Users can update their own friendship status (accept/decline)
  - Users can delete their own friendships

  ## Indexes
  - `idx_friendships_user_id` - Fast lookups by user
  - `idx_friendships_friend_id` - Fast lookups by friend
  - `idx_friendships_status` - Filter by status
  - Composite index on (user_id, status) for pending requests
  - Unique constraint on (user_id, friend_id) to prevent duplicates

  ## Notes
  - Use triggers to automatically create reciprocal friendship when accepted
  - Prevent self-friendships with CHECK constraint
  - Status transitions: pending -> accepted/declined, accepted -> deleted (unfriend)
*/

-- Create friendships table
CREATE TABLE IF NOT EXISTS friendships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  friend_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
  requested_at timestamptz NOT NULL DEFAULT now(),
  responded_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  
  -- Prevent self-friendships
  CHECK (user_id != friend_id),
  
  -- Ensure uniqueness (can't have duplicate friend requests)
  UNIQUE (user_id, friend_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_friendships_user_id ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_friendships_friend_id ON friendships(friend_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON friendships(status);
CREATE INDEX IF NOT EXISTS idx_friendships_pending ON friendships(user_id, status) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_friendships_accepted ON friendships(user_id, friend_id) WHERE status = 'accepted';

-- Add helpful comment
COMMENT ON TABLE friendships IS 'Manages friend relationships between users, supporting friend requests, acceptance, and bidirectional connections';

-- Enable Row Level Security
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read friendships where they are involved
CREATE POLICY "Users can read own friendships"
  ON friendships
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Policy: Users can send friend requests to others
CREATE POLICY "Users can send friend requests"
  ON friendships
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can accept/decline friend requests sent to them
-- Users can also update their own sent requests (e.g., to cancel)
CREATE POLICY "Users can update friendships involving them"
  ON friendships
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = friend_id)
  WITH CHECK (auth.uid() = user_id OR auth.uid() = friend_id);

-- Policy: Users can delete friendships they're involved in (unfriend)
CREATE POLICY "Users can delete own friendships"
  ON friendships
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_friendships_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on every update
CREATE TRIGGER set_friendships_updated_at
  BEFORE UPDATE ON friendships
  FOR EACH ROW
  EXECUTE FUNCTION update_friendships_updated_at();

-- Function to create reciprocal friendship when accepted
CREATE OR REPLACE FUNCTION create_reciprocal_friendship()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create reciprocal when status changes to 'accepted'
  IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN
    -- Check if reciprocal already exists
    IF NOT EXISTS (
      SELECT 1 FROM friendships 
      WHERE user_id = NEW.friend_id 
        AND friend_id = NEW.user_id
    ) THEN
      -- Create reciprocal friendship
      INSERT INTO friendships (user_id, friend_id, status, requested_at, responded_at)
      VALUES (NEW.friend_id, NEW.user_id, 'accepted', NEW.requested_at, NEW.responded_at);
    ELSE
      -- Update existing reciprocal to accepted
      UPDATE friendships 
      SET status = 'accepted', 
          responded_at = NEW.responded_at,
          updated_at = now()
      WHERE user_id = NEW.friend_id 
        AND friend_id = NEW.user_id;
    END IF;
    
    -- Update responded_at if not already set
    IF NEW.responded_at IS NULL THEN
      NEW.responded_at = now();
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create reciprocal friendship
CREATE TRIGGER create_reciprocal_friendship_trigger
  BEFORE UPDATE ON friendships
  FOR EACH ROW
  EXECUTE FUNCTION create_reciprocal_friendship();

-- Function to delete reciprocal friendship when one is deleted
CREATE OR REPLACE FUNCTION delete_reciprocal_friendship()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete the reciprocal friendship if it exists
  DELETE FROM friendships
  WHERE user_id = OLD.friend_id 
    AND friend_id = OLD.user_id;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger to delete reciprocal friendship
CREATE TRIGGER delete_reciprocal_friendship_trigger
  AFTER DELETE ON friendships
  FOR EACH ROW
  EXECUTE FUNCTION delete_reciprocal_friendship();