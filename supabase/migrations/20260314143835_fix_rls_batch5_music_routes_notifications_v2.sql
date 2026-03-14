/*
  # Fix RLS batch 5: music_shares, night_route_invites, night_routes, notifications, payment_transactions
*/

-- music_shares
DROP POLICY IF EXISTS "Recipients can update music status" ON public.music_shares;
DROP POLICY IF EXISTS "Users can send music" ON public.music_shares;
DROP POLICY IF EXISTS "Users can view music they received" ON public.music_shares;
DROP POLICY IF EXISTS "Users can view music they sent" ON public.music_shares;
CREATE POLICY "Users can send music" ON public.music_shares FOR INSERT TO authenticated
  WITH CHECK (sender_id = (SELECT auth.uid()));
CREATE POLICY "Users can view music they sent" ON public.music_shares FOR SELECT TO authenticated
  USING (sender_id = (SELECT auth.uid()));
CREATE POLICY "Users can view music they received" ON public.music_shares FOR SELECT TO authenticated
  USING (recipient_id = (SELECT auth.uid()));
CREATE POLICY "Recipients can update music status" ON public.music_shares FOR UPDATE TO authenticated
  USING (recipient_id = (SELECT auth.uid())) WITH CHECK (recipient_id = (SELECT auth.uid()));

-- night_route_invites (column is user_id)
DROP POLICY IF EXISTS "Invited users can update invite status" ON public.night_route_invites;
DROP POLICY IF EXISTS "Route creators can send invites" ON public.night_route_invites;
DROP POLICY IF EXISTS "Users can view invites they sent or received" ON public.night_route_invites;
CREATE POLICY "Route creators can send invites" ON public.night_route_invites FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.night_routes nr
    WHERE nr.id = night_route_invites.route_id AND nr.creator_id = (SELECT auth.uid())));
CREATE POLICY "Users can view invites they sent or received" ON public.night_route_invites FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid())
    OR EXISTS (SELECT 1 FROM public.night_routes nr
      WHERE nr.id = night_route_invites.route_id AND nr.creator_id = (SELECT auth.uid())));
CREATE POLICY "Invited users can update invite status" ON public.night_route_invites FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid())) WITH CHECK (user_id = (SELECT auth.uid()));

-- night_routes
DROP POLICY IF EXISTS "Creators can delete own routes" ON public.night_routes;
DROP POLICY IF EXISTS "Creators can update own routes" ON public.night_routes;
DROP POLICY IF EXISTS "Users can create routes" ON public.night_routes;
DROP POLICY IF EXISTS "Users can view own routes and invited routes" ON public.night_routes;
CREATE POLICY "Users can create routes" ON public.night_routes FOR INSERT TO authenticated
  WITH CHECK (creator_id = (SELECT auth.uid()));
CREATE POLICY "Users can view own routes and invited routes" ON public.night_routes FOR SELECT TO authenticated
  USING (creator_id = (SELECT auth.uid())
    OR EXISTS (SELECT 1 FROM public.night_route_invites nri
      WHERE nri.route_id = night_routes.id AND nri.user_id = (SELECT auth.uid())));
CREATE POLICY "Creators can update own routes" ON public.night_routes FOR UPDATE TO authenticated
  USING (creator_id = (SELECT auth.uid())) WITH CHECK (creator_id = (SELECT auth.uid()));
CREATE POLICY "Creators can delete own routes" ON public.night_routes FOR DELETE TO authenticated
  USING (creator_id = (SELECT auth.uid()));

-- notifications (recipient_user_id)
DROP POLICY IF EXISTS "Users can mark own notifications as read" ON public.notifications;
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT TO authenticated
  USING (recipient_user_id = (SELECT auth.uid()));
CREATE POLICY "Users can mark own notifications as read" ON public.notifications FOR UPDATE TO authenticated
  USING (recipient_user_id = (SELECT auth.uid())) WITH CHECK (recipient_user_id = (SELECT auth.uid()));

-- payment_transactions (from_user_id / to_user_id)
DROP POLICY IF EXISTS "Users can create transactions" ON public.payment_transactions;
DROP POLICY IF EXISTS "Users can view own transactions" ON public.payment_transactions;
CREATE POLICY "Users can create transactions" ON public.payment_transactions FOR INSERT TO authenticated
  WITH CHECK (from_user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view own transactions" ON public.payment_transactions FOR SELECT TO authenticated
  USING (from_user_id = (SELECT auth.uid()) OR to_user_id = (SELECT auth.uid()));
