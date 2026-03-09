/*
  # Create Event Log Table for System Audit Logging

  ## Overview
  Creates a comprehensive event logging system to track all significant user actions,
  system events, and security-related activities for debugging, analytics, and compliance.

  ## New Tables
  
  ### `event_log`
  Central audit log table for tracking all system events
  - `id` (uuid, primary key) - Unique event identifier
  - `user_id` (uuid, nullable) - User who triggered the event (null for system events)
  - `event_type` (text) - Category of event (e.g., 'auth', 'social', 'payment', 'venue')
  - `event_action` (text) - Specific action (e.g., 'login', 'send_gift', 'enter_venue')
  - `event_data` (jsonb) - Flexible storage for event-specific details
  - `ip_address` (inet, nullable) - IP address of the request
  - `user_agent` (text, nullable) - Browser/client user agent string
  - `session_id` (text, nullable) - Session identifier for tracking user sessions
  - `status` (text) - Event outcome: 'success', 'failure', 'pending'
  - `error_message` (text, nullable) - Error details if status is 'failure'
  - `created_at` (timestamptz) - When the event occurred

  ## Security
  - Enable RLS on event_log table
  - Users can only read their own events
  - Only authenticated users can view logs
  - System/admin can view all logs (via service role)

  ## Indexes
  - `idx_event_log_user_id` - Fast lookups by user
  - `idx_event_log_event_type` - Filter by event type
  - `idx_event_log_created_at` - Time-based queries
  - `idx_event_log_status` - Filter by status
  - Composite index on (user_id, created_at) for user activity timelines

  ## Notes
  - Partition by created_at for better performance at scale
  - Consider retention policy (archive/delete old logs after X months)
  - JSONB event_data allows flexible schema evolution
*/

-- Create event_log table
CREATE TABLE IF NOT EXISTS event_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  event_type text NOT NULL,
  event_action text NOT NULL,
  event_data jsonb DEFAULT '{}'::jsonb,
  ip_address inet,
  user_agent text,
  session_id text,
  status text NOT NULL DEFAULT 'success' CHECK (status IN ('success', 'failure', 'pending')),
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_event_log_user_id ON event_log(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_event_log_event_type ON event_log(event_type);
CREATE INDEX IF NOT EXISTS idx_event_log_created_at ON event_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_event_log_status ON event_log(status) WHERE status != 'success';
CREATE INDEX IF NOT EXISTS idx_event_log_user_timeline ON event_log(user_id, created_at DESC) WHERE user_id IS NOT NULL;

-- Add helpful comment
COMMENT ON TABLE event_log IS 'System-wide audit log for tracking user actions, system events, and security activities';

-- Enable Row Level Security
ALTER TABLE event_log ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own event logs
CREATE POLICY "Users can read own event logs"
  ON event_log
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy: System can insert all event logs (via service role)
-- Note: This policy allows authenticated users to insert their own events
CREATE POLICY "Users can insert own event logs"
  ON event_log
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Policy: No updates allowed (event logs should be immutable)
-- Policy: No deletes allowed by users (only admin/service role can delete)