-- Migration 000010: Nightlife XP — stats, badges, challenges

-- User XP totals + streak tracking
CREATE TABLE user_stats (
  user_id        uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  total_xp       int DEFAULT 0,
  current_streak int DEFAULT 0,
  longest_streak int DEFAULT 0,
  last_streak_at timestamptz,
  unique_venues  int DEFAULT 0,
  total_checkins int DEFAULT 0,
  updated_at     timestamptz DEFAULT now()
);

-- Earned badges
CREATE TABLE user_badges (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  badge_key  text NOT NULL,
  earned_at  timestamptz DEFAULT now(),
  UNIQUE(user_id, badge_key)
);

CREATE INDEX idx_user_badges_user ON user_badges (user_id);

-- Active + completed challenges
CREATE TABLE user_challenges (
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

CREATE INDEX idx_user_challenges_active
  ON user_challenges (user_id, status) WHERE status = 'active';

-- RLS
ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_challenges ENABLE ROW LEVEL SECURITY;

-- user_stats: anyone can read (leaderboards), only self can update
CREATE POLICY "Anyone can read user stats"
  ON user_stats FOR SELECT USING (true);
CREATE POLICY "Users can insert own stats"
  ON user_stats FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own stats"
  ON user_stats FOR UPDATE USING (user_id = auth.uid());

-- user_badges: anyone can read (profile display), only self inserts
CREATE POLICY "Anyone can read badges"
  ON user_badges FOR SELECT USING (true);
CREATE POLICY "Users can earn badges"
  ON user_badges FOR INSERT WITH CHECK (user_id = auth.uid());

-- user_challenges: only self can see/manage
CREATE POLICY "Users can view own challenges"
  ON user_challenges FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own challenges"
  ON user_challenges FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own challenges"
  ON user_challenges FOR UPDATE USING (user_id = auth.uid());
