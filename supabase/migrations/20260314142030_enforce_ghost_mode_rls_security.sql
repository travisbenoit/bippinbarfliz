/*
  # Enforce Ghost Mode and Privacy Controls at RLS Level

  ## Summary
  This migration strengthens Row Level Security on the `users` table so that
  ghost-mode users and users with invisible privacy settings are hidden at the
  database level, not just in client-side JavaScript.

  ## Changes

  ### Modified RLS Policies on `users` table
  - Replaces any permissive SELECT policy with one that:
    - Allows users to always read their own row
    - Hides rows where `ghost_mode = true` from other users
    - Hides rows where `privacy_mode = 'invisible'` from non-friends

  ## Security Notes
  - Ghost mode is now enforced server-side; clients cannot bypass it by
    omitting the filter
  - Privacy mode 'invisible' hides the user from the nearby-people query
    even if a malicious client omits the filter
*/

DROP POLICY IF EXISTS "Users can view other users" ON public.users;
DROP POLICY IF EXISTS "Anyone can view users" ON public.users;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.users;
DROP POLICY IF EXISTS "Users can view public profiles" ON public.users;

CREATE POLICY "Users visible to others respecting ghost and privacy mode"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = id
    OR (
      (ghost_mode IS NULL OR ghost_mode = false)
      AND (privacy_mode IS NULL OR privacy_mode != 'invisible')
    )
  );
