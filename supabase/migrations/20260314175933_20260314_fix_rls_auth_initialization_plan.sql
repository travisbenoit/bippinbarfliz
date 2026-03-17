/*
  # Fix RLS Auth Initialization Plan

  ## Summary
  Replaces direct `auth.uid()` calls with `(select auth.uid())` in all RLS policies
  flagged for re-evaluating auth functions per row. This causes Postgres to evaluate
  the auth function once per query instead of once per row, improving performance
  significantly at scale.

  ## Tables Fixed
  swarms, messages, reports, blocks, gifts, subscriptions, music_shares, user_gifts,
  emoji_reactions, user_inventory, user_venue_presence, user_language_preferences,
  user_activity_history, event_log, location_pings, geofence_events, friendships,
  conversations, conversation_participants, venue_reports, message_edits, cheers,
  venue_ratings, night_routes, night_route_invites, safe_arrivals, check_in_streaks,
  group_splits, group_split_items, venue_photos, venue_reviews, user_stats,
  user_badges, user_challenges, venue_buzz, vibe_votes, venue_room_messages,
  venue_room_reactions, venue_room_moments, venue_room_vibe_polls, venue_room_presence,
  venue_room_moment_likes, push_subscriptions, venue_wall_photos, venue_wall_photo_likes
*/

-- swarms
DROP POLICY IF EXISTS "Hosts can update swarms" ON public.swarms;
CREATE POLICY "Hosts can update swarms" ON public.swarms FOR UPDATE TO authenticated
  USING ((select auth.uid()) = host_user_id)
  WITH CHECK ((select auth.uid()) = host_user_id);

-- messages
DROP POLICY IF EXISTS "Users can insert own messages" ON public.messages;
CREATE POLICY "Users can insert own messages" ON public.messages FOR INSERT TO authenticated
  WITH CHECK (
    (sender_user_id = (select auth.uid()))
    AND (
      ((conversation_type = 'dm') AND ((dm_user_a = (select auth.uid())) OR (dm_user_b = (select auth.uid()))))
      OR ((conversation_type = 'swarm') AND (EXISTS (
        SELECT 1 FROM swarm_members WHERE swarm_members.swarm_id = messages.swarm_id AND swarm_members.user_id = (select auth.uid())
      )))
    )
  );

-- reports
DROP POLICY IF EXISTS "Users can create reports" ON public.reports;
CREATE POLICY "Users can create reports" ON public.reports FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = reporter_user_id);

DROP POLICY IF EXISTS "Users can view own reports" ON public.reports;
CREATE POLICY "Users can view own reports" ON public.reports FOR SELECT TO authenticated
  USING ((select auth.uid()) = reporter_user_id);

-- blocks
DROP POLICY IF EXISTS "Users can create blocks" ON public.blocks;
CREATE POLICY "Users can create blocks" ON public.blocks FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = blocker_user_id);

DROP POLICY IF EXISTS "Users can delete own blocks" ON public.blocks;
CREATE POLICY "Users can delete own blocks" ON public.blocks FOR DELETE TO authenticated
  USING ((select auth.uid()) = blocker_user_id);

DROP POLICY IF EXISTS "Users can view own blocks" ON public.blocks;
CREATE POLICY "Users can view own blocks" ON public.blocks FOR SELECT TO authenticated
  USING ((select auth.uid()) = blocker_user_id);

-- gifts
DROP POLICY IF EXISTS "Recipients can update their gifts" ON public.gifts;
CREATE POLICY "Recipients can update their gifts" ON public.gifts FOR UPDATE TO authenticated
  USING ((select auth.uid()) = to_user_id)
  WITH CHECK ((select auth.uid()) = to_user_id);

-- subscriptions
DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can update own subscriptions" ON public.subscriptions FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- music_shares
DROP POLICY IF EXISTS "Recipients can update music status" ON public.music_shares;
CREATE POLICY "Recipients can update music status" ON public.music_shares FOR UPDATE TO authenticated
  USING ((select auth.uid()) = recipient_id)
  WITH CHECK ((select auth.uid()) = recipient_id);

