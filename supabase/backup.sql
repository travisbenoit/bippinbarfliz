


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."add_conversation_creator_as_owner"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
INSERT INTO public.conversation_participants (conversation_id, user_id, role)
VALUES (NEW.id, NEW.created_by, 'owner')
ON CONFLICT DO NOTHING;
RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."add_conversation_creator_as_owner"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."append_to_deleted_for"("p_message_id" "uuid", "p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
UPDATE public.messages
SET deleted_for_user_ids = array_append(COALESCE(deleted_for_user_ids, '{}'), p_user_id)
WHERE id = p_message_id
AND (sender_user_id = p_user_id OR dm_user_a = p_user_id OR dm_user_b = p_user_id)
AND NOT (p_user_id = ANY(COALESCE(deleted_for_user_ids, '{}')));
END;
$$;


ALTER FUNCTION "public"."append_to_deleted_for"("p_message_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."auto_activate_venue_by_region"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
IF NEW.country_code IS NOT NULL THEN
NEW.is_active = true;
END IF;
RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."auto_activate_venue_by_region"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_distance_meters"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) RETURNS double precision
    LANGUAGE "plpgsql" IMMUTABLE
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."calculate_distance_meters"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_message_notification"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
recipient_id uuid;
sender_name text;
BEGIN
SELECT name INTO sender_name
FROM users
WHERE id = NEW.sender_user_id;

IF NEW.conversation_type = 'dm' THEN
IF NEW.dm_user_a = NEW.sender_user_id THEN
recipient_id := NEW.dm_user_b;
ELSE
recipient_id := NEW.dm_user_a;
END IF;

INSERT INTO notifications (
recipient_user_id,
actor_user_id,
notification_type,
title,
body
) VALUES (
recipient_id,
NEW.sender_user_id,
'message_dm',
sender_name || ' sent you a message',
SUBSTRING(NEW.body, 1, 100)
);

ELSIF NEW.conversation_type = 'swarm' AND NEW.swarm_id IS NOT NULL THEN
INSERT INTO notifications (
recipient_user_id,
actor_user_id,
notification_type,
title,
body,
swarm_id
)
SELECT
sm.user_id,
NEW.sender_user_id,
'message_swarm',
sender_name || ' messaged in swarm',
SUBSTRING(NEW.body, 1, 100),
NEW.swarm_id
FROM swarm_members sm
WHERE sm.swarm_id = NEW.swarm_id
AND sm.user_id != NEW.sender_user_id;
END IF;

RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."create_message_notification"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_reciprocal_friendship"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."create_reciprocal_friendship"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_reciprocal_friendship"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
DELETE FROM public.friendships WHERE user_id = OLD.friend_id AND friend_id = OLD.user_id;
RETURN OLD;
END;
$$;


ALTER FUNCTION "public"."delete_reciprocal_friendship"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."find_nearby_venues"("user_lat" double precision, "user_lng" double precision, "radius_meters" integer DEFAULT 500) RETURNS TABLE("venue_id" "uuid", "venue_name" "text", "venue_type" "text", "distance_meters" double precision, "is_in_geofence" boolean)
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."find_nearby_venues"("user_lat" double precision, "user_lng" double precision, "radius_meters" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."geofence_radius_for_category"("cat" "text") RETURNS integer
    LANGUAGE "sql" STABLE
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."geofence_radius_for_category"("cat" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_room_stats"("p_venue_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  v_message_count integer;
  v_active_users integer;
  v_top_drink text;
  v_top_music text;
BEGIN
  SELECT COUNT(*) INTO v_message_count
  FROM venue_room_messages
  WHERE venue_id = p_venue_id
    AND expires_at > now()
    AND report_count < 3;

  SELECT COUNT(*) INTO v_active_users
  FROM venue_room_presence
  WHERE venue_id = p_venue_id
    AND last_active_at > now() - interval '30 minutes';

  SELECT vote_value INTO v_top_drink
  FROM venue_room_vibe_polls
  WHERE venue_id = p_venue_id AND poll_type = 'drink'
  GROUP BY vote_value ORDER BY COUNT(*) DESC LIMIT 1;

  SELECT vote_value INTO v_top_music
  FROM venue_room_vibe_polls
  WHERE venue_id = p_venue_id AND poll_type = 'music'
  GROUP BY vote_value ORDER BY COUNT(*) DESC LIMIT 1;

  RETURN jsonb_build_object(
    'message_count', v_message_count,
    'active_users', v_active_users,
    'top_drink', COALESCE(v_top_drink, null),
    'top_music', COALESCE(v_top_music, null)
  );
END;
$$;


ALTER FUNCTION "public"."get_room_stats"("p_venue_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_time_bucket_5min"("ts" timestamp with time zone) RETURNS timestamp with time zone
    LANGUAGE "plpgsql" IMMUTABLE
    SET "search_path" TO ''
    AS $$
BEGIN
RETURN date_trunc('hour', ts) + (floor(extract(minute FROM ts) / 5) * interval '5 minutes');
END;
$$;


ALTER FUNCTION "public"."get_time_bucket_5min"("ts" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_venue_pending_reports_count"("p_venue_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."get_venue_pending_reports_count"("p_venue_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_venue_pending_reports_count"("p_venue_id" "uuid") IS 'Returns the count of pending reports for a given venue';



CREATE OR REPLACE FUNCTION "public"."get_venue_presence_count"("p_venue_id" "uuid", "include_invisible" boolean DEFAULT false) RETURNS integer
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."get_venue_presence_count"("p_venue_id" "uuid", "include_invisible" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_venue_stats"("p_venue_id" "text") RETURNS TABLE("avg_rating" numeric, "review_count" bigint, "photo_count" bigint)
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO ''
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


ALTER FUNCTION "public"."get_venue_stats"("p_venue_id" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."venues" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "address" "text",
    "city" "text",
    "state" "text",
    "country" "text" DEFAULT 'US'::"text",
    "postal_code" "text",
    "lat" numeric NOT NULL,
    "lng" numeric NOT NULL,
    "type" "text" DEFAULT 'bar'::"text",
    "category" "text",
    "hours" "jsonb",
    "verified" boolean DEFAULT false,
    "is_active" boolean DEFAULT true,
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "photo_url" "text",
    "place_id" "text",
    "rating" numeric,
    "user_ratings_total" integer,
    "geofence_shape" "jsonb",
    "geofence_radius_meters" integer DEFAULT 50,
    "description" "text",
    "demo_people_count" integer DEFAULT 0 NOT NULL,
    "vibes" "text"[] DEFAULT '{}'::"text"[],
    "user_count" integer DEFAULT 0,
    "place_type" "text",
    "google_place_id" "text",
    "phone" "text",
    "website" "text",
    "price_level" integer,
    "osm_id" "text",
    "osm_tags" "jsonb",
    "image_url_osm" "text",
    "foursquare_id" "text",
    "verified_flag" boolean DEFAULT false,
    "subcategory" "text",
    "geofence_radius_m" integer DEFAULT 75,
    CONSTRAINT "valid_radius" CHECK ((("geofence_radius_meters" > 0) AND ("geofence_radius_meters" <= 500)))
);


ALTER TABLE "public"."venues" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_venues_in_bounds"("min_lat" double precision, "min_lng" double precision, "max_lat" double precision, "max_lng" double precision, "category_filter" "text" DEFAULT NULL::"text") RETURNS SETOF "public"."venues"
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO ''
    AS $$
BEGIN
RETURN QUERY
SELECT * FROM public.venues
WHERE lat BETWEEN min_lat AND max_lat
AND lng BETWEEN min_lng AND max_lng
AND (category_filter IS NULL OR category = category_filter);
END;
$$;


ALTER FUNCTION "public"."get_venues_in_bounds"("min_lat" double precision, "min_lng" double precision, "max_lat" double precision, "max_lng" double precision, "category_filter" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  INSERT INTO public.users (id, name, created_at)
  VALUES (NEW.id, '', now())
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."has_accepted_terms"("p_user_id" "uuid", "p_version" "text" DEFAULT '1.0'::"text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
RETURN EXISTS (
SELECT 1
FROM user_consents
WHERE user_id = p_user_id
AND consent_type = 'terms'
AND accepted = true
AND version = p_version
);
END;
$$;


ALTER FUNCTION "public"."has_accepted_terms"("p_user_id" "uuid", "p_version" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_lush_coins"("p_user_id" "uuid", "p_amount" integer) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
v_new_balance integer;
BEGIN
UPDATE users
SET lush_coin_balance = GREATEST(0, COALESCE(lush_coin_balance, 0) + p_amount)
WHERE id = p_user_id
RETURNING lush_coin_balance INTO v_new_balance;

RETURN COALESCE(v_new_balance, 0);
END;
$$;


ALTER FUNCTION "public"."increment_lush_coins"("p_user_id" "uuid", "p_amount" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."initialize_visibility_settings"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
INSERT INTO visibility_settings (user_id)
VALUES (NEW.id)
ON CONFLICT (user_id) DO NOTHING;
RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."initialize_visibility_settings"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_blocked"("p_user_id" "uuid", "p_other_user_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" STABLE
    SET "search_path" TO ''
    AS $$
BEGIN
RETURN EXISTS (
SELECT 1 FROM public.user_blocks
WHERE (blocking_user_id = p_user_id AND blocked_user_id = p_other_user_id)
OR (blocking_user_id = p_other_user_id AND blocked_user_id = p_user_id)
);
END;
$$;


ALTER FUNCTION "public"."is_blocked"("p_user_id" "uuid", "p_other_user_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."is_blocked"("p_user_id" "uuid", "p_other_user_id" "uuid") IS 'Helper function to check if two users have blocked each other (either direction)';



CREATE OR REPLACE FUNCTION "public"."record_consent"("p_consent_type" "text", "p_version" "text" DEFAULT '1.0'::"text", "p_ip_address" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
v_consent_id uuid;
BEGIN
INSERT INTO user_consents (user_id, consent_type, accepted, version, ip_address)
VALUES (auth.uid(), p_consent_type, true, p_version, p_ip_address)
RETURNING id INTO v_consent_id;

RETURN v_consent_id;
END;
$$;


ALTER FUNCTION "public"."record_consent"("p_consent_type" "text", "p_version" "text", "p_ip_address" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."record_user_consent"("p_user_id" "uuid", "p_consent_type" "text", "p_ip_address" "inet" DEFAULT NULL::"inet", "p_user_agent" "text" DEFAULT NULL::"text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
v_consent_id uuid;
BEGIN
IF auth.uid() != p_user_id THEN
RAISE EXCEPTION 'Unauthorized';
END IF;

INSERT INTO user_consents (user_id, consent_type, ip_address, user_agent)
VALUES (p_user_id, p_consent_type, p_ip_address, p_user_agent)
ON CONFLICT DO NOTHING
RETURNING id INTO v_consent_id;

RETURN v_consent_id;
END;
$$;


ALTER FUNCTION "public"."record_user_consent"("p_user_id" "uuid", "p_consent_type" "text", "p_ip_address" "inet", "p_user_agent" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."remove_friendships_on_block"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
DELETE FROM public.friendships
WHERE (user_id = NEW.blocker_id AND friend_id = NEW.blocked_id)
OR (user_id = NEW.blocked_id AND friend_id = NEW.blocker_id);
RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."remove_friendships_on_block"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."report_buzz"("buzz_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  UPDATE venue_buzz SET report_count = report_count + 1 WHERE id = buzz_id;
END;
$$;


ALTER FUNCTION "public"."report_buzz"("buzz_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."report_room_message"("p_message_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  UPDATE venue_room_messages
  SET report_count = report_count + 1
  WHERE id = p_message_id;
END;
$$;


ALTER FUNCTION "public"."report_room_message"("p_message_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."report_room_moment"("p_moment_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  UPDATE venue_room_moments
  SET report_count = report_count + 1
  WHERE id = p_moment_id;
END;
$$;


ALTER FUNCTION "public"."report_room_moment"("p_moment_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."report_wall_photo"("p_photo_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
UPDATE venue_wall_photos
SET report_count = report_count + 1
WHERE id = p_photo_id;
END;
$$;


ALTER FUNCTION "public"."report_wall_photo"("p_photo_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."request_account_deletion"("p_user_id" "uuid", "p_deletion_reason" "text" DEFAULT NULL::"text", "p_data_export_requested" boolean DEFAULT false) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
v_request_id uuid;
BEGIN
IF auth.uid() != p_user_id THEN
RAISE EXCEPTION 'Unauthorized';
END IF;

INSERT INTO account_deletion_requests (user_id, deletion_reason, data_export_requested)
VALUES (p_user_id, p_deletion_reason, p_data_export_requested)
RETURNING id INTO v_request_id;

RETURN v_request_id;
END;
$$;


ALTER FUNCTION "public"."request_account_deletion"("p_user_id" "uuid", "p_deletion_reason" "text", "p_data_export_requested" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_venue_report_resolved_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
IF NEW.status IN ('resolved', 'dismissed') AND OLD.status = 'pending' THEN
NEW.resolved_at = now();
END IF;
RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_venue_report_resolved_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."toggle_moment_like"("p_moment_id" "uuid", "p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
v_existing_id uuid;
v_liked       boolean;
BEGIN
SELECT id INTO v_existing_id
FROM venue_room_moment_likes
WHERE moment_id = p_moment_id AND user_id = p_user_id;

IF v_existing_id IS NOT NULL THEN
DELETE FROM venue_room_moment_likes WHERE id = v_existing_id;
UPDATE venue_room_moments SET like_count = GREATEST(0, like_count - 1) WHERE id = p_moment_id;
v_liked := false;
ELSE
INSERT INTO venue_room_moment_likes (moment_id, user_id) VALUES (p_moment_id, p_user_id);
UPDATE venue_room_moments SET like_count = like_count + 1 WHERE id = p_moment_id;
v_liked := true;
END IF;

RETURN jsonb_build_object('liked', v_liked);
END;
$$;


ALTER FUNCTION "public"."toggle_moment_like"("p_moment_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."toggle_wall_photo_like"("p_photo_id" "uuid", "p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
v_existing uuid;
v_liked    boolean;
BEGIN
SELECT id INTO v_existing
FROM venue_wall_photo_likes
WHERE photo_id = p_photo_id AND user_id = p_user_id;

IF v_existing IS NOT NULL THEN
DELETE FROM venue_wall_photo_likes WHERE id = v_existing;
UPDATE venue_wall_photos
SET like_count = GREATEST(like_count - 1, 0)
WHERE id = p_photo_id;
v_liked := false;
ELSE
INSERT INTO venue_wall_photo_likes (photo_id, user_id) VALUES (p_photo_id, p_user_id);
UPDATE venue_wall_photos
SET like_count = like_count + 1
WHERE id = p_photo_id;
v_liked := true;
END IF;

RETURN jsonb_build_object('liked', v_liked);
END;
$$;


ALTER FUNCTION "public"."toggle_wall_photo_like"("p_photo_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_conversations_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN
UPDATE public.conversations SET updated_at = now() WHERE id = NEW.conversation_id;
RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_conversations_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_friendships_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;


ALTER FUNCTION "public"."update_friendships_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_swarm_current_size"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
UPDATE swarms
SET current_size = (
SELECT COUNT(*)
FROM swarm_members
WHERE swarm_id = NEW.swarm_id
AND rsvp IN ('going', 'interested')
)
WHERE id = NEW.swarm_id;
RETURN NEW;
ELSIF TG_OP = 'DELETE' THEN
UPDATE swarms
SET current_size = (
SELECT COUNT(*)
FROM swarm_members
WHERE swarm_id = OLD.swarm_id
AND rsvp IN ('going', 'interested')
)
WHERE id = OLD.swarm_id;
RETURN OLD;
END IF;
RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."update_swarm_current_size"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_swarms_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
BEGIN
NEW.updated_at = now();
RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_swarms_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;


ALTER FUNCTION "public"."update_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_venues_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;


ALTER FUNCTION "public"."update_venues_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_room_presence"("p_venue_id" "uuid", "p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
  INSERT INTO venue_room_presence (venue_id, user_id, joined_at, last_active_at)
  VALUES (p_venue_id, p_user_id, now(), now())
  ON CONFLICT (venue_id, user_id)
  DO UPDATE SET last_active_at = now();
END;
$$;


ALTER FUNCTION "public"."upsert_room_presence"("p_venue_id" "uuid", "p_user_id" "uuid") OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."account_deletion_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "requested_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completed_at" timestamp with time zone,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "deletion_reason" "text",
    "data_export_requested" boolean DEFAULT false NOT NULL,
    CONSTRAINT "account_deletion_requests_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'processing'::"text", 'completed'::"text"])))
);


ALTER TABLE "public"."account_deletion_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."activity_feed" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "actor_user_id" "uuid" NOT NULL,
    "activity_type" "text" NOT NULL,
    "venue_id" "uuid",
    "swarm_id" "uuid",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "activity_feed_activity_type_check" CHECK (("activity_type" = ANY (ARRAY['venue_enter'::"text", 'venue_leave'::"text", 'swarm_join'::"text", 'swarm_create'::"text", 'friend_request_accepted'::"text", 'status_update'::"text"])))
);


ALTER TABLE "public"."activity_feed" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."badge_definitions" (
    "badge_key" "text" NOT NULL,
    "name" "text" NOT NULL,
    "emoji" "text" DEFAULT ''::"text" NOT NULL,
    "requirement" "text" DEFAULT ''::"text" NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."badge_definitions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bars" (
    "bar_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "lat" double precision NOT NULL,
    "lng" double precision NOT NULL,
    "city" "text" DEFAULT 'Darwin'::"text",
    "state" "text" DEFAULT 'NT'::"text",
    "country" "text" DEFAULT 'AU'::"text",
    "radar_place_id" "text",
    "google_place_id" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "google_last_fetched_at" timestamp with time zone,
    "google_last_linked_at" timestamp with time zone,
    "rating" numeric,
    "review_count" integer DEFAULT 0,
    "photo_urls" "text"[] DEFAULT ARRAY[]::"text"[],
    "address" "text",
    "opening_hours" "jsonb",
    "google_last_synced_at" timestamp with time zone,
    CONSTRAINT "bars_darwin_bounds_check" CHECK (((("lat" >= ('-12.55'::numeric)::double precision) AND ("lat" <= ('-12.35'::numeric)::double precision)) AND (("lng" >= (130.75)::double precision) AND ("lng" <= (131.05)::double precision)))),
    CONSTRAINT "darwin_bounds_check" CHECK (((("lat" >= ('-12.55'::numeric)::double precision) AND ("lat" <= ('-12.35'::numeric)::double precision)) AND (("lng" >= (130.75)::double precision) AND ("lng" <= (131.05)::double precision))))
);


ALTER TABLE "public"."bars" OWNER TO "postgres";


COMMENT ON COLUMN "public"."bars"."google_place_id" IS 'Google Places API place_id for enriching venue data';



COMMENT ON COLUMN "public"."bars"."google_last_fetched_at" IS 'Timestamp when Google Place details were last fetched';



COMMENT ON COLUMN "public"."bars"."google_last_linked_at" IS 'Timestamp when this bar was linked to a Google Place';



COMMENT ON COLUMN "public"."bars"."rating" IS 'Rating from Google Places (0-5 scale)';



COMMENT ON COLUMN "public"."bars"."review_count" IS 'Total number of reviews on Google Places';



COMMENT ON COLUMN "public"."bars"."photo_urls" IS 'Array of photo references for displaying bar photos';



COMMENT ON COLUMN "public"."bars"."address" IS 'Formatted address from Google Places';



COMMENT ON COLUMN "public"."bars"."opening_hours" IS 'Opening hours JSON data from Google Places';



COMMENT ON COLUMN "public"."bars"."google_last_synced_at" IS 'When Google Place denormalized data was last synced to bars table';



CREATE TABLE IF NOT EXISTS "public"."blocks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "blocker_user_id" "uuid" NOT NULL,
    "blocked_user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."blocks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."challenge_definitions" (
    "challenge_key" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text" DEFAULT ''::"text" NOT NULL,
    "target" integer DEFAULT 1 NOT NULL,
    "reward_xp" integer DEFAULT 0 NOT NULL,
    "expiry_days" integer DEFAULT 7 NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."challenge_definitions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."check_in_streaks" (
    "user_id" "uuid" NOT NULL,
    "current_streak" integer DEFAULT 0 NOT NULL,
    "longest_streak" integer DEFAULT 0 NOT NULL,
    "last_checkin_date" "date",
    "total_checkins" integer DEFAULT 0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."check_in_streaks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."cheers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "recipient_id" "uuid" NOT NULL,
    "venue_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cheers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."conversation_participants" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "conversation_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" DEFAULT 'member'::"text" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "left_at" timestamp with time zone,
    "last_read_at" timestamp with time zone,
    "notifications_enabled" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "conversation_participants_role_check" CHECK (("role" = ANY (ARRAY['member'::"text", 'admin'::"text", 'owner'::"text"])))
);


ALTER TABLE "public"."conversation_participants" OWNER TO "postgres";


COMMENT ON TABLE "public"."conversation_participants" IS 'Tracks user membership in conversations with roles and read status';



CREATE TABLE IF NOT EXISTS "public"."conversation_starters" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "prompt_text" "text" NOT NULL,
    "category" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."conversation_starters" OWNER TO "postgres";


COMMENT ON TABLE "public"."conversation_starters" IS 'Template conversation starter prompts for user profiles';



CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text",
    "type" "text" DEFAULT 'direct'::"text" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "swarm_id" "uuid",
    "venue_id" "uuid",
    "is_active" boolean DEFAULT true NOT NULL,
    "last_message_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "conversations_type_check" CHECK (("type" = ANY (ARRAY['direct'::"text", 'group'::"text"])))
);


ALTER TABLE "public"."conversations" OWNER TO "postgres";


COMMENT ON TABLE "public"."conversations" IS 'Stores conversation/chat room metadata for both 1-on-1 and group chats';



CREATE TABLE IF NOT EXISTS "public"."drink_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "category_type" "text",
    "sort_order" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."drink_categories" OWNER TO "postgres";


COMMENT ON TABLE "public"."drink_categories" IS 'Drink types: Whiskey, Vodka, Beer, Wine, Tequila, etc';



CREATE TABLE IF NOT EXISTS "public"."emergency_numbers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "country" "text" NOT NULL,
    "emergency_number" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."emergency_numbers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."emoji_reactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "target_type" "text" NOT NULL,
    "target_id" "uuid" NOT NULL,
    "emoji" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "emoji_reactions_target_type_check" CHECK (("target_type" = ANY (ARRAY['message'::"text", 'post'::"text", 'profile'::"text", 'venue'::"text", 'swarm'::"text"])))
);


ALTER TABLE "public"."emoji_reactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."event_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "event_type" "text" NOT NULL,
    "event_action" "text" NOT NULL,
    "event_data" "jsonb" DEFAULT '{}'::"jsonb",
    "ip_address" "inet",
    "user_agent" "text",
    "session_id" "text",
    "status" "text" DEFAULT 'success'::"text" NOT NULL,
    "error_message" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "event_log_status_check" CHECK (("status" = ANY (ARRAY['success'::"text", 'failure'::"text", 'pending'::"text"])))
);


ALTER TABLE "public"."event_log" OWNER TO "postgres";


COMMENT ON TABLE "public"."event_log" IS 'System-wide audit log for tracking user actions, system events, and security activities';



CREATE TABLE IF NOT EXISTS "public"."friendships" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "friend_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "requested_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "responded_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "friendships_check" CHECK (("user_id" <> "friend_id")),
    CONSTRAINT "friendships_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'accepted'::"text", 'declined'::"text", 'blocked'::"text"])))
);


ALTER TABLE "public"."friendships" OWNER TO "postgres";


COMMENT ON TABLE "public"."friendships" IS 'Manages friend relationships between users, supporting friend requests, acceptance, and bidirectional connections';



CREATE TABLE IF NOT EXISTS "public"."geofence_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "venue_id" "uuid" NOT NULL,
    "event_type" "text" NOT NULL,
    "latitude" numeric(10,8) NOT NULL,
    "longitude" numeric(11,8) NOT NULL,
    "accuracy" numeric(10,2),
    "distance_from_center" numeric(10,2),
    "triggered_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "processed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "geofence_events_event_type_check" CHECK (("event_type" = ANY (ARRAY['enter'::"text", 'exit'::"text"]))),
    CONSTRAINT "geofence_events_latitude_check" CHECK ((("latitude" >= ('-90'::integer)::numeric) AND ("latitude" <= (90)::numeric))),
    CONSTRAINT "geofence_events_longitude_check" CHECK ((("longitude" >= ('-180'::integer)::numeric) AND ("longitude" <= (180)::numeric)))
);


ALTER TABLE "public"."geofence_events" OWNER TO "postgres";


COMMENT ON TABLE "public"."geofence_events" IS 'Tracks user entry/exit events for venue geofences, enabling automatic check-ins and location-based features';



CREATE TABLE IF NOT EXISTS "public"."gifts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "from_user_id" "uuid" NOT NULL,
    "to_user_id" "uuid" NOT NULL,
    "drink_type" "text" NOT NULL,
    "amount" numeric NOT NULL,
    "message" "text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "venue_id" "uuid",
    "redeemed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "gifts_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'redeemed'::"text", 'expired'::"text"])))
);


ALTER TABLE "public"."gifts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."google_api_logs" (
    "log_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "bar_id" "uuid" NOT NULL,
    "success" boolean DEFAULT false NOT NULL,
    "place_id" "text",
    "details" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."google_api_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."google_place_cache" (
    "cache_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bar_id" "uuid" NOT NULL,
    "place_id" "text" NOT NULL,
    "cached_data" "jsonb" NOT NULL,
    "cached_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."google_place_cache" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."group_split_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "split_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "amount" numeric(10,2) DEFAULT 0 NOT NULL,
    "paid" boolean DEFAULT false NOT NULL,
    "paid_at" timestamp with time zone
);


ALTER TABLE "public"."group_split_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."group_splits" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "swarm_id" "uuid",
    "creator_id" "uuid" NOT NULL,
    "total_amount" numeric(10,2) DEFAULT 0 NOT NULL,
    "description" "text" DEFAULT ''::"text" NOT NULL,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "group_splits_status_check" CHECK (("status" = ANY (ARRAY['open'::"text", 'settled'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."group_splits" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."interests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "emoji" "text",
    "sort_order" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."interests" OWNER TO "postgres";


COMMENT ON TABLE "public"."interests" IS 'User interest categories (Music, Sports, Travel, Food & Cooking, etc)';



CREATE TABLE IF NOT EXISTS "public"."languages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "native_name" "text" NOT NULL,
    "is_active" boolean DEFAULT true,
    "is_default" boolean DEFAULT false,
    "locale_tag" "text" NOT NULL,
    "sort_order" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."languages" OWNER TO "postgres";


COMMENT ON TABLE "public"."languages" IS 'Supported languages: en, es, fr, de, it, pt, ja, zh, etc';



COMMENT ON COLUMN "public"."languages"."code" IS 'Language code (en, es, fr, de, etc)';



COMMENT ON COLUMN "public"."languages"."locale_tag" IS 'Full locale tag (en-US, es-MX, pt-BR, etc)';



CREATE TABLE IF NOT EXISTS "public"."location_events" (
    "event_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "bar_id" "uuid",
    "radar_place_id" "text",
    "event_type" "text" NOT NULL,
    "occurred_at" timestamp with time zone NOT NULL,
    "lat" double precision,
    "lng" double precision,
    "accuracy_m" double precision,
    "confidence" double precision,
    "raw_payload" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "venue_id" "uuid",
    CONSTRAINT "location_events_event_type_check" CHECK (("event_type" = ANY (ARRAY['enter'::"text", 'exit'::"text", 'dwell'::"text"])))
);


ALTER TABLE "public"."location_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."location_pings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "latitude" numeric(10,8) NOT NULL,
    "longitude" numeric(11,8) NOT NULL,
    "accuracy" numeric(10,2),
    "altitude" numeric(10,2),
    "speed" numeric(10,2),
    "heading" numeric(5,2),
    "battery_level" integer,
    "is_background" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "location_pings_battery_level_check" CHECK ((("battery_level" IS NULL) OR (("battery_level" >= 0) AND ("battery_level" <= 100)))),
    CONSTRAINT "location_pings_heading_check" CHECK ((("heading" IS NULL) OR (("heading" >= (0)::numeric) AND ("heading" <= (360)::numeric)))),
    CONSTRAINT "location_pings_latitude_check" CHECK ((("latitude" >= ('-90'::integer)::numeric) AND ("latitude" <= (90)::numeric))),
    CONSTRAINT "location_pings_longitude_check" CHECK ((("longitude" >= ('-180'::integer)::numeric) AND ("longitude" <= (180)::numeric)))
);


ALTER TABLE "public"."location_pings" OWNER TO "postgres";


COMMENT ON TABLE "public"."location_pings" IS 'Real-time location tracking for users, enabling proximity features and location history';



CREATE TABLE IF NOT EXISTS "public"."looking_for_options" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "emoji" "text",
    "sort_order" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."looking_for_options" OWNER TO "postgres";


COMMENT ON TABLE "public"."looking_for_options" IS 'Relationship/connection intent (New Friends, Dating, Networking, etc)';



CREATE TABLE IF NOT EXISTS "public"."message_edits" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "message_id" "uuid" NOT NULL,
    "edited_by" "uuid" NOT NULL,
    "previous_body" "text" NOT NULL,
    "edited_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."message_edits" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "conversation_type" "text" DEFAULT 'dm'::"text",
    "dm_user_a" "uuid",
    "dm_user_b" "uuid",
    "swarm_id" "uuid",
    "sender_user_id" "uuid" NOT NULL,
    "body" "text",
    "media_url" "text",
    "read_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "edited_at" timestamp with time zone,
    "deleted_at" timestamp with time zone,
    "delivery_status" "text" DEFAULT 'sent'::"text",
    "deleted_for_user_ids" "uuid"[] DEFAULT '{}'::"uuid"[],
    "conversation_cleared_by" "uuid"[] DEFAULT '{}'::"uuid"[],
    CONSTRAINT "messages_conversation_type_check" CHECK (("conversation_type" = ANY (ARRAY['dm'::"text", 'swarm'::"text"]))),
    CONSTRAINT "messages_delivery_status_check" CHECK (("delivery_status" = ANY (ARRAY['sending'::"text", 'sent'::"text", 'delivered'::"text", 'read'::"text"])))
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mixed_drinks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "category_id" "uuid",
    "description" "text",
    "is_popular" boolean DEFAULT false,
    "sort_order" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."mixed_drinks" OWNER TO "postgres";


COMMENT ON TABLE "public"."mixed_drinks" IS 'Specific cocktails and mixed drinks (Margarita, Mojito, Old Fashioned, etc)';



CREATE TABLE IF NOT EXISTS "public"."music_shares" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "recipient_id" "uuid" NOT NULL,
    "song_id" "text" NOT NULL,
    "song_title" "text" NOT NULL,
    "artist_name" "text" NOT NULL,
    "album_art_url" "text",
    "preview_url" "text",
    "external_url" "text" NOT NULL,
    "platform" "text" NOT NULL,
    "message" "text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "swarm_id" "uuid",
    "venue_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "played_at" timestamp with time zone,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '30 days'::interval) NOT NULL,
    CONSTRAINT "music_shares_platform_check" CHECK (("platform" = ANY (ARRAY['spotify'::"text", 'apple_music'::"text", 'youtube_music'::"text"]))),
    CONSTRAINT "music_shares_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'played'::"text", 'saved'::"text", 'expired'::"text"])))
);


ALTER TABLE "public"."music_shares" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."night_route_invites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "route_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "night_route_invites_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'accepted'::"text", 'declined'::"text"])))
);


ALTER TABLE "public"."night_route_invites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."night_routes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "creator_id" "uuid" NOT NULL,
    "name" "text" DEFAULT 'My Night Out'::"text" NOT NULL,
    "stops" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "planned_date" "date",
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "night_routes_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'active'::"text", 'completed'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."night_routes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "recipient_user_id" "uuid" NOT NULL,
    "actor_user_id" "uuid",
    "notification_type" "text" NOT NULL,
    "title" "text" NOT NULL,
    "body" "text" DEFAULT ''::"text" NOT NULL,
    "venue_id" "uuid",
    "swarm_id" "uuid",
    "is_read" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."osm_import_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "region_type" "text" NOT NULL,
    "country_code" "text",
    "total_processed" integer DEFAULT 0,
    "inserted_count" integer DEFAULT 0,
    "updated_count" integer DEFAULT 0,
    "skipped_count" integer DEFAULT 0,
    "errors" "jsonb",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "completed_at" timestamp with time zone,
    "status" "text" DEFAULT 'running'::"text",
    CONSTRAINT "osm_import_logs_status_check" CHECK (("status" = ANY (ARRAY['running'::"text", 'completed'::"text", 'failed'::"text"])))
);


ALTER TABLE "public"."osm_import_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."payment_transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "from_user_id" "uuid" NOT NULL,
    "to_user_id" "uuid" NOT NULL,
    "amount" numeric NOT NULL,
    "currency" "text" DEFAULT 'USD'::"text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "provider_ref" "text",
    "swarm_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "transaction_type" "text" DEFAULT 'transfer'::"text",
    "description" "text",
    "drink_name" "text",
    "tx_signature" "text",
    "token_mint" "text",
    CONSTRAINT "payment_transactions_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'completed'::"text", 'failed'::"text", 'refunded'::"text"]))),
    CONSTRAINT "payment_transactions_transaction_type_check" CHECK (("transaction_type" = ANY (ARRAY['drink_request'::"text", 'drink_payment'::"text", 'transfer'::"text", 'gift'::"text", 'split_tab'::"text"])))
);


ALTER TABLE "public"."payment_transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."public_music_shares" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "shared_by_user_id" "uuid" NOT NULL,
    "itunes_track_id" "text" NOT NULL,
    "track_name" "text" NOT NULL,
    "artist_name" "text" NOT NULL,
    "artwork_url" "text",
    "preview_url" "text",
    "collection_name" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."public_music_shares" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."push_subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "endpoint" "text",
    "p256dh" "text",
    "auth" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "native_token" "text",
    "platform" "text" DEFAULT 'web'::"text"
);


ALTER TABLE "public"."push_subscriptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."regions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "language_id" "uuid" NOT NULL,
    "code" "text" NOT NULL,
    "name" "text" NOT NULL,
    "locale_tag" "text" NOT NULL,
    "country_code" "text",
    "is_default_for_language" boolean DEFAULT false,
    "date_format" "text" DEFAULT 'MM/DD/YYYY'::"text",
    "time_format" "text" DEFAULT 'h:mm A'::"text",
    "datetime_format" "text" DEFAULT 'MM/DD/YYYY h:mm A'::"text",
    "currency_code" "text" DEFAULT 'USD'::"text",
    "currency_symbol" "text" DEFAULT '$'::"text",
    "currency_position" "text" DEFAULT 'before'::"text",
    "decimal_separator" "text" DEFAULT '.'::"text",
    "thousands_separator" "text" DEFAULT ','::"text",
    "temperature_unit" "text" DEFAULT 'F'::"text",
    "distance_unit" "text" DEFAULT 'miles'::"text",
    "week_start_day" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."regions" OWNER TO "postgres";


COMMENT ON TABLE "public"."regions" IS 'Regional configurations for localization (US, UK, Mexico, Spain, Brazil, etc)';



COMMENT ON COLUMN "public"."regions"."date_format" IS 'Date format pattern (MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD)';



COMMENT ON COLUMN "public"."regions"."time_format" IS 'Time format pattern (h:mm A, HH:mm, h:mm:ss A)';



COMMENT ON COLUMN "public"."regions"."week_start_day" IS '0=Sunday, 1=Monday';



CREATE TABLE IF NOT EXISTS "public"."reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reporter_user_id" "uuid" NOT NULL,
    "reported_user_id" "uuid" NOT NULL,
    "context" "text",
    "reason" "text" NOT NULL,
    "details" "text",
    "status" "text" DEFAULT 'pending'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "reports_context_check" CHECK (("context" = ANY (ARRAY['dm'::"text", 'swarm'::"text", 'profile'::"text"]))),
    CONSTRAINT "reports_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'reviewed'::"text", 'actioned'::"text"])))
);


ALTER TABLE "public"."reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."safe_arrivals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "checked_in_at" timestamp with time zone DEFAULT "now"(),
    "notified_friend_ids" "jsonb" DEFAULT '[]'::"jsonb"
);


ALTER TABLE "public"."safe_arrivals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."safety_alerts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "latitude" numeric,
    "longitude" numeric,
    "location_url" "text",
    "alert_type" "text" DEFAULT 'location_share'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."safety_alerts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."safety_friends" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "friend_name" "text" NOT NULL,
    "friend_phone" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."safety_friends" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "plan_type" "text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "stripe_subscription_id" "text",
    "current_period_start" timestamp with time zone NOT NULL,
    "current_period_end" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "subscriptions_plan_type_check" CHECK (("plan_type" = ANY (ARRAY['monthly'::"text", 'yearly'::"text"]))),
    CONSTRAINT "subscriptions_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'cancelled'::"text", 'expired'::"text"])))
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."swarm_members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "swarm_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" DEFAULT 'member'::"text",
    "rsvp" "text" DEFAULT 'going'::"text",
    "joined_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "swarm_members_role_check" CHECK (("role" = ANY (ARRAY['host'::"text", 'member'::"text"]))),
    CONSTRAINT "swarm_members_rsvp_check" CHECK (("rsvp" = ANY (ARRAY['invited'::"text", 'going'::"text", 'maybe'::"text", 'not_going'::"text"])))
);


ALTER TABLE "public"."swarm_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."swarms" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "host_user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "vibe_tags" "text"[],
    "venue_id" "uuid",
    "start_time" timestamp with time zone,
    "end_time" timestamp with time zone,
    "max_attendees" integer,
    "join_mode" "text" DEFAULT 'open'::"text",
    "status" "text" DEFAULT 'active'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "venue_name" "text",
    "max_size" integer DEFAULT 50,
    "current_size" integer DEFAULT 1,
    "is_public" boolean DEFAULT true,
    "updated_at" timestamp with time zone,
    CONSTRAINT "swarms_join_mode_check" CHECK (("join_mode" = ANY (ARRAY['open'::"text", 'request_approval'::"text", 'friends'::"text", 'invite_only'::"text"]))),
    CONSTRAINT "swarms_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'ended'::"text", 'cancelled'::"text", 'completed'::"text"])))
);


ALTER TABLE "public"."swarms" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."translation_keys" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key" "text" NOT NULL,
    "description" "text",
    "category" "text",
    "platform" "text" DEFAULT 'shared'::"text",
    "requires_context" boolean DEFAULT false,
    "context_example" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."translation_keys" OWNER TO "postgres";


COMMENT ON TABLE "public"."translation_keys" IS 'Master list of all translation keys used across platforms';



COMMENT ON COLUMN "public"."translation_keys"."key" IS 'Dot-notation key (e.g., navigation.explore, payment.send_money)';



COMMENT ON COLUMN "public"."translation_keys"."platform" IS 'web, mobile, or shared (both platforms)';



COMMENT ON COLUMN "public"."translation_keys"."requires_context" IS 'Whether key has interpolation variables';



CREATE TABLE IF NOT EXISTS "public"."translations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key_id" "uuid" NOT NULL,
    "language_id" "uuid" NOT NULL,
    "translated_text" "text" NOT NULL,
    "is_complete" boolean DEFAULT true,
    "needs_review" boolean DEFAULT false,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."translations" OWNER TO "postgres";


COMMENT ON TABLE "public"."translations" IS 'Translated content for each key-language combination';



COMMENT ON COLUMN "public"."translations"."is_complete" IS 'False if translation is placeholder or needs work';



COMMENT ON COLUMN "public"."translations"."needs_review" IS 'Flag for translation review/QA';



CREATE TABLE IF NOT EXISTS "public"."user_activity_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "activity_type" "text" NOT NULL,
    "activity_data" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "location_lat" numeric,
    "location_lng" numeric,
    "venue_id" "uuid",
    "related_user_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "user_activity_history_activity_type_check" CHECK (("activity_type" = ANY (ARRAY['uber_ride'::"text", 'venue_visit'::"text", 'swarm_join'::"text", 'gift_sent'::"text", 'message_sent'::"text", 'music_shared'::"text", 'other'::"text"])))
);


ALTER TABLE "public"."user_activity_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_badges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "badge_key" "text" NOT NULL,
    "earned_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_badges" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_blocks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "blocker_id" "uuid" NOT NULL,
    "blocked_id" "uuid" NOT NULL,
    "reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "user_blocks_check" CHECK (("blocker_id" <> "blocked_id"))
);


ALTER TABLE "public"."user_blocks" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_blocks" IS 'Manages user blocking relationships for safety and privacy, preventing unwanted interactions';



CREATE TABLE IF NOT EXISTS "public"."user_challenges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "challenge_key" "text" NOT NULL,
    "progress" integer DEFAULT 0,
    "target" integer NOT NULL,
    "reward_xp" integer NOT NULL,
    "status" "text" DEFAULT 'active'::"text",
    "started_at" timestamp with time zone DEFAULT "now"(),
    "completed_at" timestamp with time zone,
    "expires_at" timestamp with time zone,
    CONSTRAINT "user_challenges_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'completed'::"text", 'expired'::"text"])))
);


ALTER TABLE "public"."user_challenges" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_consents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "consent_type" "text" NOT NULL,
    "accepted" boolean DEFAULT true NOT NULL,
    "accepted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "version" "text" DEFAULT '1.0'::"text" NOT NULL,
    "ip_address" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "user_consents_consent_type_check" CHECK (("consent_type" = ANY (ARRAY['terms'::"text", 'privacy'::"text", 'marketing'::"text", 'analytics'::"text", 'location'::"text"])))
);


ALTER TABLE "public"."user_consents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_gifts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "from_user_id" "uuid" NOT NULL,
    "to_user_id" "uuid" NOT NULL,
    "item_id" "uuid" NOT NULL,
    "message" "text",
    "status" "text" DEFAULT 'sent'::"text" NOT NULL,
    "reaction" "text",
    "context_type" "text" NOT NULL,
    "context_id" "uuid",
    "viewed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "tx_signature" "text",
    CONSTRAINT "user_gifts_context_type_check" CHECK (("context_type" = ANY (ARRAY['direct_message'::"text", 'profile'::"text", 'swarm'::"text", 'venue'::"text"]))),
    CONSTRAINT "user_gifts_status_check" CHECK (("status" = ANY (ARRAY['sent'::"text", 'viewed'::"text", 'reacted'::"text"])))
);


ALTER TABLE "public"."user_gifts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_inventory" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "item_id" "uuid" NOT NULL,
    "quantity" integer DEFAULT 1 NOT NULL,
    "acquired_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "user_inventory_quantity_check" CHECK (("quantity" >= 0))
);


ALTER TABLE "public"."user_inventory" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_language_preferences" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "language_id" "uuid" NOT NULL,
    "region_id" "uuid" NOT NULL,
    "auto_detect" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_language_preferences" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_language_preferences" IS 'User-specific language and region preferences';



CREATE TABLE IF NOT EXISTS "public"."user_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "reporter_id" "uuid" NOT NULL,
    "reported_user_id" "uuid",
    "reported_message_id" "uuid",
    "reported_venue_id" "uuid",
    "report_type" "text" NOT NULL,
    "reason" "text" NOT NULL,
    "description" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "resolution_notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "user_reports_reason_check" CHECK (("reason" = ANY (ARRAY['harassment'::"text", 'spam'::"text", 'inappropriate'::"text", 'fake'::"text", 'safety_concern'::"text", 'other'::"text"]))),
    CONSTRAINT "user_reports_report_type_check" CHECK (("report_type" = ANY (ARRAY['user'::"text", 'message'::"text", 'venue'::"text", 'photo'::"text", 'behavior'::"text"]))),
    CONSTRAINT "user_reports_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'reviewed'::"text", 'action_taken'::"text", 'dismissed'::"text"])))
);


ALTER TABLE "public"."user_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_stats" (
    "user_id" "uuid" NOT NULL,
    "total_xp" integer DEFAULT 0,
    "current_streak" integer DEFAULT 0,
    "longest_streak" integer DEFAULT 0,
    "last_streak_at" timestamp with time zone,
    "unique_venues" integer DEFAULT 0,
    "total_checkins" integer DEFAULT 0,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_stats" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_venue_presence" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "venue_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'IN_VENUE'::"text" NOT NULL,
    "entered_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "left_at" timestamp with time zone,
    "last_seen_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_visible_in_venue" boolean DEFAULT true,
    "dwell_seconds" integer DEFAULT 0,
    "entry_method" "text" DEFAULT 'AUTO_GEOFENCE'::"text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "valid_dates" CHECK ((("left_at" IS NULL) OR ("left_at" >= "entered_at"))),
    CONSTRAINT "valid_dwell" CHECK (("dwell_seconds" >= 0)),
    CONSTRAINT "valid_status" CHECK (("status" = ANY (ARRAY['IN_VENUE'::"text", 'LEFT_VENUE'::"text"])))
);


ALTER TABLE "public"."user_venue_presence" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "email" "text",
    "name" "text",
    "username" "text",
    "dob" "date",
    "age" integer,
    "bio" "text",
    "avatar_url" "text",
    "photos" "text"[],
    "tonight_status" "text" DEFAULT 'staying_in'::"text",
    "vibe_tags" "text"[],
    "favorite_drinks" "text"[],
    "venue_preferences" "text"[],
    "home_city" "text",
    "last_known_lat" numeric,
    "last_known_lng" numeric,
    "preferred_radius_meters" integer DEFAULT 5000,
    "privacy_mode" "text" DEFAULT 'nearby'::"text",
    "ghost_mode" boolean DEFAULT false,
    "is_premium" boolean DEFAULT false,
    "lush_coin_balance" integer DEFAULT 0,
    "venmo_username" "text",
    "venmo_linked" boolean DEFAULT false,
    "weather_location" "text",
    "weather_enabled" boolean DEFAULT true,
    "last_active_at" timestamp with time zone DEFAULT "now"(),
    "is_21_plus_confirmed" boolean DEFAULT false,
    "phone_number" "text",
    "phone_country_code" "text",
    "registration_country" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "looking_for" "text",
    "fun_fact" "text",
    "go_to_karaoke_song" "text",
    "ideal_night_out" "text",
    "conversation_starters" "text"[] DEFAULT ARRAY[]::"text"[],
    "interests" "text"[] DEFAULT ARRAY[]::"text"[],
    "occupation" "text",
    "education" "text",
    "spotify_username" "text",
    "instagram_username" "text",
    "first_drink_on_me" boolean DEFAULT false,
    "verified_profile" boolean DEFAULT false,
    "payment_provider" "text" DEFAULT 'venmo'::"text",
    "payment_provider_username" "text",
    "payment_provider_linked" boolean DEFAULT false,
    "distance_unit" "text",
    "temperature_unit" "text",
    "is_dd_tonight" boolean DEFAULT false NOT NULL,
    "dd_expires_at" timestamp with time zone,
    "notification_preferences" "jsonb",
    "wallet_address" "text",
    "is_visible" boolean DEFAULT true NOT NULL,
    "invisible_mode_enabled" boolean DEFAULT false NOT NULL,
    "visibility_mode" "text" DEFAULT 'visible'::"text" NOT NULL,
    "terms_accepted_at" timestamp with time zone,
    CONSTRAINT "users_privacy_mode_check" CHECK (("privacy_mode" = ANY (ARRAY['invisible'::"text", 'friends_only'::"text", 'nearby'::"text", 'public'::"text"]))),
    CONSTRAINT "users_tonight_status_check" CHECK (("tonight_status" = ANY (ARRAY['out_now'::"text", 'going_out_soon'::"text", 'going_out'::"text", 'staying_in'::"text"])))
);


ALTER TABLE "public"."users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_buzz" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "venue_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "body" "text" NOT NULL,
    "report_count" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "expires_at" timestamp with time zone DEFAULT ("now"() + '04:00:00'::interval),
    CONSTRAINT "venue_buzz_body_check" CHECK ((("char_length"("body") >= 1) AND ("char_length"("body") <= 280)))
);


