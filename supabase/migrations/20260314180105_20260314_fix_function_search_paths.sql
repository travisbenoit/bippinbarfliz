/*
  # Fix Mutable Search Path on Functions

  ## Summary
  Adds `SET search_path = ''` to all functions that had a mutable search_path.
  This prevents search path injection attacks. All table/function references
  are fully qualified with the `public.` schema prefix.

  ## Functions Fixed
  All 21 flagged functions receive immutable search_path via SET search_path = ''
*/

-- Simple trigger: update updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE OR REPLACE FUNCTION public.update_venues_updated_at()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE OR REPLACE FUNCTION public.update_friendships_updated_at()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE OR REPLACE FUNCTION public.update_conversations_updated_at()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  UPDATE public.conversations SET updated_at = now() WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$;

-- Friendship reciprocal management
CREATE OR REPLACE FUNCTION public.create_reciprocal_friendship()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  IF NEW.status = 'accepted' AND (OLD IS NULL OR OLD.status != 'accepted') THEN
    INSERT INTO public.friendships (user_id, friend_id, status)
    VALUES (NEW.friend_id, NEW.user_id, 'accepted')
    ON CONFLICT (user_id, friend_id) DO UPDATE SET status = 'accepted', updated_at = now();
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_reciprocal_friendship()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  DELETE FROM public.friendships WHERE user_id = OLD.friend_id AND friend_id = OLD.user_id;
  RETURN OLD;
END;
$$;

-- Conversation owner bootstrap
CREATE OR REPLACE FUNCTION public.add_conversation_creator_as_owner()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.conversation_participants (conversation_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'owner')
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

-- Remove friendships when user is blocked
CREATE OR REPLACE FUNCTION public.remove_friendships_on_block()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  DELETE FROM public.friendships
  WHERE (user_id = NEW.blocker_id AND friend_id = NEW.blocked_id)
     OR (user_id = NEW.blocked_id AND friend_id = NEW.blocker_id);
  RETURN NEW;
END;
$$;

-- Venue report resolved_at stamp
CREATE OR REPLACE FUNCTION public.set_venue_report_resolved_at()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  IF NEW.status IN ('resolved', 'dismissed') AND OLD.status = 'pending' THEN
    NEW.resolved_at = now();
  END IF;
  RETURN NEW;
END;
$$;

-- Geofence radius by category (preserving original param name "cat")
CREATE OR REPLACE FUNCTION public.geofence_radius_for_category(cat text)
RETURNS integer LANGUAGE sql STABLE SECURITY INVOKER SET search_path = ''
AS $$
  SELECT CASE cat
    WHEN 'bar'        THEN 80
    WHEN 'pub'        THEN 80
    WHEN 'dive_bar'   THEN 60
    WHEN 'club'       THEN 100
    WHEN 'nightclub'  THEN 100
    WHEN 'sports_bar' THEN 120
    WHEN 'brewery'    THEN 100
    WHEN 'taproom'    THEN 100
    WHEN 'rooftop'    THEN 80
    WHEN 'lounge'     THEN 80
    WHEN 'festival'   THEN 200
    WHEN 'outdoor'    THEN 200
    ELSE 80
  END;
$$;

-- Haversine distance (preserving original param names lng1/lng2)
CREATE OR REPLACE FUNCTION public.calculate_distance_meters(lat1 double precision, lng1 double precision, lat2 double precision, lng2 double precision)
RETURNS double precision LANGUAGE plpgsql IMMUTABLE SECURITY INVOKER SET search_path = ''
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

-- Find nearby venues (preserving original signature)
CREATE OR REPLACE FUNCTION public.find_nearby_venues(user_lat double precision, user_lng double precision, radius_meters integer DEFAULT 500)
RETURNS TABLE(venue_id uuid, venue_name text, venue_type text, distance_meters double precision, is_in_geofence boolean)
LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    v.id,
    v.name,
    COALESCE(v.type, v.category) as venue_type,
    public.calculate_distance_meters(user_lat, user_lng, v.lat::double precision, v.lng::double precision) as distance,
    (public.calculate_distance_meters(user_lat, user_lng, v.lat::double precision, v.lng::double precision) <= COALESCE(v.geofence_radius_meters, 80)) as in_geofence
  FROM public.venues v
  WHERE
    COALESCE(v.is_active, true) = true
    AND public.calculate_distance_meters(user_lat, user_lng, v.lat::double precision, v.lng::double precision) <= radius_meters
  ORDER BY distance ASC;
