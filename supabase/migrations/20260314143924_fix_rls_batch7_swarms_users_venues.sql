/*
  # Fix RLS batch 7: swarm_members, swarms, user_activity_history, user_blocks,
    user_gifts, user_inventory, user_language_preferences, user_venue_presence,
    users, venue_ratings, venue_reports, venue_sessions
*/

-- swarm_members
DROP POLICY IF EXISTS "Swarm members can view swarm rosters" ON public.swarm_members;
DROP POLICY IF EXISTS "Users can join swarms" ON public.swarm_members;
DROP POLICY IF EXISTS "Users can update own membership" ON public.swarm_members;
CREATE POLICY "Users can join swarms" ON public.swarm_members FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Swarm members can view swarm rosters" ON public.swarm_members FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid())
    OR swarm_id IN (SELECT sm2.swarm_id FROM public.swarm_members sm2
      WHERE sm2.user_id = (SELECT auth.uid())));
CREATE POLICY "Users can update own membership" ON public.swarm_members FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- swarms (host_user_id)
DROP POLICY IF EXISTS "Hosts can update swarms" ON public.swarms;
DROP POLICY IF EXISTS "Swarm members and creators can view swarms" ON public.swarms;
DROP POLICY IF EXISTS "Users can create swarms" ON public.swarms;
CREATE POLICY "Users can create swarms" ON public.swarms FOR INSERT TO authenticated
  WITH CHECK (host_user_id = (SELECT auth.uid()));
CREATE POLICY "Swarm members and creators can view swarms" ON public.swarms FOR SELECT TO authenticated
  USING (host_user_id = (SELECT auth.uid())
    OR id IN (SELECT sm.swarm_id FROM public.swarm_members sm WHERE sm.user_id = (SELECT auth.uid())));
CREATE POLICY "Hosts can update swarms" ON public.swarms FOR UPDATE TO authenticated
  USING (host_user_id = (SELECT auth.uid())) WITH CHECK (host_user_id = (SELECT auth.uid()));

-- user_activity_history
DROP POLICY IF EXISTS "Users can create own activity history" ON public.user_activity_history;
DROP POLICY IF EXISTS "Users can delete own activity history" ON public.user_activity_history;
DROP POLICY IF EXISTS "Users can view own activity history" ON public.user_activity_history;
CREATE POLICY "Users can create own activity history" ON public.user_activity_history FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view own activity history" ON public.user_activity_history FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can delete own activity history" ON public.user_activity_history FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- user_blocks
DROP POLICY IF EXISTS "Blocked users can see they are blocked" ON public.user_blocks;
DROP POLICY IF EXISTS "Users can create blocks" ON public.user_blocks;
DROP POLICY IF EXISTS "Users can delete own blocks" ON public.user_blocks;
CREATE POLICY "Users can create blocks" ON public.user_blocks FOR INSERT TO authenticated
  WITH CHECK (blocker_id = (SELECT auth.uid()));
CREATE POLICY "Users can delete own blocks" ON public.user_blocks FOR DELETE TO authenticated
  USING (blocker_id = (SELECT auth.uid()));
CREATE POLICY "Blocked users can see they are blocked" ON public.user_blocks FOR SELECT TO authenticated
  USING (blocker_id = (SELECT auth.uid()) OR blocked_id = (SELECT auth.uid()));

-- user_gifts
DROP POLICY IF EXISTS "Recipients can update gift status" ON public.user_gifts;
DROP POLICY IF EXISTS "Users can send gifts" ON public.user_gifts;
DROP POLICY IF EXISTS "Users can view gifts they received" ON public.user_gifts;
DROP POLICY IF EXISTS "Users can view gifts they sent" ON public.user_gifts;
CREATE POLICY "Users can send gifts" ON public.user_gifts FOR INSERT TO authenticated
  WITH CHECK (from_user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view gifts they sent" ON public.user_gifts FOR SELECT TO authenticated
  USING (from_user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view gifts they received" ON public.user_gifts FOR SELECT TO authenticated
  USING (to_user_id = (SELECT auth.uid()));
CREATE POLICY "Recipients can update gift status" ON public.user_gifts FOR UPDATE TO authenticated
  USING (to_user_id = (SELECT auth.uid())) WITH CHECK (to_user_id = (SELECT auth.uid()));

-- user_inventory
DROP POLICY IF EXISTS "Users can manage own inventory" ON public.user_inventory;
DROP POLICY IF EXISTS "Users can update own inventory" ON public.user_inventory;
DROP POLICY IF EXISTS "Users can view own inventory" ON public.user_inventory;
CREATE POLICY "Users can manage own inventory" ON public.user_inventory FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view own inventory" ON public.user_inventory FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can update own inventory" ON public.user_inventory FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid())) WITH CHECK (user_id = (SELECT auth.uid()));