ALTER TABLE "public"."venue_buzz" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_clusters" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "city" "text" NOT NULL,
    "center_lat" double precision NOT NULL,
    "center_lng" double precision NOT NULL,
    "radius_meters" integer DEFAULT 500 NOT NULL,
    "venue_ids" "uuid"[] DEFAULT '{}'::"uuid"[],
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "valid_cluster_lat" CHECK ((("center_lat" >= ('-90'::integer)::double precision) AND ("center_lat" <= (90)::double precision))),
    CONSTRAINT "valid_cluster_lng" CHECK ((("center_lng" >= ('-180'::integer)::double precision) AND ("center_lng" <= (180)::double precision))),
    CONSTRAINT "valid_cluster_radius" CHECK ((("radius_meters" > 0) AND ("radius_meters" <= 5000)))
);


ALTER TABLE "public"."venue_clusters" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."venue_crossing_paths" WITH ("security_invoker"='true') AS
 SELECT "a"."user_id" AS "viewer_id",
    "b"."user_id" AS "other_user_id",
    "a"."venue_id",
    GREATEST("a"."entered_at", "b"."entered_at") AS "overlap_start",
    LEAST(COALESCE("a"."left_at", "now"()), COALESCE("b"."left_at", "now"())) AS "overlap_end",
    "a"."entered_at" AS "viewer_entered_at",
    COALESCE("a"."left_at", "now"()) AS "viewer_left_at",
    "b"."entered_at" AS "other_entered_at",
    COALESCE("b"."left_at", "now"()) AS "other_left_at"
   FROM (("public"."user_venue_presence" "a"
     JOIN "public"."user_venue_presence" "b" ON ((("a"."venue_id" = "b"."venue_id") AND ("a"."user_id" <> "b"."user_id") AND ("a"."entered_at" < COALESCE("b"."left_at", "now"())) AND ("b"."entered_at" < COALESCE("a"."left_at", "now"())))))
     JOIN "public"."users" "u" ON (("u"."id" = "b"."user_id")))
  WHERE ((("u"."ghost_mode" IS NULL) OR ("u"."ghost_mode" = false)) AND ("a"."entered_at" >= ("now"() - '7 days'::interval)));


