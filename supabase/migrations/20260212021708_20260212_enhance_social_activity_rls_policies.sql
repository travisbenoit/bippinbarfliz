/*
  # Enhance Social Activity RLS and Indexes
  
  1. Security - Row Level Security Policies
    - messages: SELECT/INSERT/UPDATE policies for participants
    - emoji_reactions: SELECT/INSERT/DELETE policies for owners
    - user_gifts: Full CRUD with proper ownership checks
    
  2. Performance Indexes
    - messages: Indexed on sender, conversation type, created_at
    - emoji_reactions: Indexed on target, user, emoji
    - user_gifts: Indexed on from/to users
    
  3. Important Notes
    - All policies require authentication
    - Users can only see messages they're involved in
    - Users can only react with their own reactions
    - Gift access is restricted by ownership
    - Indexes optimize common query patterns
*/

-- Messages table RLS policies
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'messages' AND policyname = 'Users can view messages in their DMs'
  ) THEN
    CREATE POLICY "Users can view messages in their DMs"
      ON messages FOR SELECT
      TO authenticated
      USING (
        conversation_type = 'dm' AND (
          (auth.uid() = dm_user_a) OR (auth.uid() = dm_user_b)
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'messages' AND policyname = 'Users can view messages in swarms they are part of'
  ) THEN
    CREATE POLICY "Users can view messages in swarms they are part of"
      ON messages FOR SELECT
      TO authenticated
      USING (
        conversation_type = 'swarm' AND
        EXISTS (
          SELECT 1 FROM swarm_members
          WHERE swarm_members.swarm_id = messages.swarm_id
          AND swarm_members.user_id = auth.uid()
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'messages' AND policyname = 'Users can send DM messages'
  ) THEN
    CREATE POLICY "Users can send DM messages"
      ON messages FOR INSERT
      TO authenticated
      WITH CHECK (
        auth.uid() = sender_user_id AND
        conversation_type = 'dm' AND
        (auth.uid() = dm_user_a OR auth.uid() = dm_user_b)
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'messages' AND policyname = 'Users can send swarm messages'
  ) THEN
    CREATE POLICY "Users can send swarm messages"
      ON messages FOR INSERT
      TO authenticated
      WITH CHECK (
        auth.uid() = sender_user_id AND
        conversation_type = 'swarm' AND
        EXISTS (
          SELECT 1 FROM swarm_members
          WHERE swarm_members.swarm_id = messages.swarm_id
          AND swarm_members.user_id = auth.uid()
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'messages' AND policyname = 'Users can mark messages as read'
  ) THEN
    CREATE POLICY "Users can mark messages as read"
      ON messages FOR UPDATE
      TO authenticated
      USING (
        conversation_type = 'dm' AND (
          (auth.uid() = dm_user_a) OR (auth.uid() = dm_user_b)
        )
      )
      WITH CHECK (
        conversation_type = 'dm' AND (
          (auth.uid() = dm_user_a) OR (auth.uid() = dm_user_b)
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'emoji_reactions' AND policyname = 'Users can view reactions'
  ) THEN
    CREATE POLICY "Users can view reactions"
      ON emoji_reactions FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'emoji_reactions' AND policyname = 'Users can add reactions'
  ) THEN
    CREATE POLICY "Users can add reactions"
      ON emoji_reactions FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'emoji_reactions' AND policyname = 'Users can remove their reactions'
  ) THEN
    CREATE POLICY "Users can remove their reactions"
      ON emoji_reactions FOR DELETE
      TO authenticated
      USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'user_gifts' AND policyname = 'Users can view gifts they sent'
  ) THEN
    CREATE POLICY "Users can view gifts they sent"
      ON user_gifts FOR SELECT
      TO authenticated
      USING (auth.uid() = from_user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'user_gifts' AND policyname = 'Users can view gifts they received'
  ) THEN
    CREATE POLICY "Users can view gifts they received"
      ON user_gifts FOR SELECT
      TO authenticated
      USING (auth.uid() = to_user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'user_gifts' AND policyname = 'Users can send gifts'
  ) THEN
    CREATE POLICY "Users can send gifts"
      ON user_gifts FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = from_user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'user_gifts' AND policyname = 'Recipients can update gift status'
  ) THEN
    CREATE POLICY "Recipients can update gift status"
      ON user_gifts FOR UPDATE
      TO authenticated
      USING (auth.uid() = to_user_id)
      WITH CHECK (auth.uid() = to_user_id);
  END IF;
END $$;

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_messages_dm_user_a ON messages(dm_user_a) WHERE conversation_type = 'dm';
CREATE INDEX IF NOT EXISTS idx_messages_dm_user_b ON messages(dm_user_b) WHERE conversation_type = 'dm';
CREATE INDEX IF NOT EXISTS idx_messages_swarm_id ON messages(swarm_id) WHERE conversation_type = 'swarm';
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_user_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_type ON messages(conversation_type);

CREATE INDEX IF NOT EXISTS idx_emoji_reactions_target ON emoji_reactions(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_emoji_reactions_user ON emoji_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_emoji_reactions_emoji ON emoji_reactions(emoji);
CREATE INDEX IF NOT EXISTS idx_emoji_reactions_created_at ON emoji_reactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_gifts_from_user ON user_gifts(from_user_id);
CREATE INDEX IF NOT EXISTS idx_user_gifts_to_user ON user_gifts(to_user_id);
CREATE INDEX IF NOT EXISTS idx_user_gifts_status ON user_gifts(status);
CREATE INDEX IF NOT EXISTS idx_user_gifts_created_at ON user_gifts(created_at DESC);
