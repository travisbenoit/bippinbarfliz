/*
  # Complete RLS Optimization - Final Fix

  Comprehensive RLS policy optimization for all remaining tables by wrapping
  auth.uid() calls in SELECT subqueries to prevent re-evaluation per row.
  
  This follows Supabase performance best practices for RLS policies at scale.
  
  Tables optimized:
  - music_shares, user_gifts, gifts, conversations, venue_reports
  - night_routes, night_route_invites, venue_ratings, check_in_streaks
  - safe_arrivals, group_splits, group_split_items, user_venue_presence
  - location_events, location_pings, user_inventory, payment_transactions
  - subscriptions, message_edits, cheers, google_api_logs, venue_sessions
  - emoji_reactions, bars, google_place_cache, venue_reviews, venue_photos
  - translations, translation_keys, reference data tables
*/

-- Music Shares
DROP POLICY IF EXISTS "Users can create music shares" ON music_shares;
CREATE POLICY "Users can create music shares"
  ON music_shares FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = sender_id);

DROP POLICY IF EXISTS "Users can view received music" ON music_shares;
CREATE POLICY "Users can view received music"
  ON music_shares FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = recipient_id OR (SELECT auth.uid()) = sender_id);

-- User Gifts
DROP POLICY IF EXISTS "Users can create gifts" ON user_gifts;
CREATE POLICY "Users can create gifts"
  ON user_gifts FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = from_user_id);

DROP POLICY IF EXISTS "Users can view own gifts" ON user_gifts;
CREATE POLICY "Users can view own gifts"
  ON user_gifts FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = from_user_id OR (SELECT auth.uid()) = to_user_id);

DROP POLICY IF EXISTS "Users can update own gifts" ON user_gifts;
CREATE POLICY "Users can update own gifts"
  ON user_gifts FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = to_user_id)
  WITH CHECK ((SELECT auth.uid()) = to_user_id);

-- Gifts
DROP POLICY IF EXISTS "Users can create gifts" ON gifts;
CREATE POLICY "Users can create gifts"
  ON gifts FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = from_user_id);

DROP POLICY IF EXISTS "Users can view gifts" ON gifts;
CREATE POLICY "Users can view gifts"
  ON gifts FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = from_user_id OR (SELECT auth.uid()) = to_user_id);

-- Conversations
DROP POLICY IF EXISTS "Users can view own conversations" ON conversations;
CREATE POLICY "Users can view own conversations"
  ON conversations FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = created_by);

DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
CREATE POLICY "Users can create conversations"
  ON conversations FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = created_by);

DROP POLICY IF EXISTS "Users can update own conversations" ON conversations;
CREATE POLICY "Users can update own conversations"
  ON conversations FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = created_by)
  WITH CHECK ((SELECT auth.uid()) = created_by);

-- Venue Reports
DROP POLICY IF EXISTS "Users can create venue reports" ON venue_reports;
CREATE POLICY "Users can create venue reports"
  ON venue_reports FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = reporter_id);

DROP POLICY IF EXISTS "Users can view own reports" ON venue_reports;
CREATE POLICY "Users can view own reports"
  ON venue_reports FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = reporter_id OR (SELECT auth.uid()) = resolved_by);

DROP POLICY IF EXISTS "Users can update own reports" ON venue_reports;
CREATE POLICY "Users can update own reports"
  ON venue_reports FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = reporter_id)
  WITH CHECK ((SELECT auth.uid()) = reporter_id);

-- Night Routes
DROP POLICY IF EXISTS "Users can view own night routes" ON night_routes;
CREATE POLICY "Users can view own night routes"
  ON night_routes FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = creator_id);

DROP POLICY IF EXISTS "Users can create night routes" ON night_routes;
CREATE POLICY "Users can create night routes"
  ON night_routes FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = creator_id);

DROP POLICY IF EXISTS "Users can update own night routes" ON night_routes;
CREATE POLICY "Users can update own night routes"
  ON night_routes FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = creator_id)
  WITH CHECK ((SELECT auth.uid()) = creator_id);

-- Night Route Invites
DROP POLICY IF EXISTS "Users can view own route invites" ON night_route_invites;
CREATE POLICY "Users can view own route invites"
  ON night_route_invites FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can create route invites" ON night_route_invites;
CREATE POLICY "Users can create route invites"
  ON night_route_invites FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Venue Ratings
DROP POLICY IF EXISTS "Users can create venue ratings" ON venue_ratings;
CREATE POLICY "Users can create venue ratings"
  ON venue_ratings FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Public can view venue ratings" ON venue_ratings;
CREATE POLICY "Public can view venue ratings"
  ON venue_ratings FOR SELECT
  USING (true);

-- Check-in Streaks
DROP POLICY IF EXISTS "Users can view own streaks" ON check_in_streaks;
CREATE POLICY "Users can view own streaks"
  ON check_in_streaks FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own streaks" ON check_in_streaks;
CREATE POLICY "Users can update own streaks"
  ON check_in_streaks FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Safe Arrivals
DROP POLICY IF EXISTS "Users can create safe arrivals" ON safe_arrivals;
CREATE POLICY "Users can create safe arrivals"
  ON safe_arrivals FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view own arrivals" ON safe_arrivals;
CREATE POLICY "Users can view own arrivals"
  ON safe_arrivals FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- Group Splits
DROP POLICY IF EXISTS "Users can view own splits" ON group_splits;
CREATE POLICY "Users can view own splits"
  ON group_splits FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = creator_id);