-- user_gifts
DROP POLICY IF EXISTS "Recipients can update gift status" ON public.user_gifts;
CREATE POLICY "Recipients can update gift status" ON public.user_gifts FOR UPDATE TO authenticated
  USING ((select auth.uid()) = to_user_id)
  WITH CHECK ((select auth.uid()) = to_user_id);

-- emoji_reactions
DROP POLICY IF EXISTS "Users can add reactions" ON public.emoji_reactions;
CREATE POLICY "Users can add reactions" ON public.emoji_reactions FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- user_inventory
DROP POLICY IF EXISTS "Users can manage own inventory" ON public.user_inventory;
CREATE POLICY "Users can manage own inventory" ON public.user_inventory FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- user_venue_presence
DROP POLICY IF EXISTS "Users can insert own presence" ON public.user_venue_presence;
CREATE POLICY "Users can insert own presence" ON public.user_venue_presence FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own presence" ON public.user_venue_presence;
CREATE POLICY "Users can update own presence" ON public.user_venue_presence FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view relevant presence" ON public.user_venue_presence;
CREATE POLICY "Users can view relevant presence" ON public.user_venue_presence FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id
    OR (
      is_visible_in_venue = true
      AND status = 'IN_VENUE'
      AND left_at IS NULL
      AND last_seen_at > (now() - interval '24 hours')
      AND (
        EXISTS (
          SELECT 1 FROM friendships
          WHERE friendships.status = 'accepted'
            AND ((friendships.user_id = (select auth.uid()) AND friendships.friend_id = user_venue_presence.user_id)
              OR (friendships.friend_id = (select auth.uid()) AND friendships.user_id = user_venue_presence.user_id))
        )
        OR EXISTS (
          SELECT 1 FROM swarm_members sm1
            JOIN swarm_members sm2 ON sm1.swarm_id = sm2.swarm_id
            JOIN swarms s ON s.id = sm1.swarm_id
          WHERE sm1.user_id = (select auth.uid())
            AND sm2.user_id = user_venue_presence.user_id
            AND s.status = ANY(ARRAY['active','ongoing'])
        )
      )
    )
  );

-- user_language_preferences
DROP POLICY IF EXISTS "Users can insert own language preferences" ON public.user_language_preferences;
CREATE POLICY "Users can insert own language preferences" ON public.user_language_preferences FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can read own language preferences" ON public.user_language_preferences;
CREATE POLICY "Users can read own language preferences" ON public.user_language_preferences FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own language preferences" ON public.user_language_preferences;
CREATE POLICY "Users can update own language preferences" ON public.user_language_preferences FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- user_activity_history
DROP POLICY IF EXISTS "Users can create own activity history" ON public.user_activity_history;
CREATE POLICY "Users can create own activity history" ON public.user_activity_history FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own activity history" ON public.user_activity_history;
CREATE POLICY "Users can delete own activity history" ON public.user_activity_history FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view own activity history" ON public.user_activity_history;
CREATE POLICY "Users can view own activity history" ON public.user_activity_history FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- event_log
DROP POLICY IF EXISTS "Users can insert own event logs" ON public.event_log;
CREATE POLICY "Users can insert own event logs" ON public.event_log FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id OR user_id IS NULL);

DROP POLICY IF EXISTS "Users can read own event logs" ON public.event_log;
CREATE POLICY "Users can read own event logs" ON public.event_log FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- location_pings
DROP POLICY IF EXISTS "Users can delete own location pings" ON public.location_pings;
CREATE POLICY "Users can delete own location pings" ON public.location_pings FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can read own location pings" ON public.location_pings;
CREATE POLICY "Users can read own location pings" ON public.location_pings FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- geofence_events
DROP POLICY IF EXISTS "System can update processed_at" ON public.geofence_events;
CREATE POLICY "System can update processed_at" ON public.geofence_events FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own geofence events" ON public.geofence_events;
CREATE POLICY "Users can delete own geofence events" ON public.geofence_events FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own geofence events" ON public.geofence_events;
CREATE POLICY "Users can insert own geofence events" ON public.geofence_events FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can read geofence events" ON public.geofence_events;
CREATE POLICY "Users can read geofence events" ON public.geofence_events FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id
    OR venue_id IN (
      SELECT ge2.venue_id FROM geofence_events ge2
      WHERE ge2.user_id = (select auth.uid())
        AND ge2.event_type = 'enter'
        AND ge2.triggered_at > (now() - interval '24 hours')
    )
  );

