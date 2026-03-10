/*
  # Initial Schema - Core Tables
  Creates the base users, venues, swarms, swarm_members, messages, reports, and blocks tables.
*/

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text,
  name text,
  username text UNIQUE,
  dob date,
  age integer,
  bio text,
  avatar_url text,
  photos text[],
  tonight_status text DEFAULT 'staying_in' CHECK (tonight_status IN ('out_now', 'going_out_soon', 'going_out', 'staying_in')),
  vibe_tags text[],
  favorite_drinks text[],
  venue_preferences text[],
  home_city text,
  last_known_lat numeric,
  last_known_lng numeric,
  preferred_radius_meters integer DEFAULT 5000,
  privacy_mode text DEFAULT 'nearby' CHECK (privacy_mode IN ('invisible', 'friends_only', 'nearby', 'public')),
  ghost_mode boolean DEFAULT false,
  is_premium boolean DEFAULT false,
  lush_coin_balance integer DEFAULT 0,
  venmo_username text,
  venmo_linked boolean DEFAULT false,
  weather_location text,
  weather_enabled boolean DEFAULT true,
  last_active_at timestamptz DEFAULT now(),
  is_21_plus_confirmed boolean DEFAULT false,
  phone_number text,
  phone_country_code text,
  registration_country text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can view other profiles"
  ON users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Create venues table
CREATE TABLE IF NOT EXISTS venues (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  address text,
  city text,
  state text,
  country text DEFAULT 'US',
  postal_code text,
  lat numeric NOT NULL,
  lng numeric NOT NULL,
  type text DEFAULT 'bar',
  category text,
  hours jsonb,
  verified boolean DEFAULT false,
  is_active boolean DEFAULT true,
  metadata jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE venues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view venues"
  ON venues FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Service role can manage venues"
  ON venues FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anon can view venues"
  ON venues FOR SELECT
  TO anon
  USING (true);

-- Create swarms table
CREATE TABLE IF NOT EXISTS swarms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  host_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  vibe_tags text[],
  venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
  start_time timestamptz,
  end_time timestamptz,
  max_attendees integer,
  join_mode text DEFAULT 'open' CHECK (join_mode IN ('open', 'request_approval')),
  status text DEFAULT 'active' CHECK (status IN ('active', 'ended', 'cancelled')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE swarms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active swarms"
  ON swarms FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create swarms"
  ON swarms FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = host_user_id);

CREATE POLICY "Hosts can update swarms"
  ON swarms FOR UPDATE
  TO authenticated
  USING (auth.uid() = host_user_id)
  WITH CHECK (auth.uid() = host_user_id);

-- Create swarm_members table
CREATE TABLE IF NOT EXISTS swarm_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  swarm_id uuid NOT NULL REFERENCES swarms(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role text DEFAULT 'member' CHECK (role IN ('host', 'member')),
  rsvp text DEFAULT 'going' CHECK (rsvp IN ('going', 'maybe', 'invited')),
  joined_at timestamptz DEFAULT now(),
  UNIQUE(swarm_id, user_id)
);

ALTER TABLE swarm_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view swarm members"
  ON swarm_members FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can join swarms"
  ON swarm_members FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own membership"
  ON swarm_members FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_type text DEFAULT 'dm' CHECK (conversation_type IN ('dm', 'swarm')),
  dm_user_a uuid REFERENCES users(id) ON DELETE CASCADE,
  dm_user_b uuid REFERENCES users(id) ON DELETE CASCADE,
  swarm_id uuid REFERENCES swarms(id) ON DELETE CASCADE,
  sender_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body text,
  media_url text,
  read_at timestamptz,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own messages"
  ON messages FOR SELECT
  TO authenticated
  USING (
    auth.uid() = sender_user_id
    OR auth.uid() = dm_user_a
    OR auth.uid() = dm_user_b
    OR swarm_id IN (SELECT swarm_id FROM swarm_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = sender_user_id);

CREATE POLICY "Users can update messages"
  ON messages FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = sender_user_id
    OR auth.uid() = dm_user_a
    OR auth.uid() = dm_user_b
  );

-- Create reports table
CREATE TABLE IF NOT EXISTS reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reported_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  context text CHECK (context IN ('dm', 'swarm', 'profile')),
  reason text NOT NULL,
  details text,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'actioned')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can create reports"
  ON reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reporter_user_id);

CREATE POLICY "Users can view own reports"
  ON reports FOR SELECT
  TO authenticated
  USING (auth.uid() = reporter_user_id);

-- Create blocks table
CREATE TABLE IF NOT EXISTS blocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(blocker_user_id, blocked_user_id)
);

ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own blocks"
  ON blocks FOR SELECT
  TO authenticated
  USING (auth.uid() = blocker_user_id);

CREATE POLICY "Users can create blocks"
  ON blocks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = blocker_user_id);

CREATE POLICY "Users can delete own blocks"
  ON blocks FOR DELETE
  TO authenticated
  USING (auth.uid() = blocker_user_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_tonight_status ON users(tonight_status);
CREATE INDEX IF NOT EXISTS idx_venues_city ON venues(city);
CREATE INDEX IF NOT EXISTS idx_venues_country ON venues(country);
CREATE INDEX IF NOT EXISTS idx_venues_is_active ON venues(is_active);
CREATE INDEX IF NOT EXISTS idx_swarms_host ON swarms(host_user_id);
CREATE INDEX IF NOT EXISTS idx_swarms_venue ON swarms(venue_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_user_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_venues_updated_at
  BEFORE UPDATE ON venues
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
