/*
  # Drop Duplicate Indexes and Fix Security Definer View

  ## Summary

  ### 1. Duplicate Index Removal
  Drops the redundant member of each duplicate pair, keeping the one with
  the more descriptive name where both are equivalent:
  - location_pings: drop idx_location_pings_user (keep idx_location_pings_user_timeline)
  - swarms host: drop idx_swarms_host (keep idx_swarms_host_user)
  - swarms venue: drop idx_swarms_venue (keep idx_swarms_venue_id)
  - user_blocks blocked: drop idx_user_blocks_blocked (keep idx_user_blocks_blocked_id)
  - user_blocks blocker: drop idx_user_blocks_blocker (keep idx_user_blocks_blocker_id)
  - user_gifts created: drop idx_user_gifts_created (keep idx_user_gifts_created_at)
  - venues country: drop idx_venues_country (keep venues_country_idx)
  - venues lat/lng: drop idx_venues_lat_lng (keep venues_lat_lng_idx)

  ### 2. Security Definer View Fix
  Recreates venue_crossing_paths without SECURITY DEFINER so it runs with
  the querying user's permissions instead of the view owner's permissions.
*/

-- Drop duplicate indexes
DROP INDEX IF EXISTS public.idx_location_pings_user;
DROP INDEX IF EXISTS public.idx_swarms_host;
DROP INDEX IF EXISTS public.idx_swarms_venue;
DROP INDEX IF EXISTS public.idx_user_blocks_blocked;
DROP INDEX IF EXISTS public.idx_user_blocks_blocker;
DROP INDEX IF EXISTS public.idx_user_gifts_created;
DROP INDEX IF EXISTS public.idx_venues_country;
DROP INDEX IF EXISTS public.idx_venues_lat_lng;

-- Fix security definer view: recreate venue_crossing_paths as SECURITY INVOKER
DO $$
DECLARE
  view_def text;
BEGIN
  SELECT pg_get_viewdef('public.venue_crossing_paths'::regclass, true) INTO view_def;
  IF view_def IS NOT NULL THEN
    EXECUTE 'DROP VIEW IF EXISTS public.venue_crossing_paths';
    EXECUTE 'CREATE VIEW public.venue_crossing_paths WITH (security_invoker = true) AS ' || view_def;
  END IF;
END $$;
