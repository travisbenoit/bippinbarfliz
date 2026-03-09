/*
  # Add Performance Indexes

  ## Purpose
  Add missing indexes to frequently queried columns to improve query performance across the app.

  ## New Indexes

  ### messages table
  - Composite index on (dm_user_a, dm_user_b) for fast DM conversation lookups
  - Index on (swarm_id) for fast swarm message lookups
  - Index on (sender_user_id) for user message history
  - Index on (created_at DESC) for chronological ordering
  - Partial index on unread DM messages for unread count queries

  ### users table
  - Index on (last_active_at DESC) for recently active user queries
  - Partial index on (last_known_lat, last_known_lng) for location-based queries

  ### venues table
  - Index on (place_id) for Google Places lookups
  - Index on (created_at DESC) for recent venue queries

  ### swarms table
  - Index on (status) for active swarm filtering
  - Index on (created_at DESC) for recent swarm queries
  - Index on (host_user_id) for user's own swarms

  ### geofence_events table
  - Index on (user_id, created_at DESC) for per-user event history

  ### location_pings table
  - Index on (user_id, created_at DESC) for location history queries

  ### venue_sessions table
  - Index on (user_id) for active session lookups
  - Index on (bar_id) for bar crowd counts

  ## Notes
  - All indexes use IF NOT EXISTS to be idempotent
  - Partial indexes used where appropriate to keep index sizes small
*/

CREATE INDEX IF NOT EXISTS idx_messages_dm_users
  ON messages (dm_user_a, dm_user_b)
  WHERE conversation_type = 'dm';

CREATE INDEX IF NOT EXISTS idx_messages_swarm_id
  ON messages (swarm_id)
  WHERE conversation_type = 'swarm';

CREATE INDEX IF NOT EXISTS idx_messages_sender
  ON messages (sender_user_id);

CREATE INDEX IF NOT EXISTS idx_messages_created_at
  ON messages (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_messages_unread
  ON messages (dm_user_a, dm_user_b, read_at)
  WHERE read_at IS NULL AND conversation_type = 'dm';

CREATE INDEX IF NOT EXISTS idx_users_last_active
  ON users (last_active_at DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_users_location
  ON users (last_known_lat, last_known_lng)
  WHERE last_known_lat IS NOT NULL AND last_known_lng IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_venues_place_id
  ON venues (place_id)
  WHERE place_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_venues_created_at
  ON venues (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_swarms_status
  ON swarms (status);

CREATE INDEX IF NOT EXISTS idx_swarms_created_at
  ON swarms (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_swarms_host_user
  ON swarms (host_user_id);

CREATE INDEX IF NOT EXISTS idx_geofence_events_user
  ON geofence_events (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_location_pings_user
  ON location_pings (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_venue_sessions_user
  ON venue_sessions (user_id);

CREATE INDEX IF NOT EXISTS idx_venue_sessions_bar
  ON venue_sessions (bar_id);
