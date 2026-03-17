/*
  # Consolidate Remaining Duplicate Permissive Policies

  ## Problem
  After the first cleanup pass, 18 (table, cmd) pairs still have multiple permissive
  policies. This migration fixes them in three ways:

  1. Drop authenticated-role policies that are made redundant by an existing public-role
     policy on the same table/operation.
  2. Drop service_role policies that are unnecessary because the service_role key
     bypasses Row Level Security entirely in Supabase.
  3. Consolidate legitimate multi-condition policies (e.g., "own rows OR shared rows")
     into a single combined policy using OR.

  ## Tables fixed
  conversation_starters, drink_categories, geofence_events, google_place_cache,
  interests, looking_for_options, messages (SELECT + UPDATE), mixed_drinks,
  notifications, translation_keys, translations, user_venue_presence (SELECT/INSERT/UPDATE),
  venue_ratings, venue_sessions, venues
*/

-- ─────────────────────────────────────────────────────────────────
-- 1. Lookup/reference tables: drop the authenticated-role SELECT
--    policies because the public-role policy already covers everyone.
-- ─────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Conversation starters are readable by authenticated users" ON conversation_starters;
DROP POLICY IF EXISTS "Drink categories are readable by authenticated users" ON drink_categories;
DROP POLICY IF EXISTS "Interests are readable by authenticated users" ON interests;
DROP POLICY IF EXISTS "Looking for options are readable by authenticated users" ON looking_for_options;
DROP POLICY IF EXISTS "Mixed drinks are readable by authenticated users" ON mixed_drinks;
DROP POLICY IF EXISTS "Translation keys are readable by authenticated users" ON translation_keys;
DROP POLICY IF EXISTS "Translations are readable by authenticated users" ON translations;
DROP POLICY IF EXISTS "Authenticated users can view cache" ON google_place_cache;

-- venue_ratings: public policy grants all access; authenticated friend-filter is moot
DROP POLICY IF EXISTS "Users can view friend ratings" ON venue_ratings;

-- venues: replace anon + authenticated pair with a single anon+authenticated policy
DROP POLICY IF EXISTS "Anon can view venues" ON venues;
DROP POLICY IF EXISTS "Anyone can view venues" ON venues;
CREATE POLICY "Anyone can view venues"
  ON venues
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ─────────────────────────────────────────────────────────────────
-- 2. service_role policies: unnecessary because service_role bypasses
--    RLS entirely. Removing them has no effect on functionality.
-- ─────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Service role can insert presence" ON user_venue_presence;
DROP POLICY IF EXISTS "Service role can update presence" ON user_venue_presence;
DROP POLICY IF EXISTS "Service role can insert notifications" ON notifications;

-- ─────────────────────────────────────────────────────────────────
-- 3. Consolidate legitimate multi-condition SELECT/UPDATE policies
--    into single combined policies using OR.
-- ─────────────────────────────────────────────────────────────────

-- messages SELECT: DM access + swarm access → one combined policy
DROP POLICY IF EXISTS "Users can view messages in their DMs" ON messages;
DROP POLICY IF EXISTS "Users can view messages in swarms they are part of" ON messages;
CREATE POLICY "Users can view their messages"
  ON messages
  FOR SELECT
  TO authenticated
  USING (
    ((conversation_type = 'dm') AND
      ((SELECT auth.uid() AS uid) = dm_user_a OR (SELECT auth.uid() AS uid) = dm_user_b))
    OR
    ((conversation_type = 'swarm') AND
      EXISTS (
        SELECT 1 FROM swarm_members
        WHERE swarm_members.swarm_id = messages.swarm_id
          AND swarm_members.user_id = (SELECT auth.uid() AS uid)
      ))
  );

