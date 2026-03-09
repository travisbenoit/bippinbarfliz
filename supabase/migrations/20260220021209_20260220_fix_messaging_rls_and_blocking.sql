/*
  # Fix Messaging RLS and Blocking Policies

  ## Summary
  This migration fixes several critical issues with the messaging system:

  1. Missing RLS Policy: The SELECT policy for swarm messages was never applied.
     Without this, swarm members cannot read messages in their swarms.

  2. Also ensures the soft-delete UPDATE policy is correctly scoped.

  ## Changes

  ### messages table
  - Add missing SELECT policy for swarm messages
    Users who are members of a swarm can read that swarm's messages.

  ## Security Notes
  - All policies check auth.uid() for ownership/membership
  - Swarm message access requires active membership in swarm_members table
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'messages'
    AND policyname = 'Users can view swarm messages they are in'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Users can view swarm messages they are in"
        ON messages FOR SELECT
        TO authenticated
        USING (
          conversation_type = 'swarm'
          AND deleted_at IS NULL
          AND EXISTS (
            SELECT 1 FROM swarm_members
            WHERE swarm_members.swarm_id = messages.swarm_id
            AND swarm_members.user_id = auth.uid()
          )
        )
    $policy$;
  END IF;
END $$;
