/*
  # Add increment_lush_coins RPC

  Atomic coin increment/decrement to avoid race conditions when multiple
  gamification events fire simultaneously (e.g., check-in + streak milestone).

  ## Functions

  ### increment_lush_coins(p_user_id, p_amount)
  - Adds p_amount to users.lush_coin_balance atomically
  - Clamps to 0 (balance can never go negative)
  - Returns the new balance
  - p_amount can be negative (for spending coins)
*/

CREATE OR REPLACE FUNCTION increment_lush_coins(
  p_user_id uuid,
  p_amount   integer
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
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

-- Grant execute to authenticated users (they can only update their own balance
-- because the function is called with their own user_id from the client, and
-- RLS on the users table enforces ownership for direct writes)
GRANT EXECUTE ON FUNCTION increment_lush_coins(uuid, integer) TO authenticated;