ALTER VIEW "public"."venue_crossing_paths" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_photos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "venue_id" "text" NOT NULL,
    "source" "text" NOT NULL,
    "image_url" "text" NOT NULL,
    "caption" "text",
    "created_by_user_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "venue_photos_source_check" CHECK (("source" = ANY (ARRAY['user_upload'::"text", 'owner_upload'::"text", 'osm'::"text"])))
);


ALTER TABLE "public"."venue_photos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_ratings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "venue_id" "uuid" NOT NULL,
    "rating" integer NOT NULL,
    "notes" "text" DEFAULT ''::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "venue_ratings_rating_check" CHECK ((("rating" >= 1) AND ("rating" <= 5)))
);


ALTER TABLE "public"."venue_ratings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "venue_id" "uuid" NOT NULL,
    "reporter_id" "uuid" NOT NULL,
    "report_type" "text" NOT NULL,
    "description" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "admin_notes" "text",
    "resolved_at" timestamp with time zone,
    "resolved_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "venue_reports_report_type_check" CHECK (("report_type" = ANY (ARRAY['incorrect_info'::"text", 'closed'::"text", 'inappropriate'::"text", 'safety_concern'::"text", 'spam'::"text", 'other'::"text"]))),
    CONSTRAINT "venue_reports_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'reviewing'::"text", 'resolved'::"text", 'dismissed'::"text"])))
);


ALTER TABLE "public"."venue_reports" OWNER TO "postgres";


COMMENT ON TABLE "public"."venue_reports" IS 'Stores user-submitted reports about venue issues for moderation and data quality';



CREATE TABLE IF NOT EXISTS "public"."venue_reviews" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "venue_id" "text" NOT NULL,
    "rating" integer NOT NULL,
    "title" "text",
    "body" "text",
    "created_by_user_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "venue_reviews_rating_check" CHECK ((("rating" >= 1) AND ("rating" <= 5)))
);


ALTER TABLE "public"."venue_reviews" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_room_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "venue_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "body" "text" NOT NULL,
    "message_type" "text" DEFAULT 'text'::"text" NOT NULL,
    "metadata" "jsonb",
    "report_count" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '24:00:00'::interval) NOT NULL,
    CONSTRAINT "venue_room_messages_body_check" CHECK (("char_length"("body") <= 280)),
    CONSTRAINT "venue_room_messages_message_type_check" CHECK (("message_type" = ANY (ARRAY['text'::"text", 'drink'::"text", 'music'::"text", 'prompt'::"text", 'gif'::"text"])))
);


