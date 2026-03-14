/*
  # Add Missing Foreign Key Indexes

  Adds indexes on unindexed foreign key columns identified by the Supabase security advisor.
  These indexes improve query performance and resolve the security advisor warnings.
*/

CREATE INDEX IF NOT EXISTS idx_activity_feed_swarm_id ON public.activity_feed(swarm_id);
CREATE INDEX IF NOT EXISTS idx_cheers_venue_id ON public.cheers(venue_id);
CREATE INDEX IF NOT EXISTS idx_gifts_venue_id ON public.gifts(venue_id);
CREATE INDEX IF NOT EXISTS idx_group_splits_creator_id ON public.group_splits(creator_id);
CREATE INDEX IF NOT EXISTS idx_mixed_drinks_category_id ON public.mixed_drinks(category_id);
CREATE INDEX IF NOT EXISTS idx_music_shares_swarm_id ON public.music_shares(swarm_id);
CREATE INDEX IF NOT EXISTS idx_music_shares_venue_id ON public.music_shares(venue_id);
CREATE INDEX IF NOT EXISTS idx_notifications_actor_user_id ON public.notifications(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_swarm_id ON public.notifications(swarm_id);
CREATE INDEX IF NOT EXISTS idx_notifications_venue_id ON public.notifications(venue_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_swarm_id ON public.payment_transactions(swarm_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported_user_id ON public.reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_reports_reporter_user_id ON public.reports(reporter_user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_history_related_user_id ON public.user_activity_history(related_user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_history_venue_id ON public.user_activity_history(venue_id);
CREATE INDEX IF NOT EXISTS idx_user_gifts_item_id ON public.user_gifts(item_id);
CREATE INDEX IF NOT EXISTS idx_user_language_preferences_language_id ON public.user_language_preferences(language_id);
CREATE INDEX IF NOT EXISTS idx_user_language_preferences_region_id ON public.user_language_preferences(region_id);
