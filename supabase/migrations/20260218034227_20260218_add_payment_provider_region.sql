/*
  # Add Payment Provider Region Support

  1. New Columns
    - `payment_provider` (text) - tracks which payment provider user uses ('venmo' or 'beem')
    - `payment_provider_username` (text) - username for the active payment provider
    - `payment_provider_linked` (boolean) - whether payment provider is linked

  2. Migration Details
    - Adds region-based payment provider support
    - Maintains backward compatibility with existing venmo_linked and venmo_username fields
    - Users will use the appropriate provider based on their region (Australia = Beem, other = Venmo)
    - payment_provider defaults to 'venmo' for existing users
    - New users will have their provider set based on their detected region

  3. Security
    - No changes to RLS policies needed as this is just metadata
    - Existing users table RLS continues to apply
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'payment_provider'
  ) THEN
    ALTER TABLE users ADD COLUMN payment_provider text DEFAULT 'venmo';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'payment_provider_username'
  ) THEN
    ALTER TABLE users ADD COLUMN payment_provider_username text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'payment_provider_linked'
  ) THEN
    ALTER TABLE users ADD COLUMN payment_provider_linked boolean DEFAULT false;
  END IF;
END $$;
