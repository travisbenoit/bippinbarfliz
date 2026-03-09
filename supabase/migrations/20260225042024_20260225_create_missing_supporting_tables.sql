/*
  # Create missing supporting tables

  1. New Tables
    - `gifts` - drink gift tracking between users
    - `subscriptions` - premium subscription management
    - `safety_friends` - emergency contact list per user
    - `safety_alerts` - location sharing emergency alerts
    - `payment_transactions` - payment/drink transaction records
    - `conversations` - conversation metadata
    - `conversation_participants` - who is in each conversation
    - `venue_reports` - user reports about venues
    - `event_log` - application event logging
    - `geofence_events` - geofence enter/exit event records
    - `user_inventory` - virtual items owned by users
    - `weather_cache` - cached weather data

  2. Security
    - RLS enabled on all tables
    - Users can only access their own data
    - Service role has elevated access for background tasks

  3. Important Notes
    - All tables use IF NOT EXISTS for idempotent creation
    - Foreign keys reference existing users, venues, swarms tables
*/

CREATE TABLE IF NOT EXISTS gifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  drink_type text NOT NULL,
  amount numeric NOT NULL,
  message text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'redeemed', 'expired')),
  venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
  redeemed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE gifts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view gifts they sent"
  ON gifts FOR SELECT TO authenticated
  USING (auth.uid() = from_user_id);

CREATE POLICY "Users can view gifts they received"
  ON gifts FOR SELECT TO authenticated
  USING (auth.uid() = to_user_id);

CREATE POLICY "Users can create gifts"
  ON gifts FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = from_user_id);

CREATE POLICY "Recipients can update their gifts"
  ON gifts FOR UPDATE TO authenticated
  USING (auth.uid() = to_user_id)
  WITH CHECK (auth.uid() = to_user_id);

CREATE INDEX IF NOT EXISTS idx_gifts_from_user ON gifts(from_user_id);
CREATE INDEX IF NOT EXISTS idx_gifts_to_user ON gifts(to_user_id);
CREATE INDEX IF NOT EXISTS idx_gifts_status ON gifts(status);

CREATE TABLE IF NOT EXISTS subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_type text NOT NULL CHECK (plan_type IN ('monthly', 'yearly')),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')),
  stripe_subscription_id text,
  current_period_start timestamptz NOT NULL,
  current_period_end timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE (user_id, stripe_subscription_id)
);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscriptions"
  ON subscriptions FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own subscriptions"
  ON subscriptions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscriptions"
  ON subscriptions FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

CREATE TABLE IF NOT EXISTS safety_friends (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  friend_name text NOT NULL,
  friend_phone text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE safety_friends ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own safety friends"
  ON safety_friends FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own safety friends"
  ON safety_friends FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own safety friends"
  ON safety_friends FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own safety friends"
  ON safety_friends FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS safety_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude numeric,
  longitude numeric,
  location_url text,
  alert_type text NOT NULL DEFAULT 'location_share',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE safety_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own safety alerts"
  ON safety_alerts FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own safety alerts"
  ON safety_alerts FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS payment_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount numeric NOT NULL DEFAULT 0,
  transaction_type text DEFAULT 'transfer' CHECK (transaction_type IN ('drink_request', 'drink_payment', 'transfer', 'gift', 'split_tab')),
  description text,
  drink_name text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own transactions"
  ON payment_transactions FOR SELECT TO authenticated
  USING (auth.uid() = from_user_id OR auth.uid() = to_user_id);

CREATE POLICY "Users can create transactions"
  ON payment_transactions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = from_user_id);

CREATE POLICY "Users can update own transactions"
  ON payment_transactions FOR UPDATE TO authenticated
  USING (auth.uid() = from_user_id OR auth.uid() = to_user_id)
  WITH CHECK (auth.uid() = from_user_id OR auth.uid() = to_user_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_from ON payment_transactions(from_user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_to ON payment_transactions(to_user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_type ON payment_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_created ON payment_transactions(created_at DESC);

CREATE TABLE IF NOT EXISTS conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text,
  type text NOT NULL DEFAULT 'direct' CHECK (type IN ('direct', 'group')),
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  swarm_id uuid REFERENCES swarms(id) ON DELETE CASCADE,
  venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
  is_active boolean NOT NULL DEFAULT true,
  last_message_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS conversation_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member' CHECK (role IN ('member', 'admin', 'owner')),
  joined_at timestamptz NOT NULL DEFAULT now(),
  left_at timestamptz,
  last_read_at timestamptz,
  notifications_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (conversation_id, user_id)
);

ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own conversations"
  ON conversations FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants
      WHERE conversation_participants.conversation_id = conversations.id
      AND conversation_participants.user_id = auth.uid()
      AND conversation_participants.left_at IS NULL
    )
  );

