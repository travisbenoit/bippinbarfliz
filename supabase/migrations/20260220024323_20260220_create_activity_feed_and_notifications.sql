/*
  # Create Activity Feed and Notifications Tables

  ## New Tables
  - `activity_feed` - Social activity events (friend entered venue, friend joined swarm, etc.)
    - `id` - UUID primary key
    - `user_id` - The user who the activity is about (actor)
    - `actor_user_id` - Alias for clarity (same as user_id)
    - `activity_type` - enum: venue_enter, venue_leave, swarm_join, swarm_create, friend_request_accepted
    - `venue_id` - Optional venue reference
    - `swarm_id` - Optional swarm reference
    - `metadata` - JSONB for flexible extra data (venue name, etc.)
    - `created_at` - Timestamp

  - `notifications` - In-app notification inbox per user
    - `id` - UUID primary key
    - `recipient_user_id` - Who receives the notification
    - `actor_user_id` - Who triggered it (nullable for system notifications)
    - `notification_type` - Type string
    - `title` - Notification title
    - `body` - Notification body text
    - `venue_id` - Optional venue reference
    - `swarm_id` - Optional swarm reference
    - `is_read` - Boolean, defaults false
    - `created_at` - Timestamp

  ## Security
  - RLS enabled on both tables
  - Users can only see their own notifications
  - Activity feed visible to mutual friends only
*/

CREATE TABLE IF NOT EXISTS activity_feed (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_type text NOT NULL CHECK (activity_type IN (
    'venue_enter', 'venue_leave', 'swarm_join', 'swarm_create', 'friend_request_accepted', 'status_update'
  )),
  venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
  swarm_id uuid REFERENCES swarms(id) ON DELETE SET NULL,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_activity_feed_actor ON activity_feed(actor_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_feed_venue ON activity_feed(venue_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_feed_created ON activity_feed(created_at DESC);

ALTER TABLE activity_feed ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view activity of their friends"
  ON activity_feed FOR SELECT
  TO authenticated
  USING (
    actor_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM friendships
      WHERE status = 'accepted'
      AND (
        (user_id = auth.uid() AND friend_id = activity_feed.actor_user_id)
        OR (friend_id = auth.uid() AND user_id = activity_feed.actor_user_id)
      )
    )
  );

CREATE POLICY "Users can insert their own activity"
  ON activity_feed FOR INSERT
  TO authenticated
  WITH CHECK (actor_user_id = auth.uid());

CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  actor_user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  notification_type text NOT NULL,
  title text NOT NULL,
  body text NOT NULL DEFAULT '',
  venue_id uuid REFERENCES venues(id) ON DELETE SET NULL,
  swarm_id uuid REFERENCES swarms(id) ON DELETE SET NULL,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(recipient_user_id, is_read) WHERE is_read = false;

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (recipient_user_id = auth.uid());

CREATE POLICY "Service can insert notifications"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can mark own notifications as read"
  ON notifications FOR UPDATE
  TO authenticated
  USING (recipient_user_id = auth.uid())
  WITH CHECK (recipient_user_id = auth.uid());
