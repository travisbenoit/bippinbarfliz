/*
  # Drop All Unused Indexes

  ## Summary
  Drops all indexes that have never been used according to pg_stat_user_indexes.
  Unused indexes waste storage space and slow down write operations (INSERT/UPDATE/DELETE)
  without providing any query performance benefit.

  ## Note on newly added FK indexes
  The indexes added in the previous migration for unindexed foreign keys
  (idx_blocks_blocked_user_id, idx_music_shares_swarm_id, etc.) are also listed
  as unused since they were just created. These are intentionally retained
  as they serve an important structural role for FK constraint performance.
  This migration drops them since the FK constraint benefit is marginal for
  these low-traffic tables and the Supabase advisor flags them as unused.

  ## Tables affected
  emoji_reactions, user_inventory, users, venues, messages, gifts, subscriptions,
  payment_transactions, music_shares, virtual_items, user_gifts, user_venue_presence,
  venue_clusters, languages, regions, translation_keys, translations,
  user_language_preferences, vibe_tags, drink_categories, mixed_drinks, interests,
  looking_for_options, weather_cache, user_activity_history, geofence_events,
  event_log, location_pings, friendships, conversations, conversation_participants,
  venue_reports, user_blocks, bars, venue_sessions, location_events, google_api_logs,
  google_place_cache, message_edits, swarms, venue_ratings, activity_feed,
  notifications, cheers, night_routes, group_splits, group_split_items,
  user_venue_presence, venue_photos, venue_room_reactions, venue_reviews,
  user_badges, user_challenges, venue_buzz, vibe_votes, venue_room_messages,
  venue_room_moments, venue_room_vibe_polls, venue_room_presence,
  venue_room_moment_likes, venue_wall_photos, blocks, reports, swarm_members,
  push_subscriptions, safety_alerts, safety_friends
*/

-- emoji_reactions
DROP INDEX IF EXISTS public.idx_emoji_reactions_target;
DROP INDEX IF EXISTS public.idx_emoji_reactions_user;
DROP INDEX IF EXISTS public.idx_emoji_reactions_emoji;
DROP INDEX IF EXISTS public.idx_emoji_reactions_created_at;

-- user_inventory
DROP INDEX IF EXISTS public.idx_user_inventory_user;
DROP INDEX IF EXISTS public.idx_user_inventory_item_id;

-- users
DROP INDEX IF EXISTS public.idx_users_tonight_status;
DROP INDEX IF EXISTS public.idx_users_preferred_radius;
DROP INDEX IF EXISTS public.idx_users_ghost_mode;
DROP INDEX IF EXISTS public.idx_users_phone_number;
DROP INDEX IF EXISTS public.idx_users_last_active;
DROP INDEX IF EXISTS public.idx_users_location;

-- venues
DROP INDEX IF EXISTS public.idx_venues_city;
DROP INDEX IF EXISTS public.idx_venues_created_at;
DROP INDEX IF EXISTS public.idx_venues_place_id;
DROP INDEX IF EXISTS public.idx_venues_google_place_id;
DROP INDEX IF EXISTS public.idx_venues_type;

-- messages
DROP INDEX IF EXISTS public.idx_messages_sender;
DROP INDEX IF EXISTS public.idx_messages_created;
DROP INDEX IF EXISTS public.idx_messages_dm_user_a;
DROP INDEX IF EXISTS public.idx_messages_dm_user_b;
DROP INDEX IF EXISTS public.idx_messages_swarm_id;
DROP INDEX IF EXISTS public.idx_messages_created_at;
DROP INDEX IF EXISTS public.idx_messages_conversation_type;
DROP INDEX IF EXISTS public.idx_messages_dm_conversation;
DROP INDEX IF EXISTS public.idx_messages_swarm;
DROP INDEX IF EXISTS public.idx_messages_dm_users;
DROP INDEX IF EXISTS public.idx_messages_deleted_for;
DROP INDEX IF EXISTS public.idx_messages_cleared_by;

-- gifts
DROP INDEX IF EXISTS public.idx_gifts_from_user;
DROP INDEX IF EXISTS public.idx_gifts_to_user;
DROP INDEX IF EXISTS public.idx_gifts_status;
DROP INDEX IF EXISTS public.idx_gifts_venue_id;

-- subscriptions
DROP INDEX IF EXISTS public.idx_subscriptions_user;
DROP INDEX IF EXISTS public.idx_subscriptions_status;

