/*
  # Fix All Security Advisor Issues

  ## Summary
  Resolves all issues flagged by the Supabase Security Advisor:

  1. notifications — Fix INSERT policy that allows any authenticated user to insert
     notifications for any recipient. Restrict to service_role only.

  2. users — Remove old permissive USING(true) SELECT policy superseded by the
     ghost-mode-aware policy.

  3. messages — Remove 8 duplicate INSERT/SELECT/UPDATE policies, keeping one clean
     policy per operation.

  4. friendships — Remove 3 duplicate SELECT/UPDATE/DELETE policies.

  5. emoji_reactions — Remove 5 duplicate INSERT/DELETE/SELECT policies.

  6. user_blocks — Remove duplicate SELECT policy.

  7. user_gifts — Remove duplicate UPDATE policy.

  8. swarm_members — Replace USING(true) SELECT with scoped members-only visibility.

  9. swarms — Replace USING(true) SELECT with creator + member visibility.

  10. user_venue_presence — Remove overly-broad USING(true) SELECT policy.
*/

-- ============================================================
-- 1. NOTIFICATIONS — fix INSERT that allows any user to target anyone
-- ============================================================
DROP POLICY IF EXISTS "Service can insert notifications" ON public.notifications;

CREATE POLICY "Service role can insert notifications"
  ON public.notifications
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- ============================================================
-- 2. USERS — remove the open USING(true) SELECT policy
-- ============================================================
DROP POLICY IF EXISTS "Users can view other profiles" ON public.users;

-- ============================================================
-- 3. MESSAGES — remove duplicate policies
-- ============================================================
DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
DROP POLICY IF EXISTS "Users can send DM messages" ON public.messages;
DROP POLICY IF EXISTS "Users can send swarm messages" ON public.messages;

DROP POLICY IF EXISTS "Users can view messages in swarms they are part of" ON public.messages;
DROP POLICY IF EXISTS "Users can view messages in their DMs" ON public.messages;
DROP POLICY IF EXISTS "Users can view own direct messages" ON public.messages;
DROP POLICY IF EXISTS "Users can view swarm messages they are in" ON public.messages;
DROP POLICY IF EXISTS "Users can view swarm messages they're in" ON public.messages;

DROP POLICY IF EXISTS "Users can update messages" ON public.messages;
DROP POLICY IF EXISTS "Users can update own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can mark messages as read" ON public.messages;

-- Recreate clean, consolidated UPDATE policies
CREATE POLICY "Users can mark DM messages as read"
  ON public.messages
  FOR UPDATE
  TO authenticated
  USING (
    conversation_type = 'dm'
    AND (auth.uid() = dm_user_a OR auth.uid() = dm_user_b)
  )
  WITH CHECK (
    conversation_type = 'dm'
    AND (auth.uid() = dm_user_a OR auth.uid() = dm_user_b)
  );

-- ============================================================
-- 4. FRIENDSHIPS — remove duplicates
-- ============================================================
DROP POLICY IF EXISTS "Users can read own friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can update friendships involving them" ON public.friendships;
DROP POLICY IF EXISTS "Users can remove friendships" ON public.friendships;

-- ============================================================
-- 5. EMOJI REACTIONS — remove duplicates
-- ============================================================
DROP POLICY IF EXISTS "Users can add reactions" ON public.emoji_reactions;
DROP POLICY IF EXISTS "Users can remove their reactions" ON public.emoji_reactions;
DROP POLICY IF EXISTS "Users can view all reactions" ON public.emoji_reactions;

-- ============================================================
-- 6. USER_BLOCKS — remove duplicate SELECT policy
-- ============================================================
DROP POLICY IF EXISTS "Users can read own blocks" ON public.user_blocks;

-- ============================================================
-- 7. USER_GIFTS — remove duplicate UPDATE policy
-- ============================================================
DROP POLICY IF EXISTS "Recipients can update received gifts" ON public.user_gifts;

-- ============================================================
-- 8. SWARM_MEMBERS — replace USING(true) with scoped visibility
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view swarm members" ON public.swarm_members;

CREATE POLICY "Swarm members can view swarm rosters"
  ON public.swarm_members
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id
    OR swarm_id IN (
      SELECT swarm_id FROM public.swarm_members sm2 WHERE sm2.user_id = auth.uid()
    )
  );

-- ============================================================
-- 9. SWARMS — replace USING(true) with creator + member visibility
-- ============================================================
DROP POLICY IF EXISTS "Anyone can view active swarms" ON public.swarms;

CREATE POLICY "Swarm members and creators can view swarms"
  ON public.swarms
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = host_user_id
    OR id IN (
      SELECT swarm_id FROM public.swarm_members WHERE user_id = auth.uid()
    )
  );

-- ============================================================
-- 10. USER_VENUE_PRESENCE — remove overly-broad USING(true) SELECT
-- ============================================================
DROP POLICY IF EXISTS "Users can view visible presence of others" ON public.user_venue_presence;
