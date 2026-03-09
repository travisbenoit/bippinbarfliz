/*
  # Nightlife XP — gamification with stats, badges, and challenges

  1. New Tables
    - `user_stats`
      - `user_id` (uuid, primary key, references auth.users)
      - `total_xp` (int, defaults to 0)
      - `current_streak` (int, defaults to 0)
      - `longest_streak` (int, defaults to 0)
      - `last_streak_at` (timestamptz, nullable)
      - `unique_venues` (int, defaults to 0)
      - `total_checkins` (int, defaults to 0)
      - `updated_at` (timestamptz)
    
    - `user_badges`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `badge_key` (text, e.g. 'first_checkin', 'night_owl')
      - `earned_at` (timestamptz)
      - Unique constraint on (user_id, badge_key)
    
    - `user_challenges`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `challenge_key` (text)
      - `progress` (int, defaults to 0)
      - `target` (int)
      - `reward_xp` (int)
      - `status` (text: 'active', 'completed', 'expired')
      - `started_at` (timestamptz)
      - `completed_at` (timestamptz, nullable)
      - `expires_at` (timestamptz, nullable)
      - Unique constraint on (user_id, challenge_key, started_at)
  
  2. Indexes
    - `idx_user_badges_user` on user_badges (user_id)
    - `idx_user_challenges_active` on user_challenges (user_id, status) where status = 'active'
  
  3. Security
    - RLS enabled on all three tables
    - user_stats: public read (leaderboards), users can insert/update own
    - user_badges: public read (profile display), users can insert own
    - user_challenges: private (only self can view/manage)
*/

CREATE TABLE IF NOT EXISTS user_stats (
  user_id        uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  total_xp       int DEFAULT 0,
  current_streak int DEFAULT 0,
  longest_streak int DEFAULT 0,
  last_streak_at timestamptz,
  unique_venues  int DEFAULT 0,
  total_checkins int DEFAULT 0,
  updated_at     timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_badges (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  badge_key  text NOT NULL,
  earned_at  timestamptz DEFAULT now(),
  UNIQUE(user_id, badge_key)
);

CREATE INDEX IF NOT EXISTS idx_user_badges_user ON user_badges (user_id);

CREATE TABLE IF NOT EXISTS user_challenges (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_key  text NOT NULL,
  progress       int DEFAULT 0,
  target         int NOT NULL,
  reward_xp      int NOT NULL,
  status         text DEFAULT 'active' CHECK (status IN ('active', 'completed', 'expired')),
  started_at     timestamptz DEFAULT now(),
  completed_at   timestamptz,
  expires_at     timestamptz,
  UNIQUE(user_id, challenge_key, started_at)
);

CREATE INDEX IF NOT EXISTS idx_user_challenges_active
  ON user_challenges (user_id, status) WHERE status = 'active';

ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read user stats"
  ON user_stats FOR SELECT USING (true);

CREATE POLICY "Users can insert own stats"
  ON user_stats FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own stats"
  ON user_stats FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Anyone can read badges"
  ON user_badges FOR SELECT USING (true);

CREATE POLICY "Users can earn badges"
  ON user_badges FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view own challenges"
  ON user_challenges FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own challenges"
  ON user_challenges FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own challenges"
  ON user_challenges FOR UPDATE USING (user_id = auth.uid());