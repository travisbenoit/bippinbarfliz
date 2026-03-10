/*
  # Create user_venue_presence and venue_clusters tables

  ## Summary
  These tables power the geofencing and venue check-in system. They were defined
  in a migration file but had not been applied to the live database.

  ## Tables

  ### user_venue_presence
  Tracks when users are physically inside venues. Written exclusively by
  Edge Functions (service role) so all validation happens server-side.

  Key columns:
  - user_id, venue_id: who and where
  - status: IN_VENUE or LEFT_VENUE
  - entered_at, left_at, last_seen_at: timing
  - is_visible_in_venue: false when ghost mode is on
  - dwell_seconds: how long the user stayed
  - entry_method: AUTO_GEOFENCE or MANUAL_CHECKIN

  ### venue_clusters
  Groups nearby venues for efficient low-precision monitoring.

  ## Security (visibility model)
  Users can only see each other's presence if:
  1. They have a mutual accepted friendship, OR
  2. They are both members of the same active swarm
  Ghost mode (is_visible_in_venue=false) hides from all queries above.
  Own records are always visible to the user themselves.
  All writes require service_role (Edge Functions only).

  ## Functions
  - calculate_distance_meters: Haversine distance between two lat/lng points
  - find_nearby_venues: Returns venues within a radius with geofence status
  - get_venue_presence_count: Aggregate count without exposing individual presence
*/

CREATE TABLE IF NOT EXISTS user_venue_presence (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  venue_id uuid NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'IN_VENUE',
  entered_at timestamptz NOT NULL DEFAULT now(),
  left_at timestamptz,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  is_visible_in_venue boolean DEFAULT true,
  dwell_seconds integer DEFAULT 0,
  entry_method text DEFAULT 'AUTO_GEOFENCE',
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),

  CONSTRAINT valid_status CHECK (status IN ('IN_VENUE', 'LEFT_VENUE')),
  CONSTRAINT valid_dwell CHECK (dwell_seconds >= 0),
  CONSTRAINT valid_dates CHECK (left_at IS NULL OR left_at >= entered_at)
);

CREATE INDEX IF NOT EXISTS idx_presence_user_id ON user_venue_presence (user_id);
CREATE INDEX IF NOT EXISTS idx_presence_venue_id ON user_venue_presence (venue_id);
CREATE INDEX IF NOT EXISTS idx_presence_status ON user_venue_presence (status);
CREATE INDEX IF NOT EXISTS idx_presence_active ON user_venue_presence (user_id, venue_id, status)
  WHERE status = 'IN_VENUE' AND left_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_presence_visible ON user_venue_presence (venue_id, is_visible_in_venue, status)
  WHERE is_visible_in_venue = true AND status = 'IN_VENUE';

CREATE TABLE IF NOT EXISTS venue_clusters (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  city text NOT NULL,
  center_lat double precision NOT NULL,
  center_lng double precision NOT NULL,
  radius_meters integer NOT NULL DEFAULT 500,
  venue_ids uuid[] DEFAULT '{}',
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),

  CONSTRAINT valid_cluster_lat CHECK (center_lat >= -90 AND center_lat <= 90),
  CONSTRAINT valid_cluster_lng CHECK (center_lng >= -180 AND center_lng <= 180),
  CONSTRAINT valid_cluster_radius CHECK (radius_meters > 0 AND radius_meters <= 5000)
);

CREATE INDEX IF NOT EXISTS idx_clusters_lat_lng ON venue_clusters (center_lat, center_lng);
CREATE INDEX IF NOT EXISTS idx_clusters_city ON venue_clusters (city);
CREATE INDEX IF NOT EXISTS idx_clusters_active ON venue_clusters (is_active) WHERE is_active = true;

ALTER TABLE user_venue_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE venue_clusters ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own presence" ON user_venue_presence;
CREATE POLICY "Users can view own presence"
  ON user_venue_presence FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view presence of mutual friends and swarm members" ON user_venue_presence;