DROP POLICY IF EXISTS "Users can create splits" ON group_splits;
CREATE POLICY "Users can create splits"
  ON group_splits FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = creator_id);

-- Group Split Items
DROP POLICY IF EXISTS "Users can view split items" ON group_split_items;
CREATE POLICY "Users can view split items"
  ON group_split_items FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- User Venue Presence
DROP POLICY IF EXISTS "Users can view venue presence" ON user_venue_presence;
CREATE POLICY "Users can view venue presence"
  ON user_venue_presence FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own presence" ON user_venue_presence;
CREATE POLICY "Users can update own presence"
  ON user_venue_presence FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Location Events
DROP POLICY IF EXISTS "Users can create location events" ON location_events;
CREATE POLICY "Users can create location events"
  ON location_events FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view own location events" ON location_events;
CREATE POLICY "Users can view own location events"
  ON location_events FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- Location Pings
DROP POLICY IF EXISTS "Users can create location pings" ON location_pings;
CREATE POLICY "Users can create location pings"
  ON location_pings FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view own pings" ON location_pings;
CREATE POLICY "Users can view own pings"
  ON location_pings FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- User Inventory
DROP POLICY IF EXISTS "Users can view own inventory" ON user_inventory;
CREATE POLICY "Users can view own inventory"
  ON user_inventory FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update own inventory" ON user_inventory;
CREATE POLICY "Users can update own inventory"
  ON user_inventory FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Payment Transactions
DROP POLICY IF EXISTS "Users can view own transactions" ON payment_transactions;
CREATE POLICY "Users can view own transactions"
  ON payment_transactions FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = from_user_id OR (SELECT auth.uid()) = to_user_id);

DROP POLICY IF EXISTS "Users can create transactions" ON payment_transactions;
CREATE POLICY "Users can create transactions"
  ON payment_transactions FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = from_user_id);

-- Subscriptions
DROP POLICY IF EXISTS "Users can view own subscriptions" ON subscriptions;
CREATE POLICY "Users can view own subscriptions"
  ON subscriptions FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can create subscriptions" ON subscriptions;
CREATE POLICY "Users can create subscriptions"
  ON subscriptions FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- Message Edits
DROP POLICY IF EXISTS "Users can view message edits" ON message_edits;
CREATE POLICY "Users can view message edits"
  ON message_edits FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = edited_by);

-- Cheers
DROP POLICY IF EXISTS "Users can create cheers" ON cheers;
CREATE POLICY "Users can create cheers"
  ON cheers FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = sender_id);

DROP POLICY IF EXISTS "Users can view received cheers" ON cheers;
CREATE POLICY "Users can view received cheers"
  ON cheers FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = recipient_id OR (SELECT auth.uid()) = sender_id);

-- Google API Logs
DROP POLICY IF EXISTS "Users can view own API logs" ON google_api_logs;
CREATE POLICY "Users can view own API logs"
  ON google_api_logs FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- Venue Sessions
DROP POLICY IF EXISTS "Users can create venue sessions" ON venue_sessions;
CREATE POLICY "Users can create venue sessions"
  ON venue_sessions FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view own sessions" ON venue_sessions;
CREATE POLICY "Users can view own sessions"
  ON venue_sessions FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- Emoji Reactions
DROP POLICY IF EXISTS "Users can create emoji reactions" ON emoji_reactions;
CREATE POLICY "Users can create emoji reactions"
  ON emoji_reactions FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own reactions" ON emoji_reactions;
CREATE POLICY "Users can delete own reactions"
  ON emoji_reactions FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- Bars (read-only, public)
DROP POLICY IF EXISTS "Public can view bars" ON bars;
CREATE POLICY "Public can view bars"
  ON bars FOR SELECT
  USING (true);

-- Google Place Cache (read-only, public)
DROP POLICY IF EXISTS "Public can view place cache" ON google_place_cache;
CREATE POLICY "Public can view place cache"
  ON google_place_cache FOR SELECT
  USING (true);

-- Venue Reviews
DROP POLICY IF EXISTS "Authenticated users can create reviews" ON venue_reviews;
CREATE POLICY "Authenticated users can create reviews"
  ON venue_reviews FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = created_by_user_id);

DROP POLICY IF EXISTS "Public can view venue reviews" ON venue_reviews;
CREATE POLICY "Public can view venue reviews"
  ON venue_reviews FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can update own reviews" ON venue_reviews;
CREATE POLICY "Users can update own reviews"
  ON venue_reviews FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = created_by_user_id)
  WITH CHECK ((SELECT auth.uid()) = created_by_user_id);

-- Venue Photos
DROP POLICY IF EXISTS "Authenticated users can upload photos" ON venue_photos;
CREATE POLICY "Authenticated users can upload photos"
  ON venue_photos FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = created_by_user_id);

DROP POLICY IF EXISTS "Public can view venue photos" ON venue_photos;
CREATE POLICY "Public can view venue photos"
  ON venue_photos FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can delete own photos" ON venue_photos;
CREATE POLICY "Users can delete own photos"
  ON venue_photos FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = created_by_user_id);

-- Translations (read-only, public)
DROP POLICY IF EXISTS "Public can view translations" ON translations;
CREATE POLICY "Public can view translations"
  ON translations FOR SELECT
  USING (true);

-- Translation Keys (read-only, public)
DROP POLICY IF EXISTS "Public can view translation keys" ON translation_keys;
CREATE POLICY "Public can view translation keys"
  ON translation_keys FOR SELECT
  USING (true);