ALTER TABLE "public"."venue_room_messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_room_moment_likes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "moment_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."venue_room_moment_likes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_room_moments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "venue_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "media_url" "text",
    "caption" "text",
    "moment_type" "text" DEFAULT 'text'::"text" NOT NULL,
    "like_count" integer DEFAULT 0 NOT NULL,
    "report_count" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '24:00:00'::interval) NOT NULL,
    CONSTRAINT "venue_room_moments_caption_check" CHECK (("char_length"("caption") <= 150)),
    CONSTRAINT "venue_room_moments_moment_type_check" CHECK (("moment_type" = ANY (ARRAY['photo'::"text", 'video'::"text", 'text'::"text"])))
);


ALTER TABLE "public"."venue_room_moments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_room_presence" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "venue_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_active_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_post_at" timestamp with time zone
);


ALTER TABLE "public"."venue_room_presence" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_room_reactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "message_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "reaction" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "venue_room_reactions_reaction_check" CHECK (("reaction" = ANY (ARRAY['beer'::"text", 'cocktail'::"text", 'fire'::"text", 'dance'::"text", 'music'::"text", 'whiskey'::"text", 'heart'::"text", 'laugh'::"text"])))
);


ALTER TABLE "public"."venue_room_reactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_room_vibe_polls" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "venue_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "poll_type" "text" NOT NULL,
    "vote_value" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "venue_room_vibe_polls_poll_type_check" CHECK (("poll_type" = ANY (ARRAY['music'::"text", 'energy'::"text", 'drink'::"text"])))
);


ALTER TABLE "public"."venue_room_vibe_polls" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_sessions" (
    "session_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "bar_id" "uuid" NOT NULL,
    "status" "text" NOT NULL,
    "checkin_method" "text" DEFAULT 'radar_auto'::"text" NOT NULL,
    "confidence" double precision,
    "start_at" timestamp with time zone NOT NULL,
    "end_at" timestamp with time zone,
    "last_event_at" timestamp with time zone NOT NULL,
    "dedupe_key" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "venue_sessions_status_check" CHECK (("status" = ANY (ARRAY['open'::"text", 'closed'::"text", 'invalid'::"text", 'closed_timeout'::"text"])))
);


ALTER TABLE "public"."venue_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_wall_photo_likes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "photo_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."venue_wall_photo_likes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."venue_wall_photos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "venue_id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "photo_url" "text" NOT NULL,
    "caption" "text",
    "like_count" integer DEFAULT 0 NOT NULL,
    "report_count" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "venue_wall_photos_caption_check" CHECK (("char_length"("caption") <= 200))
);


ALTER TABLE "public"."venue_wall_photos" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vibe_tags" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "icon_name" "text",
    "sort_order" integer DEFAULT 0,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."vibe_tags" OWNER TO "postgres";


COMMENT ON TABLE "public"."vibe_tags" IS 'Mood/activity tags for swarms and user profiles (Happy Hour, Dance Party, etc)';



COMMENT ON COLUMN "public"."vibe_tags"."name" IS 'Translatable vibe name (Happy Hour, Big Game, Chill Night, Dance Party, etc)';



COMMENT ON COLUMN "public"."vibe_tags"."icon_name" IS 'Lucide icon name for UI display';



CREATE TABLE IF NOT EXISTS "public"."vibe_votes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "venue_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "vibe" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "vibe_votes_vibe_check" CHECK (("vibe" = ANY (ARRAY['lit'::"text", 'chill'::"text", 'vibing'::"text", 'dead'::"text", 'dancing'::"text"])))
);


ALTER TABLE "public"."vibe_votes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."virtual_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "category" "text" NOT NULL,
    "emoji" "text" NOT NULL,
    "price" integer DEFAULT 0 NOT NULL,
    "is_premium" boolean DEFAULT false,
    "rarity" "text" DEFAULT 'common'::"text",
    "description" "text",
    "animation_url" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "virtual_items_category_check" CHECK (("category" = ANY (ARRAY['emoji'::"text", 'drink'::"text", 'gift'::"text", 'sticker'::"text", 'celebration'::"text", 'seasonal'::"text"]))),
    CONSTRAINT "virtual_items_rarity_check" CHECK (("rarity" = ANY (ARRAY['common'::"text", 'rare'::"text", 'epic'::"text", 'legendary'::"text"])))
);


ALTER TABLE "public"."virtual_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."visibility_settings" (
    "user_id" "uuid" NOT NULL,
    "is_invisible" boolean DEFAULT false,
    "show_on_map" boolean DEFAULT true,
    "show_in_venue" boolean DEFAULT true,
    "ghost_mode_until" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."visibility_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."waitlist" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "status" "text" DEFAULT 'pending'::"text",
    "referral_code" "text",
    "referred_by" "text",
    "notes" "text",
    "country_code" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "waitlist_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'confirmed'::"text", 'converted'::"text"])))
);


ALTER TABLE "public"."waitlist" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."weather_cache" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "latitude" numeric NOT NULL,
    "longitude" numeric NOT NULL,
    "temperature" integer NOT NULL,
    "weather_code" integer NOT NULL,
    "condition" "text" NOT NULL,
    "wind_speed" numeric NOT NULL,
    "humidity" integer NOT NULL,
    "feels_like" integer NOT NULL,
    "source" "text" DEFAULT 'open-meteo'::"text" NOT NULL,
    "cached_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone DEFAULT ("now"() + '01:00:00'::interval) NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."weather_cache" OWNER TO "postgres";


ALTER TABLE ONLY "public"."account_deletion_requests"
    ADD CONSTRAINT "account_deletion_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."activity_feed"
    ADD CONSTRAINT "activity_feed_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."badge_definitions"
    ADD CONSTRAINT "badge_definitions_pkey" PRIMARY KEY ("badge_key");



ALTER TABLE ONLY "public"."bars"
    ADD CONSTRAINT "bars_pkey" PRIMARY KEY ("bar_id");



ALTER TABLE ONLY "public"."blocks"
    ADD CONSTRAINT "blocks_blocker_user_id_blocked_user_id_key" UNIQUE ("blocker_user_id", "blocked_user_id");



ALTER TABLE ONLY "public"."blocks"
    ADD CONSTRAINT "blocks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."challenge_definitions"
    ADD CONSTRAINT "challenge_definitions_pkey" PRIMARY KEY ("challenge_key");



ALTER TABLE ONLY "public"."check_in_streaks"
    ADD CONSTRAINT "check_in_streaks_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."cheers"
    ADD CONSTRAINT "cheers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversation_participants"
    ADD CONSTRAINT "conversation_participants_conversation_id_user_id_key" UNIQUE ("conversation_id", "user_id");



ALTER TABLE ONLY "public"."conversation_participants"
    ADD CONSTRAINT "conversation_participants_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversation_starters"
    ADD CONSTRAINT "conversation_starters_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."drink_categories"
    ADD CONSTRAINT "drink_categories_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."drink_categories"
    ADD CONSTRAINT "drink_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."emergency_numbers"
    ADD CONSTRAINT "emergency_numbers_country_key" UNIQUE ("country");



ALTER TABLE ONLY "public"."emergency_numbers"
    ADD CONSTRAINT "emergency_numbers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."emoji_reactions"
    ADD CONSTRAINT "emoji_reactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."emoji_reactions"
    ADD CONSTRAINT "emoji_reactions_user_id_target_type_target_id_key" UNIQUE ("user_id", "target_type", "target_id");



ALTER TABLE ONLY "public"."event_log"
    ADD CONSTRAINT "event_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_user_id_friend_id_key" UNIQUE ("user_id", "friend_id");



ALTER TABLE ONLY "public"."geofence_events"
    ADD CONSTRAINT "geofence_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gifts"
    ADD CONSTRAINT "gifts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."google_api_logs"
    ADD CONSTRAINT "google_api_logs_pkey" PRIMARY KEY ("log_id");



ALTER TABLE ONLY "public"."google_place_cache"
    ADD CONSTRAINT "google_place_cache_bar_id_key" UNIQUE ("bar_id");



ALTER TABLE ONLY "public"."google_place_cache"
    ADD CONSTRAINT "google_place_cache_pkey" PRIMARY KEY ("cache_id");



ALTER TABLE ONLY "public"."group_split_items"
    ADD CONSTRAINT "group_split_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."group_split_items"
    ADD CONSTRAINT "group_split_items_split_id_user_id_key" UNIQUE ("split_id", "user_id");



ALTER TABLE ONLY "public"."group_splits"
    ADD CONSTRAINT "group_splits_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."interests"
    ADD CONSTRAINT "interests_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."interests"
    ADD CONSTRAINT "interests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."languages"
    ADD CONSTRAINT "languages_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."languages"
    ADD CONSTRAINT "languages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."location_events"
    ADD CONSTRAINT "location_events_pkey" PRIMARY KEY ("event_id");



ALTER TABLE ONLY "public"."location_pings"
    ADD CONSTRAINT "location_pings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."looking_for_options"
    ADD CONSTRAINT "looking_for_options_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."looking_for_options"
    ADD CONSTRAINT "looking_for_options_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."message_edits"
    ADD CONSTRAINT "message_edits_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mixed_drinks"
    ADD CONSTRAINT "mixed_drinks_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."mixed_drinks"
    ADD CONSTRAINT "mixed_drinks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."music_shares"
    ADD CONSTRAINT "music_shares_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."night_route_invites"
    ADD CONSTRAINT "night_route_invites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."night_route_invites"
    ADD CONSTRAINT "night_route_invites_route_id_user_id_key" UNIQUE ("route_id", "user_id");



ALTER TABLE ONLY "public"."night_routes"
    ADD CONSTRAINT "night_routes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."osm_import_logs"
    ADD CONSTRAINT "osm_import_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payment_transactions"
    ADD CONSTRAINT "payment_transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."public_music_shares"
    ADD CONSTRAINT "public_music_shares_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."push_subscriptions"
    ADD CONSTRAINT "push_subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."push_subscriptions"
    ADD CONSTRAINT "push_subscriptions_user_id_endpoint_key" UNIQUE ("user_id", "endpoint");



ALTER TABLE ONLY "public"."push_subscriptions"
    ADD CONSTRAINT "push_subscriptions_user_id_platform_key" UNIQUE ("user_id", "platform");



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_language_id_code_key" UNIQUE ("language_id", "code");



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."safe_arrivals"
    ADD CONSTRAINT "safe_arrivals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."safety_alerts"
    ADD CONSTRAINT "safety_alerts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."safety_friends"
    ADD CONSTRAINT "safety_friends_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_user_id_stripe_subscription_id_key" UNIQUE ("user_id", "stripe_subscription_id");



ALTER TABLE ONLY "public"."swarm_members"
    ADD CONSTRAINT "swarm_members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."swarm_members"
    ADD CONSTRAINT "swarm_members_swarm_id_user_id_key" UNIQUE ("swarm_id", "user_id");



ALTER TABLE ONLY "public"."swarms"
    ADD CONSTRAINT "swarms_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."translation_keys"
    ADD CONSTRAINT "translation_keys_key_key" UNIQUE ("key");



ALTER TABLE ONLY "public"."translation_keys"
    ADD CONSTRAINT "translation_keys_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."translations"
    ADD CONSTRAINT "translations_key_id_language_id_key" UNIQUE ("key_id", "language_id");



ALTER TABLE ONLY "public"."translations"
    ADD CONSTRAINT "translations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_activity_history"
    ADD CONSTRAINT "user_activity_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_user_id_badge_key_key" UNIQUE ("user_id", "badge_key");



ALTER TABLE ONLY "public"."user_blocks"
    ADD CONSTRAINT "user_blocks_blocker_id_blocked_id_key" UNIQUE ("blocker_id", "blocked_id");



ALTER TABLE ONLY "public"."user_blocks"
    ADD CONSTRAINT "user_blocks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_challenges"
    ADD CONSTRAINT "user_challenges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_challenges"
    ADD CONSTRAINT "user_challenges_user_id_challenge_key_started_at_key" UNIQUE ("user_id", "challenge_key", "started_at");



ALTER TABLE ONLY "public"."user_consents"
    ADD CONSTRAINT "user_consents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_gifts"
    ADD CONSTRAINT "user_gifts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_inventory"
    ADD CONSTRAINT "user_inventory_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_inventory"
    ADD CONSTRAINT "user_inventory_user_id_item_id_key" UNIQUE ("user_id", "item_id");



ALTER TABLE ONLY "public"."user_language_preferences"
    ADD CONSTRAINT "user_language_preferences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_language_preferences"
    ADD CONSTRAINT "user_language_preferences_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_stats"
    ADD CONSTRAINT "user_stats_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."user_venue_presence"
    ADD CONSTRAINT "user_venue_presence_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_username_key" UNIQUE ("username");



ALTER TABLE ONLY "public"."venue_buzz"
    ADD CONSTRAINT "venue_buzz_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_clusters"
    ADD CONSTRAINT "venue_clusters_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_photos"
    ADD CONSTRAINT "venue_photos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_ratings"
    ADD CONSTRAINT "venue_ratings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_ratings"
    ADD CONSTRAINT "venue_ratings_user_id_venue_id_key" UNIQUE ("user_id", "venue_id");



ALTER TABLE ONLY "public"."venue_reports"
    ADD CONSTRAINT "venue_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_reviews"
    ADD CONSTRAINT "venue_reviews_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_room_messages"
    ADD CONSTRAINT "venue_room_messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_room_moment_likes"
    ADD CONSTRAINT "venue_room_moment_likes_moment_id_user_id_key" UNIQUE ("moment_id", "user_id");



ALTER TABLE ONLY "public"."venue_room_moment_likes"
    ADD CONSTRAINT "venue_room_moment_likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_room_moments"
    ADD CONSTRAINT "venue_room_moments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_room_presence"
    ADD CONSTRAINT "venue_room_presence_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_room_presence"
    ADD CONSTRAINT "venue_room_presence_venue_id_user_id_key" UNIQUE ("venue_id", "user_id");



ALTER TABLE ONLY "public"."venue_room_reactions"
    ADD CONSTRAINT "venue_room_reactions_message_id_user_id_reaction_key" UNIQUE ("message_id", "user_id", "reaction");



ALTER TABLE ONLY "public"."venue_room_reactions"
    ADD CONSTRAINT "venue_room_reactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_room_vibe_polls"
    ADD CONSTRAINT "venue_room_vibe_polls_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_room_vibe_polls"
    ADD CONSTRAINT "venue_room_vibe_polls_venue_id_user_id_poll_type_key" UNIQUE ("venue_id", "user_id", "poll_type");



ALTER TABLE ONLY "public"."venue_sessions"
    ADD CONSTRAINT "venue_sessions_dedupe_key_key" UNIQUE ("dedupe_key");



ALTER TABLE ONLY "public"."venue_sessions"
    ADD CONSTRAINT "venue_sessions_pkey" PRIMARY KEY ("session_id");



ALTER TABLE ONLY "public"."venue_wall_photo_likes"
    ADD CONSTRAINT "venue_wall_photo_likes_photo_id_user_id_key" UNIQUE ("photo_id", "user_id");



ALTER TABLE ONLY "public"."venue_wall_photo_likes"
    ADD CONSTRAINT "venue_wall_photo_likes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venue_wall_photos"
    ADD CONSTRAINT "venue_wall_photos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."venues"
    ADD CONSTRAINT "venues_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vibe_tags"
    ADD CONSTRAINT "vibe_tags_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."vibe_tags"
    ADD CONSTRAINT "vibe_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vibe_votes"
    ADD CONSTRAINT "vibe_votes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."virtual_items"
    ADD CONSTRAINT "virtual_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."visibility_settings"
    ADD CONSTRAINT "visibility_settings_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."waitlist"
    ADD CONSTRAINT "waitlist_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."waitlist"
    ADD CONSTRAINT "waitlist_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."waitlist"
    ADD CONSTRAINT "waitlist_referral_code_key" UNIQUE ("referral_code");



ALTER TABLE ONLY "public"."weather_cache"
    ADD CONSTRAINT "weather_cache_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_activity_feed_actor" ON "public"."activity_feed" USING "btree" ("actor_user_id", "created_at" DESC);



CREATE INDEX "idx_activity_feed_created" ON "public"."activity_feed" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_activity_feed_venue_id" ON "public"."activity_feed" USING "btree" ("venue_id");



CREATE INDEX "idx_activity_history_user_created" ON "public"."user_activity_history" USING "btree" ("user_id", "created_at" DESC);



CREATE INDEX "idx_blocks_blocked_user_id" ON "public"."blocks" USING "btree" ("blocked_user_id");



CREATE INDEX "idx_cheers_recipient_id" ON "public"."cheers" USING "btree" ("recipient_id");



CREATE INDEX "idx_cheers_sender_id" ON "public"."cheers" USING "btree" ("sender_id");



CREATE INDEX "idx_conversation_participants_user_id" ON "public"."conversation_participants" USING "btree" ("user_id");



CREATE INDEX "idx_conversations_created_by" ON "public"."conversations" USING "btree" ("created_by");



CREATE INDEX "idx_conversations_swarm_id" ON "public"."conversations" USING "btree" ("swarm_id");



CREATE INDEX "idx_conversations_venue_id" ON "public"."conversations" USING "btree" ("venue_id");



CREATE INDEX "idx_event_log_user_id" ON "public"."event_log" USING "btree" ("user_id");



CREATE INDEX "idx_friendships_accepted" ON "public"."friendships" USING "btree" ("user_id", "friend_id") WHERE ("status" = 'accepted'::"text");



CREATE INDEX "idx_friendships_friend_id" ON "public"."friendships" USING "btree" ("friend_id");



CREATE INDEX "idx_friendships_status" ON "public"."friendships" USING "btree" ("status");



CREATE INDEX "idx_geofence_events_user_id" ON "public"."geofence_events" USING "btree" ("user_id");



CREATE INDEX "idx_geofence_events_venue_id" ON "public"."geofence_events" USING "btree" ("venue_id");



