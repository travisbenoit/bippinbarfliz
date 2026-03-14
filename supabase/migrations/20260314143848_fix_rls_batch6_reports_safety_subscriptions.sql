/*
  # Fix RLS batch 6: reports, safe_arrivals, safety_alerts, safety_friends, subscriptions
*/

-- reports
DROP POLICY IF EXISTS "Users can create reports" ON public.reports;
DROP POLICY IF EXISTS "Users can view own reports" ON public.reports;
CREATE POLICY "Users can create reports" ON public.reports FOR INSERT TO authenticated
  WITH CHECK (reporter_user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view own reports" ON public.reports FOR SELECT TO authenticated
  USING (reporter_user_id = (SELECT auth.uid()));

-- safe_arrivals
DROP POLICY IF EXISTS "Users can create own safe arrivals" ON public.safe_arrivals;
DROP POLICY IF EXISTS "Users can view own and friends safe arrivals" ON public.safe_arrivals;
CREATE POLICY "Users can create own safe arrivals" ON public.safe_arrivals FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view own and friends safe arrivals" ON public.safe_arrivals FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid())
    OR EXISTS (SELECT 1 FROM public.friendships f WHERE f.status = 'accepted'
      AND ((f.user_id = (SELECT auth.uid()) AND f.friend_id = safe_arrivals.user_id)
        OR (f.friend_id = (SELECT auth.uid()) AND f.user_id = safe_arrivals.user_id))));

-- safety_alerts
DROP POLICY IF EXISTS "Users can insert own safety alerts" ON public.safety_alerts;
DROP POLICY IF EXISTS "Users can view own safety alerts" ON public.safety_alerts;
CREATE POLICY "Users can insert own safety alerts" ON public.safety_alerts FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view own safety alerts" ON public.safety_alerts FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- safety_friends
DROP POLICY IF EXISTS "Users can delete own safety friends" ON public.safety_friends;
DROP POLICY IF EXISTS "Users can insert own safety friends" ON public.safety_friends;
DROP POLICY IF EXISTS "Users can update own safety friends" ON public.safety_friends;
DROP POLICY IF EXISTS "Users can view own safety friends" ON public.safety_friends;
CREATE POLICY "Users can insert own safety friends" ON public.safety_friends FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view own safety friends" ON public.safety_friends FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can update own safety friends" ON public.safety_friends FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid())) WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can delete own safety friends" ON public.safety_friends FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- subscriptions
DROP POLICY IF EXISTS "Users can create own subscriptions" ON public.subscriptions;
DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.subscriptions;
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can create own subscriptions" ON public.subscriptions FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view own subscriptions" ON public.subscriptions FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can update own subscriptions" ON public.subscriptions FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid())) WITH CHECK (user_id = (SELECT auth.uid()));