-- friendships
DROP POLICY IF EXISTS "Users can delete own friendships" ON public.friendships;
CREATE POLICY "Users can delete own friendships" ON public.friendships FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id OR (select auth.uid()) = friend_id);

DROP POLICY IF EXISTS "Users can read own friendships" ON public.friendships;
CREATE POLICY "Users can read own friendships" ON public.friendships FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR (select auth.uid()) = friend_id);

DROP POLICY IF EXISTS "Users can respond to friend requests" ON public.friendships;
CREATE POLICY "Users can respond to friend requests" ON public.friendships FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id OR (select auth.uid()) = friend_id)
  WITH CHECK ((select auth.uid()) = user_id OR (select auth.uid()) = friend_id);

-- conversations
DROP POLICY IF EXISTS "Admins can update conversations" ON public.conversations;
CREATE POLICY "Admins can update conversations" ON public.conversations FOR UPDATE TO authenticated
  USING (
    id IN (
      SELECT cp.conversation_id FROM conversation_participants cp
      WHERE cp.user_id = (select auth.uid())
        AND cp.role = ANY(ARRAY['admin','owner'])
        AND cp.left_at IS NULL
    )
  )
  WITH CHECK (
    id IN (
      SELECT cp.conversation_id FROM conversation_participants cp
      WHERE cp.user_id = (select auth.uid())
        AND cp.role = ANY(ARRAY['admin','owner'])
        AND cp.left_at IS NULL
    )
  );

DROP POLICY IF EXISTS "Owners can delete conversations" ON public.conversations;
CREATE POLICY "Owners can delete conversations" ON public.conversations FOR DELETE TO authenticated
  USING (
    id IN (
      SELECT cp.conversation_id FROM conversation_participants cp
      WHERE cp.user_id = (select auth.uid())
        AND cp.role = 'owner'
        AND cp.left_at IS NULL
    )
  );

DROP POLICY IF EXISTS "Users can read own conversations" ON public.conversations;
CREATE POLICY "Users can read own conversations" ON public.conversations FOR SELECT TO authenticated
  USING (
    id IN (
      SELECT cp.conversation_id FROM conversation_participants cp
      WHERE cp.user_id = (select auth.uid())
        AND cp.left_at IS NULL
    )
  );

-- conversation_participants
DROP POLICY IF EXISTS "Admins can remove participants" ON public.conversation_participants;
CREATE POLICY "Admins can remove participants" ON public.conversation_participants FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = user_id
    OR conversation_id IN (
      SELECT cp2.conversation_id FROM conversation_participants cp2
      WHERE cp2.user_id = (select auth.uid())
        AND cp2.role = ANY(ARRAY['admin','owner'])
        AND cp2.left_at IS NULL
    )
  );

DROP POLICY IF EXISTS "Users can add conversation participants" ON public.conversation_participants;
CREATE POLICY "Users can add conversation participants" ON public.conversation_participants FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = user_id
    OR conversation_id IN (
      SELECT cp2.conversation_id FROM conversation_participants cp2
      WHERE cp2.user_id = (select auth.uid())
        AND cp2.role = ANY(ARRAY['admin','owner'])
        AND cp2.left_at IS NULL
    )
  );

DROP POLICY IF EXISTS "Users can read conversation participants" ON public.conversation_participants;
CREATE POLICY "Users can read conversation participants" ON public.conversation_participants FOR SELECT TO authenticated
  USING (
    conversation_id IN (
      SELECT cp2.conversation_id FROM conversation_participants cp2
      WHERE cp2.user_id = (select auth.uid())
        AND cp2.left_at IS NULL
    )
  );

