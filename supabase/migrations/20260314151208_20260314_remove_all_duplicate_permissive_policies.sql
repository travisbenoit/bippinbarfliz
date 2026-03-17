/*
  # Remove All Duplicate Permissive Policies

  ## Problem
  The Supabase security advisor flags tables where multiple PERMISSIVE policies exist
  for the same (table, operation) pair. Because permissive policies are OR'd together,
  duplicate policies create maintenance overhead and the advisor counts each table/cmd
  pair as a separate warning.

  ## Changes
  For every table with duplicate policies, the most restrictive/comprehensive single
  policy is kept and all redundant duplicates are dropped.

  ### Tables fixed:
  bars, check_in_streaks, cheers, conversations, emoji_reactions, friendships,
  gifts, google_api_logs, group_split_items, group_splits, location_events,
  location_pings, message_edits, messages, music_shares, night_route_invites,
  night_routes, safe_arrivals, subscriptions, swarm_members, swarms,
  user_blocks, user_gifts, user_venue_presence, users, venue_photos,
  venue_ratings, venue_reports, venue_reviews, venue_sessions
*/

-- bars: drop redundant authenticated SELECT (public policy already covers all users)
DROP POLICY IF EXISTS "Authenticated users can view all bars" ON bars;

-- check_in_streaks: keep the friend-inclusive SELECT, drop the own-only one
DROP POLICY IF EXISTS "Users can view own streaks" ON check_in_streaks;
-- UPDATE: keep one, drop the other
DROP POLICY IF EXISTS "Users can update own streaks" ON check_in_streaks;

-- cheers: INSERT and SELECT each have two identical policies
DROP POLICY IF EXISTS "Users can send cheers" ON cheers;
DROP POLICY IF EXISTS "Users can view received cheers" ON cheers;

-- conversations: keep participant-based SELECT, drop creator-based (less secure)
DROP POLICY IF EXISTS "Users can view own conversations" ON conversations;
-- UPDATE: keep admin/owner role check, drop simpler creator check
DROP POLICY IF EXISTS "Users can update own conversations" ON conversations;

-- emoji_reactions: 3 identical policies each for SELECT, INSERT, DELETE
DROP POLICY IF EXISTS "Users can view reactions" ON emoji_reactions;
DROP POLICY IF EXISTS "Authenticated users can view reactions" ON emoji_reactions;
DROP POLICY IF EXISTS "Users can add their own reactions" ON emoji_reactions;
DROP POLICY IF EXISTS "Users can create emoji reactions" ON emoji_reactions;
DROP POLICY IF EXISTS "Users can remove their own reactions" ON emoji_reactions;
DROP POLICY IF EXISTS "Users can remove their reactions" ON emoji_reactions;

-- friendships: 3 identical policies each for SELECT, UPDATE, DELETE
DROP POLICY IF EXISTS "Users can view their friendships" ON friendships;
DROP POLICY IF EXISTS "Users can view their own friendships" ON friendships;
DROP POLICY IF EXISTS "Users can update friendships involving them" ON friendships;
DROP POLICY IF EXISTS "Users can update friendships they are part of" ON friendships;
DROP POLICY IF EXISTS "Users can remove friendships" ON friendships;
DROP POLICY IF EXISTS "Users can delete their own friendship rows" ON friendships;

-- gifts: keep the OR-combined policy, drop the split ones
DROP POLICY IF EXISTS "Users can view gifts they received" ON gifts;
DROP POLICY IF EXISTS "Users can view gifts they sent" ON gifts;

-- google_api_logs: two identical SELECT policies
DROP POLICY IF EXISTS "Users can view their own API logs" ON google_api_logs;

-- group_split_items: keep the comprehensive policy
DROP POLICY IF EXISTS "Users can view split items" ON group_split_items;

-- group_splits: keep the comprehensive policy
DROP POLICY IF EXISTS "Users can view own splits" ON group_splits;

-- location_events: service_role ALL already covers INSERT; drop the redundant INSERT-only policy
DROP POLICY IF EXISTS "Service role full access to location_events" ON location_events;
-- SELECT: two identical policies
DROP POLICY IF EXISTS "Users can view their own location events" ON location_events;

-- location_pings: two identical INSERT, two identical SELECT
DROP POLICY IF EXISTS "Users can insert own location pings" ON location_pings;
DROP POLICY IF EXISTS "Users can view own pings" ON location_pings;

-- message_edits: keep the most comprehensive SELECT
DROP POLICY IF EXISTS "Users can view edits of their messages" ON message_edits;
DROP POLICY IF EXISTS "Users can view message edits" ON message_edits;

