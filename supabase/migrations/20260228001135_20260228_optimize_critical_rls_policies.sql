/*
  # Optimize Critical RLS Policies for Performance

  1. RLS Performance Fixes
    - Wrapped auth.uid() in SELECT subqueries to optimize query planning
    - Prevents re-evaluation of auth functions for each row
    - Critical tables: users, messages, friendships, swarms, notifications, safety tables
    
  2. Performance Impact
    - Reduces function call overhead per row
    - Allows better query plan caching
    - Improves performance at scale as per Supabase documentation
*/

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
    DROP POLICY IF EXISTS "Users can insert own profile" ON users;
    CREATE POLICY "Users can insert own profile"
      ON users FOR INSERT TO authenticated
      WITH CHECK ((SELECT auth.uid()) = id);
    
    DROP POLICY IF EXISTS "Users can update own profile" ON users;
    CREATE POLICY "Users can update own profile"
      ON users FOR UPDATE TO authenticated
      USING ((SELECT auth.uid()) = id)
      WITH CHECK ((SELECT auth.uid()) = id);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'messages' AND table_schema = 'public') THEN
    DROP POLICY IF EXISTS "Users can send messages" ON messages;
    CREATE POLICY "Users can send messages"
      ON messages FOR INSERT TO authenticated
      WITH CHECK ((SELECT auth.uid()) = sender_user_id);
    
    DROP POLICY IF EXISTS "Users can view their own DM messages" ON messages;
    CREATE POLICY "Users can view their own DM messages"
      ON messages FOR SELECT TO authenticated
      USING (conversation_type = 'dm' AND ((SELECT auth.uid()) = dm_user_a OR (SELECT auth.uid()) = dm_user_b));
    
    DROP POLICY IF EXISTS "Users can view swarm messages they are in" ON messages;
    CREATE POLICY "Users can view swarm messages they are in"
      ON messages FOR SELECT TO authenticated
      USING (conversation_type = 'swarm' AND swarm_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM swarm_members
        WHERE swarm_members.swarm_id = messages.swarm_id
        AND swarm_members.user_id = (SELECT auth.uid())
      ));
    
    DROP POLICY IF EXISTS "Senders can update own messages" ON messages;
    CREATE POLICY "Senders can update own messages"
      ON messages FOR UPDATE TO authenticated
      USING ((SELECT auth.uid()) = sender_user_id)
      WITH CHECK ((SELECT auth.uid()) = sender_user_id);
    
    DROP POLICY IF EXISTS "Recipients can mark messages as read" ON messages;
    CREATE POLICY "Recipients can mark messages as read"
      ON messages FOR UPDATE TO authenticated
      USING ((conversation_type = 'dm' AND ((SELECT auth.uid()) = dm_user_a OR (SELECT auth.uid()) = dm_user_b)) OR (conversation_type = 'swarm' AND EXISTS (SELECT 1 FROM swarm_members WHERE swarm_members.swarm_id = messages.swarm_id AND swarm_members.user_id = (SELECT auth.uid()))))
      WITH CHECK ((conversation_type = 'dm' AND ((SELECT auth.uid()) = dm_user_a OR (SELECT auth.uid()) = dm_user_b)) OR (conversation_type = 'swarm' AND EXISTS (SELECT 1 FROM swarm_members WHERE swarm_members.swarm_id = messages.swarm_id AND swarm_members.user_id = (SELECT auth.uid()))));
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'friendships' AND table_schema = 'public') THEN
    DROP POLICY IF EXISTS "Users can view their own friendships" ON friendships;
    CREATE POLICY "Users can view their own friendships"
      ON friendships FOR SELECT TO authenticated
      USING ((SELECT auth.uid()) = user_id OR (SELECT auth.uid()) = friend_id);
    
    DROP POLICY IF EXISTS "Users can send friend requests" ON friendships;
    CREATE POLICY "Users can send friend requests"
      ON friendships FOR INSERT TO authenticated
      WITH CHECK ((SELECT auth.uid()) = user_id);
    
    DROP POLICY IF EXISTS "Users can update friendships they are part of" ON friendships;
    CREATE POLICY "Users can update friendships they are part of"
      ON friendships FOR UPDATE TO authenticated
      USING ((SELECT auth.uid()) = user_id OR (SELECT auth.uid()) = friend_id)
      WITH CHECK ((SELECT auth.uid()) = user_id OR (SELECT auth.uid()) = friend_id);
    
    DROP POLICY IF EXISTS "Users can delete their own friendship rows" ON friendships;
    CREATE POLICY "Users can delete their own friendship rows"
      ON friendships FOR DELETE TO authenticated
      USING ((SELECT auth.uid()) = user_id OR (SELECT auth.uid()) = friend_id);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'swarms' AND table_schema = 'public') THEN
    DROP POLICY IF EXISTS "Users can create swarms" ON swarms;
    CREATE POLICY "Users can create swarms"
      ON swarms FOR INSERT TO authenticated
      WITH CHECK ((SELECT auth.uid()) = host_user_id);
    
    DROP POLICY IF EXISTS "Hosts can update their swarms" ON swarms;
    CREATE POLICY "Hosts can update their swarms"
      ON swarms FOR UPDATE TO authenticated
      USING ((SELECT auth.uid()) = host_user_id)
      WITH CHECK ((SELECT auth.uid()) = host_user_id);
    
    DROP POLICY IF EXISTS "Authenticated users can view accessible swarms" ON swarms;
    CREATE POLICY "Authenticated users can view accessible swarms"
      ON swarms FOR SELECT TO authenticated
      USING ((SELECT auth.uid()) = host_user_id OR EXISTS (SELECT 1 FROM swarm_members WHERE swarm_members.swarm_id = swarms.id AND swarm_members.user_id = (SELECT auth.uid())));
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'swarm_members' AND table_schema = 'public') THEN
    DROP POLICY IF EXISTS "Users can join swarms" ON swarm_members;
    CREATE POLICY "Users can join swarms"
      ON swarm_members FOR INSERT TO authenticated
      WITH CHECK ((SELECT auth.uid()) = user_id);
    
    DROP POLICY IF EXISTS "Users can update their own membership" ON swarm_members;
    CREATE POLICY "Users can update their own membership"
      ON swarm_members FOR UPDATE TO authenticated
      USING ((SELECT auth.uid()) = user_id)
      WITH CHECK ((SELECT auth.uid()) = user_id);
    
    DROP POLICY IF EXISTS "Users can leave swarms" ON swarm_members;
    CREATE POLICY "Users can leave swarms"
      ON swarm_members FOR DELETE TO authenticated
      USING ((SELECT auth.uid()) = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_blocks' AND table_schema = 'public') THEN
    DROP POLICY IF EXISTS "Users can view their own blocks" ON user_blocks;
    CREATE POLICY "Users can view their own blocks"
      ON user_blocks FOR SELECT TO authenticated
      USING ((SELECT auth.uid()) = blocker_id OR (SELECT auth.uid()) = blocked_id);

    DROP POLICY IF EXISTS "Users can block others" ON user_blocks;
    CREATE POLICY "Users can block others"
      ON user_blocks FOR INSERT TO authenticated
      WITH CHECK ((SELECT auth.uid()) = blocker_id);

    DROP POLICY IF EXISTS "Users can unblock others" ON user_blocks;
    CREATE POLICY "Users can unblock others"
      ON user_blocks FOR DELETE TO authenticated
      USING ((SELECT auth.uid()) = blocker_id);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'activity_feed' AND table_schema = 'public') THEN
    DROP POLICY IF EXISTS "Users can view activity of their friends" ON activity_feed;
    CREATE POLICY "Users can view activity of their friends"
      ON activity_feed FOR SELECT TO authenticated
      USING (EXISTS (SELECT 1 FROM friendships f WHERE ((f.user_id = (SELECT auth.uid()) AND f.friend_id = activity_feed.actor_user_id) OR (f.friend_id = (SELECT auth.uid()) AND f.user_id = activity_feed.actor_user_id)) AND f.status = 'accepted'));
    
    DROP POLICY IF EXISTS "Users can insert their own activity" ON activity_feed;
    CREATE POLICY "Users can insert their own activity"
      ON activity_feed FOR INSERT TO authenticated
      WITH CHECK ((SELECT auth.uid()) = actor_user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications' AND table_schema = 'public') THEN
    DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
    CREATE POLICY "Users can view own notifications"
      ON notifications FOR SELECT TO authenticated
      USING ((SELECT auth.uid()) = recipient_user_id);
    
    DROP POLICY IF EXISTS "Users can mark own notifications as read" ON notifications;
    CREATE POLICY "Users can mark own notifications as read"
      ON notifications FOR UPDATE TO authenticated
      USING ((SELECT auth.uid()) = recipient_user_id)
      WITH CHECK ((SELECT auth.uid()) = recipient_user_id);
    
    DROP POLICY IF EXISTS "Actors can insert own notifications" ON notifications;
    CREATE POLICY "Actors can insert own notifications"
      ON notifications FOR INSERT TO authenticated
      WITH CHECK ((SELECT auth.uid()) = actor_user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'safety_friends' AND table_schema = 'public') THEN
    DROP POLICY IF EXISTS "Users can view own safety friends" ON safety_friends;
    CREATE POLICY "Users can view own safety friends"
      ON safety_friends FOR SELECT TO authenticated
      USING ((SELECT auth.uid()) = user_id);
    
    DROP POLICY IF EXISTS "Users can insert own safety friends" ON safety_friends;
    CREATE POLICY "Users can insert own safety friends"
      ON safety_friends FOR INSERT TO authenticated
      WITH CHECK ((SELECT auth.uid()) = user_id);
    
    DROP POLICY IF EXISTS "Users can update own safety friends" ON safety_friends;
    CREATE POLICY "Users can update own safety friends"
      ON safety_friends FOR UPDATE TO authenticated
      USING ((SELECT auth.uid()) = user_id)
      WITH CHECK ((SELECT auth.uid()) = user_id);
    
    DROP POLICY IF EXISTS "Users can delete own safety friends" ON safety_friends;
    CREATE POLICY "Users can delete own safety friends"
      ON safety_friends FOR DELETE TO authenticated
      USING ((SELECT auth.uid()) = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'safety_alerts' AND table_schema = 'public') THEN
    DROP POLICY IF EXISTS "Users can view own safety alerts" ON safety_alerts;
    CREATE POLICY "Users can view own safety alerts"
      ON safety_alerts FOR SELECT TO authenticated
      USING ((SELECT auth.uid()) = user_id);
    
    DROP POLICY IF EXISTS "Users can insert own safety alerts" ON safety_alerts;
    CREATE POLICY "Users can insert own safety alerts"
      ON safety_alerts FOR INSERT TO authenticated
      WITH CHECK ((SELECT auth.uid()) = user_id);
  END IF;
END $$;