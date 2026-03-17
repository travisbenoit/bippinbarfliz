/*
  # Fix SECURITY DEFINER Functions Missing search_path

  ## Problem
  Three public functions use SECURITY DEFINER without setting an explicit search_path.
  This allows a malicious user with schema-creation privileges to shadow built-in
  functions/tables by creating objects in a schema that comes before public in
  search_path — a privilege escalation vector flagged by the Supabase security advisor.

  ## Changes
  - `create_message_notification` — trigger function; add SET search_path = public
  - `increment_lush_coins` — RPC function; add SET search_path = public
  - `toggle_moment_like` — RPC function; add SET search_path = public

  All function bodies are identical to the originals; only the security attribute is added.
*/

CREATE OR REPLACE FUNCTION public.create_message_notification()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
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

CREATE OR REPLACE FUNCTION public.increment_lush_coins(p_user_id uuid, p_amount integer)
  RETURNS integer
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
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

CREATE OR REPLACE FUNCTION public.toggle_moment_like(p_moment_id uuid, p_user_id uuid)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
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
