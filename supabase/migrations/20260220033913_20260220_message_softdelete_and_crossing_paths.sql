/*
  # Message Soft Delete and Venue Crossing Paths

  ## Summary
  
  ## 1. Message Soft Delete Columns
  - Adds `deleted_for_user_ids` (uuid[]) to `messages` table for per-user soft delete of individual messages
  - Adds `conversation_cleared_by` (uuid[]) to `messages` table so users can "delete full chat" for themselves only

  ## 2. User Blocks - Allow Blocked User to See They're Blocked
  - Adds a SELECT policy so blocked users can see the block entry (needed to enforce they can't request)

  ## 3. venue_crossing_paths View
  - Creates a view that finds users who overlapped at the same venue within 7 days
  - Uses the correct column `left_at` from user_venue_presence
  - Suppresses ghost_mode users from appearing

  ## 4. Performance Indexes
  - Indexes for faster crossing paths queries
*/

-- ============================================================
-- 1. MESSAGE SOFT-DELETE COLUMNS
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'messages' AND column_name = 'deleted_for_user_ids'
  ) THEN
    ALTER TABLE messages ADD COLUMN deleted_for_user_ids uuid[] DEFAULT '{}';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'messages' AND column_name = 'conversation_cleared_by'
  ) THEN
    ALTER TABLE messages ADD COLUMN conversation_cleared_by uuid[] DEFAULT '{}';
  END IF;
END $$;

-- ============================================================
-- 2. USER BLOCKS - Add policy so blocked user can see the block
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'user_blocks' AND policyname = 'Blocked users can see they are blocked'
  ) THEN
    CREATE POLICY "Blocked users can see they are blocked"
      ON user_blocks FOR SELECT
      TO authenticated
      USING (auth.uid() = blocker_id OR auth.uid() = blocked_id);
  END IF;
END $$;

-- ============================================================
-- 3. VENUE CROSSING PATHS VIEW
-- ============================================================
CREATE OR REPLACE VIEW venue_crossing_paths AS
SELECT
  a.user_id AS viewer_id,
  b.user_id AS other_user_id,
  a.venue_id,
  GREATEST(a.entered_at, b.entered_at) AS overlap_start,
  LEAST(
    COALESCE(a.left_at, now()),
    COALESCE(b.left_at, now())
  ) AS overlap_end,
  a.entered_at AS viewer_entered_at,
  COALESCE(a.left_at, now()) AS viewer_left_at,
  b.entered_at AS other_entered_at,
  COALESCE(b.left_at, now()) AS other_left_at
FROM user_venue_presence a
JOIN user_venue_presence b
  ON a.venue_id = b.venue_id
  AND a.user_id <> b.user_id
  -- Time windows must overlap
  AND a.entered_at < COALESCE(b.left_at, now())
  AND b.entered_at < COALESCE(a.left_at, now())
JOIN users u ON u.id = b.user_id
WHERE
  -- Suppress ghost mode users from appearing in others' history
  (u.ghost_mode IS NULL OR u.ghost_mode = false)
  -- Only surface crossings within last 7 days
  AND a.entered_at >= now() - interval '7 days';

-- ============================================================
-- 4. INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_messages_deleted_for ON messages USING GIN(deleted_for_user_ids);
CREATE INDEX IF NOT EXISTS idx_messages_cleared_by ON messages USING GIN(conversation_cleared_by);
CREATE INDEX IF NOT EXISTS idx_user_venue_presence_entered ON user_venue_presence(user_id, entered_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_venue_presence_venue_time ON user_venue_presence(venue_id, entered_at DESC);