DROP POLICY IF EXISTS "Users can update own participation" ON public.conversation_participants;
CREATE POLICY "Users can update own participation" ON public.conversation_participants FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- venue_reports
DROP POLICY IF EXISTS "Users can create reports" ON public.venue_reports;
CREATE POLICY "Users can create reports" ON public.venue_reports FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = reporter_id);

DROP POLICY IF EXISTS "Users can delete own pending reports" ON public.venue_reports;
CREATE POLICY "Users can delete own pending reports" ON public.venue_reports FOR DELETE TO authenticated
  USING ((select auth.uid()) = reporter_id AND status = 'pending');

DROP POLICY IF EXISTS "Users can update own pending reports" ON public.venue_reports;
CREATE POLICY "Users can update own pending reports" ON public.venue_reports FOR UPDATE TO authenticated
  USING ((select auth.uid()) = reporter_id AND status = 'pending')
  WITH CHECK ((select auth.uid()) = reporter_id AND status = 'pending');

-- message_edits
DROP POLICY IF EXISTS "Users can record edits to own messages" ON public.message_edits;
CREATE POLICY "Users can record edits to own messages" ON public.message_edits FOR INSERT TO authenticated
  WITH CHECK (edited_by = (select auth.uid()));

DROP POLICY IF EXISTS "Users can view edits for accessible messages" ON public.message_edits;
CREATE POLICY "Users can view edits for accessible messages" ON public.message_edits FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM messages m
      WHERE m.id = message_edits.message_id
        AND (
          ((m.conversation_type = 'dm') AND ((m.dm_user_a = (select auth.uid())) OR (m.dm_user_b = (select auth.uid()))))
          OR ((m.conversation_type = 'swarm') AND EXISTS (
            SELECT 1 FROM swarm_members sm WHERE sm.swarm_id = m.swarm_id AND sm.user_id = (select auth.uid())
          ))
        )
    )
  );

-- cheers
DROP POLICY IF EXISTS "Users can view own cheers" ON public.cheers;
CREATE POLICY "Users can view own cheers" ON public.cheers FOR SELECT TO authenticated
  USING ((select auth.uid()) = sender_id OR (select auth.uid()) = recipient_id);

-- venue_ratings
DROP POLICY IF EXISTS "Users can delete own ratings" ON public.venue_ratings;
CREATE POLICY "Users can delete own ratings" ON public.venue_ratings FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own ratings" ON public.venue_ratings;
CREATE POLICY "Users can update own ratings" ON public.venue_ratings FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- night_routes
DROP POLICY IF EXISTS "Creators can delete own routes" ON public.night_routes;
CREATE POLICY "Creators can delete own routes" ON public.night_routes FOR DELETE TO authenticated
  USING ((select auth.uid()) = creator_id);

DROP POLICY IF EXISTS "Creators can update own routes" ON public.night_routes;
CREATE POLICY "Creators can update own routes" ON public.night_routes FOR UPDATE TO authenticated
  USING ((select auth.uid()) = creator_id)
  WITH CHECK ((select auth.uid()) = creator_id);

DROP POLICY IF EXISTS "Users can view own routes and invited routes" ON public.night_routes;
CREATE POLICY "Users can view own routes and invited routes" ON public.night_routes FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = creator_id
    OR EXISTS (
      SELECT 1 FROM night_route_invites nri
      WHERE nri.route_id = night_routes.id AND nri.user_id = (select auth.uid())
    )
  );

-- night_route_invites
DROP POLICY IF EXISTS "Invited users can update invite status" ON public.night_route_invites;
CREATE POLICY "Invited users can update invite status" ON public.night_route_invites FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Route creators can send invites" ON public.night_route_invites;
CREATE POLICY "Route creators can send invites" ON public.night_route_invites FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM night_routes nr
      WHERE nr.id = night_route_invites.route_id AND nr.creator_id = (select auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can view invites they sent or received" ON public.night_route_invites;
CREATE POLICY "Users can view invites they sent or received" ON public.night_route_invites FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id
    OR EXISTS (
      SELECT 1 FROM night_routes nr
      WHERE nr.id = night_route_invites.route_id AND nr.creator_id = (select auth.uid())
    )
  );

