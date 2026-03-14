/*
  # Fix RLS batch 1: activity_feed, blocks, check_in_streaks, cheers
  Replace auth.uid() with (SELECT auth.uid()) for performance and security.
*/

-- activity_feed (actor_user_id)
DROP POLICY IF EXISTS "Users can insert their own activity" ON public.activity_feed;
DROP POLICY IF EXISTS "Users can view activity of their friends" ON public.activity_feed;
CREATE POLICY "Users can insert their own activity" ON public.activity_feed FOR INSERT TO authenticated
  WITH CHECK (actor_user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view activity of their friends" ON public.activity_feed FOR SELECT TO authenticated
  USING (
    actor_user_id = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.friendships f WHERE f.status = 'accepted'
      AND ((f.user_id = (SELECT auth.uid()) AND f.friend_id = activity_feed.actor_user_id)
        OR (f.friend_id = (SELECT auth.uid()) AND f.user_id = activity_feed.actor_user_id))
    )
  );

-- blocks (blocker_user_id / blocked_user_id)
DROP POLICY IF EXISTS "Users can create blocks" ON public.blocks;
DROP POLICY IF EXISTS "Users can delete own blocks" ON public.blocks;
DROP POLICY IF EXISTS "Users can view own blocks" ON public.blocks;
CREATE POLICY "Users can create blocks" ON public.blocks FOR INSERT TO authenticated
  WITH CHECK (blocker_user_id = (SELECT auth.uid()));
CREATE POLICY "Users can delete own blocks" ON public.blocks FOR DELETE TO authenticated
  USING (blocker_user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view own blocks" ON public.blocks FOR SELECT TO authenticated
  USING (blocker_user_id = (SELECT auth.uid()));

-- check_in_streaks
DROP POLICY IF EXISTS "Users can insert own streak" ON public.check_in_streaks;
DROP POLICY IF EXISTS "Users can update own streak" ON public.check_in_streaks;
DROP POLICY IF EXISTS "Users can view friend streaks" ON public.check_in_streaks;
CREATE POLICY "Users can insert own streak" ON public.check_in_streaks FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can update own streak" ON public.check_in_streaks FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid())) WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view friend streaks" ON public.check_in_streaks FOR SELECT TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.friendships f WHERE f.status = 'accepted'
      AND ((f.user_id = (SELECT auth.uid()) AND f.friend_id = check_in_streaks.user_id)
        OR (f.friend_id = (SELECT auth.uid()) AND f.user_id = check_in_streaks.user_id))
    )
  );

-- cheers
DROP POLICY IF EXISTS "Users can send cheers" ON public.cheers;
DROP POLICY IF EXISTS "Users can view own cheers" ON public.cheers;
CREATE POLICY "Users can send cheers" ON public.cheers FOR INSERT TO authenticated
  WITH CHECK (sender_id = (SELECT auth.uid()));
CREATE POLICY "Users can view own cheers" ON public.cheers FOR SELECT TO authenticated
  USING (sender_id = (SELECT auth.uid()) OR recipient_id = (SELECT auth.uid()));
