/*
  # Fix initialize_visibility_settings trigger function

  The on_user_created_visibility trigger on auth.users calls this function on every
  new signup. It had no SET search_path configured and used an unqualified table name.
  GoTrue's database connection uses an empty search_path, so `visibility_settings`
  could not be resolved — causing every signup to fail with
  "Database error saving new user" (500).

  Fix: add SET search_path = 'public' and fully qualify the table reference.
*/

CREATE OR REPLACE FUNCTION public.initialize_visibility_settings()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  INSERT INTO public.visibility_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;