-- safe_arrivals
DROP POLICY IF EXISTS "Users can view own and friends safe arrivals" ON public.safe_arrivals;
CREATE POLICY "Users can view own and friends safe arrivals" ON public.safe_arrivals FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id
    OR EXISTS (
      SELECT 1 FROM friendships f
      WHERE f.status = 'accepted'
        AND ((f.user_id = (select auth.uid()) AND f.friend_id = safe_arrivals.user_id)
          OR (f.friend_id = (select auth.uid()) AND f.user_id = safe_arrivals.user_id))
    )
  );

-- check_in_streaks
DROP POLICY IF EXISTS "Users can insert own streak" ON public.check_in_streaks;
CREATE POLICY "Users can insert own streak" ON public.check_in_streaks FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own streak" ON public.check_in_streaks;
CREATE POLICY "Users can update own streak" ON public.check_in_streaks FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view friend streaks" ON public.check_in_streaks;
CREATE POLICY "Users can view friend streaks" ON public.check_in_streaks FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id
    OR EXISTS (
      SELECT 1 FROM friendships f
      WHERE f.status = 'accepted'
        AND ((f.user_id = (select auth.uid()) AND f.friend_id = check_in_streaks.user_id)
          OR (f.friend_id = (select auth.uid()) AND f.user_id = check_in_streaks.user_id))
    )
  );

-- group_splits
DROP POLICY IF EXISTS "Creators can update splits" ON public.group_splits;
CREATE POLICY "Creators can update splits" ON public.group_splits FOR UPDATE TO authenticated
  USING ((select auth.uid()) = creator_id)
  WITH CHECK ((select auth.uid()) = creator_id);

DROP POLICY IF EXISTS "Split participants can view splits" ON public.group_splits;
CREATE POLICY "Split participants can view splits" ON public.group_splits FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = creator_id
    OR EXISTS (
      SELECT 1 FROM group_split_items gsi
      WHERE gsi.split_id = group_splits.id AND gsi.user_id = (select auth.uid())
    )
  );

-- group_split_items
DROP POLICY IF EXISTS "Creators can add split items" ON public.group_split_items;
CREATE POLICY "Creators can add split items" ON public.group_split_items FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_splits gs
      WHERE gs.id = group_split_items.split_id AND gs.creator_id = (select auth.uid())
    )
  );