END;
$$;

-- Venue presence count (preserving original signature)
CREATE OR REPLACE FUNCTION public.get_venue_presence_count(p_venue_id uuid, include_invisible boolean DEFAULT false)
RETURNS integer LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = ''
AS $$
DECLARE
  presence_count integer;
BEGIN
  IF include_invisible THEN
    SELECT COUNT(*) INTO presence_count
    FROM public.user_venue_presence
    WHERE venue_id = p_venue_id AND status = 'IN_VENUE' AND left_at IS NULL AND last_seen_at > now() - interval '1 hour';
  ELSE
    SELECT COUNT(*) INTO presence_count
    FROM public.user_venue_presence
    WHERE venue_id = p_venue_id AND status = 'IN_VENUE' AND is_visible_in_venue = true AND left_at IS NULL AND last_seen_at > now() - interval '1 hour';
  END IF;
  RETURN COALESCE(presence_count, 0);
END;
$$;

-- Check if user is blocked (preserving original signature)
CREATE OR REPLACE FUNCTION public.is_blocked(p_user_id uuid, p_other_user_id uuid)
RETURNS boolean LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_blocks
    WHERE (blocking_user_id = p_user_id AND blocked_user_id = p_other_user_id)
       OR (blocking_user_id = p_other_user_id AND blocked_user_id = p_user_id)
  );
END;
$$;

-- Append user to deleted_for array (preserving original signature)
CREATE OR REPLACE FUNCTION public.append_to_deleted_for(p_message_id uuid, p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  UPDATE public.messages
  SET deleted_for_user_ids = array_append(COALESCE(deleted_for_user_ids, '{}'), p_user_id)
  WHERE id = p_message_id
    AND (sender_user_id = p_user_id OR dm_user_a = p_user_id OR dm_user_b = p_user_id)
    AND NOT (p_user_id = ANY(COALESCE(deleted_for_user_ids, '{}')));
END;
$$;

-- Venue pending reports count (preserving original signature)
CREATE OR REPLACE FUNCTION public.get_venue_pending_reports_count(p_venue_id uuid)
RETURNS integer LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = ''
AS $$
DECLARE
  report_count integer;
BEGIN
  SELECT count(*)::integer INTO report_count
  FROM public.venue_reports
  WHERE venue_id = p_venue_id AND status = 'pending';
  RETURN COALESCE(report_count, 0);
END;
$$;

-- 5-minute time bucket
CREATE OR REPLACE FUNCTION public.get_time_bucket_5min(ts timestamptz)
RETURNS timestamptz LANGUAGE plpgsql IMMUTABLE SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  RETURN date_trunc('hour', ts) + (floor(extract(minute FROM ts) / 5) * interval '5 minutes');
END;
$$;

-- Venues in bounds (preserving original signature)
CREATE OR REPLACE FUNCTION public.get_venues_in_bounds(min_lat double precision, min_lng double precision, max_lat double precision, max_lng double precision, category_filter text DEFAULT NULL)
RETURNS SETOF public.venues LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM public.venues
  WHERE lat BETWEEN min_lat AND max_lat
    AND lng BETWEEN min_lng AND max_lng
    AND (category_filter IS NULL OR category = category_filter);
END;
$$;

-- Venue stats (preserving original signature: p_venue_id text)
CREATE OR REPLACE FUNCTION public.get_venue_stats(p_venue_id text)
RETURNS TABLE(avg_rating numeric, review_count bigint, photo_count bigint)
LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(AVG(vr.rating)::numeric, 0) as avg_rating,
    COUNT(DISTINCT vr.id) as review_count,
    (SELECT COUNT(*) FROM public.venue_photos vp WHERE vp.venue_id = p_venue_id) as photo_count
  FROM public.venue_reviews vr
  WHERE vr.venue_id = p_venue_id;
END;
$$;

-- Auto-activate venue by region
CREATE OR REPLACE FUNCTION public.auto_activate_venue_by_region()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $$
BEGIN
  IF NEW.country_code IS NOT NULL THEN
    NEW.is_active = true;
  END IF;
  RETURN NEW;
END;
$$;
