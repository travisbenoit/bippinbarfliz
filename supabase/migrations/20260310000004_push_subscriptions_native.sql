-- Add native push token support (Capacitor APNS/FCM) to push_subscriptions

-- Make endpoint/p256dh/auth nullable (they're only used for web push)
ALTER TABLE push_subscriptions
  ALTER COLUMN endpoint DROP NOT NULL,
  ALTER COLUMN p256dh   DROP NOT NULL,
  ALTER COLUMN auth     DROP NOT NULL;

-- Add native token column and platform column
ALTER TABLE push_subscriptions
  ADD COLUMN IF NOT EXISTS native_token text,
  ADD COLUMN IF NOT EXISTS platform     text DEFAULT 'web';  -- 'web' | 'ios' | 'android'

-- New unique constraint: one row per user per platform
-- (the old unique was on user_id, endpoint — we keep that and add the native one)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'push_subscriptions_user_id_platform_key'
  ) THEN
    ALTER TABLE push_subscriptions
      ADD CONSTRAINT push_subscriptions_user_id_platform_key
      UNIQUE (user_id, platform);
  END IF;
END $$;

-- Index for native token lookups
CREATE INDEX IF NOT EXISTS idx_push_subscriptions_native_token
  ON push_subscriptions (native_token)
  WHERE native_token IS NOT NULL;