CREATE POLICY "Users can view presence of mutual friends and swarm members"
  ON user_venue_presence FOR SELECT
  TO authenticated
  USING (
    is_visible_in_venue = true
    AND status = 'IN_VENUE'
    AND left_at IS NULL
    AND last_seen_at > now() - interval '24 hours'
    AND (
      EXISTS (
        SELECT 1 FROM friendships
        WHERE status = 'accepted'
        AND (
          (friendships.user_id = auth.uid() AND friendships.friend_id = user_venue_presence.user_id)
          OR
          (friendships.friend_id = auth.uid() AND friendships.user_id = user_venue_presence.user_id)
        )
      )
      OR
      EXISTS (
        SELECT 1 FROM swarm_members sm1
        JOIN swarm_members sm2 ON sm1.swarm_id = sm2.swarm_id
        JOIN swarms s ON s.id = sm1.swarm_id
        WHERE sm1.user_id = auth.uid()
          AND sm2.user_id = user_venue_presence.user_id
          AND s.status IN ('active', 'ongoing')
      )
    )
  );

DROP POLICY IF EXISTS "Service role can insert presence" ON user_venue_presence;
CREATE POLICY "Service role can insert presence"
  ON user_venue_presence FOR INSERT
  TO service_role
  WITH CHECK (true);

DROP POLICY IF EXISTS "Service role can update presence" ON user_venue_presence;
CREATE POLICY "Service role can update presence"
  ON user_venue_presence FOR UPDATE
  TO service_role
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Users can view active clusters" ON venue_clusters;
CREATE POLICY "Users can view active clusters"
  ON venue_clusters FOR SELECT
  TO authenticated
  USING (is_active = true);

DROP POLICY IF EXISTS "Service role can manage clusters" ON venue_clusters;
CREATE POLICY "Service role can manage clusters"
  ON venue_clusters FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE OR REPLACE FUNCTION calculate_distance_meters(
  lat1 double precision,
  lng1 double precision,
  lat2 double precision,
  lng2 double precision
)
RETURNS double precision
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  earth_radius_meters constant double precision := 6371000.0;
  lat1_rad double precision;
  lat2_rad double precision;
  delta_lat double precision;
  delta_lng double precision;
  a double precision;
  c double precision;
BEGIN
  lat1_rad := radians(lat1);
  lat2_rad := radians(lat2);
  delta_lat := radians(lat2 - lat1);
  delta_lng := radians(lng2 - lng1);

  a := sin(delta_lat / 2.0) * sin(delta_lat / 2.0) +
       cos(lat1_rad) * cos(lat2_rad) *
       sin(delta_lng / 2.0) * sin(delta_lng / 2.0);
  c := 2.0 * atan2(sqrt(a), sqrt(1.0 - a));

  RETURN earth_radius_meters * c;
END;
$$;

CREATE OR REPLACE FUNCTION find_nearby_venues(
  user_lat double precision,
  user_lng double precision,
  radius_meters integer DEFAULT 500
)
RETURNS TABLE (
  venue_id uuid,
  venue_name text,
  venue_type text,
  distance_meters double precision,
  is_in_geofence boolean
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT
    v.id,
    v.name,
    COALESCE(v.type, v.category) as venue_type,
    calculate_distance_meters(user_lat, user_lng, v.lat::double precision, v.lng::double precision) as distance,
    (calculate_distance_meters(user_lat, user_lng, v.lat::double precision, v.lng::double precision) <= COALESCE(v.geofence_radius_meters, 80)) as in_geofence
  FROM venues v
  WHERE
    COALESCE(v.is_active, true) = true
    AND calculate_distance_meters(user_lat, user_lng, v.lat::double precision, v.lng::double precision) <= radius_meters
  ORDER BY distance ASC;
END;
$$;

CREATE OR REPLACE FUNCTION get_venue_presence_count(
  p_venue_id uuid,
  include_invisible boolean DEFAULT false
)
RETURNS integer
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  presence_count integer;
BEGIN
  IF include_invisible THEN
    SELECT COUNT(*)
    INTO presence_count
    FROM user_venue_presence
    WHERE venue_id = p_venue_id
      AND status = 'IN_VENUE'
      AND left_at IS NULL
      AND last_seen_at > now() - interval '1 hour';
  ELSE
    SELECT COUNT(*)
    INTO presence_count
    FROM user_venue_presence
    WHERE venue_id = p_venue_id
      AND status = 'IN_VENUE'
      AND is_visible_in_venue = true
      AND left_at IS NULL
      AND last_seen_at > now() - interval '1 hour';
  END IF;

  RETURN COALESCE(presence_count, 0);
END;
$$;