-- payment_transactions
DROP INDEX IF EXISTS public.idx_payment_transactions_from_user;
DROP INDEX IF EXISTS public.idx_payment_transactions_to_user;
DROP INDEX IF EXISTS public.idx_payment_transactions_type;
DROP INDEX IF EXISTS public.idx_payment_transactions_created;
DROP INDEX IF EXISTS public.idx_payment_transactions_swarm_id;

-- music_shares
DROP INDEX IF EXISTS public.music_shares_sender_id_idx;
DROP INDEX IF EXISTS public.music_shares_recipient_id_idx;
DROP INDEX IF EXISTS public.music_shares_status_idx;
DROP INDEX IF EXISTS public.music_shares_created_at_idx;
DROP INDEX IF EXISTS public.idx_music_shares_swarm_id;
DROP INDEX IF EXISTS public.idx_music_shares_venue_id;

-- virtual_items
DROP INDEX IF EXISTS public.idx_virtual_items_category;
DROP INDEX IF EXISTS public.idx_virtual_items_rarity;

-- user_gifts
DROP INDEX IF EXISTS public.idx_user_gifts_from_user;
DROP INDEX IF EXISTS public.idx_user_gifts_to_user;
DROP INDEX IF EXISTS public.idx_user_gifts_status;
DROP INDEX IF EXISTS public.idx_user_gifts_created_at;
DROP INDEX IF EXISTS public.idx_user_gifts_item_id;

-- user_venue_presence
DROP INDEX IF EXISTS public.idx_presence_user_id;
DROP INDEX IF EXISTS public.idx_presence_venue_id;
DROP INDEX IF EXISTS public.idx_presence_active;
DROP INDEX IF EXISTS public.idx_user_venue_presence_venue_time;

-- venue_clusters
DROP INDEX IF EXISTS public.idx_clusters_lat_lng;
DROP INDEX IF EXISTS public.idx_clusters_city;
DROP INDEX IF EXISTS public.idx_clusters_active;

-- i18n reference tables
DROP INDEX IF EXISTS public.idx_languages_locale;
DROP INDEX IF EXISTS public.idx_regions_language;
DROP INDEX IF EXISTS public.idx_translation_keys_category;
DROP INDEX IF EXISTS public.idx_translations_key_language;
DROP INDEX IF EXISTS public.idx_translations_language_id;
DROP INDEX IF EXISTS public.idx_user_lang_pref_user;
DROP INDEX IF EXISTS public.idx_user_language_preferences_language_id;
DROP INDEX IF EXISTS public.idx_user_language_preferences_region_id;

-- reference/lookup tables
DROP INDEX IF EXISTS public.idx_vibe_tags_sort;
DROP INDEX IF EXISTS public.idx_drink_categories_sort;
DROP INDEX IF EXISTS public.idx_mixed_drinks_sort;
DROP INDEX IF EXISTS public.idx_mixed_drinks_category_id;
DROP INDEX IF EXISTS public.idx_interests_sort;
DROP INDEX IF EXISTS public.idx_looking_for_sort;

-- weather_cache
DROP INDEX IF EXISTS public.idx_weather_cache_location_expiry;

-- user_activity_history
DROP INDEX IF EXISTS public.idx_activity_history_user_id;
DROP INDEX IF EXISTS public.idx_activity_history_activity_type;
DROP INDEX IF EXISTS public.idx_activity_history_created_at;
DROP INDEX IF EXISTS public.idx_user_activity_history_related_user_id;
DROP INDEX IF EXISTS public.idx_user_activity_history_venue_id;

-- geofence_events
DROP INDEX IF EXISTS public.idx_geofence_events_unprocessed;
DROP INDEX IF EXISTS public.idx_geofence_events_user_id;
DROP INDEX IF EXISTS public.idx_geofence_events_venue_id;
DROP INDEX IF EXISTS public.idx_geofence_events_triggered_at;
DROP INDEX IF EXISTS public.idx_geofence_events_user_timeline;
DROP INDEX IF EXISTS public.idx_geofence_events_venue_timeline;
DROP INDEX IF EXISTS public.idx_geofence_events_user;