-- messages UPDATE: sender edits + read receipts → one combined policy
DROP POLICY IF EXISTS "Senders can update own messages" ON messages;
DROP POLICY IF EXISTS "Recipients can mark messages as read" ON messages;
CREATE POLICY "Users can update their messages"
  ON messages
  FOR UPDATE
  TO authenticated
  USING (
    ((SELECT auth.uid() AS uid) = sender_user_id)
    OR
    ((conversation_type = 'dm') AND
      ((SELECT auth.uid() AS uid) = dm_user_a OR (SELECT auth.uid() AS uid) = dm_user_b))
    OR
    ((conversation_type = 'swarm') AND
      EXISTS (
        SELECT 1 FROM swarm_members
        WHERE swarm_members.swarm_id = messages.swarm_id
          AND swarm_members.user_id = (SELECT auth.uid() AS uid)
      ))
  )
  WITH CHECK (
    ((SELECT auth.uid() AS uid) = sender_user_id)
    OR
    ((conversation_type = 'dm') AND
      ((SELECT auth.uid() AS uid) = dm_user_a OR (SELECT auth.uid() AS uid) = dm_user_b))
    OR
    ((conversation_type = 'swarm') AND
      EXISTS (
        SELECT 1 FROM swarm_members
        WHERE swarm_members.swarm_id = messages.swarm_id
          AND swarm_members.user_id = (SELECT auth.uid() AS uid)
      ))
  );

-- geofence_events SELECT: own events + events at venues user has entered → combined
DROP POLICY IF EXISTS "Users can read own geofence events" ON geofence_events;
DROP POLICY IF EXISTS "Users can read events at their venues" ON geofence_events;
CREATE POLICY "Users can read geofence events"
  ON geofence_events
  FOR SELECT
  TO authenticated
  USING (
    (auth.uid() = user_id)
    OR
    (venue_id IN (
      SELECT ge2.venue_id FROM geofence_events ge2
      WHERE ge2.user_id = auth.uid()
        AND ge2.event_type = 'enter'
        AND ge2.triggered_at > (now() - interval '24 hours')
    ))
  );

-- user_venue_presence SELECT: own presence + visible friends/swarm-members → combined
DROP POLICY IF EXISTS "Users can view own presence" ON user_venue_presence;
DROP POLICY IF EXISTS "Users can view presence of mutual friends and swarm members" ON user_venue_presence;
CREATE POLICY "Users can view relevant presence"
  ON user_venue_presence
  FOR SELECT
  TO authenticated
  USING (
    (auth.uid() = user_id)
    OR
    (
      is_visible_in_venue = true
      AND status = 'IN_VENUE'
      AND left_at IS NULL
      AND last_seen_at > (now() - interval '24 hours')
      AND (
        EXISTS (
          SELECT 1 FROM friendships
          WHERE friendships.status = 'accepted'
            AND (
              (friendships.user_id = auth.uid() AND friendships.friend_id = user_venue_presence.user_id)
              OR (friendships.friend_id = auth.uid() AND friendships.user_id = user_venue_presence.user_id)
            )
        )
        OR EXISTS (
          SELECT 1
          FROM swarm_members sm1
          JOIN swarm_members sm2 ON sm1.swarm_id = sm2.swarm_id
          JOIN swarms s ON s.id = sm1.swarm_id
          WHERE sm1.user_id = auth.uid()
            AND sm2.user_id = user_venue_presence.user_id
            AND s.status = ANY(ARRAY['active', 'ongoing'])
        )
      )
    )
  );

-- venue_sessions SELECT: own sessions + sessions at same venue → combined
DROP POLICY IF EXISTS "Users can view own sessions" ON venue_sessions;
DROP POLICY IF EXISTS "Users can view sessions at bars they're at" ON venue_sessions;
CREATE POLICY "Users can view relevant venue sessions"
  ON venue_sessions
  FOR SELECT
  TO authenticated
  USING (
    ((SELECT auth.uid() AS uid) = user_id)
    OR
    EXISTS (
      SELECT 1 FROM venue_sessions vs
      WHERE vs.user_id = auth.uid()
        AND vs.bar_id = venue_sessions.bar_id
        AND vs.status = 'open'
    )
  );
