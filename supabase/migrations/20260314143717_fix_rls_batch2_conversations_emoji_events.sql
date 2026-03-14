/*
  # Fix RLS batch 2: conversation_participants, conversations, emoji_reactions, event_log
*/

-- conversation_participants
DROP POLICY IF EXISTS "Admins can remove participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can add conversation participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can read conversation participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can update own participation" ON public.conversation_participants;
CREATE POLICY "Users can read conversation participants" ON public.conversation_participants FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.conversation_participants cp2
    WHERE cp2.conversation_id = conversation_participants.conversation_id AND cp2.user_id = (SELECT auth.uid())));
CREATE POLICY "Users can add conversation participants" ON public.conversation_participants FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid())
    OR EXISTS (SELECT 1 FROM public.conversation_participants cp2
      WHERE cp2.conversation_id = conversation_participants.conversation_id
      AND cp2.user_id = (SELECT auth.uid()) AND cp2.role IN ('owner','admin')));
CREATE POLICY "Users can update own participation" ON public.conversation_participants FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid())) WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Admins can remove participants" ON public.conversation_participants FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid())
    OR EXISTS (SELECT 1 FROM public.conversation_participants cp2
      WHERE cp2.conversation_id = conversation_participants.conversation_id
      AND cp2.user_id = (SELECT auth.uid()) AND cp2.role IN ('owner','admin')));

-- conversations
DROP POLICY IF EXISTS "Admins can update conversations" ON public.conversations;
DROP POLICY IF EXISTS "Owners can delete conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can read own conversations" ON public.conversations;
CREATE POLICY "Users can create conversations" ON public.conversations FOR INSERT TO authenticated
  WITH CHECK (created_by = (SELECT auth.uid()));
CREATE POLICY "Users can read own conversations" ON public.conversations FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.conversation_participants cp
    WHERE cp.conversation_id = conversations.id AND cp.user_id = (SELECT auth.uid())));
CREATE POLICY "Admins can update conversations" ON public.conversations FOR UPDATE TO authenticated
  USING (created_by = (SELECT auth.uid())
    OR EXISTS (SELECT 1 FROM public.conversation_participants cp
      WHERE cp.conversation_id = conversations.id AND cp.user_id = (SELECT auth.uid()) AND cp.role IN ('owner','admin')))
  WITH CHECK (created_by = (SELECT auth.uid())
    OR EXISTS (SELECT 1 FROM public.conversation_participants cp
      WHERE cp.conversation_id = conversations.id AND cp.user_id = (SELECT auth.uid()) AND cp.role IN ('owner','admin')));
CREATE POLICY "Owners can delete conversations" ON public.conversations FOR DELETE TO authenticated
  USING (created_by = (SELECT auth.uid()));

-- emoji_reactions
DROP POLICY IF EXISTS "Users can add their own reactions" ON public.emoji_reactions;
DROP POLICY IF EXISTS "Users can remove their own reactions" ON public.emoji_reactions;
CREATE POLICY "Users can add their own reactions" ON public.emoji_reactions FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "Users can remove their own reactions" ON public.emoji_reactions FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- event_log (insert allows user_id IS NULL per original policy)
DROP POLICY IF EXISTS "Users can insert own event logs" ON public.event_log;
DROP POLICY IF EXISTS "Users can read own event logs" ON public.event_log;
CREATE POLICY "Users can insert own event logs" ON public.event_log FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id OR user_id IS NULL);
CREATE POLICY "Users can read own event logs" ON public.event_log FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));