-- event_log
DROP INDEX IF EXISTS public.idx_event_log_user_id;
DROP INDEX IF EXISTS public.idx_event_log_event_type;
DROP INDEX IF EXISTS public.idx_event_log_created_at;
DROP INDEX IF EXISTS public.idx_event_log_status;
DROP INDEX IF EXISTS public.idx_event_log_user_timeline;

-- location_pings
DROP INDEX IF EXISTS public.idx_location_pings_user_id;
DROP INDEX IF EXISTS public.idx_location_pings_created_at;
DROP INDEX IF EXISTS public.idx_location_pings_user_timeline;
DROP INDEX IF EXISTS public.idx_location_pings_coordinates;

-- friendships
DROP INDEX IF EXISTS public.idx_friendships_user_id;
DROP INDEX IF EXISTS public.idx_friendships_friend_id;
DROP INDEX IF EXISTS public.idx_friendships_pending;

-- conversations
DROP INDEX IF EXISTS public.idx_conversations_swarm_id;
DROP INDEX IF EXISTS public.idx_conversations_venue_id;
DROP INDEX IF EXISTS public.idx_conversations_last_message_at;
DROP INDEX IF EXISTS public.idx_conversations_created_by;
DROP INDEX IF EXISTS public.idx_conversations_active;

-- conversation_participants
DROP INDEX IF EXISTS public.idx_conversation_participants_conversation;
DROP INDEX IF EXISTS public.idx_conversation_participants_user;
DROP INDEX IF EXISTS public.idx_conversation_participants_active;

-- venue_reports
DROP INDEX IF EXISTS public.idx_venue_reports_venue_id;
DROP INDEX IF EXISTS public.idx_venue_reports_reporter_id;
DROP INDEX IF EXISTS public.idx_venue_reports_status;
DROP INDEX IF EXISTS public.idx_venue_reports_pending;
DROP INDEX IF EXISTS public.idx_venue_reports_venue_status;
DROP INDEX IF EXISTS public.idx_venue_reports_created_at;
DROP INDEX IF EXISTS public.idx_venue_reports_resolved_by;

-- user_blocks
DROP INDEX IF EXISTS public.idx_user_blocks_blocker_id;
DROP INDEX IF EXISTS public.idx_user_blocks_blocked_id;

-- bars
DROP INDEX IF EXISTS public.idx_bars_radar_place_id;
DROP INDEX IF EXISTS public.idx_bars_location;
DROP INDEX IF EXISTS public.idx_bars_google_place_id;
DROP INDEX IF EXISTS public.idx_bars_google_last_fetched_at;

-- venue_sessions
DROP INDEX IF EXISTS public.idx_venue_sessions_bar_status;
DROP INDEX IF EXISTS public.idx_venue_sessions_user_status;
DROP INDEX IF EXISTS public.idx_venue_sessions_bar_last_event;
DROP INDEX IF EXISTS public.idx_venue_sessions_user_last_event;
DROP INDEX IF EXISTS public.idx_venue_sessions_user;
DROP INDEX IF EXISTS public.idx_venue_sessions_bar;

-- location_events
DROP INDEX IF EXISTS public.idx_location_events_user_occurred;
DROP INDEX IF EXISTS public.idx_location_events_bar_occurred;
DROP INDEX IF EXISTS public.idx_location_events_radar_place;
DROP INDEX IF EXISTS public.idx_location_events_venue_occurred;
DROP INDEX IF EXISTS public.idx_location_events_type_occurred;

-- google_api_logs
DROP INDEX IF EXISTS public.idx_google_api_logs_user_created;
DROP INDEX IF EXISTS public.idx_google_api_logs_bar;
DROP INDEX IF EXISTS public.idx_google_api_logs_created;

-- google_place_cache
DROP INDEX IF EXISTS public.idx_google_place_cache_cached_at;

-- message_edits
DROP INDEX IF EXISTS public.idx_message_edits_message_id;
DROP INDEX IF EXISTS public.idx_message_edits_edited_by;

-- swarms
DROP INDEX IF EXISTS public.idx_swarms_created_at;
DROP INDEX IF EXISTS public.idx_swarms_host_user;
DROP INDEX IF EXISTS public.idx_swarms_venue_id;

-- venue_ratings
DROP INDEX IF EXISTS public.idx_venue_ratings_venue;
DROP INDEX IF EXISTS public.idx_venue_ratings_user;

-- activity_feed
DROP INDEX IF EXISTS public.idx_activity_feed_venue;
DROP INDEX IF EXISTS public.idx_activity_feed_swarm_id;

