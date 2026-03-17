/*
  # Fix Policies That Should Require Authentication

  ## Problem
  Several INSERT, UPDATE, and DELETE policies are assigned to the `public` role
  (which includes unauthenticated/anon users) instead of the `authenticated` role.
  Although the WITH CHECK / USING clauses reference auth.uid() — which returns NULL
  for anon users, making them effectively blocked at runtime — the Supabase security
  advisor flags these as a misconfiguration because the intent should be expressed
  explicitly via the role restriction, not implicitly via a null auth.uid() check.

  ## Changes
  The following policies are dropped and recreated with `TO authenticated`:
  - user_badges: INSERT "Users can earn badges"
  - user_challenges: INSERT "Users can insert own challenges"
  - user_challenges: UPDATE "Users can update own challenges"
  - user_stats: INSERT "Users can insert own stats"
  - user_stats: UPDATE "Users can update own stats"
  - venue_buzz: INSERT "Users can post buzz"
  - venue_buzz: DELETE "Users can delete own buzz"
  - vibe_votes: INSERT "Users can cast vibe votes"
*/

DROP POLICY IF EXISTS "Users can earn badges" ON user_badges;
CREATE POLICY "Users can earn badges"
  ON user_badges
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own challenges" ON user_challenges;
CREATE POLICY "Users can insert own challenges"
  ON user_challenges
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own challenges" ON user_challenges;
CREATE POLICY "Users can update own challenges"
  ON user_challenges
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own stats" ON user_stats;
CREATE POLICY "Users can insert own stats"
  ON user_stats
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own stats" ON user_stats;
CREATE POLICY "Users can update own stats"
  ON user_stats
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can post buzz" ON venue_buzz;
CREATE POLICY "Users can post buzz"
  ON venue_buzz
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own buzz" ON venue_buzz;
CREATE POLICY "Users can delete own buzz"
  ON venue_buzz
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can cast vibe votes" ON vibe_votes;
CREATE POLICY "Users can cast vibe votes"
  ON vibe_votes
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());