-- messages SELECT: 7 → 2 (DM and swarm)
DROP POLICY IF EXISTS "Users can view own messages" ON messages;
DROP POLICY IF EXISTS "Users can view own direct messages" ON messages;
DROP POLICY IF EXISTS "Users can view their own DM messages" ON messages;
DROP POLICY IF EXISTS "Users can view swarm messages they're in" ON messages;
DROP POLICY IF EXISTS "Users can view swarm messages they are in" ON messages;

-- messages INSERT: 4 → 1 (keep the comprehensive one)
DROP POLICY IF EXISTS "Users can send DM messages" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can send swarm messages" ON messages;

-- messages UPDATE: 6 → 2 (sender edits + recipient read receipts)
DROP POLICY IF EXISTS "Users can mark messages as read" ON messages;
DROP POLICY IF EXISTS "Users can soft delete own messages" ON messages;
DROP POLICY IF EXISTS "Users can update messages" ON messages;
DROP POLICY IF EXISTS "Users can update own messages" ON messages;

-- music_shares: 3 SELECT → 1 (combined), 2 INSERT → 1
DROP POLICY IF EXISTS "Users can view music they received" ON music_shares;
DROP POLICY IF EXISTS "Users can view music they sent" ON music_shares;
DROP POLICY IF EXISTS "Users can send music" ON music_shares;

-- night_route_invites: INSERT (keep creator-based), SELECT (keep comprehensive)
DROP POLICY IF EXISTS "Users can create route invites" ON night_route_invites;
DROP POLICY IF EXISTS "Users can view own route invites" ON night_route_invites;

-- night_routes: 2 INSERT → 1, 2 SELECT → 1, 2 UPDATE → 1
DROP POLICY IF EXISTS "Users can create routes" ON night_routes;
DROP POLICY IF EXISTS "Users can view own night routes" ON night_routes;
DROP POLICY IF EXISTS "Users can update own night routes" ON night_routes;

-- safe_arrivals: 2 INSERT → 1, 2 SELECT → 1 (keep friend-inclusive)
DROP POLICY IF EXISTS "Users can create own safe arrivals" ON safe_arrivals;
DROP POLICY IF EXISTS "Users can view own arrivals" ON safe_arrivals;

-- subscriptions: 2 INSERT → 1
DROP POLICY IF EXISTS "Users can create own subscriptions" ON subscriptions;

-- swarm_members: 2 UPDATE → 1 (keep the one with WITH CHECK)
DROP POLICY IF EXISTS "Users can update own membership" ON swarm_members;

-- swarms: SELECT (true already covers all cases), UPDATE 2 → 1
DROP POLICY IF EXISTS "Authenticated users can view accessible swarms" ON swarms;
DROP POLICY IF EXISTS "Hosts can update their swarms" ON swarms;

-- user_blocks: 2 SELECT → 1 (comprehensive), 2 INSERT → 1, 2 DELETE → 1
DROP POLICY IF EXISTS "Users can read own blocks" ON user_blocks;
DROP POLICY IF EXISTS "Users can create blocks" ON user_blocks;
DROP POLICY IF EXISTS "Users can delete own blocks" ON user_blocks;

-- user_gifts: 3 SELECT → 1 (combined), 2 INSERT → 1, 3 UPDATE → 1
DROP POLICY IF EXISTS "Users can view gifts they received" ON user_gifts;
DROP POLICY IF EXISTS "Users can view gifts they sent" ON user_gifts;
DROP POLICY IF EXISTS "Users can send gifts" ON user_gifts;
DROP POLICY IF EXISTS "Recipients can update received gifts" ON user_gifts;
DROP POLICY IF EXISTS "Users can update own gifts" ON user_gifts;

-- user_venue_presence SELECT: 4 → 2 (own presence + friends/swarm members)
DROP POLICY IF EXISTS "Users can view venue presence" ON user_venue_presence;
DROP POLICY IF EXISTS "Users can view visible presence of others" ON user_venue_presence;

-- users SELECT: "Users can view other profiles" (qual=true) subsumes the own-only policy
DROP POLICY IF EXISTS "Users can view own profile" ON users;

-- venue_photos: 2 DELETE → 1
DROP POLICY IF EXISTS "Users can delete their own photos" ON venue_photos;

-- venue_ratings: 2 INSERT → 1
DROP POLICY IF EXISTS "Users can insert own ratings" ON venue_ratings;

-- venue_reports: 2 SELECT → 1, 2 INSERT → 1, keep the pending-restricted UPDATE
DROP POLICY IF EXISTS "Users can read own reports" ON venue_reports;
DROP POLICY IF EXISTS "Users can create venue reports" ON venue_reports;
DROP POLICY IF EXISTS "Users can update own reports" ON venue_reports;

-- venue_reviews: 2 UPDATE → 1
DROP POLICY IF EXISTS "Users can update their own reviews" ON venue_reviews;

-- venue_sessions: 3 SELECT → 2 (own sessions + venue-based)
DROP POLICY IF EXISTS "Users can view their own sessions" ON venue_sessions;