-- user_language_preferences
DROP POLICY IF EXISTS "Users can insert own language preferences" ON public.user_language_preferences;
DROP POLICY IF EXISTS "Users can read own language preferences" ON public.user_language_preferences;
DROP POLICY IF EXISTS "Users can update own language preferences" ON public.user_language_preferences;
CREATE POLICY "Users can insert own language preferences" ON public.user_language_preferences FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can read own language preferences" ON public.user_language_preferences FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can update own language preferences" ON public.user_language_preferences FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid())) WITH CHECK (user_id = (SELECT auth.uid()));

-- user_venue_presence
DROP POLICY IF EXISTS "Users can view own presence" ON public.user_venue_presence;
DROP POLICY IF EXISTS "Users can view presence of mutual friends and swarm members" ON public.user_venue_presence;
CREATE POLICY "Users can view own presence" ON public.user_venue_presence FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view presence of mutual friends and swarm members" ON public.user_venue_presence FOR SELECT TO authenticated
  USING (
    is_visible_in_venue = true AND status = 'IN_VENUE' AND left_at IS NULL
    AND last_seen_at > now() - interval '24 hours'
    AND (
      EXISTS (SELECT 1 FROM public.friendships f WHERE f.status = 'accepted'
        AND ((f.user_id = (SELECT auth.uid()) AND f.friend_id = user_venue_presence.user_id)
          OR (f.friend_id = (SELECT auth.uid()) AND f.user_id = user_venue_presence.user_id)))
      OR EXISTS (
        SELECT 1 FROM public.swarm_members sm1
        JOIN public.swarm_members sm2 ON sm1.swarm_id = sm2.swarm_id
        JOIN public.swarms s ON s.id = sm1.swarm_id
        WHERE sm1.user_id = (SELECT auth.uid())
        AND sm2.user_id = user_venue_presence.user_id
        AND s.status = ANY(ARRAY['active','ongoing'])
      )
    )
  );

-- users
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users visible to others respecting ghost and privacy mode" ON public.users;
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT TO authenticated
  WITH CHECK (id = (SELECT auth.uid()));
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT TO authenticated
  USING (id = (SELECT auth.uid()));
CREATE POLICY "Users visible to others respecting ghost and privacy mode" ON public.users FOR SELECT TO authenticated
  USING (
    id = (SELECT auth.uid())
    OR ((ghost_mode IS NULL OR ghost_mode = false)
        AND (privacy_mode IS NULL OR privacy_mode != 'invisible'))
  );
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE TO authenticated
  USING (id = (SELECT auth.uid())) WITH CHECK (id = (SELECT auth.uid()));

-- venue_ratings
DROP POLICY IF EXISTS "Users can delete own ratings" ON public.venue_ratings;
DROP POLICY IF EXISTS "Users can insert own ratings" ON public.venue_ratings;
DROP POLICY IF EXISTS "Users can update own ratings" ON public.venue_ratings;
DROP POLICY IF EXISTS "Users can view friend ratings" ON public.venue_ratings;
CREATE POLICY "Users can insert own ratings" ON public.venue_ratings FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view friend ratings" ON public.venue_ratings FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid())
    OR EXISTS (SELECT 1 FROM public.friendships f WHERE f.status = 'accepted'
      AND ((f.user_id = (SELECT auth.uid()) AND f.friend_id = venue_ratings.user_id)
        OR (f.friend_id = (SELECT auth.uid()) AND f.user_id = venue_ratings.user_id))));
CREATE POLICY "Users can update own ratings" ON public.venue_ratings FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid())) WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can delete own ratings" ON public.venue_ratings FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- venue_reports
DROP POLICY IF EXISTS "Users can create reports" ON public.venue_reports;
DROP POLICY IF EXISTS "Users can delete own pending reports" ON public.venue_reports;
DROP POLICY IF EXISTS "Users can read own reports" ON public.venue_reports;
DROP POLICY IF EXISTS "Users can update own pending reports" ON public.venue_reports;
CREATE POLICY "Users can create reports" ON public.venue_reports FOR INSERT TO authenticated
  WITH CHECK (reporter_id = (SELECT auth.uid()));
CREATE POLICY "Users can read own reports" ON public.venue_reports FOR SELECT TO authenticated
  USING (reporter_id = (SELECT auth.uid()));
CREATE POLICY "Users can update own pending reports" ON public.venue_reports FOR UPDATE TO authenticated
  USING (reporter_id = (SELECT auth.uid()) AND status = 'pending')
  WITH CHECK (reporter_id = (SELECT auth.uid()));
CREATE POLICY "Users can delete own pending reports" ON public.venue_reports FOR DELETE TO authenticated
  USING (reporter_id = (SELECT auth.uid()) AND status = 'pending');

-- venue_sessions (uses status='open')
DROP POLICY IF EXISTS "Users can view sessions at bars they're at" ON public.venue_sessions;
DROP POLICY IF EXISTS "Users can view their own sessions" ON public.venue_sessions;
CREATE POLICY "Users can view their own sessions" ON public.venue_sessions FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view sessions at bars they're at" ON public.venue_sessions FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.venue_sessions vs
    WHERE vs.user_id = (SELECT auth.uid())
    AND vs.bar_id = venue_sessions.bar_id
    AND vs.status = 'open'));
