/*
  # Create missing utility functions

  1. New Functions
    - `is_blocked(p_user_id, p_other_user_id)` - checks if either user has blocked the other
    - `append_to_deleted_for(message_id, user_id)` - appends a user ID to the deleted_for_user_ids array on a message
    - `get_venue_pending_reports_count(p_venue_id)` - counts pending venue reports
    - `get_time_bucket_5min(ts)` - rounds timestamp to nearest 5-minute bucket

  2. Important Notes
    - is_blocked checks both directions of blocking
    - append_to_deleted_for uses array_append for soft-delete per user
    - All functions use SECURITY INVOKER (default) for RLS compliance
*/

CREATE OR REPLACE FUNCTION is_blocked(p_user_id uuid, p_other_user_id uuid)
  RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_blocks
    WHERE (blocking_user_id = p_user_id AND blocked_user_id = p_other_user_id)
       OR (blocking_user_id = p_other_user_id AND blocked_user_id = p_user_id)
  );
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION append_to_deleted_for(p_message_id uuid, p_user_id uuid)
  RETURNS void AS $$
BEGIN
  UPDATE messages
  SET deleted_for_user_ids = array_append(
    COALESCE(deleted_for_user_ids, '{}'),
    p_user_id
  )
  WHERE id = p_message_id
    AND (sender_user_id = p_user_id
      OR dm_user_a = p_user_id
      OR dm_user_b = p_user_id)
    AND NOT (p_user_id = ANY(COALESCE(deleted_for_user_ids, '{}')));
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_venue_pending_reports_count(p_venue_id uuid)
  RETURNS integer AS $$
DECLARE
  report_count integer;
BEGIN
  SELECT count(*)::integer INTO report_count
  FROM venue_reports
  WHERE venue_id = p_venue_id AND status = 'pending';
  RETURN COALESCE(report_count, 0);
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION get_time_bucket_5min(ts timestamptz)
  RETURNS timestamptz AS $$
BEGIN
  RETURN date_trunc('hour', ts) + (floor(extract(minute FROM ts) / 5) * interval '5 minutes');
END;
$$ LANGUAGE plpgsql IMMUTABLE;
