/*
  # Google Places API Logging and Rate Limiting

  This migration creates infrastructure for tracking Google Places API usage
  to enable cost control, rate limiting, and monitoring.

  ## New Tables

  ### `google_api_logs`
  Tracks all Google Places API calls for monitoring and rate limiting.
  - `log_id` (uuid, primary key) - Unique log entry identifier
  - `user_id` (uuid, required) - User who initiated the API call
  - `bar_id` (uuid, required) - Bar being linked
  - `success` (boolean, required) - Whether the API call succeeded
  - `place_id` (text, nullable) - Google Place ID if found
  - `details` (jsonb, required) - Call details, errors, match info
  - `created_at` (timestamptz) - Timestamp of API call

  ## Security
  - RLS enabled with policies for user access to own logs
  - Service role has full access for webhook and admin operations
  - Authenticated users can only view their own API logs

  ## Indexes
  - Index on user_id + created_at for rate limiting queries
  - Index on bar_id for lookup by venue
  - Index on created_at for cleanup/reporting

  ## Important Notes
  - Rate limiting: 50 requests per user per hour
  - Logs retained for cost monitoring and debugging
  - Used to prevent API abuse and control costs
*/

-- Create google_api_logs table
CREATE TABLE IF NOT EXISTS google_api_logs (
  log_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  bar_id uuid NOT NULL REFERENCES bars(bar_id) ON DELETE CASCADE,
  success boolean NOT NULL DEFAULT false,
  place_id text,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_google_api_logs_user_created 
  ON google_api_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_google_api_logs_bar 
  ON google_api_logs(bar_id);
CREATE INDEX IF NOT EXISTS idx_google_api_logs_created 
  ON google_api_logs(created_at DESC);

-- Enable Row Level Security
ALTER TABLE google_api_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own API logs"
  ON google_api_logs FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Service role has full access to API logs"
  ON google_api_logs FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