CREATE INDEX "idx_gifts_from_user_id" ON "public"."gifts" USING "btree" ("from_user_id");



CREATE INDEX "idx_gifts_to_user_id" ON "public"."gifts" USING "btree" ("to_user_id");



CREATE INDEX "idx_google_api_logs_bar_id" ON "public"."google_api_logs" USING "btree" ("bar_id");



CREATE INDEX "idx_group_split_items_user_id" ON "public"."group_split_items" USING "btree" ("user_id");



CREATE INDEX "idx_group_splits_swarm_id" ON "public"."group_splits" USING "btree" ("swarm_id");



CREATE INDEX "idx_languages_code" ON "public"."languages" USING "btree" ("code");



CREATE INDEX "idx_location_events_bar_id" ON "public"."location_events" USING "btree" ("bar_id");



CREATE INDEX "idx_location_events_venue_id" ON "public"."location_events" USING "btree" ("venue_id");



CREATE INDEX "idx_location_pings_user_id" ON "public"."location_pings" USING "btree" ("user_id");



CREATE INDEX "idx_message_edits_edited_by" ON "public"."message_edits" USING "btree" ("edited_by");



CREATE INDEX "idx_message_edits_message_id" ON "public"."message_edits" USING "btree" ("message_id");



CREATE INDEX "idx_messages_dm_user_b" ON "public"."messages" USING "btree" ("dm_user_b");



CREATE INDEX "idx_messages_sender_user_id" ON "public"."messages" USING "btree" ("sender_user_id");



CREATE INDEX "idx_messages_swarm_id" ON "public"."messages" USING "btree" ("swarm_id");



CREATE INDEX "idx_messages_unread" ON "public"."messages" USING "btree" ("dm_user_a", "dm_user_b", "read_at") WHERE (("read_at" IS NULL) AND ("conversation_type" = 'dm'::"text"));



CREATE INDEX "idx_music_shares_recipient_id" ON "public"."music_shares" USING "btree" ("recipient_id");



CREATE INDEX "idx_music_shares_sender_id" ON "public"."music_shares" USING "btree" ("sender_id");



CREATE INDEX "idx_night_route_invites_user_id" ON "public"."night_route_invites" USING "btree" ("user_id");



CREATE INDEX "idx_night_routes_creator_id" ON "public"."night_routes" USING "btree" ("creator_id");



CREATE INDEX "idx_notifications_unread" ON "public"."notifications" USING "btree" ("recipient_user_id", "is_read") WHERE ("is_read" = false);



CREATE INDEX "idx_payment_transactions_from_user_id" ON "public"."payment_transactions" USING "btree" ("from_user_id");



CREATE INDEX "idx_payment_transactions_to_user_id" ON "public"."payment_transactions" USING "btree" ("to_user_id");



CREATE INDEX "idx_presence_status" ON "public"."user_venue_presence" USING "btree" ("status");



CREATE INDEX "idx_presence_visible" ON "public"."user_venue_presence" USING "btree" ("venue_id", "is_visible_in_venue", "status") WHERE (("is_visible_in_venue" = true) AND ("status" = 'IN_VENUE'::"text"));



CREATE INDEX "idx_safe_arrivals_user" ON "public"."safe_arrivals" USING "btree" ("user_id", "checked_in_at" DESC);



CREATE INDEX "idx_safety_alerts_user_id" ON "public"."safety_alerts" USING "btree" ("user_id");



CREATE INDEX "idx_safety_friends_user_id" ON "public"."safety_friends" USING "btree" ("user_id");



CREATE INDEX "idx_swarm_members_user_id" ON "public"."swarm_members" USING "btree" ("user_id");



CREATE INDEX "idx_swarms_host_user_id" ON "public"."swarms" USING "btree" ("host_user_id");



CREATE INDEX "idx_swarms_status" ON "public"."swarms" USING "btree" ("status");



CREATE INDEX "idx_swarms_venue_id" ON "public"."swarms" USING "btree" ("venue_id");



CREATE INDEX "idx_translations_language_id" ON "public"."translations" USING "btree" ("language_id");



CREATE INDEX "idx_user_blocks_blocked_id" ON "public"."user_blocks" USING "btree" ("blocked_id");



CREATE INDEX "idx_user_gifts_from_user_id" ON "public"."user_gifts" USING "btree" ("from_user_id");



CREATE INDEX "idx_user_gifts_to_user_id" ON "public"."user_gifts" USING "btree" ("to_user_id");



CREATE INDEX "idx_user_inventory_item_id" ON "public"."user_inventory" USING "btree" ("item_id");



CREATE INDEX "idx_user_reports_reported_message_id" ON "public"."user_reports" USING "btree" ("reported_message_id");



CREATE INDEX "idx_user_reports_reported_venue_id" ON "public"."user_reports" USING "btree" ("reported_venue_id");



CREATE INDEX "idx_user_reports_reviewed_by" ON "public"."user_reports" USING "btree" ("reviewed_by");



CREATE INDEX "idx_user_venue_presence_entered" ON "public"."user_venue_presence" USING "btree" ("user_id", "entered_at" DESC);



CREATE INDEX "idx_venue_buzz_user_id" ON "public"."venue_buzz" USING "btree" ("user_id");



CREATE INDEX "idx_venue_buzz_venue_id" ON "public"."venue_buzz" USING "btree" ("venue_id");



CREATE INDEX "idx_venue_photos_created_by_user_id" ON "public"."venue_photos" USING "btree" ("created_by_user_id");



CREATE INDEX "idx_venue_reports_reporter_id" ON "public"."venue_reports" USING "btree" ("reporter_id");



CREATE INDEX "idx_venue_reports_resolved_by" ON "public"."venue_reports" USING "btree" ("resolved_by");



CREATE INDEX "idx_venue_reports_venue_id" ON "public"."venue_reports" USING "btree" ("venue_id");



CREATE INDEX "idx_venue_reviews_created_by_user_id" ON "public"."venue_reviews" USING "btree" ("created_by_user_id");



CREATE INDEX "idx_venue_room_messages_user_id" ON "public"."venue_room_messages" USING "btree" ("user_id");



CREATE INDEX "idx_venue_room_messages_venue_id" ON "public"."venue_room_messages" USING "btree" ("venue_id");



CREATE INDEX "idx_venue_room_moment_likes_user_id" ON "public"."venue_room_moment_likes" USING "btree" ("user_id");



CREATE INDEX "idx_venue_room_moments_user_id" ON "public"."venue_room_moments" USING "btree" ("user_id");



CREATE INDEX "idx_venue_room_moments_venue_id" ON "public"."venue_room_moments" USING "btree" ("venue_id");



CREATE INDEX "idx_venue_room_presence_user_id" ON "public"."venue_room_presence" USING "btree" ("user_id");



CREATE INDEX "idx_venue_room_reactions_user_id" ON "public"."venue_room_reactions" USING "btree" ("user_id");



CREATE INDEX "idx_venue_room_vibe_polls_user_id" ON "public"."venue_room_vibe_polls" USING "btree" ("user_id");



CREATE INDEX "idx_venue_sessions_bar_id" ON "public"."venue_sessions" USING "btree" ("bar_id");



CREATE INDEX "idx_venue_wall_photo_likes_user" ON "public"."venue_wall_photo_likes" USING "btree" ("user_id", "photo_id");



CREATE INDEX "idx_venue_wall_photos_user_id" ON "public"."venue_wall_photos" USING "btree" ("user_id");



CREATE INDEX "idx_venues_active" ON "public"."venues" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_venues_is_active" ON "public"."venues" USING "btree" ("is_active");



CREATE INDEX "idx_vibe_votes_user_id" ON "public"."vibe_votes" USING "btree" ("user_id");



CREATE INDEX "idx_vibe_votes_venue_id" ON "public"."vibe_votes" USING "btree" ("venue_id");



CREATE INDEX "venues_country_idx" ON "public"."venues" USING "btree" ("country");



CREATE INDEX "venues_lat_lng_idx" ON "public"."venues" USING "btree" ("lat", "lng");



CREATE UNIQUE INDEX "venues_osm_id_unique" ON "public"."venues" USING "btree" ("osm_id") WHERE ("osm_id" IS NOT NULL);



CREATE INDEX "venues_state_idx" ON "public"."venues" USING "btree" ("state");



CREATE OR REPLACE TRIGGER "add_creator_as_owner_trigger" AFTER INSERT ON "public"."conversations" FOR EACH ROW EXECUTE FUNCTION "public"."add_conversation_creator_as_owner"();



CREATE OR REPLACE TRIGGER "auto_activate_venue_by_region_trigger" BEFORE INSERT ON "public"."venues" FOR EACH ROW EXECUTE FUNCTION "public"."auto_activate_venue_by_region"();



CREATE OR REPLACE TRIGGER "bars_updated_at" BEFORE UPDATE ON "public"."bars" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "create_reciprocal_friendship_trigger" BEFORE UPDATE ON "public"."friendships" FOR EACH ROW EXECUTE FUNCTION "public"."create_reciprocal_friendship"();



CREATE OR REPLACE TRIGGER "delete_reciprocal_friendship_trigger" AFTER DELETE ON "public"."friendships" FOR EACH ROW EXECUTE FUNCTION "public"."delete_reciprocal_friendship"();



CREATE OR REPLACE TRIGGER "on_message_created" AFTER INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."create_message_notification"();



CREATE OR REPLACE TRIGGER "remove_friendships_on_block_trigger" AFTER INSERT ON "public"."user_blocks" FOR EACH ROW EXECUTE FUNCTION "public"."remove_friendships_on_block"();



CREATE OR REPLACE TRIGGER "set_conversations_updated_at" BEFORE UPDATE ON "public"."conversations" FOR EACH ROW EXECUTE FUNCTION "public"."update_conversations_updated_at"();



CREATE OR REPLACE TRIGGER "set_friendships_updated_at" BEFORE UPDATE ON "public"."friendships" FOR EACH ROW EXECUTE FUNCTION "public"."update_friendships_updated_at"();



CREATE OR REPLACE TRIGGER "set_venue_report_resolved_at_trigger" BEFORE UPDATE ON "public"."venue_reports" FOR EACH ROW EXECUTE FUNCTION "public"."set_venue_report_resolved_at"();



CREATE OR REPLACE TRIGGER "swarm_members_update_size_trigger" AFTER INSERT OR DELETE OR UPDATE ON "public"."swarm_members" FOR EACH ROW EXECUTE FUNCTION "public"."update_swarm_current_size"();



CREATE OR REPLACE TRIGGER "swarms_updated_at_trigger" BEFORE UPDATE ON "public"."swarms" FOR EACH ROW EXECUTE FUNCTION "public"."update_swarms_updated_at"();



CREATE OR REPLACE TRIGGER "update_clusters_updated_at" BEFORE UPDATE ON "public"."venue_clusters" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_presence_updated_at" BEFORE UPDATE ON "public"."user_venue_presence" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_users_updated_at" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_venues_updated_at" BEFORE UPDATE ON "public"."venues" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "venue_sessions_updated_at" BEFORE UPDATE ON "public"."venue_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "venues_updated_at_trigger" BEFORE UPDATE ON "public"."venues" FOR EACH ROW EXECUTE FUNCTION "public"."update_venues_updated_at"();



