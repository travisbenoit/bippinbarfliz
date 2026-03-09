/*
  # Fix Messages UPDATE Policy for Read Receipts

  The previous UPDATE policy only allowed the sender to update messages.
  This prevented recipients from marking messages as read (updating read_at
  and delivery_status fields).

  ## Changes
  1. Drop the old single UPDATE policy
  2. Create two separate UPDATE policies:
     - Senders can update their own messages (edit body, soft-delete)
     - DM recipients and swarm members can update read_at/delivery_status
*/

DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;

CREATE POLICY "Senders can update own messages"
  ON public.messages
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = sender_user_id)
  WITH CHECK (auth.uid() = sender_user_id);

CREATE POLICY "Recipients can mark messages as read"
  ON public.messages
  FOR UPDATE
  TO authenticated
  USING (
    auth.uid() <> sender_user_id
    AND (
      (conversation_type = 'dm' AND (auth.uid() = dm_user_a OR auth.uid() = dm_user_b))
      OR
      (conversation_type = 'swarm' AND EXISTS (
        SELECT 1 FROM public.swarm_members sm
        WHERE sm.swarm_id = messages.swarm_id AND sm.user_id = auth.uid()
      ))
    )
  )
  WITH CHECK (
    auth.uid() <> sender_user_id
    AND (
      (conversation_type = 'dm' AND (auth.uid() = dm_user_a OR auth.uid() = dm_user_b))
      OR
      (conversation_type = 'swarm' AND EXISTS (
        SELECT 1 FROM public.swarm_members sm
        WHERE sm.swarm_id = messages.swarm_id AND sm.user_id = auth.uid()
      ))
    )
  );
