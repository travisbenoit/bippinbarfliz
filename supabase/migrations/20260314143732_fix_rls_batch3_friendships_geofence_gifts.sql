/*
  # Fix RLS batch 3: friendships, geofence_events, gifts, google_api_logs
*/

-- friendships
DROP POLICY IF EXISTS "Users can delete own friendships" ON public.friendships;
DROP POLICY IF EXISTS "Users can respond to friend requests" ON public.friendships;
DROP POLICY IF EXISTS "Users can send friend requests" ON public.friendships;
DROP POLICY IF EXISTS "Users can view their friendships" ON public.friendships;
CREATE POLICY "Users can send friend requests" ON public.friendships FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view their friendships" ON public.friendships FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()) OR friend_id = (SELECT auth.uid()));
CREATE POLICY "Users can respond to friend requests" ON public.friendships FOR UPDATE TO authenticated
  USING (friend_id = (SELECT auth.uid())) WITH CHECK (friend_id = (SELECT auth.uid()));
CREATE POLICY "Users can delete own friendships" ON public.friendships FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()) OR friend_id = (SELECT auth.uid()));

-- geofence_events
DROP POLICY IF EXISTS "System can update processed_at" ON public.geofence_events;
DROP POLICY IF EXISTS "Users can delete own geofence events" ON public.geofence_events;
DROP POLICY IF EXISTS "Users can insert own geofence events" ON public.geofence_events;
DROP POLICY IF EXISTS "Users can read events at their venues" ON public.geofence_events;
DROP POLICY IF EXISTS "Users can read own geofence events" ON public.geofence_events;
CREATE POLICY "Users can insert own geofence events" ON public.geofence_events FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can read own geofence events" ON public.geofence_events FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can read events at their venues" ON public.geofence_events FOR SELECT TO authenticated
  USING (venue_id IN (
    SELECT ge2.venue_id FROM public.geofence_events ge2
    WHERE ge2.user_id = (SELECT auth.uid()) AND ge2.event_type = 'enter'
    AND ge2.triggered_at > now() - interval '24 hours'
  ));
CREATE POLICY "System can update processed_at" ON public.geofence_events FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid())) WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can delete own geofence events" ON public.geofence_events FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- gifts (from_user_id / to_user_id)
DROP POLICY IF EXISTS "Recipients can update their gifts" ON public.gifts;
DROP POLICY IF EXISTS "Users can create gifts" ON public.gifts;
DROP POLICY IF EXISTS "Users can view gifts they received" ON public.gifts;
DROP POLICY IF EXISTS "Users can view gifts they sent" ON public.gifts;
CREATE POLICY "Users can create gifts" ON public.gifts FOR INSERT TO authenticated
  WITH CHECK (from_user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view gifts they sent" ON public.gifts FOR SELECT TO authenticated
  USING (from_user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view gifts they received" ON public.gifts FOR SELECT TO authenticated
  USING (to_user_id = (SELECT auth.uid()));
CREATE POLICY "Recipients can update their gifts" ON public.gifts FOR UPDATE TO authenticated
  USING (to_user_id = (SELECT auth.uid())) WITH CHECK (to_user_id = (SELECT auth.uid()));

-- google_api_logs
DROP POLICY IF EXISTS "Users can view their own API logs" ON public.google_api_logs;
CREATE POLICY "Users can view their own API logs" ON public.google_api_logs FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