DROP POLICY IF EXISTS "Split participants can view items" ON public.group_split_items;
CREATE POLICY "Split participants can view items" ON public.group_split_items FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id
    OR EXISTS (
      SELECT 1 FROM group_splits gs
      WHERE gs.id = group_split_items.split_id AND gs.creator_id = (select auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can update own payment status" ON public.group_split_items;
CREATE POLICY "Users can update own payment status" ON public.group_split_items FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- venue_photos
DROP POLICY IF EXISTS "Users can update their own photos" ON public.venue_photos;
CREATE POLICY "Users can update their own photos" ON public.venue_photos FOR UPDATE TO authenticated
  USING ((select auth.uid()) = created_by_user_id)
  WITH CHECK ((select auth.uid()) = created_by_user_id);

-- venue_reviews
DROP POLICY IF EXISTS "Users can delete their own reviews" ON public.venue_reviews;
CREATE POLICY "Users can delete their own reviews" ON public.venue_reviews FOR DELETE TO authenticated
  USING ((select auth.uid()) = created_by_user_id);

-- user_stats
DROP POLICY IF EXISTS "Users can insert own stats" ON public.user_stats;
CREATE POLICY "Users can insert own stats" ON public.user_stats FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own stats" ON public.user_stats;
CREATE POLICY "Users can update own stats" ON public.user_stats FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- user_badges
DROP POLICY IF EXISTS "Users can earn badges" ON public.user_badges;
CREATE POLICY "Users can earn badges" ON public.user_badges FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- user_challenges
DROP POLICY IF EXISTS "Users can insert own challenges" ON public.user_challenges;
CREATE POLICY "Users can insert own challenges" ON public.user_challenges FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own challenges" ON public.user_challenges;
CREATE POLICY "Users can update own challenges" ON public.user_challenges FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view own challenges" ON public.user_challenges;
CREATE POLICY "Users can view own challenges" ON public.user_challenges FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- vibe_votes
DROP POLICY IF EXISTS "Authenticated users can read vibe votes" ON public.vibe_votes;
CREATE POLICY "Authenticated users can read vibe votes" ON public.vibe_votes FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can cast vibe votes" ON public.vibe_votes;
CREATE POLICY "Users can cast vibe votes" ON public.vibe_votes FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- venue_room_messages
DROP POLICY IF EXISTS "Authenticated users can post room messages" ON public.venue_room_messages;
CREATE POLICY "Authenticated users can post room messages" ON public.venue_room_messages FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own room messages" ON public.venue_room_messages;
CREATE POLICY "Users can delete own room messages" ON public.venue_room_messages FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- venue_room_reactions
DROP POLICY IF EXISTS "Authenticated users can add reactions" ON public.venue_room_reactions;
CREATE POLICY "Authenticated users can add reactions" ON public.venue_room_reactions FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can remove own reactions" ON public.venue_room_reactions;
CREATE POLICY "Users can remove own reactions" ON public.venue_room_reactions FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- venue_room_moments
DROP POLICY IF EXISTS "Authenticated users can post moments" ON public.venue_room_moments;
CREATE POLICY "Authenticated users can post moments" ON public.venue_room_moments FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own moments" ON public.venue_room_moments;
CREATE POLICY "Users can delete own moments" ON public.venue_room_moments FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- venue_room_vibe_polls
DROP POLICY IF EXISTS "Authenticated users can vote" ON public.venue_room_vibe_polls;
CREATE POLICY "Authenticated users can vote" ON public.venue_room_vibe_polls FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can remove own vote" ON public.venue_room_vibe_polls;
CREATE POLICY "Users can remove own vote" ON public.venue_room_vibe_polls FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own vote" ON public.venue_room_vibe_polls;
CREATE POLICY "Users can update own vote" ON public.venue_room_vibe_polls FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- venue_room_presence
DROP POLICY IF EXISTS "Authenticated users can join room" ON public.venue_room_presence;
CREATE POLICY "Authenticated users can join room" ON public.venue_room_presence FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can leave room" ON public.venue_room_presence;
CREATE POLICY "Users can leave room" ON public.venue_room_presence FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own presence" ON public.venue_room_presence;
CREATE POLICY "Users can update own presence" ON public.venue_room_presence FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- venue_room_moment_likes
DROP POLICY IF EXISTS "Authenticated users can like moments" ON public.venue_room_moment_likes;
CREATE POLICY "Authenticated users can like moments" ON public.venue_room_moment_likes FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can unlike their own likes" ON public.venue_room_moment_likes;
CREATE POLICY "Users can unlike their own likes" ON public.venue_room_moment_likes FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- push_subscriptions
DROP POLICY IF EXISTS "Users can manage own push subscriptions" ON public.push_subscriptions;
CREATE POLICY "Users can manage own push subscriptions" ON public.push_subscriptions FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- venue_wall_photos
DROP POLICY IF EXISTS "Users can delete own wall photos" ON public.venue_wall_photos;
CREATE POLICY "Users can delete own wall photos" ON public.venue_wall_photos FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own wall photos" ON public.venue_wall_photos;
CREATE POLICY "Users can insert own wall photos" ON public.venue_wall_photos FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

-- venue_wall_photo_likes
DROP POLICY IF EXISTS "Users can delete own wall photo likes" ON public.venue_wall_photo_likes;
CREATE POLICY "Users can delete own wall photo likes" ON public.venue_wall_photo_likes FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own wall photo likes" ON public.venue_wall_photo_likes;
CREATE POLICY "Users can insert own wall photo likes" ON public.venue_wall_photo_likes FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