CREATE POLICY "Users can create conversations"
  ON conversations FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Admins can update conversations"
  ON conversations FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants
      WHERE conversation_participants.conversation_id = conversations.id
      AND conversation_participants.user_id = auth.uid()
      AND conversation_participants.role IN ('admin', 'owner')
    )
  );

CREATE POLICY "Users can read conversation participants"
  ON conversation_participants FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = conversation_participants.conversation_id
      AND cp.user_id = auth.uid()
      AND cp.left_at IS NULL
    )
  );

CREATE POLICY "Users can add conversation participants"
  ON conversation_participants FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own participation"
  ON conversation_participants FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_conversations_swarm ON conversations(swarm_id) WHERE swarm_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_conversations_active ON conversations(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation ON conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user ON conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_active ON conversation_participants(conversation_id, user_id) WHERE left_at IS NULL;

CREATE TABLE IF NOT EXISTS venue_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  reporter_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  report_type text NOT NULL CHECK (report_type IN ('incorrect_info', 'closed', 'inappropriate', 'safety_concern', 'spam', 'other')),
  description text NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
  admin_notes text,
  resolved_at timestamptz,
  resolved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE venue_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own reports"
  ON venue_reports FOR SELECT TO authenticated
  USING (auth.uid() = reporter_id);

CREATE POLICY "Users can create reports"
  ON venue_reports FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can update own pending reports"
  ON venue_reports FOR UPDATE TO authenticated
  USING (auth.uid() = reporter_id AND status = 'pending')
  WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can delete own pending reports"
  ON venue_reports FOR DELETE TO authenticated
  USING (auth.uid() = reporter_id AND status = 'pending');

CREATE INDEX IF NOT EXISTS idx_venue_reports_venue ON venue_reports(venue_id);
CREATE INDEX IF NOT EXISTS idx_venue_reports_reporter ON venue_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_venue_reports_status ON venue_reports(status);

CREATE TABLE IF NOT EXISTS event_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  event_type text NOT NULL,
  event_action text NOT NULL,
  event_data jsonb DEFAULT '{}',
  ip_address inet,
  user_agent text,
  session_id text,
  status text NOT NULL DEFAULT 'success' CHECK (status IN ('success', 'failure', 'pending')),
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE event_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own event logs"
  ON event_log FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own event logs"
  ON event_log FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_event_log_user ON event_log(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_event_log_type ON event_log(event_type);
CREATE INDEX IF NOT EXISTS idx_event_log_created ON event_log(created_at DESC);

CREATE TABLE IF NOT EXISTS geofence_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  venue_id uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  event_type text NOT NULL CHECK (event_type IN ('enter', 'exit')),
  latitude decimal(10,8) NOT NULL,
  longitude decimal(11,8) NOT NULL,
  accuracy decimal(10,2),
  distance_from_center decimal(10,2),
  triggered_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE geofence_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own geofence events"
  ON geofence_events FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own geofence events"
  ON geofence_events FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_geofence_events_user ON geofence_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_geofence_events_venue ON geofence_events(venue_id);
CREATE INDEX IF NOT EXISTS idx_geofence_events_triggered ON geofence_events(triggered_at DESC);

CREATE TABLE IF NOT EXISTS user_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_id text NOT NULL REFERENCES virtual_items(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 1 CHECK (quantity >= 0),
  acquired_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE (user_id, item_id)
);

ALTER TABLE user_inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own inventory"
  ON user_inventory FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own inventory"
  ON user_inventory FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own inventory"
  ON user_inventory FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_user_inventory_user ON user_inventory(user_id);

CREATE TABLE IF NOT EXISTS weather_cache (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  temperature integer NOT NULL,
  weather_code integer NOT NULL,
  condition text NOT NULL,
  wind_speed numeric NOT NULL,
  humidity integer NOT NULL,
  feels_like integer NOT NULL,
  source text NOT NULL DEFAULT 'open-meteo',
  cached_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '1 hour'),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE weather_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Weather data is publicly readable"
  ON weather_cache FOR SELECT TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Service role can insert weather data"
  ON weather_cache FOR INSERT TO service_role
  WITH CHECK (true);

CREATE POLICY "Service role can delete expired weather data"
  ON weather_cache FOR DELETE TO service_role
  USING (true);

CREATE INDEX IF NOT EXISTS idx_weather_cache_location ON weather_cache(latitude, longitude, expires_at);
