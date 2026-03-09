/*
  # Fix Unindexed Foreign Keys

  1. Indexes Added
    - Created indexes on all foreign key columns without covering indexes
    - This improves query performance for lookups, joins, and DELETE operations
    
  2. Tables Fixed
    - activity_feed: swarm_id
    - cheers: venue_id
    - conversations: venue_id
    - gifts: venue_id
    - group_splits: creator_id
    - message_edits: edited_by, message_id
    - messages: dm_user_b
    - mixed_drinks: category_id
    - music_shares: venue_id
    - night_route_invites: user_id
    - notifications: actor_user_id, swarm_id, venue_id
    - safety_alerts: user_id
    - safety_friends: user_id
    - swarms: venue_id
    - translations: language_id
    - user_activity_history: related_user_id, venue_id
    - user_blocks: blocked_user_id
    - user_gifts: item_id
    - user_inventory: item_id
    - user_language_preferences: language_id, region_id
    - venue_reports: resolved_by
*/

CREATE INDEX IF NOT EXISTS idx_activity_feed_swarm_id ON activity_feed(swarm_id);
CREATE INDEX IF NOT EXISTS idx_cheers_venue_id ON cheers(venue_id);
CREATE INDEX IF NOT EXISTS idx_conversations_venue_id ON conversations(venue_id);
CREATE INDEX IF NOT EXISTS idx_gifts_venue_id ON gifts(venue_id);
CREATE INDEX IF NOT EXISTS idx_group_splits_creator_id ON group_splits(creator_id);
CREATE INDEX IF NOT EXISTS idx_message_edits_edited_by ON message_edits(edited_by);
CREATE INDEX IF NOT EXISTS idx_message_edits_message_id ON message_edits(message_id);
CREATE INDEX IF NOT EXISTS idx_messages_dm_user_b ON messages(dm_user_b);
CREATE INDEX IF NOT EXISTS idx_mixed_drinks_category_id ON mixed_drinks(category_id);
CREATE INDEX IF NOT EXISTS idx_music_shares_venue_id ON music_shares(venue_id);
CREATE INDEX IF NOT EXISTS idx_night_route_invites_user_id ON night_route_invites(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_actor_user_id ON notifications(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_swarm_id ON notifications(swarm_id);
CREATE INDEX IF NOT EXISTS idx_notifications_venue_id ON notifications(venue_id);
CREATE INDEX IF NOT EXISTS idx_safety_alerts_user_id ON safety_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_safety_friends_user_id ON safety_friends(user_id);
CREATE INDEX IF NOT EXISTS idx_swarms_venue_id ON swarms(venue_id);
CREATE INDEX IF NOT EXISTS idx_translations_language_id ON translations(language_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_history_related_user_id ON user_activity_history(related_user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_history_venue_id ON user_activity_history(venue_id);
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked_user_id ON user_blocks(blocked_user_id);
CREATE INDEX IF NOT EXISTS idx_user_gifts_item_id ON user_gifts(item_id);
CREATE INDEX IF NOT EXISTS idx_user_inventory_item_id ON user_inventory(item_id);
CREATE INDEX IF NOT EXISTS idx_user_language_preferences_language_id ON user_language_preferences(language_id);
CREATE INDEX IF NOT EXISTS idx_user_language_preferences_region_id ON user_language_preferences(region_id);
CREATE INDEX IF NOT EXISTS idx_venue_reports_resolved_by ON venue_reports(resolved_by);