-- Add notification_preferences JSONB column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT NULL;
