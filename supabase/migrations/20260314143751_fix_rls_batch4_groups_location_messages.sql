/*
  # Fix RLS batch 4: group_split_items, group_splits, location_events, location_pings, message_edits, messages
*/

-- group_split_items
DROP POLICY IF EXISTS "Creators can add split items" ON public.group_split_items;
DROP POLICY IF EXISTS "Split participants can view items" ON public.group_split_items;
DROP POLICY IF EXISTS "Users can update own payment status" ON public.group_split_items;
CREATE POLICY "Creators can add split items" ON public.group_split_items FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.group_splits gs
    WHERE gs.id = group_split_items.split_id AND gs.creator_id = (SELECT auth.uid())));
CREATE POLICY "Split participants can view items" ON public.group_split_items FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid())
    OR EXISTS (SELECT 1 FROM public.group_splits gs
      WHERE gs.id = group_split_items.split_id AND gs.creator_id = (SELECT auth.uid())));
CREATE POLICY "Users can update own payment status" ON public.group_split_items FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid())) WITH CHECK (user_id = (SELECT auth.uid()));

-- group_splits
DROP POLICY IF EXISTS "Creators can update splits" ON public.group_splits;
DROP POLICY IF EXISTS "Split participants can view splits" ON public.group_splits;
DROP POLICY IF EXISTS "Users can create splits" ON public.group_splits;
CREATE POLICY "Users can create splits" ON public.group_splits FOR INSERT TO authenticated
  WITH CHECK (creator_id = (SELECT auth.uid()));
CREATE POLICY "Split participants can view splits" ON public.group_splits FOR SELECT TO authenticated
  USING (creator_id = (SELECT auth.uid())
    OR EXISTS (SELECT 1 FROM public.group_split_items gsi
      WHERE gsi.split_id = group_splits.id AND gsi.user_id = (SELECT auth.uid())));
CREATE POLICY "Creators can update splits" ON public.group_splits FOR UPDATE TO authenticated
  USING (creator_id = (SELECT auth.uid())) WITH CHECK (creator_id = (SELECT auth.uid()));

-- location_events
DROP POLICY IF EXISTS "Users can view their own location events" ON public.location_events;
CREATE POLICY "Users can view their own location events" ON public.location_events FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- location_pings
DROP POLICY IF EXISTS "Users can delete own location pings" ON public.location_pings;
DROP POLICY IF EXISTS "Users can insert own location pings" ON public.location_pings;
DROP POLICY IF EXISTS "Users can read own location pings" ON public.location_pings;
CREATE POLICY "Users can insert own location pings" ON public.location_pings FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can read own location pings" ON public.location_pings FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can delete own location pings" ON public.location_pings FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- message_edits
DROP POLICY IF EXISTS "Users can record edits to own messages" ON public.message_edits;
DROP POLICY IF EXISTS "Users can view edits of their messages" ON public.message_edits;
CREATE POLICY "Users can record edits to own messages" ON public.message_edits FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.messages m
    WHERE m.id = message_edits.message_id AND m.sender_user_id = (SELECT auth.uid())));
CREATE POLICY "Users can view edits of their messages" ON public.message_edits FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.messages m
    WHERE m.id = message_edits.message_id
    AND (m.sender_user_id = (SELECT auth.uid())
      OR m.dm_user_a = (SELECT auth.uid())
      OR m.dm_user_b = (SELECT auth.uid()))));

-- messages
DROP POLICY IF EXISTS "Users can insert own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can mark DM messages as read" ON public.messages;
DROP POLICY IF EXISTS "Users can soft delete own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can view own messages" ON public.messages;
CREATE POLICY "Users can insert own messages" ON public.messages FOR INSERT TO authenticated
  WITH CHECK (sender_user_id = (SELECT auth.uid()));
CREATE POLICY "Users can view own messages" ON public.messages FOR SELECT TO authenticated
  USING (sender_user_id = (SELECT auth.uid())
    OR dm_user_a = (SELECT auth.uid())
    OR dm_user_b = (SELECT auth.uid())
    OR (swarm_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.swarm_members sm
      WHERE sm.swarm_id = messages.swarm_id AND sm.user_id = (SELECT auth.uid()))));
CREATE POLICY "Users can mark DM messages as read" ON public.messages FOR UPDATE TO authenticated
  USING (dm_user_a = (SELECT auth.uid()) OR dm_user_b = (SELECT auth.uid()))
  WITH CHECK (dm_user_a = (SELECT auth.uid()) OR dm_user_b = (SELECT auth.uid()));
CREATE POLICY "Users can soft delete own messages" ON public.messages FOR UPDATE TO authenticated
  USING (sender_user_id = (SELECT auth.uid()))
  WITH CHECK (sender_user_id = (SELECT auth.uid()));
