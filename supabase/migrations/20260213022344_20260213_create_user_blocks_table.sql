/*
  # Create User Blocks Table for Blocking Functionality

  ## Overview
  Creates a user blocking system to allow users to block other users from contacting them,
  seeing their profile, or interacting with them in any way. This is a critical safety feature.

  ## New Tables
  
  ### `user_blocks`
  Stores blocked user relationships
  - `id` (uuid, primary key) - Unique block identifier
  - `blocker_id` (uuid, required) - User who is doing the blocking
  - `blocked_id` (uuid, required) - User who is being blocked
  - `reason` (text, nullable) - Optional reason for blocking (for reporting/analytics)
  - `created_at` (timestamptz) - When the block was created

  ## Security
  - Enable RLS on user_blocks table
  - Users can only read their own blocks (who they've blocked)
  - Users cannot see who has blocked them (privacy)
  - Users can insert new blocks
  - Users can delete their own blocks (unblock)
  - No updates allowed (blocks are created or deleted, not modified)

  ## Indexes
  - `idx_user_blocks_blocker_id` - Fast lookups by blocker
  - `idx_user_blocks_blocked_id` - Fast lookups by blocked user
  - Unique constraint on (blocker_id, blocked_id) to prevent duplicate blocks

  ## Notes
  - Blocking should be unidirectional (A blocks B doesn't mean B blocks A)
  - Prevent self-blocking with CHECK constraint
  - When a user is blocked, they should:
    * Not see the blocker's profile or location
    * Not be able to send messages to the blocker
    * Not appear in the blocker's search results
    * Be automatically removed from any shared conversations
  - Consider adding a trigger to remove friendships when blocking occurs
*/

-- Create user_blocks table
CREATE TABLE IF NOT EXISTS user_blocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  blocked_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  
  -- Prevent self-blocking
  CHECK (blocker_id != blocked_id),
  
  -- Ensure uniqueness (can't block same user twice)
  UNIQUE (blocker_id, blocked_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker_id ON user_blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked_id ON user_blocks(blocked_id);

-- Add helpful comment
COMMENT ON TABLE user_blocks IS 'Manages user blocking relationships for safety and privacy, preventing unwanted interactions';

-- Enable Row Level Security
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only read their own blocks (who they've blocked)
-- Important: Users CANNOT see who has blocked them
CREATE POLICY "Users can read own blocks"
  ON user_blocks
  FOR SELECT
  TO authenticated
  USING (auth.uid() = blocker_id);

-- Policy: Users can block other users
CREATE POLICY "Users can create blocks"
  ON user_blocks
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = blocker_id);

-- Policy: No updates allowed (blocks are immutable)
-- Policy: Users can delete their own blocks (unblock)
CREATE POLICY "Users can delete own blocks"
  ON user_blocks
  FOR DELETE
  TO authenticated
  USING (auth.uid() = blocker_id);

-- Function to remove friendships when blocking occurs
CREATE OR REPLACE FUNCTION remove_friendships_on_block()
RETURNS TRIGGER AS $$
BEGIN
  -- Remove both directions of the friendship
  DELETE FROM friendships
  WHERE (user_id = NEW.blocker_id AND friend_id = NEW.blocked_id)
     OR (user_id = NEW.blocked_id AND friend_id = NEW.blocker_id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to remove friendships when blocking
CREATE TRIGGER remove_friendships_on_block_trigger
  AFTER INSERT ON user_blocks
  FOR EACH ROW
  EXECUTE FUNCTION remove_friendships_on_block();

-- Function to prevent interactions between blocked users
-- This can be used in other queries to filter out blocked users
CREATE OR REPLACE FUNCTION is_blocked(p_user_id uuid, p_other_user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_blocks
    WHERE (blocker_id = p_user_id AND blocked_id = p_other_user_id)
       OR (blocker_id = p_other_user_id AND blocked_id = p_user_id)
  );
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION is_blocked IS 'Helper function to check if two users have blocked each other (either direction)';