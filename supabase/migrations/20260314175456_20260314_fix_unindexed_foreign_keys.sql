/*
  # Fix Unindexed Foreign Keys

  ## Summary
  Adds covering indexes for foreign key columns that were missing indexes.
  This prevents full table scans when joining or filtering on these columns.

  ## New Indexes
  - blocks.blocked_user_id
  - music_shares.swarm_id
  - payment_transactions.swarm_id
  - reports.reported_user_id
  - reports.reporter_user_id
  - swarm_members.user_id
  - venue_room_messages.user_id
  - venue_room_moments.user_id
  - venue_room_presence.user_id
  - venue_room_reactions.user_id
  - venue_room_vibe_polls.user_id
*/

CREATE INDEX IF NOT EXISTS idx_blocks_blocked_user_id ON public.blocks (blocked_user_id);
CREATE INDEX IF NOT EXISTS idx_music_shares_swarm_id ON public.music_shares (swarm_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_swarm_id ON public.payment_transactions (swarm_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported_user_id ON public.reports (reported_user_id);
CREATE INDEX IF NOT EXISTS idx_reports_reporter_user_id ON public.reports (reporter_user_id);
CREATE INDEX IF NOT EXISTS idx_swarm_members_user_id ON public.swarm_members (user_id);
CREATE INDEX IF NOT EXISTS idx_venue_room_messages_user_id ON public.venue_room_messages (user_id);
CREATE INDEX IF NOT EXISTS idx_venue_room_moments_user_id ON public.venue_room_moments (user_id);
CREATE INDEX IF NOT EXISTS idx_venue_room_presence_user_id ON public.venue_room_presence (user_id);
CREATE INDEX IF NOT EXISTS idx_venue_room_reactions_user_id ON public.venue_room_reactions (user_id);
CREATE INDEX IF NOT EXISTS idx_venue_room_vibe_polls_user_id ON public.venue_room_vibe_polls (user_id);
