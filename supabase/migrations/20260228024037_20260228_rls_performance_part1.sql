/*
  # RLS Performance Optimization - Part 1
  
  Optimize auth function calls in RLS policies for better performance.
  Replace auth.uid() with (select auth.uid()) to prevent re-evaluation per row.
*/

-- Test with one simple table first
DROP POLICY IF EXISTS "Weather data is publicly readable" ON weather_cache;
CREATE POLICY "Weather data is publicly readable" ON weather_cache FOR SELECT TO authenticated
  USING ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Translations are readable by authenticated users" ON translations;
CREATE POLICY "Translations are readable by authenticated users" ON translations FOR SELECT TO authenticated
  USING ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can view all bars" ON bars;
CREATE POLICY "Authenticated users can view all bars" ON bars FOR SELECT TO authenticated
  USING ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can view cache" ON google_place_cache;
CREATE POLICY "Authenticated users can view cache" ON google_place_cache FOR SELECT TO authenticated
  USING ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Translation keys are readable by authenticated users" ON translation_keys;
CREATE POLICY "Translation keys are readable by authenticated users" ON translation_keys FOR SELECT TO authenticated
  USING ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Drink categories are readable by authenticated users" ON drink_categories;
CREATE POLICY "Drink categories are readable by authenticated users" ON drink_categories FOR SELECT TO authenticated
  USING ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Mixed drinks are readable by authenticated users" ON mixed_drinks;
CREATE POLICY "Mixed drinks are readable by authenticated users" ON mixed_drinks FOR SELECT TO authenticated
  USING ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Interests are readable by authenticated users" ON interests;
CREATE POLICY "Interests are readable by authenticated users" ON interests FOR SELECT TO authenticated
  USING ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Looking for options are readable by authenticated users" ON looking_for_options;
CREATE POLICY "Looking for options are readable by authenticated users" ON looking_for_options FOR SELECT TO authenticated
  USING ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Conversation starters are readable by authenticated users" ON conversation_starters;
CREATE POLICY "Conversation starters are readable by authenticated users" ON conversation_starters FOR SELECT TO authenticated
  USING ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated users can view reactions" ON emoji_reactions;
CREATE POLICY "Authenticated users can view reactions" ON emoji_reactions FOR SELECT TO authenticated
  USING ((select auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "Users can add their own reactions" ON emoji_reactions;
CREATE POLICY "Users can add their own reactions" ON emoji_reactions FOR INSERT TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS "Users can remove their own reactions" ON emoji_reactions;
CREATE POLICY "Users can remove their own reactions" ON emoji_reactions FOR DELETE TO authenticated
  USING (user_id = (select auth.uid()));