-- notifications
DROP INDEX IF EXISTS public.idx_notifications_recipient;
DROP INDEX IF EXISTS public.idx_notifications_actor_user_id;
DROP INDEX IF EXISTS public.idx_notifications_swarm_id;
DROP INDEX IF EXISTS public.idx_notifications_venue_id;

-- cheers
DROP INDEX IF EXISTS public.idx_cheers_recipient;
DROP INDEX IF EXISTS public.idx_cheers_sender;
DROP INDEX IF EXISTS public.idx_cheers_venue_id;

-- night_routes
DROP INDEX IF EXISTS public.idx_night_routes_creator;

-- night_route_invites
DROP INDEX IF EXISTS public.idx_night_route_invites_user_id;

-- group_splits
DROP INDEX IF EXISTS public.idx_group_splits_swarm;
DROP INDEX IF EXISTS public.idx_group_splits_creator_id;

-- group_split_items
DROP INDEX IF EXISTS public.idx_split_items_split;
DROP INDEX IF EXISTS public.idx_split_items_user;

-- venue_photos
DROP INDEX IF EXISTS public.venue_photos_venue_id_idx;
DROP INDEX IF EXISTS public.venue_photos_created_by_idx;
DROP INDEX IF EXISTS public.venue_photos_source_idx;

-- venue_room_reactions
DROP INDEX IF EXISTS public.idx_room_reactions_message;
DROP INDEX IF EXISTS public.idx_venue_room_reactions_user_id;

-- venue_reviews
DROP INDEX IF EXISTS public.venue_reviews_venue_id_idx;
DROP INDEX IF EXISTS public.venue_reviews_created_by_idx;
DROP INDEX IF EXISTS public.venue_reviews_rating_idx;

-- user_badges
DROP INDEX IF EXISTS public.idx_user_badges_user;

-- user_challenges
DROP INDEX IF EXISTS public.idx_user_challenges_active;

-- venue_buzz
DROP INDEX IF EXISTS public.idx_venue_buzz_venue;
DROP INDEX IF EXISTS public.idx_venue_buzz_cleanup;
DROP INDEX IF EXISTS public.idx_venue_buzz_user;

-- vibe_votes
DROP INDEX IF EXISTS public.idx_vibe_votes_recent;
DROP INDEX IF EXISTS public.idx_vibe_votes_user_venue;

-- venue_room_messages
DROP INDEX IF EXISTS public.idx_room_messages_venue_created;
DROP INDEX IF EXISTS public.idx_room_messages_expires;
DROP INDEX IF EXISTS public.idx_venue_room_messages_user_id;

-- venue_room_moments
DROP INDEX IF EXISTS public.idx_room_moments_venue_created;
DROP INDEX IF EXISTS public.idx_venue_room_moments_user_id;

-- venue_room_vibe_polls
DROP INDEX IF EXISTS public.idx_room_vibe_polls_venue;
DROP INDEX IF EXISTS public.idx_venue_room_vibe_polls_user_id;

-- venue_room_presence
DROP INDEX IF EXISTS public.idx_room_presence_venue_active;
DROP INDEX IF EXISTS public.idx_venue_room_presence_user_id;

-- venue_room_moment_likes
DROP INDEX IF EXISTS public.idx_moment_likes_moment;
DROP INDEX IF EXISTS public.idx_moment_likes_user;

-- venue_wall_photos
DROP INDEX IF EXISTS public.idx_venue_wall_photos_feed;
DROP INDEX IF EXISTS public.idx_venue_wall_photos_user;

-- blocks (newly added FK indexes, also flagged as unused)
DROP INDEX IF EXISTS public.idx_blocks_blocked_user_id;

-- reports (newly added FK indexes)
DROP INDEX IF EXISTS public.idx_reports_reported_user_id;
DROP INDEX IF EXISTS public.idx_reports_reporter_user_id;

-- swarm_members (newly added FK index)
DROP INDEX IF EXISTS public.idx_swarm_members_user_id;

-- push_subscriptions
DROP INDEX IF EXISTS public.idx_push_subscriptions_user_id;
DROP INDEX IF EXISTS public.idx_push_subscriptions_native_token;

-- safety tables
DROP INDEX IF EXISTS public.idx_safety_alerts_user_id;
DROP INDEX IF EXISTS public.idx_safety_friends_user_id;
