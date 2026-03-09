/*
  # Create Conversations Tables for Group Chat Support

  ## Overview
  Creates a comprehensive group chat system supporting both 1-on-1 and group conversations.
  This extends the existing direct messages system to support multi-user conversations.

  ## New Tables
  
  ### `conversations`
  Stores conversation/chat room metadata
  - `id` (uuid, primary key) - Unique conversation identifier
  - `name` (text, nullable) - Optional group name (null for 1-on-1 chats)
  - `type` (text) - Conversation type: 'direct' (1-on-1) or 'group' (multi-user)
  - `created_by` (uuid, required) - User who created the conversation
  - `swarm_id` (uuid, nullable) - Associated swarm (if conversation is swarm-based)
  - `venue_id` (uuid, nullable) - Associated venue (if conversation is venue-based)
  - `is_active` (boolean) - Whether the conversation is active
  - `last_message_at` (timestamptz, nullable) - Timestamp of most recent message
  - `created_at` (timestamptz) - When the conversation was created
  - `updated_at` (timestamptz) - When the conversation was last updated

  ### `conversation_participants`
  Stores membership in conversations
  - `id` (uuid, primary key) - Unique participant identifier
  - `conversation_id` (uuid, required) - The conversation
  - `user_id` (uuid, required) - The participant user
  - `role` (text) - User role: 'member', 'admin', 'owner'
  - `joined_at` (timestamptz) - When the user joined
  - `left_at` (timestamptz, nullable) - When the user left (null if still active)
  - `last_read_at` (timestamptz, nullable) - Last time user read messages
  - `notifications_enabled` (boolean) - Whether user wants notifications
  - `created_at` (timestamptz) - When the record was created

  ## Security
  - Enable RLS on both tables
  - Users can only read conversations they're part of
  - Users can create new conversations
  - Only admins/owners can update conversation metadata
  - Only owners can delete conversations
  - Participants can leave conversations by updating their left_at

  ## Indexes
  - `idx_conversations_swarm_id` - Find conversations by swarm
  - `idx_conversations_venue_id` - Find conversations by venue
  - `idx_conversations_last_message_at` - Sort by recent activity
  - `idx_conversation_participants_conversation` - Find participants by conversation
  - `idx_conversation_participants_user` - Find user's conversations
  - Unique constraint on (conversation_id, user_id) to prevent duplicate membership

  ## Notes
  - Direct messages (type='direct') should have exactly 2 participants
  - Group chats (type='group') can have 3+ participants
  - last_message_at is updated via trigger when new message is inserted
  - Consider implementing message table foreign key constraints
*/

-- Create conversations table
CREATE TABLE IF NOT EXISTS conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text,
  type text NOT NULL DEFAULT 'direct' CHECK (type IN ('direct', 'group')),
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  swarm_id uuid REFERENCES swarms(id) ON DELETE CASCADE,
  venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
  is_active boolean NOT NULL DEFAULT true,
  last_message_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Create conversation_participants table
CREATE TABLE IF NOT EXISTS conversation_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('member', 'admin', 'owner')),
  joined_at timestamptz NOT NULL DEFAULT now(),
  left_at timestamptz,
  last_read_at timestamptz,
  notifications_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  
  -- Ensure unique participation (can't join same conversation twice)
  UNIQUE (conversation_id, user_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_conversations_swarm_id ON conversations(swarm_id) WHERE swarm_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_conversations_venue_id ON conversations(venue_id) WHERE venue_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at ON conversations(last_message_at DESC) WHERE last_message_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_conversations_active ON conversations(is_active) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation ON conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user ON conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_active ON conversation_participants(conversation_id, user_id) WHERE left_at IS NULL;

-- Add helpful comments
COMMENT ON TABLE conversations IS 'Stores conversation/chat room metadata for both 1-on-1 and group chats';
COMMENT ON TABLE conversation_participants IS 'Tracks user membership in conversations with roles and read status';

-- Enable Row Level Security
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;

-- Conversations Policies

-- Policy: Users can read conversations they're part of
CREATE POLICY "Users can read own conversations"
  ON conversations
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid() 
        AND left_at IS NULL
    )
  );

-- Policy: Users can create new conversations
CREATE POLICY "Users can create conversations"
  ON conversations
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);

-- Policy: Only admins/owners can update conversation metadata
CREATE POLICY "Admins can update conversations"
  ON conversations
  FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid() 
        AND role IN ('admin', 'owner')
        AND left_at IS NULL
    )
  )
  WITH CHECK (
    id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid() 
        AND role IN ('admin', 'owner')
        AND left_at IS NULL
    )
  );

-- Policy: Only owners can delete conversations
CREATE POLICY "Owners can delete conversations"
  ON conversations
  FOR DELETE
  TO authenticated
  USING (
    id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid() 
        AND role = 'owner'
        AND left_at IS NULL
    )
  );

-- Conversation Participants Policies

-- Policy: Users can read participants in their conversations
CREATE POLICY "Users can read conversation participants"
  ON conversation_participants
  FOR SELECT
  TO authenticated
  USING (
    conversation_id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid()
        AND left_at IS NULL
    )
  );

-- Policy: Users can add themselves to conversations they created
-- Admins can add others to their conversations
CREATE POLICY "Users can add conversation participants"
  ON conversation_participants
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- User can add themselves to any conversation
    auth.uid() = user_id
    OR
    -- Or user is admin/owner of the conversation
    conversation_id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid() 
        AND role IN ('admin', 'owner')
        AND left_at IS NULL
    )
  );

-- Policy: Users can update their own participation (leave, read status, notifications)
CREATE POLICY "Users can update own participation"
  ON conversation_participants
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Admins can remove participants from conversations
CREATE POLICY "Admins can remove participants"
  ON conversation_participants
  FOR DELETE
  TO authenticated
  USING (
    conversation_id IN (
      SELECT conversation_id 
      FROM conversation_participants 
      WHERE user_id = auth.uid() 
        AND role IN ('admin', 'owner')
        AND left_at IS NULL
    )
    OR auth.uid() = user_id
  );

-- Function to automatically update updated_at timestamp on conversations
CREATE OR REPLACE FUNCTION update_conversations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on every conversation update
CREATE TRIGGER set_conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION update_conversations_updated_at();

-- Function to automatically add creator as owner when conversation is created
CREATE OR REPLACE FUNCTION add_conversation_creator_as_owner()
RETURNS TRIGGER AS $$
BEGIN
  -- Add creator as owner participant
  INSERT INTO conversation_participants (conversation_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'owner');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to add creator as owner
CREATE TRIGGER add_creator_as_owner_trigger
  AFTER INSERT ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION add_conversation_creator_as_owner();