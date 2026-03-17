/*
  # Add native_token and platform to push_subscriptions

  ## Summary
  Adds two columns needed for Pushy.io push notification routing:
  - `native_token` (text, nullable): The Pushy device token for this subscription
  - `platform` (text, default 'web'): Which platform this subscription is for
    (values: 'web', 'ios', 'android')

  Also adds an index on native_token for fast lookups when cleaning stale tokens.

  ## Tables Modified
  - `push_subscriptions`
    - Add `native_token text` (nullable)
    - Add `platform text DEFAULT 'web'`

  ## Notes
  - Existing rows will get platform='web' automatically
  - The endpoint/p256dh/auth columns remain for any legacy VAPID rows
  - native_token stores the Pushy device registration token
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'push_subscriptions' AND column_name = 'native_token'
  ) THEN
    ALTER TABLE push_subscriptions ADD COLUMN native_token text;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'push_subscriptions' AND column_name = 'platform'
  ) THEN
    ALTER TABLE push_subscriptions ADD COLUMN platform text DEFAULT 'web';
  END IF;
END $$;

UPDATE push_subscriptions SET platform = 'web' WHERE platform IS NULL;

CREATE INDEX IF NOT EXISTS idx_push_subscriptions_native_token
  ON push_subscriptions (native_token)
  WHERE native_token IS NOT NULL;