ALTER TABLE ONLY "public"."account_deletion_requests"
    ADD CONSTRAINT "account_deletion_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."activity_feed"
    ADD CONSTRAINT "activity_feed_actor_user_id_fkey" FOREIGN KEY ("actor_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."activity_feed"
    ADD CONSTRAINT "activity_feed_swarm_id_fkey" FOREIGN KEY ("swarm_id") REFERENCES "public"."swarms"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."activity_feed"
    ADD CONSTRAINT "activity_feed_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."blocks"
    ADD CONSTRAINT "blocks_blocked_user_id_fkey" FOREIGN KEY ("blocked_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."blocks"
    ADD CONSTRAINT "blocks_blocker_user_id_fkey" FOREIGN KEY ("blocker_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."check_in_streaks"
    ADD CONSTRAINT "check_in_streaks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cheers"
    ADD CONSTRAINT "cheers_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cheers"
    ADD CONSTRAINT "cheers_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cheers"
    ADD CONSTRAINT "cheers_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."conversation_participants"
    ADD CONSTRAINT "conversation_participants_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversation_participants"
    ADD CONSTRAINT "conversation_participants_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_swarm_id_fkey" FOREIGN KEY ("swarm_id") REFERENCES "public"."swarms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."emoji_reactions"
    ADD CONSTRAINT "emoji_reactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."event_log"
    ADD CONSTRAINT "event_log_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_friend_id_fkey" FOREIGN KEY ("friend_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_friend_id_public_users_fkey" FOREIGN KEY ("friend_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."friendships"
    ADD CONSTRAINT "friendships_user_id_public_users_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."geofence_events"
    ADD CONSTRAINT "geofence_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."geofence_events"
    ADD CONSTRAINT "geofence_events_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."gifts"
    ADD CONSTRAINT "gifts_from_user_id_fkey" FOREIGN KEY ("from_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."gifts"
    ADD CONSTRAINT "gifts_to_user_id_fkey" FOREIGN KEY ("to_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."gifts"
    ADD CONSTRAINT "gifts_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."google_api_logs"
    ADD CONSTRAINT "google_api_logs_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("bar_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."google_place_cache"
    ADD CONSTRAINT "google_place_cache_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("bar_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."group_split_items"
    ADD CONSTRAINT "group_split_items_split_id_fkey" FOREIGN KEY ("split_id") REFERENCES "public"."group_splits"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."group_split_items"
    ADD CONSTRAINT "group_split_items_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."group_splits"
    ADD CONSTRAINT "group_splits_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."group_splits"
    ADD CONSTRAINT "group_splits_swarm_id_fkey" FOREIGN KEY ("swarm_id") REFERENCES "public"."swarms"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."location_events"
    ADD CONSTRAINT "location_events_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("bar_id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."location_events"
    ADD CONSTRAINT "location_events_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."location_pings"
    ADD CONSTRAINT "location_pings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."message_edits"
    ADD CONSTRAINT "message_edits_edited_by_fkey" FOREIGN KEY ("edited_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."message_edits"
    ADD CONSTRAINT "message_edits_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "public"."messages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_dm_user_a_fkey" FOREIGN KEY ("dm_user_a") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_dm_user_b_fkey" FOREIGN KEY ("dm_user_b") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_sender_user_id_fkey" FOREIGN KEY ("sender_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_swarm_id_fkey" FOREIGN KEY ("swarm_id") REFERENCES "public"."swarms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mixed_drinks"
    ADD CONSTRAINT "mixed_drinks_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "public"."drink_categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."music_shares"
    ADD CONSTRAINT "music_shares_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."music_shares"
    ADD CONSTRAINT "music_shares_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."music_shares"
    ADD CONSTRAINT "music_shares_swarm_id_fkey" FOREIGN KEY ("swarm_id") REFERENCES "public"."swarms"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."music_shares"
    ADD CONSTRAINT "music_shares_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."night_route_invites"
    ADD CONSTRAINT "night_route_invites_route_id_fkey" FOREIGN KEY ("route_id") REFERENCES "public"."night_routes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."night_route_invites"
    ADD CONSTRAINT "night_route_invites_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."night_routes"
    ADD CONSTRAINT "night_routes_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_actor_user_id_fkey" FOREIGN KEY ("actor_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_recipient_user_id_fkey" FOREIGN KEY ("recipient_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_swarm_id_fkey" FOREIGN KEY ("swarm_id") REFERENCES "public"."swarms"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."payment_transactions"
    ADD CONSTRAINT "payment_transactions_from_user_id_fkey" FOREIGN KEY ("from_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payment_transactions"
    ADD CONSTRAINT "payment_transactions_swarm_id_fkey" FOREIGN KEY ("swarm_id") REFERENCES "public"."swarms"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."payment_transactions"
    ADD CONSTRAINT "payment_transactions_to_user_id_fkey" FOREIGN KEY ("to_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."public_music_shares"
    ADD CONSTRAINT "public_music_shares_shared_by_user_id_fkey" FOREIGN KEY ("shared_by_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."push_subscriptions"
    ADD CONSTRAINT "push_subscriptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."regions"
    ADD CONSTRAINT "regions_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "public"."languages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_reported_user_id_fkey" FOREIGN KEY ("reported_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_reporter_user_id_fkey" FOREIGN KEY ("reporter_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."safe_arrivals"
    ADD CONSTRAINT "safe_arrivals_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."safety_alerts"
    ADD CONSTRAINT "safety_alerts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."safety_friends"
    ADD CONSTRAINT "safety_friends_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."swarm_members"
    ADD CONSTRAINT "swarm_members_swarm_id_fkey" FOREIGN KEY ("swarm_id") REFERENCES "public"."swarms"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."swarm_members"
    ADD CONSTRAINT "swarm_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."swarms"
    ADD CONSTRAINT "swarms_host_user_id_fkey" FOREIGN KEY ("host_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."swarms"
    ADD CONSTRAINT "swarms_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."translations"
    ADD CONSTRAINT "translations_key_id_fkey" FOREIGN KEY ("key_id") REFERENCES "public"."translation_keys"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."translations"
    ADD CONSTRAINT "translations_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "public"."languages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_activity_history"
    ADD CONSTRAINT "user_activity_history_related_user_id_fkey" FOREIGN KEY ("related_user_id") REFERENCES "public"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_activity_history"
    ADD CONSTRAINT "user_activity_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_activity_history"
    ADD CONSTRAINT "user_activity_history_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_blocks"
    ADD CONSTRAINT "user_blocks_blocked_id_fkey" FOREIGN KEY ("blocked_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_blocks"
    ADD CONSTRAINT "user_blocks_blocked_id_public_users_fkey" FOREIGN KEY ("blocked_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_blocks"
    ADD CONSTRAINT "user_blocks_blocker_id_fkey" FOREIGN KEY ("blocker_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_blocks"
    ADD CONSTRAINT "user_blocks_blocker_id_public_users_fkey" FOREIGN KEY ("blocker_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_challenges"
    ADD CONSTRAINT "user_challenges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_consents"
    ADD CONSTRAINT "user_consents_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_gifts"
    ADD CONSTRAINT "user_gifts_from_user_id_fkey" FOREIGN KEY ("from_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_gifts"
    ADD CONSTRAINT "user_gifts_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "public"."virtual_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_gifts"
    ADD CONSTRAINT "user_gifts_to_user_id_fkey" FOREIGN KEY ("to_user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_inventory"
    ADD CONSTRAINT "user_inventory_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "public"."virtual_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_inventory"
    ADD CONSTRAINT "user_inventory_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_language_preferences"
    ADD CONSTRAINT "user_language_preferences_language_id_fkey" FOREIGN KEY ("language_id") REFERENCES "public"."languages"("id");



ALTER TABLE ONLY "public"."user_language_preferences"
    ADD CONSTRAINT "user_language_preferences_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "public"."regions"("id");



ALTER TABLE ONLY "public"."user_language_preferences"
    ADD CONSTRAINT "user_language_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_reported_message_id_fkey" FOREIGN KEY ("reported_message_id") REFERENCES "public"."messages"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_reported_user_id_fkey" FOREIGN KEY ("reported_user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_reported_venue_id_fkey" FOREIGN KEY ("reported_venue_id") REFERENCES "public"."venues"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_reports"
    ADD CONSTRAINT "user_reports_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_stats"
    ADD CONSTRAINT "user_stats_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_venue_presence"
    ADD CONSTRAINT "user_venue_presence_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_venue_presence"
    ADD CONSTRAINT "user_venue_presence_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_buzz"
    ADD CONSTRAINT "venue_buzz_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."venue_buzz"
    ADD CONSTRAINT "venue_buzz_user_id_public_users_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_buzz"
    ADD CONSTRAINT "venue_buzz_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_photos"
    ADD CONSTRAINT "venue_photos_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."venue_ratings"
    ADD CONSTRAINT "venue_ratings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_reports"
    ADD CONSTRAINT "venue_reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."venue_reports"
    ADD CONSTRAINT "venue_reports_resolved_by_fkey" FOREIGN KEY ("resolved_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."venue_reports"
    ADD CONSTRAINT "venue_reports_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_reviews"
    ADD CONSTRAINT "venue_reviews_created_by_user_id_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."venue_room_messages"
    ADD CONSTRAINT "venue_room_messages_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_room_messages"
    ADD CONSTRAINT "venue_room_messages_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."bars"("bar_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_room_moment_likes"
    ADD CONSTRAINT "venue_room_moment_likes_moment_id_fkey" FOREIGN KEY ("moment_id") REFERENCES "public"."venue_room_moments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_room_moment_likes"
    ADD CONSTRAINT "venue_room_moment_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_room_moments"
    ADD CONSTRAINT "venue_room_moments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_room_moments"
    ADD CONSTRAINT "venue_room_moments_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."bars"("bar_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_room_presence"
    ADD CONSTRAINT "venue_room_presence_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_room_presence"
    ADD CONSTRAINT "venue_room_presence_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."bars"("bar_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_room_reactions"
    ADD CONSTRAINT "venue_room_reactions_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "public"."venue_room_messages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_room_reactions"
    ADD CONSTRAINT "venue_room_reactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_room_vibe_polls"
    ADD CONSTRAINT "venue_room_vibe_polls_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_room_vibe_polls"
    ADD CONSTRAINT "venue_room_vibe_polls_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."bars"("bar_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_sessions"
    ADD CONSTRAINT "venue_sessions_bar_id_fkey" FOREIGN KEY ("bar_id") REFERENCES "public"."bars"("bar_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_wall_photo_likes"
    ADD CONSTRAINT "venue_wall_photo_likes_photo_id_fkey" FOREIGN KEY ("photo_id") REFERENCES "public"."venue_wall_photos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_wall_photo_likes"
    ADD CONSTRAINT "venue_wall_photo_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_wall_photos"
    ADD CONSTRAINT "venue_wall_photos_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."venue_wall_photos"
    ADD CONSTRAINT "venue_wall_photos_user_id_public_users_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vibe_votes"
    ADD CONSTRAINT "vibe_votes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."vibe_votes"
    ADD CONSTRAINT "vibe_votes_venue_id_fkey" FOREIGN KEY ("venue_id") REFERENCES "public"."venues"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."visibility_settings"
    ADD CONSTRAINT "visibility_settings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Actors can insert own notifications" ON "public"."notifications" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "actor_user_id"));



CREATE POLICY "Admins can insert emergency numbers" ON "public"."emergency_numbers" FOR INSERT TO "authenticated" WITH CHECK (false);



CREATE POLICY "Admins can remove participants" ON "public"."conversation_participants" FOR DELETE TO "authenticated" USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."conversation_participants" "cp2"
  WHERE (("cp2"."conversation_id" = "conversation_participants"."conversation_id") AND ("cp2"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("cp2"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])))))));



CREATE POLICY "Admins can update conversations" ON "public"."conversations" FOR UPDATE TO "authenticated" USING ((("created_by" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."conversation_participants" "cp"
  WHERE (("cp"."conversation_id" = "conversations"."id") AND ("cp"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("cp"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"]))))))) WITH CHECK ((("created_by" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."conversation_participants" "cp"
  WHERE (("cp"."conversation_id" = "conversations"."id") AND ("cp"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("cp"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])))))));



CREATE POLICY "Admins can update emergency numbers" ON "public"."emergency_numbers" FOR UPDATE TO "authenticated" USING (false) WITH CHECK (false);



CREATE POLICY "Anyone authenticated can read moments" ON "public"."venue_room_moments" FOR SELECT TO "authenticated" USING ((("report_count" < 3) AND ("expires_at" > "now"())));



CREATE POLICY "Anyone authenticated can read reactions" ON "public"."venue_room_reactions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Anyone authenticated can read room messages" ON "public"."venue_room_messages" FOR SELECT TO "authenticated" USING ((("report_count" < 3) AND ("expires_at" > "now"())));



CREATE POLICY "Anyone authenticated can read room presence" ON "public"."venue_room_presence" FOR SELECT TO "authenticated" USING (("last_active_at" > ("now"() - '00:30:00'::interval)));



CREATE POLICY "Anyone authenticated can read vibe polls" ON "public"."venue_room_vibe_polls" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Anyone can read badge definitions" ON "public"."badge_definitions" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Anyone can read badges" ON "public"."user_badges" FOR SELECT USING (true);



CREATE POLICY "Anyone can read challenge definitions" ON "public"."challenge_definitions" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Anyone can read emergency numbers" ON "public"."emergency_numbers" FOR SELECT USING (true);



CREATE POLICY "Anyone can read user stats" ON "public"."user_stats" FOR SELECT USING (true);



CREATE POLICY "Anyone can view public music shares" ON "public"."public_music_shares" FOR SELECT USING (true);



CREATE POLICY "Anyone can view venue photos" ON "public"."venue_photos" FOR SELECT USING (true);



CREATE POLICY "Anyone can view venue reviews" ON "public"."venue_reviews" FOR SELECT USING (true);



CREATE POLICY "Anyone can view venues" ON "public"."venues" FOR SELECT TO "authenticated", "anon" USING (true);



CREATE POLICY "Authenticated users can add reactions" ON "public"."venue_room_reactions" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Authenticated users can create music shares" ON "public"."public_music_shares" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "shared_by_user_id"));



CREATE POLICY "Authenticated users can create reviews" ON "public"."venue_reviews" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "created_by_user_id"));



CREATE POLICY "Authenticated users can join room" ON "public"."venue_room_presence" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Authenticated users can like moments" ON "public"."venue_room_moment_likes" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Authenticated users can post moments" ON "public"."venue_room_moments" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Authenticated users can post room messages" ON "public"."venue_room_messages" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Authenticated users can read non-reported buzz" ON "public"."venue_buzz" FOR SELECT TO "authenticated" USING (((( SELECT "auth"."role"() AS "role") = 'authenticated'::"text") AND ("report_count" < 3)));



CREATE POLICY "Authenticated users can read vibe votes" ON "public"."vibe_votes" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Authenticated users can upload photos" ON "public"."venue_photos" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "created_by_user_id"));



CREATE POLICY "Authenticated users can view moment likes" ON "public"."venue_room_moment_likes" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Authenticated users can view swarm members" ON "public"."swarm_members" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Authenticated users can view swarms" ON "public"."swarms" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Authenticated users can view their own email" ON "public"."waitlist" FOR SELECT TO "authenticated" USING ((("email" = CURRENT_USER) OR (("auth"."jwt"() ->> 'email'::"text") = "email")));



CREATE POLICY "Authenticated users can view wall photo likes" ON "public"."venue_wall_photo_likes" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Authenticated users can view wall photos" ON "public"."venue_wall_photos" FOR SELECT TO "authenticated" USING (("report_count" < 5));



CREATE POLICY "Authenticated users can vote" ON "public"."venue_room_vibe_polls" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Conversation starters are publicly readable" ON "public"."conversation_starters" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Creators can add split items" ON "public"."group_split_items" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."group_splits" "gs"
  WHERE (("gs"."id" = "group_split_items"."split_id") AND ("gs"."creator_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Creators can delete own routes" ON "public"."night_routes" FOR DELETE TO "authenticated" USING (("creator_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Creators can update own routes" ON "public"."night_routes" FOR UPDATE TO "authenticated" USING (("creator_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("creator_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Creators can update splits" ON "public"."group_splits" FOR UPDATE TO "authenticated" USING (("creator_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("creator_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Drink categories are publicly readable" ON "public"."drink_categories" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Hosts can update swarms" ON "public"."swarms" FOR UPDATE TO "authenticated" USING (("host_user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("host_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Interests are publicly readable" ON "public"."interests" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Invited users can update invite status" ON "public"."night_route_invites" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Languages are publicly readable" ON "public"."languages" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Looking for options are publicly readable" ON "public"."looking_for_options" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Mixed drinks are publicly readable" ON "public"."mixed_drinks" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Owners can delete conversations" ON "public"."conversations" FOR DELETE TO "authenticated" USING (("created_by" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Public can check if email exists" ON "public"."waitlist" FOR SELECT TO "anon" USING (false);



CREATE POLICY "Public can view bars" ON "public"."bars" FOR SELECT USING (true);



CREATE POLICY "Public can view place cache" ON "public"."google_place_cache" FOR SELECT USING (true);



CREATE POLICY "Recipients can update gift status" ON "public"."user_gifts" FOR UPDATE TO "authenticated" USING (("to_user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("to_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Recipients can update music status" ON "public"."music_shares" FOR UPDATE TO "authenticated" USING (("recipient_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("recipient_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Recipients can update their gifts" ON "public"."gifts" FOR UPDATE TO "authenticated" USING (("to_user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("to_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Regions are publicly readable" ON "public"."regions" FOR SELECT USING (true);



CREATE POLICY "Route creators can send invites" ON "public"."night_route_invites" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."night_routes" "nr"
  WHERE (("nr"."id" = "night_route_invites"."route_id") AND ("nr"."creator_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Service role can delete expired weather data" ON "public"."weather_cache" FOR DELETE TO "service_role" USING (true);



CREATE POLICY "Service role can insert notifications" ON "public"."notifications" FOR INSERT TO "service_role" WITH CHECK (true);



CREATE POLICY "Service role can insert weather data" ON "public"."weather_cache" FOR INSERT TO "service_role" WITH CHECK (true);



CREATE POLICY "Service role can manage clusters" ON "public"."venue_clusters" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Service role can manage import logs" ON "public"."osm_import_logs" USING (false) WITH CHECK (false);



CREATE POLICY "Service role can manage venues" ON "public"."venues" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Service role can update location_events" ON "public"."location_events" FOR UPDATE TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Service role has full access to API logs" ON "public"."google_api_logs" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Service role has full access to bars" ON "public"."bars" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Service role has full access to cache" ON "public"."google_place_cache" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Service role has full access to location_events" ON "public"."location_events" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Service role has full access to venue_sessions" ON "public"."venue_sessions" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Split participants can view items" ON "public"."group_split_items" FOR SELECT TO "authenticated" USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."group_splits" "gs"
  WHERE (("gs"."id" = "group_split_items"."split_id") AND ("gs"."creator_id" = ( SELECT "auth"."uid"() AS "uid")))))));



CREATE POLICY "Split participants can view splits" ON "public"."group_splits" FOR SELECT TO "authenticated" USING ((("creator_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."group_split_items" "gsi"
  WHERE (("gsi"."split_id" = "group_splits"."id") AND ("gsi"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))));



CREATE POLICY "System can update processed_at" ON "public"."geofence_events" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Translation keys are publicly readable" ON "public"."translation_keys" FOR SELECT USING (true);



CREATE POLICY "Translations are publicly readable" ON "public"."translations" FOR SELECT USING (true);



CREATE POLICY "Users can add conversation participants" ON "public"."conversation_participants" FOR INSERT TO "authenticated" WITH CHECK ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."conversation_participants" "cp2"
  WHERE (("cp2"."conversation_id" = "conversation_participants"."conversation_id") AND ("cp2"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("cp2"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"])))))));



CREATE POLICY "Users can add their own reactions" ON "public"."emoji_reactions" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can block others" ON "public"."user_blocks" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "blocker_id"));



CREATE POLICY "Users can cast vibe votes" ON "public"."vibe_votes" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can create blocks" ON "public"."blocks" FOR INSERT TO "authenticated" WITH CHECK (("blocker_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can create cheers" ON "public"."cheers" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "sender_id"));



CREATE POLICY "Users can create conversations" ON "public"."conversations" FOR INSERT TO "authenticated" WITH CHECK (("created_by" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can create deletion requests" ON "public"."account_deletion_requests" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can create gifts" ON "public"."gifts" FOR INSERT TO "authenticated" WITH CHECK (("from_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can create gifts" ON "public"."user_gifts" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "from_user_id"));



CREATE POLICY "Users can create location events" ON "public"."location_events" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can create location pings" ON "public"."location_pings" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can create music shares" ON "public"."music_shares" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "sender_id"));



CREATE POLICY "Users can create night routes" ON "public"."night_routes" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "creator_id"));



CREATE POLICY "Users can create own activity history" ON "public"."user_activity_history" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can create own safe arrivals" ON "public"."safe_arrivals" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can create own subscriptions" ON "public"."subscriptions" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can create reports" ON "public"."reports" FOR INSERT TO "authenticated" WITH CHECK (("reporter_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can create reports" ON "public"."user_reports" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "reporter_id"));



CREATE POLICY "Users can create reports" ON "public"."venue_reports" FOR INSERT TO "authenticated" WITH CHECK (("reporter_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can create splits" ON "public"."group_splits" FOR INSERT TO "authenticated" WITH CHECK (("creator_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can create swarms" ON "public"."swarms" FOR INSERT TO "authenticated" WITH CHECK (("host_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can create transactions" ON "public"."payment_transactions" FOR INSERT TO "authenticated" WITH CHECK (("from_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can create venue ratings" ON "public"."venue_ratings" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can create venue sessions" ON "public"."venue_sessions" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can delete own activity history" ON "public"."user_activity_history" FOR DELETE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can delete own blocks" ON "public"."blocks" FOR DELETE TO "authenticated" USING (("blocker_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can delete own blocks" ON "public"."user_blocks" FOR DELETE TO "authenticated" USING (("blocker_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can delete own buzz" ON "public"."venue_buzz" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can delete own friendships" ON "public"."friendships" FOR DELETE TO "authenticated" USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR ("friend_id" = ( SELECT "auth"."uid"() AS "uid"))));



CREATE POLICY "Users can delete own geofence events" ON "public"."geofence_events" FOR DELETE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can delete own location pings" ON "public"."location_pings" FOR DELETE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can delete own moments" ON "public"."venue_room_moments" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can delete own music shares" ON "public"."public_music_shares" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "shared_by_user_id"));



CREATE POLICY "Users can delete own pending reports" ON "public"."venue_reports" FOR DELETE TO "authenticated" USING ((("reporter_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("status" = 'pending'::"text")));



CREATE POLICY "Users can delete own photos" ON "public"."venue_photos" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "created_by_user_id"));



CREATE POLICY "Users can delete own ratings" ON "public"."venue_ratings" FOR DELETE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can delete own reactions" ON "public"."emoji_reactions" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can delete own room messages" ON "public"."venue_room_messages" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can delete own safety friends" ON "public"."safety_friends" FOR DELETE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can delete own wall photo likes" ON "public"."venue_wall_photo_likes" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can delete own wall photos" ON "public"."venue_wall_photos" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can delete their own reviews" ON "public"."venue_reviews" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "created_by_user_id"));



CREATE POLICY "Users can earn badges" ON "public"."user_badges" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can insert own challenges" ON "public"."user_challenges" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can insert own consents" ON "public"."user_consents" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own event logs" ON "public"."event_log" FOR INSERT TO "authenticated" WITH CHECK (((( SELECT "auth"."uid"() AS "uid") = "user_id") OR ("user_id" IS NULL)));



CREATE POLICY "Users can insert own geofence events" ON "public"."geofence_events" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can insert own language preferences" ON "public"."user_language_preferences" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can insert own messages" ON "public"."messages" FOR INSERT TO "authenticated" WITH CHECK (("sender_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can insert own presence" ON "public"."user_venue_presence" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can insert own profile" ON "public"."users" FOR INSERT TO "authenticated" WITH CHECK (("id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can insert own safety alerts" ON "public"."safety_alerts" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can insert own safety friends" ON "public"."safety_friends" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can insert own stats" ON "public"."user_stats" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can insert own streak" ON "public"."check_in_streaks" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can insert own visibility settings" ON "public"."visibility_settings" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own wall photo likes" ON "public"."venue_wall_photo_likes" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can insert own wall photos" ON "public"."venue_wall_photos" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can insert their own activity" ON "public"."activity_feed" FOR INSERT TO "authenticated" WITH CHECK (("actor_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can join swarms" ON "public"."swarm_members" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can join waitlist" ON "public"."waitlist" FOR INSERT TO "authenticated", "anon" WITH CHECK ((("email" IS NOT NULL) AND ("email" ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$'::"text")));



CREATE POLICY "Users can leave room" ON "public"."venue_room_presence" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can leave swarms" ON "public"."swarm_members" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can manage own inventory" ON "public"."user_inventory" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can manage own push subscriptions" ON "public"."push_subscriptions" TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can mark own notifications as read" ON "public"."notifications" FOR UPDATE TO "authenticated" USING (("recipient_user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("recipient_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can post buzz" ON "public"."venue_buzz" FOR INSERT TO "authenticated" WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can read conversation participants" ON "public"."conversation_participants" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."conversation_participants" "cp2"
  WHERE (("cp2"."conversation_id" = "conversation_participants"."conversation_id") AND ("cp2"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Users can read own conversations" ON "public"."conversations" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."conversation_participants" "cp"
  WHERE (("cp"."conversation_id" = "conversations"."id") AND ("cp"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Users can read own event logs" ON "public"."event_log" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can read own geofence events" ON "public"."geofence_events" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can read own language preferences" ON "public"."user_language_preferences" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can read own location pings" ON "public"."location_pings" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can record edits to own messages" ON "public"."message_edits" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."messages" "m"
  WHERE (("m"."id" = "message_edits"."message_id") AND ("m"."sender_user_id" = ( SELECT "auth"."uid"() AS "uid"))))));



CREATE POLICY "Users can remove own reactions" ON "public"."venue_room_reactions" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can remove own vote" ON "public"."venue_room_vibe_polls" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can respond to friend requests" ON "public"."friendships" FOR UPDATE TO "authenticated" USING (("friend_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("friend_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can send friend requests" ON "public"."friendships" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can soft delete own messages" ON "public"."messages" FOR UPDATE TO "authenticated" USING (("sender_user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("sender_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can unlike their own likes" ON "public"."venue_room_moment_likes" FOR DELETE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can update own challenges" ON "public"."user_challenges" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can update own consents" ON "public"."user_consents" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own inventory" ON "public"."user_inventory" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update own language preferences" ON "public"."user_language_preferences" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update own membership" ON "public"."swarm_members" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update own participation" ON "public"."conversation_participants" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update own payment status" ON "public"."group_split_items" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update own pending reports" ON "public"."venue_reports" FOR UPDATE TO "authenticated" USING ((("reporter_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("status" = 'pending'::"text"))) WITH CHECK (("reporter_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update own presence" ON "public"."user_venue_presence" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can update own presence" ON "public"."venue_room_presence" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can update own profile" ON "public"."users" FOR UPDATE TO "authenticated" USING (("id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update own ratings" ON "public"."venue_ratings" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update own reviews" ON "public"."venue_reviews" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "created_by_user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "created_by_user_id"));



CREATE POLICY "Users can update own safety friends" ON "public"."safety_friends" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update own stats" ON "public"."user_stats" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can update own streak" ON "public"."check_in_streaks" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update own subscriptions" ON "public"."subscriptions" FOR UPDATE TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can update own visibility settings" ON "public"."visibility_settings" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own vote" ON "public"."venue_room_vibe_polls" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can update their own photos" ON "public"."venue_photos" FOR UPDATE TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "created_by_user_id")) WITH CHECK ((( SELECT "auth"."uid"() AS "uid") = "created_by_user_id"));



CREATE POLICY "Users can view active clusters" ON "public"."venue_clusters" FOR SELECT TO "authenticated" USING (("is_active" = true));



CREATE POLICY "Users can view activity of their friends" ON "public"."activity_feed" FOR SELECT TO "authenticated" USING ((("actor_user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."friendships" "f"
  WHERE (("f"."status" = 'accepted'::"text") AND ((("f"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("f"."friend_id" = "activity_feed"."actor_user_id")) OR (("f"."friend_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("f"."user_id" = "activity_feed"."actor_user_id"))))))));



CREATE POLICY "Users can view edits for accessible messages" ON "public"."message_edits" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."messages" "m"
  WHERE (("m"."id" = "message_edits"."message_id") AND ((("m"."conversation_type" = 'dm'::"text") AND (("m"."dm_user_a" = ( SELECT "auth"."uid"() AS "uid")) OR ("m"."dm_user_b" = ( SELECT "auth"."uid"() AS "uid")))) OR (("m"."conversation_type" = 'swarm'::"text") AND (EXISTS ( SELECT 1
           FROM "public"."swarm_members" "sm"
          WHERE (("sm"."swarm_id" = "m"."swarm_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))))))));



CREATE POLICY "Users can view friend ratings" ON "public"."venue_ratings" FOR SELECT TO "authenticated" USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."friendships" "f"
  WHERE (("f"."status" = 'accepted'::"text") AND ((("f"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("f"."friend_id" = "venue_ratings"."user_id")) OR (("f"."friend_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("f"."user_id" = "venue_ratings"."user_id"))))))));



CREATE POLICY "Users can view friend streaks" ON "public"."check_in_streaks" FOR SELECT TO "authenticated" USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."friendships" "f"
  WHERE (("f"."status" = 'accepted'::"text") AND ((("f"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("f"."friend_id" = "check_in_streaks"."user_id")) OR (("f"."friend_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("f"."user_id" = "check_in_streaks"."user_id"))))))));



CREATE POLICY "Users can view gifts" ON "public"."gifts" FOR SELECT TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") = "from_user_id") OR (( SELECT "auth"."uid"() AS "uid") = "to_user_id")));



CREATE POLICY "Users can view invites they sent or received" ON "public"."night_route_invites" FOR SELECT TO "authenticated" USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."night_routes" "nr"
  WHERE (("nr"."id" = "night_route_invites"."route_id") AND ("nr"."creator_id" = ( SELECT "auth"."uid"() AS "uid")))))));



CREATE POLICY "Users can view music they sent" ON "public"."music_shares" FOR SELECT TO "authenticated" USING (("sender_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can view own API logs" ON "public"."google_api_logs" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can view own activity history" ON "public"."user_activity_history" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can view own and friends safe arrivals" ON "public"."safe_arrivals" FOR SELECT TO "authenticated" USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."friendships" "f"
  WHERE (("f"."status" = 'accepted'::"text") AND ((("f"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("f"."friend_id" = "safe_arrivals"."user_id")) OR (("f"."friend_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("f"."user_id" = "safe_arrivals"."user_id"))))))));



CREATE POLICY "Users can view own blocks" ON "public"."blocks" FOR SELECT TO "authenticated" USING (("blocker_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can view own challenges" ON "public"."user_challenges" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can view own cheers" ON "public"."cheers" FOR SELECT TO "authenticated" USING ((("sender_id" = ( SELECT "auth"."uid"() AS "uid")) OR ("recipient_id" = ( SELECT "auth"."uid"() AS "uid"))));



CREATE POLICY "Users can view own consents" ON "public"."user_consents" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own deletion requests" ON "public"."account_deletion_requests" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own inventory" ON "public"."user_inventory" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can view own location events" ON "public"."location_events" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = "user_id"));



CREATE POLICY "Users can view own messages" ON "public"."messages" FOR SELECT TO "authenticated" USING ((("sender_user_id" = ( SELECT "auth"."uid"() AS "uid")) OR ("dm_user_a" = ( SELECT "auth"."uid"() AS "uid")) OR ("dm_user_b" = ( SELECT "auth"."uid"() AS "uid")) OR (("swarm_id" IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM "public"."swarm_members" "sm"
  WHERE (("sm"."swarm_id" = "messages"."swarm_id") AND ("sm"."user_id" = ( SELECT "auth"."uid"() AS "uid"))))))));



CREATE POLICY "Users can view own notifications" ON "public"."notifications" FOR SELECT TO "authenticated" USING (("recipient_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can view own presence" ON "public"."user_venue_presence" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can view own profile" ON "public"."users" FOR SELECT TO "authenticated" USING (("id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can view own reports" ON "public"."reports" FOR SELECT TO "authenticated" USING (("reporter_user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can view own reports" ON "public"."user_reports" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "reporter_id"));



CREATE POLICY "Users can view own reports" ON "public"."venue_reports" FOR SELECT TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") = "reporter_id") OR (( SELECT "auth"."uid"() AS "uid") = "resolved_by")));



CREATE POLICY "Users can view own routes and invited routes" ON "public"."night_routes" FOR SELECT TO "authenticated" USING ((("creator_id" = ( SELECT "auth"."uid"() AS "uid")) OR (EXISTS ( SELECT 1
   FROM "public"."night_route_invites" "nri"
  WHERE (("nri"."route_id" = "night_routes"."id") AND ("nri"."user_id" = ( SELECT "auth"."uid"() AS "uid")))))));



CREATE POLICY "Users can view own safety alerts" ON "public"."safety_alerts" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can view own safety friends" ON "public"."safety_friends" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can view own subscriptions" ON "public"."subscriptions" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



CREATE POLICY "Users can view own transactions" ON "public"."payment_transactions" FOR SELECT TO "authenticated" USING ((("from_user_id" = ( SELECT "auth"."uid"() AS "uid")) OR ("to_user_id" = ( SELECT "auth"."uid"() AS "uid"))));



CREATE POLICY "Users can view own visibility settings" ON "public"."visibility_settings" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view relevant presence" ON "public"."user_venue_presence" FOR SELECT TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") = "user_id") OR (("is_visible_in_venue" = true) AND ("status" = 'IN_VENUE'::"text") AND ("left_at" IS NULL) AND ("last_seen_at" > ("now"() - '24:00:00'::interval)) AND ((EXISTS ( SELECT 1
   FROM "public"."friendships"
  WHERE (("friendships"."status" = 'accepted'::"text") AND ((("friendships"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("friendships"."friend_id" = "user_venue_presence"."user_id")) OR (("friendships"."friend_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("friendships"."user_id" = "user_venue_presence"."user_id")))))) OR (EXISTS ( SELECT 1
   FROM (("public"."swarm_members" "sm1"
     JOIN "public"."swarm_members" "sm2" ON (("sm1"."swarm_id" = "sm2"."swarm_id")))
     JOIN "public"."swarms" "s" ON (("s"."id" = "sm1"."swarm_id")))
  WHERE (("sm1"."user_id" = ( SELECT "auth"."uid"() AS "uid")) AND ("sm2"."user_id" = "user_venue_presence"."user_id") AND ("s"."status" = ANY (ARRAY['active'::"text", 'ongoing'::"text"])))))))));



CREATE POLICY "Users can view relevant venue sessions" ON "public"."venue_sessions" FOR SELECT TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") = "user_id") OR (EXISTS ( SELECT 1
   FROM "public"."venue_sessions" "vs"
  WHERE (("vs"."user_id" = "auth"."uid"()) AND ("vs"."bar_id" = "venue_sessions"."bar_id") AND ("vs"."status" = 'open'::"text"))))));



CREATE POLICY "Users can view their friendships" ON "public"."friendships" FOR SELECT TO "authenticated" USING ((("user_id" = ( SELECT "auth"."uid"() AS "uid")) OR ("friend_id" = ( SELECT "auth"."uid"() AS "uid"))));



CREATE POLICY "Users can view their own blocks" ON "public"."user_blocks" FOR SELECT TO "authenticated" USING (((( SELECT "auth"."uid"() AS "uid") = "blocker_id") OR (( SELECT "auth"."uid"() AS "uid") = "blocked_id")));



CREATE POLICY "Vibe tags are publicly readable" ON "public"."vibe_tags" FOR SELECT USING (("is_active" = true));



CREATE POLICY "Virtual items are viewable by everyone" ON "public"."virtual_items" FOR SELECT TO "authenticated" USING (("is_active" = true));



CREATE POLICY "Weather data is publicly readable" ON "public"."weather_cache" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") IS NOT NULL));



ALTER TABLE "public"."account_deletion_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."activity_feed" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."badge_definitions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bars" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."blocks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."challenge_definitions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."check_in_streaks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."cheers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."conversation_participants" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."conversation_starters" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."drink_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."emergency_numbers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."emoji_reactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."event_log" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."friendships" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."geofence_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."gifts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."google_api_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."google_place_cache" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."group_split_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."group_splits" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."interests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."languages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."location_events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."location_pings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."looking_for_options" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."message_edits" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mixed_drinks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."music_shares" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."night_route_invites" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."night_routes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."osm_import_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."payment_transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."public_music_shares" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."push_subscriptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."regions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."safe_arrivals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."safety_alerts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."safety_friends" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."swarm_members" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."swarms" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."translation_keys" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."translations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_activity_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_badges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_blocks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_challenges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_consents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_gifts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_inventory" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_language_preferences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_stats" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_venue_presence" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_buzz" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_clusters" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_photos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_ratings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_reviews" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_room_messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_room_moment_likes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_room_moments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_room_presence" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_room_reactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_room_vibe_polls" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_wall_photo_likes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venue_wall_photos" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."venues" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vibe_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vibe_votes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."virtual_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."visibility_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."waitlist" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."weather_cache" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."messages";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."notifications";



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."add_conversation_creator_as_owner"() TO "anon";
GRANT ALL ON FUNCTION "public"."add_conversation_creator_as_owner"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."add_conversation_creator_as_owner"() TO "service_role";



GRANT ALL ON FUNCTION "public"."append_to_deleted_for"("p_message_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."append_to_deleted_for"("p_message_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."append_to_deleted_for"("p_message_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."auto_activate_venue_by_region"() TO "anon";
GRANT ALL ON FUNCTION "public"."auto_activate_venue_by_region"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."auto_activate_venue_by_region"() TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_distance_meters"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_distance_meters"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_distance_meters"("lat1" double precision, "lng1" double precision, "lat2" double precision, "lng2" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_message_notification"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_message_notification"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_message_notification"() TO "service_role";



GRANT ALL ON FUNCTION "public"."create_reciprocal_friendship"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_reciprocal_friendship"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_reciprocal_friendship"() TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_reciprocal_friendship"() TO "anon";
GRANT ALL ON FUNCTION "public"."delete_reciprocal_friendship"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_reciprocal_friendship"() TO "service_role";



GRANT ALL ON FUNCTION "public"."find_nearby_venues"("user_lat" double precision, "user_lng" double precision, "radius_meters" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."find_nearby_venues"("user_lat" double precision, "user_lng" double precision, "radius_meters" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."find_nearby_venues"("user_lat" double precision, "user_lng" double precision, "radius_meters" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."geofence_radius_for_category"("cat" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."geofence_radius_for_category"("cat" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geofence_radius_for_category"("cat" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_room_stats"("p_venue_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_room_stats"("p_venue_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_room_stats"("p_venue_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_time_bucket_5min"("ts" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."get_time_bucket_5min"("ts" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_time_bucket_5min"("ts" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_venue_pending_reports_count"("p_venue_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_venue_pending_reports_count"("p_venue_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_venue_pending_reports_count"("p_venue_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_venue_presence_count"("p_venue_id" "uuid", "include_invisible" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."get_venue_presence_count"("p_venue_id" "uuid", "include_invisible" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_venue_presence_count"("p_venue_id" "uuid", "include_invisible" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_venue_stats"("p_venue_id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_venue_stats"("p_venue_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_venue_stats"("p_venue_id" "text") TO "service_role";



GRANT ALL ON TABLE "public"."venues" TO "anon";
GRANT ALL ON TABLE "public"."venues" TO "authenticated";
GRANT ALL ON TABLE "public"."venues" TO "service_role";



GRANT ALL ON FUNCTION "public"."get_venues_in_bounds"("min_lat" double precision, "min_lng" double precision, "max_lat" double precision, "max_lng" double precision, "category_filter" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_venues_in_bounds"("min_lat" double precision, "min_lng" double precision, "max_lat" double precision, "max_lng" double precision, "category_filter" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_venues_in_bounds"("min_lat" double precision, "min_lng" double precision, "max_lat" double precision, "max_lng" double precision, "category_filter" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."has_accepted_terms"("p_user_id" "uuid", "p_version" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."has_accepted_terms"("p_user_id" "uuid", "p_version" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."has_accepted_terms"("p_user_id" "uuid", "p_version" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_lush_coins"("p_user_id" "uuid", "p_amount" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."increment_lush_coins"("p_user_id" "uuid", "p_amount" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_lush_coins"("p_user_id" "uuid", "p_amount" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."initialize_visibility_settings"() TO "anon";
GRANT ALL ON FUNCTION "public"."initialize_visibility_settings"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."initialize_visibility_settings"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_blocked"("p_user_id" "uuid", "p_other_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_blocked"("p_user_id" "uuid", "p_other_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_blocked"("p_user_id" "uuid", "p_other_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."record_consent"("p_consent_type" "text", "p_version" "text", "p_ip_address" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."record_consent"("p_consent_type" "text", "p_version" "text", "p_ip_address" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."record_consent"("p_consent_type" "text", "p_version" "text", "p_ip_address" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."record_user_consent"("p_user_id" "uuid", "p_consent_type" "text", "p_ip_address" "inet", "p_user_agent" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."record_user_consent"("p_user_id" "uuid", "p_consent_type" "text", "p_ip_address" "inet", "p_user_agent" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."record_user_consent"("p_user_id" "uuid", "p_consent_type" "text", "p_ip_address" "inet", "p_user_agent" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."remove_friendships_on_block"() TO "anon";
GRANT ALL ON FUNCTION "public"."remove_friendships_on_block"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."remove_friendships_on_block"() TO "service_role";



GRANT ALL ON FUNCTION "public"."report_buzz"("buzz_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."report_buzz"("buzz_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."report_buzz"("buzz_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."report_room_message"("p_message_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."report_room_message"("p_message_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."report_room_message"("p_message_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."report_room_moment"("p_moment_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."report_room_moment"("p_moment_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."report_room_moment"("p_moment_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."report_wall_photo"("p_photo_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."report_wall_photo"("p_photo_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."report_wall_photo"("p_photo_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."request_account_deletion"("p_user_id" "uuid", "p_deletion_reason" "text", "p_data_export_requested" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."request_account_deletion"("p_user_id" "uuid", "p_deletion_reason" "text", "p_data_export_requested" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."request_account_deletion"("p_user_id" "uuid", "p_deletion_reason" "text", "p_data_export_requested" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_venue_report_resolved_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_venue_report_resolved_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_venue_report_resolved_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."toggle_moment_like"("p_moment_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."toggle_moment_like"("p_moment_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."toggle_moment_like"("p_moment_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."toggle_wall_photo_like"("p_photo_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."toggle_wall_photo_like"("p_photo_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."toggle_wall_photo_like"("p_photo_id" "uuid", "p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_conversations_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_conversations_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_conversations_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_friendships_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_friendships_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_friendships_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_swarm_current_size"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_swarm_current_size"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_swarm_current_size"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_swarms_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_swarms_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_swarms_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_venues_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_venues_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_venues_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_room_presence"("p_venue_id" "uuid", "p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_room_presence"("p_venue_id" "uuid", "p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_room_presence"("p_venue_id" "uuid", "p_user_id" "uuid") TO "service_role";


















GRANT ALL ON TABLE "public"."account_deletion_requests" TO "anon";
GRANT ALL ON TABLE "public"."account_deletion_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."account_deletion_requests" TO "service_role";



GRANT ALL ON TABLE "public"."activity_feed" TO "anon";
GRANT ALL ON TABLE "public"."activity_feed" TO "authenticated";
GRANT ALL ON TABLE "public"."activity_feed" TO "service_role";



GRANT ALL ON TABLE "public"."badge_definitions" TO "anon";
GRANT ALL ON TABLE "public"."badge_definitions" TO "authenticated";
GRANT ALL ON TABLE "public"."badge_definitions" TO "service_role";



GRANT ALL ON TABLE "public"."bars" TO "anon";
GRANT ALL ON TABLE "public"."bars" TO "authenticated";
GRANT ALL ON TABLE "public"."bars" TO "service_role";



GRANT ALL ON TABLE "public"."blocks" TO "anon";
GRANT ALL ON TABLE "public"."blocks" TO "authenticated";
GRANT ALL ON TABLE "public"."blocks" TO "service_role";



GRANT ALL ON TABLE "public"."challenge_definitions" TO "anon";
GRANT ALL ON TABLE "public"."challenge_definitions" TO "authenticated";
GRANT ALL ON TABLE "public"."challenge_definitions" TO "service_role";



GRANT ALL ON TABLE "public"."check_in_streaks" TO "anon";
GRANT ALL ON TABLE "public"."check_in_streaks" TO "authenticated";
GRANT ALL ON TABLE "public"."check_in_streaks" TO "service_role";



GRANT ALL ON TABLE "public"."cheers" TO "anon";
GRANT ALL ON TABLE "public"."cheers" TO "authenticated";
GRANT ALL ON TABLE "public"."cheers" TO "service_role";



GRANT ALL ON TABLE "public"."conversation_participants" TO "anon";
GRANT ALL ON TABLE "public"."conversation_participants" TO "authenticated";
GRANT ALL ON TABLE "public"."conversation_participants" TO "service_role";



GRANT ALL ON TABLE "public"."conversation_starters" TO "anon";
GRANT ALL ON TABLE "public"."conversation_starters" TO "authenticated";
GRANT ALL ON TABLE "public"."conversation_starters" TO "service_role";



GRANT ALL ON TABLE "public"."conversations" TO "anon";
GRANT ALL ON TABLE "public"."conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."conversations" TO "service_role";



GRANT ALL ON TABLE "public"."drink_categories" TO "anon";
GRANT ALL ON TABLE "public"."drink_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."drink_categories" TO "service_role";



GRANT ALL ON TABLE "public"."emergency_numbers" TO "anon";
GRANT ALL ON TABLE "public"."emergency_numbers" TO "authenticated";
GRANT ALL ON TABLE "public"."emergency_numbers" TO "service_role";



GRANT ALL ON TABLE "public"."emoji_reactions" TO "anon";
GRANT ALL ON TABLE "public"."emoji_reactions" TO "authenticated";
GRANT ALL ON TABLE "public"."emoji_reactions" TO "service_role";



GRANT ALL ON TABLE "public"."event_log" TO "anon";
GRANT ALL ON TABLE "public"."event_log" TO "authenticated";
GRANT ALL ON TABLE "public"."event_log" TO "service_role";



GRANT ALL ON TABLE "public"."friendships" TO "anon";
GRANT ALL ON TABLE "public"."friendships" TO "authenticated";
GRANT ALL ON TABLE "public"."friendships" TO "service_role";



GRANT ALL ON TABLE "public"."geofence_events" TO "anon";
GRANT ALL ON TABLE "public"."geofence_events" TO "authenticated";
GRANT ALL ON TABLE "public"."geofence_events" TO "service_role";



GRANT ALL ON TABLE "public"."gifts" TO "anon";
GRANT ALL ON TABLE "public"."gifts" TO "authenticated";
GRANT ALL ON TABLE "public"."gifts" TO "service_role";



GRANT ALL ON TABLE "public"."google_api_logs" TO "anon";
GRANT ALL ON TABLE "public"."google_api_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."google_api_logs" TO "service_role";



GRANT ALL ON TABLE "public"."google_place_cache" TO "anon";
GRANT ALL ON TABLE "public"."google_place_cache" TO "authenticated";
GRANT ALL ON TABLE "public"."google_place_cache" TO "service_role";



GRANT ALL ON TABLE "public"."group_split_items" TO "anon";
GRANT ALL ON TABLE "public"."group_split_items" TO "authenticated";
GRANT ALL ON TABLE "public"."group_split_items" TO "service_role";



GRANT ALL ON TABLE "public"."group_splits" TO "anon";
GRANT ALL ON TABLE "public"."group_splits" TO "authenticated";
GRANT ALL ON TABLE "public"."group_splits" TO "service_role";



GRANT ALL ON TABLE "public"."interests" TO "anon";
GRANT ALL ON TABLE "public"."interests" TO "authenticated";
GRANT ALL ON TABLE "public"."interests" TO "service_role";



GRANT ALL ON TABLE "public"."languages" TO "anon";
GRANT ALL ON TABLE "public"."languages" TO "authenticated";
GRANT ALL ON TABLE "public"."languages" TO "service_role";



GRANT ALL ON TABLE "public"."location_events" TO "anon";
GRANT ALL ON TABLE "public"."location_events" TO "authenticated";
GRANT ALL ON TABLE "public"."location_events" TO "service_role";



GRANT ALL ON TABLE "public"."location_pings" TO "anon";
GRANT ALL ON TABLE "public"."location_pings" TO "authenticated";
GRANT ALL ON TABLE "public"."location_pings" TO "service_role";



GRANT ALL ON TABLE "public"."looking_for_options" TO "anon";
GRANT ALL ON TABLE "public"."looking_for_options" TO "authenticated";
GRANT ALL ON TABLE "public"."looking_for_options" TO "service_role";



GRANT ALL ON TABLE "public"."message_edits" TO "anon";
GRANT ALL ON TABLE "public"."message_edits" TO "authenticated";
GRANT ALL ON TABLE "public"."message_edits" TO "service_role";



GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



GRANT ALL ON TABLE "public"."mixed_drinks" TO "anon";
GRANT ALL ON TABLE "public"."mixed_drinks" TO "authenticated";
GRANT ALL ON TABLE "public"."mixed_drinks" TO "service_role";



GRANT ALL ON TABLE "public"."music_shares" TO "anon";
GRANT ALL ON TABLE "public"."music_shares" TO "authenticated";
GRANT ALL ON TABLE "public"."music_shares" TO "service_role";



GRANT ALL ON TABLE "public"."night_route_invites" TO "anon";
GRANT ALL ON TABLE "public"."night_route_invites" TO "authenticated";
GRANT ALL ON TABLE "public"."night_route_invites" TO "service_role";



GRANT ALL ON TABLE "public"."night_routes" TO "anon";
GRANT ALL ON TABLE "public"."night_routes" TO "authenticated";
GRANT ALL ON TABLE "public"."night_routes" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."osm_import_logs" TO "anon";
GRANT ALL ON TABLE "public"."osm_import_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."osm_import_logs" TO "service_role";



GRANT ALL ON TABLE "public"."payment_transactions" TO "anon";
GRANT ALL ON TABLE "public"."payment_transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."payment_transactions" TO "service_role";



GRANT ALL ON TABLE "public"."public_music_shares" TO "anon";
GRANT ALL ON TABLE "public"."public_music_shares" TO "authenticated";
GRANT ALL ON TABLE "public"."public_music_shares" TO "service_role";



GRANT ALL ON TABLE "public"."push_subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."push_subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."push_subscriptions" TO "service_role";



GRANT ALL ON TABLE "public"."regions" TO "anon";
GRANT ALL ON TABLE "public"."regions" TO "authenticated";
GRANT ALL ON TABLE "public"."regions" TO "service_role";



GRANT ALL ON TABLE "public"."reports" TO "anon";
GRANT ALL ON TABLE "public"."reports" TO "authenticated";
GRANT ALL ON TABLE "public"."reports" TO "service_role";



GRANT ALL ON TABLE "public"."safe_arrivals" TO "anon";
GRANT ALL ON TABLE "public"."safe_arrivals" TO "authenticated";
GRANT ALL ON TABLE "public"."safe_arrivals" TO "service_role";



GRANT ALL ON TABLE "public"."safety_alerts" TO "anon";
GRANT ALL ON TABLE "public"."safety_alerts" TO "authenticated";
GRANT ALL ON TABLE "public"."safety_alerts" TO "service_role";



GRANT ALL ON TABLE "public"."safety_friends" TO "anon";
GRANT ALL ON TABLE "public"."safety_friends" TO "authenticated";
GRANT ALL ON TABLE "public"."safety_friends" TO "service_role";



GRANT ALL ON TABLE "public"."subscriptions" TO "anon";
GRANT ALL ON TABLE "public"."subscriptions" TO "authenticated";
GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";



GRANT ALL ON TABLE "public"."swarm_members" TO "anon";
GRANT ALL ON TABLE "public"."swarm_members" TO "authenticated";
GRANT ALL ON TABLE "public"."swarm_members" TO "service_role";



GRANT ALL ON TABLE "public"."swarms" TO "anon";
GRANT ALL ON TABLE "public"."swarms" TO "authenticated";
GRANT ALL ON TABLE "public"."swarms" TO "service_role";



GRANT ALL ON TABLE "public"."translation_keys" TO "anon";
GRANT ALL ON TABLE "public"."translation_keys" TO "authenticated";
GRANT ALL ON TABLE "public"."translation_keys" TO "service_role";



GRANT ALL ON TABLE "public"."translations" TO "anon";
GRANT ALL ON TABLE "public"."translations" TO "authenticated";
GRANT ALL ON TABLE "public"."translations" TO "service_role";



GRANT ALL ON TABLE "public"."user_activity_history" TO "anon";
GRANT ALL ON TABLE "public"."user_activity_history" TO "authenticated";
GRANT ALL ON TABLE "public"."user_activity_history" TO "service_role";



GRANT ALL ON TABLE "public"."user_badges" TO "anon";
GRANT ALL ON TABLE "public"."user_badges" TO "authenticated";
GRANT ALL ON TABLE "public"."user_badges" TO "service_role";



GRANT ALL ON TABLE "public"."user_blocks" TO "anon";
GRANT ALL ON TABLE "public"."user_blocks" TO "authenticated";
GRANT ALL ON TABLE "public"."user_blocks" TO "service_role";



GRANT ALL ON TABLE "public"."user_challenges" TO "anon";
GRANT ALL ON TABLE "public"."user_challenges" TO "authenticated";
GRANT ALL ON TABLE "public"."user_challenges" TO "service_role";



GRANT ALL ON TABLE "public"."user_consents" TO "anon";
GRANT ALL ON TABLE "public"."user_consents" TO "authenticated";
GRANT ALL ON TABLE "public"."user_consents" TO "service_role";



GRANT ALL ON TABLE "public"."user_gifts" TO "anon";
GRANT ALL ON TABLE "public"."user_gifts" TO "authenticated";
GRANT ALL ON TABLE "public"."user_gifts" TO "service_role";



GRANT ALL ON TABLE "public"."user_inventory" TO "anon";
GRANT ALL ON TABLE "public"."user_inventory" TO "authenticated";
GRANT ALL ON TABLE "public"."user_inventory" TO "service_role";



GRANT ALL ON TABLE "public"."user_language_preferences" TO "anon";
GRANT ALL ON TABLE "public"."user_language_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."user_language_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."user_reports" TO "anon";
GRANT ALL ON TABLE "public"."user_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."user_reports" TO "service_role";



GRANT ALL ON TABLE "public"."user_stats" TO "anon";
GRANT ALL ON TABLE "public"."user_stats" TO "authenticated";
GRANT ALL ON TABLE "public"."user_stats" TO "service_role";



GRANT ALL ON TABLE "public"."user_venue_presence" TO "anon";
GRANT ALL ON TABLE "public"."user_venue_presence" TO "authenticated";
GRANT ALL ON TABLE "public"."user_venue_presence" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT ALL ON TABLE "public"."venue_buzz" TO "anon";
GRANT ALL ON TABLE "public"."venue_buzz" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_buzz" TO "service_role";



GRANT ALL ON TABLE "public"."venue_clusters" TO "anon";
GRANT ALL ON TABLE "public"."venue_clusters" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_clusters" TO "service_role";



GRANT ALL ON TABLE "public"."venue_crossing_paths" TO "anon";
GRANT ALL ON TABLE "public"."venue_crossing_paths" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_crossing_paths" TO "service_role";



GRANT ALL ON TABLE "public"."venue_photos" TO "anon";
GRANT ALL ON TABLE "public"."venue_photos" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_photos" TO "service_role";



GRANT ALL ON TABLE "public"."venue_ratings" TO "anon";
GRANT ALL ON TABLE "public"."venue_ratings" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_ratings" TO "service_role";



GRANT ALL ON TABLE "public"."venue_reports" TO "anon";
GRANT ALL ON TABLE "public"."venue_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_reports" TO "service_role";



GRANT ALL ON TABLE "public"."venue_reviews" TO "anon";
GRANT ALL ON TABLE "public"."venue_reviews" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_reviews" TO "service_role";



GRANT ALL ON TABLE "public"."venue_room_messages" TO "anon";
GRANT ALL ON TABLE "public"."venue_room_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_room_messages" TO "service_role";



GRANT ALL ON TABLE "public"."venue_room_moment_likes" TO "anon";
GRANT ALL ON TABLE "public"."venue_room_moment_likes" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_room_moment_likes" TO "service_role";



GRANT ALL ON TABLE "public"."venue_room_moments" TO "anon";
GRANT ALL ON TABLE "public"."venue_room_moments" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_room_moments" TO "service_role";



GRANT ALL ON TABLE "public"."venue_room_presence" TO "anon";
GRANT ALL ON TABLE "public"."venue_room_presence" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_room_presence" TO "service_role";



GRANT ALL ON TABLE "public"."venue_room_reactions" TO "anon";
GRANT ALL ON TABLE "public"."venue_room_reactions" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_room_reactions" TO "service_role";



GRANT ALL ON TABLE "public"."venue_room_vibe_polls" TO "anon";
GRANT ALL ON TABLE "public"."venue_room_vibe_polls" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_room_vibe_polls" TO "service_role";



GRANT ALL ON TABLE "public"."venue_sessions" TO "anon";
GRANT ALL ON TABLE "public"."venue_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."venue_wall_photo_likes" TO "anon";
GRANT ALL ON TABLE "public"."venue_wall_photo_likes" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_wall_photo_likes" TO "service_role";



GRANT ALL ON TABLE "public"."venue_wall_photos" TO "anon";
GRANT ALL ON TABLE "public"."venue_wall_photos" TO "authenticated";
GRANT ALL ON TABLE "public"."venue_wall_photos" TO "service_role";



GRANT ALL ON TABLE "public"."vibe_tags" TO "anon";
GRANT ALL ON TABLE "public"."vibe_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."vibe_tags" TO "service_role";



GRANT ALL ON TABLE "public"."vibe_votes" TO "anon";
GRANT ALL ON TABLE "public"."vibe_votes" TO "authenticated";
GRANT ALL ON TABLE "public"."vibe_votes" TO "service_role";



GRANT ALL ON TABLE "public"."virtual_items" TO "anon";
GRANT ALL ON TABLE "public"."virtual_items" TO "authenticated";
GRANT ALL ON TABLE "public"."virtual_items" TO "service_role";



GRANT ALL ON TABLE "public"."visibility_settings" TO "anon";
GRANT ALL ON TABLE "public"."visibility_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."visibility_settings" TO "service_role";



GRANT ALL ON TABLE "public"."waitlist" TO "anon";
GRANT ALL ON TABLE "public"."waitlist" TO "authenticated";
GRANT ALL ON TABLE "public"."waitlist" TO "service_role";



GRANT ALL ON TABLE "public"."weather_cache" TO "anon";
GRANT ALL ON TABLE "public"."weather_cache" TO "authenticated";
GRANT ALL ON TABLE "public"."weather_cache" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































