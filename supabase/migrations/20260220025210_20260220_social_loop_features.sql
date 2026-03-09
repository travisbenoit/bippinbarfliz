/*
  # Social Loop Features Migration

  ## New Tables
  - cheers: Friend toasts at same venue
  - venue_ratings: Private friend-network 1-5 star ratings
  - night_routes: Planned bar crawl routes with stops
  - night_route_invites: Route invitations
  - safe_arrivals: "I'm home safe" confirmations
  - check_in_streaks: Consecutive nights-out tracking
  - group_splits: Bill splitting for swarms
  - group_split_items: Individual amounts per split

  ## Modified Tables
  - users: add is_dd_tonight, dd_expires_at columns
*/

-- cheers table
CREATE TABLE IF NOT EXISTS cheers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cheers_recipient ON cheers(recipient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cheers_sender ON cheers(sender_id, created_at DESC);

ALTER TABLE cheers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can send cheers"
  ON cheers FOR INSERT TO authenticated
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can view own cheers"
  ON cheers FOR SELECT TO authenticated
  USING (sender_id = auth.uid() OR recipient_id = auth.uid());

-- venue_ratings table
CREATE TABLE IF NOT EXISTS venue_ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  venue_id uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, venue_id)
);

CREATE INDEX IF NOT EXISTS idx_venue_ratings_venue ON venue_ratings(venue_id);
CREATE INDEX IF NOT EXISTS idx_venue_ratings_user ON venue_ratings(user_id);

ALTER TABLE venue_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view friend ratings"
  ON venue_ratings FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM friendships
      WHERE status = 'accepted'
      AND (
        (friendships.user_id = auth.uid() AND friendships.friend_id = venue_ratings.user_id)
        OR (friendships.friend_id = auth.uid() AND friendships.user_id = venue_ratings.user_id)
      )
    )
  );

CREATE POLICY "Users can insert own ratings"
  ON venue_ratings FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own ratings"
  ON venue_ratings FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own ratings"
  ON venue_ratings FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- night_routes table
CREATE TABLE IF NOT EXISTS night_routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name text NOT NULL DEFAULT 'My Night Out',
  stops jsonb NOT NULL DEFAULT '[]',
  planned_date date,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'completed', 'cancelled')),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_night_routes_creator ON night_routes(creator_id, created_at DESC);

ALTER TABLE night_routes ENABLE ROW LEVEL SECURITY;

-- night_route_invites table (must come before policies that reference it)
CREATE TABLE IF NOT EXISTS night_route_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id uuid NOT NULL REFERENCES night_routes(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(route_id, user_id)
);

ALTER TABLE night_route_invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own routes and invited routes"
  ON night_routes FOR SELECT TO authenticated
  USING (
    creator_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM night_route_invites
      WHERE night_route_invites.route_id = night_routes.id AND night_route_invites.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create routes"
  ON night_routes FOR INSERT TO authenticated
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "Creators can update own routes"
  ON night_routes FOR UPDATE TO authenticated
  USING (creator_id = auth.uid())
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "Creators can delete own routes"
  ON night_routes FOR DELETE TO authenticated
  USING (creator_id = auth.uid());

CREATE POLICY "Users can view invites they sent or received"
  ON night_route_invites FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (SELECT 1 FROM night_routes WHERE night_routes.id = route_id AND night_routes.creator_id = auth.uid())
  );

CREATE POLICY "Route creators can send invites"
  ON night_route_invites FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM night_routes WHERE night_routes.id = route_id AND night_routes.creator_id = auth.uid())
  );

CREATE POLICY "Invited users can update invite status"
  ON night_route_invites FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- safe_arrivals table
CREATE TABLE IF NOT EXISTS safe_arrivals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  checked_in_at timestamptz DEFAULT now(),
  notified_friend_ids jsonb DEFAULT '[]'
);

CREATE INDEX IF NOT EXISTS idx_safe_arrivals_user ON safe_arrivals(user_id, checked_in_at DESC);

ALTER TABLE safe_arrivals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own and friends safe arrivals"
  ON safe_arrivals FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM friendships
      WHERE status = 'accepted'
      AND (
        (friendships.user_id = auth.uid() AND friendships.friend_id = safe_arrivals.user_id)
        OR (friendships.friend_id = auth.uid() AND friendships.user_id = safe_arrivals.user_id)
      )
    )
  );

CREATE POLICY "Users can create own safe arrivals"
  ON safe_arrivals FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- check_in_streaks table
CREATE TABLE IF NOT EXISTS check_in_streaks (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  current_streak integer NOT NULL DEFAULT 0,
  longest_streak integer NOT NULL DEFAULT 0,
  last_checkin_date date,
  total_checkins integer NOT NULL DEFAULT 0,
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE check_in_streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view friend streaks"
  ON check_in_streaks FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM friendships
      WHERE status = 'accepted'
      AND (
        (friendships.user_id = auth.uid() AND friendships.friend_id = check_in_streaks.user_id)
        OR (friendships.friend_id = auth.uid() AND friendships.user_id = check_in_streaks.user_id)
      )
    )
  );

CREATE POLICY "Users can insert own streak"
  ON check_in_streaks FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own streak"
  ON check_in_streaks FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- group_splits table
CREATE TABLE IF NOT EXISTS group_splits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  swarm_id uuid REFERENCES swarms(id) ON DELETE SET NULL,
  creator_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total_amount numeric(10,2) NOT NULL DEFAULT 0,
  description text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'settled', 'cancelled')),
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_group_splits_swarm ON group_splits(swarm_id);

ALTER TABLE group_splits ENABLE ROW LEVEL SECURITY;

-- group_split_items table (must come before policies)
CREATE TABLE IF NOT EXISTS group_split_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  split_id uuid NOT NULL REFERENCES group_splits(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount numeric(10,2) NOT NULL DEFAULT 0,
  paid boolean NOT NULL DEFAULT false,
  paid_at timestamptz,
  UNIQUE(split_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_split_items_split ON group_split_items(split_id);
CREATE INDEX IF NOT EXISTS idx_split_items_user ON group_split_items(user_id);

ALTER TABLE group_split_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Split participants can view splits"
  ON group_splits FOR SELECT TO authenticated
  USING (
    creator_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM group_split_items
      WHERE group_split_items.split_id = group_splits.id AND group_split_items.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create splits"
  ON group_splits FOR INSERT TO authenticated
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "Creators can update splits"
  ON group_splits FOR UPDATE TO authenticated
  USING (creator_id = auth.uid())
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "Split participants can view items"
  ON group_split_items FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM group_splits
      WHERE group_splits.id = split_id AND group_splits.creator_id = auth.uid()
    )
  );

CREATE POLICY "Creators can add split items"
  ON group_split_items FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM group_splits WHERE group_splits.id = split_id AND group_splits.creator_id = auth.uid())
  );

CREATE POLICY "Users can update own payment status"
  ON group_split_items FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Add DD mode to users table
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'is_dd_tonight') THEN
    ALTER TABLE users ADD COLUMN is_dd_tonight boolean NOT NULL DEFAULT false;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'dd_expires_at') THEN
    ALTER TABLE users ADD COLUMN dd_expires_at timestamptz;
  END IF;
END $$;
