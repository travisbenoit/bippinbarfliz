# Barfliz Database Architecture

## Overview

**Database**: Supabase PostgreSQL
**Security**: Row Level Security (RLS) on all tables
**Real-time**: Subscriptions enabled via Supabase Realtime
**Location**: PostGIS extension for geographic queries

---

## Table of Contents

1. [Core User Tables](#1-core-user-tables)
2. [Venue & Location Tables](#2-venue--location-tables)
3. [Social & Relationships](#3-social--relationships)
4. [Messaging & Communication](#4-messaging--communication)
5. [Activity & Events](#5-activity--events)
6. [Payments & Transactions](#6-payments--transactions)
7. [Safety & Security](#7-safety--security)
8. [Content & Media](#8-content--media)
9. [Internationalization](#9-internationalization)
10. [Reference Data](#10-reference-data)
11. [Analytics & Logging](#11-analytics--logging)
12. [Storage Buckets](#12-storage-buckets)
13. [Indexes & Performance](#13-indexes--performance)
14. [Security Policies](#14-security-policies)

---

## 1. Core User Tables

### `users` (Profile & Settings)

Primary user profile and preferences table.

```sql
users
├── id (uuid, PK) - References auth.users
├── email (text)
├── phone_number (text)
├── phone_country_code (text) - E.164 format
├── phone_verified (boolean)
├── full_name (text)
├── display_name (text)
├── avatar_url (text)
├── birthday (date)
├── age_verified (boolean)
├── country (text) - ISO 3166-1 alpha-2
├── timezone (text) - IANA timezone
├── language_code (text, FK → languages)
├── preferred_units (text) - 'metric' | 'imperial'
├── preferred_temperature (text) - 'celsius' | 'fahrenheit'
├── preferred_time_format (text) - '12h' | '24h'
├── bio (text)
├── instagram_handle (text)
├── preferred_drinks (text[])
├── payment_provider (text) - 'venmo' | 'payid' | etc.
├── payment_username (text)
├── venmo_username (text)
├── default_radius_km (numeric) - Search radius preference
├── ghost_mode (boolean) - Hide from others
├── is_premium (boolean)
├── premium_expires_at (timestamptz)
├── last_seen_at (timestamptz)
├── current_location (geography(Point)) - PostGIS
├── current_venue_id (uuid, FK → bars)
├── tonight_status (text) - 'out' | 'home' | 'maybe'
├── tonight_status_text (text)
├── tonight_status_updated_at (timestamptz)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

**Indexes**
- `idx_users_country` on `country`
- `idx_users_current_location` (GIST) on `current_location`
- `idx_users_current_venue_id` on `current_venue_id`
- `idx_users_tonight_status` on `tonight_status`

**RLS Policies**
- Users can read their own profile
- Users can read profiles of non-blocked friends
- Users can update their own profile
- Public profiles visible to authenticated users (limited fields)

**Triggers**
- `auto_create_user_profile` - Creates profile on auth signup
- Updates `updated_at` on modification

---

## 2. Venue & Location Tables

### `bars` (Venues)

All venue locations (bars, clubs, lounges, etc.)

```sql
bars
├── id (uuid, PK)
├── name (text, required)
├── address (text)
├── city (text)
├── region (text) - State/province
├── country (text) - ISO 3166-1 alpha-2
├── postal_code (text)
├── latitude (numeric, required)
├── longitude (numeric, required)
├── location (geography(Point)) - PostGIS
├── venue_type (text) - 'bar' | 'nightclub' | 'lounge' | 'pub' | etc.
├── geofence_radius_meters (numeric) - Default 50
├── google_place_id (text, unique) - Google Places reference
├── google_name (text)
├── google_address (text)
├── google_rating (numeric)
├── google_user_ratings_total (integer)
├── google_price_level (integer) - 0-4
├── google_phone_number (text)
├── google_website (text)
├── google_opening_hours (jsonb)
├── google_photos (jsonb[]) - Array of photo references
├── google_types (text[]) - Place types from Google
├── google_business_status (text)
├── google_last_fetched_at (timestamptz)
├── osm_id (text) - OpenStreetMap ID
├── osm_type (text) - 'node' | 'way' | 'relation'
├── is_active (boolean) - Visible to users
├── is_verified (boolean) - Manually verified
├── description (text)
├── hours_of_operation (jsonb)
├── photo_urls (text[])
├── demo_people_count (integer) - Demo/testing purposes
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

**Indexes**
- `idx_bars_location` (GIST) on `location`
- `idx_bars_country` on `country`
- `idx_bars_city` on `city`
- `idx_bars_venue_type` on `venue_type`
- `idx_bars_is_active` on `is_active`
- `idx_bars_google_place_id` on `google_place_id`

**RLS Policies**
- All authenticated users can read active venues
- Only admins can insert/update/delete venues

### `venue_sessions`

Tracks user presence at venues.

```sql
venue_sessions
├── id (uuid, PK)
├── user_id (uuid, FK → users, required)
├── venue_id (uuid, FK → bars, required)
├── entered_at (timestamptz, required)
├── exited_at (timestamptz) - null = still present
├── duration_minutes (integer) - Calculated on exit
├── session_type (text) - 'automatic' | 'manual' | 'checkin'
├── is_visible (boolean) - User privacy setting
└── created_at (timestamptz)
```

**Indexes**
- `idx_venue_sessions_user_id` on `user_id`
- `idx_venue_sessions_venue_id` on `venue_id`
- `idx_venue_sessions_entered_at` on `entered_at`
- `idx_venue_sessions_active` on `(user_id, venue_id)` WHERE `exited_at IS NULL`

**RLS Policies**
- Users can read their own sessions
- Users can read friends' sessions (if visible)
- Users can create/update their own sessions

### `user_venue_presence`

Current real-time presence at venues (denormalized for performance).

```sql
user_venue_presence
├── user_id (uuid, PK, FK → users)
├── venue_id (uuid, FK → bars)
├── entered_at (timestamptz)
├── is_visible (boolean)
└── updated_at (timestamptz)
```

**Indexes**
- `idx_user_venue_presence_venue_id` on `venue_id`

**RLS Policies**
- Users can read presence of non-blocked friends
- Users can update their own presence

### `location_pings`

Historical location tracking for users.

```sql
location_pings
├── id (uuid, PK)
├── user_id (uuid, FK → users, required)
├── location (geography(Point), required)
├── latitude (numeric)
├── longitude (numeric)
├── accuracy_meters (numeric)
├── heading (numeric) - Compass direction
├── speed_mps (numeric) - Meters per second
├── altitude_meters (numeric)
├── source (text) - 'gps' | 'network' | 'manual'
├── battery_level (numeric)
└── created_at (timestamptz)
```

**Indexes**
- `idx_location_pings_user_id` on `user_id`
- `idx_location_pings_created_at` on `created_at`
- `idx_location_pings_location` (GIST) on `location`

**RLS Policies**
- Users can only read their own location pings
- Users can insert their own location pings

**Retention**: Automatic cleanup of pings older than 30 days

### `location_events`

Geofence entry/exit events and location-based triggers.

```sql
location_events
├── id (uuid, PK)
├── user_id (uuid, FK → users, required)
├── event_type (text) - 'venue_entry' | 'venue_exit' | 'geofence_enter' | etc.
├── venue_id (uuid, FK → bars)
├── location (geography(Point))
├── metadata (jsonb) - Additional event data
├── source (text) - 'radar' | 'manual' | 'system'
└── created_at (timestamptz)
```

**Indexes**
- `idx_location_events_user_id` on `user_id`
- `idx_location_events_venue_id` on `venue_id`
- `idx_location_events_created_at` on `created_at`
- `idx_location_events_type` on `event_type`

**RLS Policies**
- Users can read their own events
- System can insert events for any user

### `geofence_events`

Radar-specific geofence events (separate from location_events for API integration).

```sql
geofence_events
├── id (uuid, PK)
├── user_id (uuid, FK → users, required)
├── radar_geofence_id (text) - Radar's geofence ID
├── venue_id (uuid, FK → bars)
├── event_type (text) - 'entered' | 'exited' | 'dwelled'
├── confidence (numeric) - 0-1 confidence score
├── location (geography(Point))
├── radar_payload (jsonb) - Full webhook payload
└── created_at (timestamptz)
```

**Indexes**
- `idx_geofence_events_user_id` on `user_id`
- `idx_geofence_events_venue_id` on `venue_id`

**RLS Policies**
- Users can read their own geofence events
- System can insert events

---

## 3. Social & Relationships

### `friendships`

Bidirectional friend connections.

```sql
friendships
├── id (uuid, PK)
├── user_id (uuid, FK → users, required)
├── friend_id (uuid, FK → users, required)
├── status (text) - 'pending' | 'accepted' | 'declined'
├── requested_at (timestamptz)
├── accepted_at (timestamptz)
├── declined_at (timestamptz)
└── created_at (timestamptz)
```

**Constraints**
- Unique `(user_id, friend_id)`
- Check: `user_id != friend_id`

**Indexes**
- `idx_friendships_user_id` on `user_id`
- `idx_friendships_friend_id` on `friend_id`
- `idx_friendships_status` on `status`

**RLS Policies**
- Users can read friendships where they are user_id or friend_id
- Users can create friendship requests
- Users can update friendships where they are involved

### `user_blocks`

User blocking for safety and privacy.

```sql
user_blocks
├── id (uuid, PK)
├── blocker_id (uuid, FK → users, required) - User doing the blocking
├── blocked_id (uuid, FK → users, required) - User being blocked
└── created_at (timestamptz)
```

**Constraints**
- Unique `(blocker_id, blocked_id)`
- Check: `blocker_id != blocked_id`

**Indexes**
- `idx_user_blocks_blocker_id` on `blocker_id`
- `idx_user_blocks_blocked_id` on `blocked_id`

**RLS Policies**
- Users can only read their own blocks (where they are blocker)
- Users can insert/delete their own blocks
- Blocking is enforced in all other table policies

### `swarms`

Group meetup plans and events.

```sql
swarms
├── id (uuid, PK)
├── name (text, required)
├── description (text)
├── creator_id (uuid, FK → users, required)
├── venue_id (uuid, FK → bars)
├── venue_name (text) - Denormalized for display
├── scheduled_date (date)
├── scheduled_time (time)
├── scheduled_datetime (timestamptz) - Computed
├── is_public (boolean) - Discoverable by others
├── is_active (boolean)
├── max_participants (integer)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

**Indexes**
- `idx_swarms_creator_id` on `creator_id`
- `idx_swarms_venue_id` on `venue_id`
- `idx_swarms_scheduled_datetime` on `scheduled_datetime`
- `idx_swarms_is_public` on `is_public` WHERE `is_active = true`

**RLS Policies**
- Users can read their own swarms
- Users can read public swarms
- Users can read swarms they're invited to
- Creator can update/delete their swarms

### `swarm_participants`

Swarm RSVP tracking.

```sql
swarm_participants
├── id (uuid, PK)
├── swarm_id (uuid, FK → swarms, required)
├── user_id (uuid, FK → users, required)
├── status (text) - 'invited' | 'going' | 'maybe' | 'declined'
├── invited_at (timestamptz)
├── responded_at (timestamptz)
└── created_at (timestamptz)
```

**Constraints**
- Unique `(swarm_id, user_id)`

**Indexes**
- `idx_swarm_participants_swarm_id` on `swarm_id`
- `idx_swarm_participants_user_id` on `user_id`
- `idx_swarm_participants_status` on `status`

**RLS Policies**
- Users can read participants of swarms they have access to
- Users can update their own participation status

---

## 4. Messaging & Communication

### `conversations`

Message thread containers (DM or group).

```sql
conversations
├── id (uuid, PK)
├── conversation_type (text) - 'direct' | 'group' | 'swarm'
├── swarm_id (uuid, FK → swarms) - If type = 'swarm'
├── name (text) - For group chats
├── created_by (uuid, FK → users)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

**Indexes**
- `idx_conversations_swarm_id` on `swarm_id`
- `idx_conversations_created_by` on `created_by`

**RLS Policies**
- Users can read conversations they are participants in
- Users can create conversations
- Users can update conversations they created

### `conversation_participants`

Who is in each conversation.

```sql
conversation_participants
├── id (uuid, PK)
├── conversation_id (uuid, FK → conversations, required)
├── user_id (uuid, FK → users, required)
├── joined_at (timestamptz)
├── left_at (timestamptz) - null = still in conversation
├── is_muted (boolean)
├── last_read_at (timestamptz)
└── created_at (timestamptz)
```

**Constraints**
- Unique `(conversation_id, user_id)`

**Indexes**
- `idx_conversation_participants_conversation_id` on `conversation_id`
- `idx_conversation_participants_user_id` on `user_id`
- `idx_conversation_participants_active` WHERE `left_at IS NULL`

**RLS Policies**
- Users can read participants of their conversations
- Users can insert themselves as participants
- Users can update their own participation (mute, last_read)

### `messages`

Individual messages in conversations.

```sql
messages
├── id (uuid, PK)
├── conversation_id (uuid, FK → conversations, required)
├── sender_id (uuid, FK → users, required)
├── content (text)
├── message_type (text) - 'text' | 'photo' | 'music' | 'gift' | 'system'
├── media_url (text) - Photo URL if type = 'photo'
├── metadata (jsonb) - Additional data (music track, gift info)
├── is_deleted (boolean) - Soft delete
├── deleted_at (timestamptz)
├── edited_at (timestamptz)
├── read_by (uuid[]) - Array of user IDs who read
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

**Indexes**
- `idx_messages_conversation_id` on `conversation_id`
- `idx_messages_sender_id` on `sender_id`
- `idx_messages_created_at` on `created_at`
- `idx_messages_active` WHERE `is_deleted = false`

**RLS Policies**
- Users can read messages in conversations they participate in
- Users cannot read messages from users who blocked them
- Users can insert messages in conversations they participate in
- Users can update their own messages (edit, delete)
- Users can update read_by array to mark as read

**Triggers**
- `notify_new_message` - Creates notification on insert

### `message_reads`

Track individual message read receipts (alternative to read_by array).

```sql
message_reads
├── id (uuid, PK)
├── message_id (uuid, FK → messages, required)
├── user_id (uuid, FK → users, required)
└── read_at (timestamptz)
```

**Constraints**
- Unique `(message_id, user_id)`

**Indexes**
- `idx_message_reads_message_id` on `message_id`
- `idx_message_reads_user_id` on `user_id`

---

## 5. Activity & Events

### `activities`

Social activity feed (check-ins, swarms joined, friendships).

```sql
activities
├── id (uuid, PK)
├── user_id (uuid, FK → users, required)
├── activity_type (text) - 'venue_checkin' | 'swarm_created' | 'friend_added' | etc.
├── venue_id (uuid, FK → bars)
├── swarm_id (uuid, FK → swarms)
├── friend_id (uuid, FK → users)
├── description (text)
├── metadata (jsonb)
├── is_visible (boolean) - User privacy setting
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

**Indexes**
- `idx_activities_user_id` on `user_id`
- `idx_activities_created_at` on `created_at`
- `idx_activities_type` on `activity_type`
- `idx_activities_venue_id` on `venue_id`

**RLS Policies**
- Users can read their own activities
- Users can read visible activities of friends
- Users can create their own activities

### `user_activity_history`

Long-term analytics and history tracking.

```sql
user_activity_history
├── id (uuid, PK)
├── user_id (uuid, FK → users, required)
├── activity_date (date)
├── venues_visited (uuid[]) - Array of venue IDs
├── friends_met (uuid[]) - Array of user IDs
├── swarms_attended (uuid[]) - Array of swarm IDs
├── total_duration_minutes (integer)
├── start_time (timestamptz)
├── end_time (timestamptz)
└── created_at (timestamptz)
```

**Indexes**
- `idx_user_activity_history_user_id` on `user_id`
- `idx_user_activity_history_date` on `activity_date`

### `notifications`

System and social notifications.

```sql
notifications
├── id (uuid, PK)
├── user_id (uuid, FK → users, required) - Recipient
├── notification_type (text) - 'friend_request' | 'message' | 'swarm_invite' | etc.
├── title (text)
├── body (text)
├── data (jsonb) - Structured notification data
├── is_read (boolean)
├── read_at (timestamptz)
├── sender_id (uuid, FK → users) - Who triggered it
├── related_id (uuid) - ID of related entity (message, swarm, etc.)
├── related_type (text) - Type of related entity
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

**Indexes**
- `idx_notifications_user_id` on `user_id`
- `idx_notifications_created_at` on `created_at`
- `idx_notifications_is_read` on `is_read`
- `idx_notifications_type` on `notification_type`

**RLS Policies**
- Users can read their own notifications
- Users can update their own notifications (mark as read)

### `emoji_reactions`

Quick emoji reactions to activities and content.

```sql
emoji_reactions
├── id (uuid, PK)
├── user_id (uuid, FK → users, required)
├── target_type (text) - 'activity' | 'message' | 'swarm' | 'venue_session'
├── target_id (uuid, required)
├── emoji (text, required) - Unicode emoji
└── created_at (timestamptz)
```

**Constraints**
- Unique `(user_id, target_type, target_id, emoji)`

**Indexes**
- `idx_emoji_reactions_target` on `(target_type, target_id)`
- `idx_emoji_reactions_user_id` on `user_id`

---

## 6. Payments & Transactions

### `transactions`

Payment history between users.

```sql
transactions
├── id (uuid, PK)
├── sender_id (uuid, FK → users, required)
├── recipient_id (uuid, FK → users, required)
├── amount (numeric, required)
├── currency (text) - 'USD', 'EUR', 'AUD', etc.
├── payment_provider (text) - 'venmo', 'payid', etc.
├── provider_transaction_id (text) - External reference
├── transaction_type (text) - 'send' | 'request' | 'split'
├── status (text) - 'pending' | 'completed' | 'failed' | 'cancelled'
├── description (text)
├── swarm_id (uuid, FK → swarms) - If bill split for swarm
├── metadata (jsonb)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

**Indexes**
- `idx_transactions_sender_id` on `sender_id`
- `idx_transactions_recipient_id` on `recipient_id`
- `idx_transactions_swarm_id` on `swarm_id`
- `idx_transactions_status` on `status`
- `idx_transactions_created_at` on `created_at`

**RLS Policies**
- Users can read transactions where they are sender or recipient
- Users can create transactions where they are sender
- Users can update their own transaction statuses

---

## 7. Safety & Security

### `emergency_contacts`

User-designated emergency contacts.

```sql
emergency_contacts
├── id (uuid, PK)
├── user_id (uuid, FK → users, required)
├── name (text, required)
├── phone_number (text, required)
├── relationship (text) - 'friend', 'family', 'partner', etc.
├── is_primary (boolean)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

**Indexes**
- `idx_emergency_contacts_user_id` on `user_id`

**RLS Policies**
- Users can only access their own emergency contacts

### `safe_arrival_checks`

Safety check-ins and arrivals.

```sql
safe_arrival_checks
├── id (uuid, PK)
├── user_id (uuid, FK → users, required)
├── check_type (text) - 'arrival' | 'periodic' | 'emergency'
├── location (geography(Point))
├── venue_id (uuid, FK → bars)
├── status (text) - 'scheduled' | 'confirmed' | 'missed' | 'alert'
├── scheduled_time (timestamptz)
├── confirmed_time (timestamptz)
├── alert_contacts (boolean) - Whether to notify emergency contacts
└── created_at (timestamptz)
```

**Indexes**
- `idx_safe_arrival_checks_user_id` on `user_id`
- `idx_safe_arrival_checks_scheduled_time` on `scheduled_time`
- `idx_safe_arrival_checks_status` on `status`

**RLS Policies**
- Users can only access their own safety checks

### `venue_reports`

User reports of issues with venues or content.

```sql
venue_reports
├── id (uuid, PK)
├── reporter_id (uuid, FK → users, required)
├── venue_id (uuid, FK → bars)
├── report_type (text) - 'incorrect_info' | 'closed' | 'unsafe' | 'inappropriate'
├── description (text)
├── status (text) - 'pending' | 'reviewed' | 'resolved' | 'dismissed'
├── reviewed_by (uuid, FK → users) - Admin
├── reviewed_at (timestamptz)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

**Indexes**
- `idx_venue_reports_venue_id` on `venue_id`
- `idx_venue_reports_status` on `status`
- `idx_venue_reports_reporter_id` on `reporter_id`

**RLS Policies**
- Users can create reports
- Users can read their own reports
- Admins can read all reports

### `user_reports`

Reports of problematic user behavior.

```sql
user_reports
├── id (uuid, PK)
├── reporter_id (uuid, FK → users, required)
├── reported_user_id (uuid, FK → users, required)
├── report_type (text) - 'harassment' | 'spam' | 'inappropriate' | 'fake'
├── description (text)
├── evidence_urls (text[]) - Screenshots, etc.
├── status (text) - 'pending' | 'reviewed' | 'action_taken' | 'dismissed'
├── reviewed_by (uuid, FK → users)
├── action_taken (text)
├── reviewed_at (timestamptz)
└── created_at (timestamptz)
```

**Indexes**
- `idx_user_reports_reported_user_id` on `reported_user_id`
- `idx_user_reports_status` on `status`

**RLS Policies**
- Users can create reports
- Users can read their own reports (as reporter)
- Admins can read all reports

---

## 8. Content & Media

### `music_shares`

Spotify track sharing between users.

```sql
music_shares
├── id (uuid, PK)
├── sender_id (uuid, FK → users, required)
├── recipient_id (uuid, FK → users)
├── conversation_id (uuid, FK → conversations)
├── spotify_track_id (text, required)
├── track_name (text)
├── artist_name (text)
├── album_name (text)
├── preview_url (text)
├── album_art_url (text)
├── is_public (boolean) - Share on profile
└── created_at (timestamptz)
```

**Indexes**
- `idx_music_shares_sender_id` on `sender_id`
- `idx_music_shares_recipient_id` on `recipient_id`
- `idx_music_shares_conversation_id` on `conversation_id`
- `idx_music_shares_is_public` WHERE `is_public = true`

**RLS Policies**
- Users can read their own music shares
- Users can read public music shares
- Users can read shares in conversations they participate in

### `gifts`

Virtual gifts sent between users.

```sql
gifts
├── id (uuid, PK)
├── sender_id (uuid, FK → users, required)
├── recipient_id (uuid, FK → users, required)
├── gift_type (text) - 'drink' | 'emoji' | 'badge' | 'premium'
├── gift_id (text) - Reference to virtual item
├── message (text)
├── is_opened (boolean)
├── opened_at (timestamptz)
├── cost_credits (integer) - Virtual currency
├── cost_usd (numeric) - Real money equivalent
└── created_at (timestamptz)
```

**Indexes**
- `idx_gifts_sender_id` on `sender_id`
- `idx_gifts_recipient_id` on `recipient_id`
- `idx_gifts_is_opened` on `is_opened`

**RLS Policies**
- Users can read gifts they sent
- Users can read gifts they received
- Users can update received gifts (mark as opened)

### `virtual_items`

Catalog of virtual items (drinks, emojis, etc.).

```sql
virtual_items
├── id (uuid, PK)
├── item_type (text) - 'drink' | 'emoji' | 'badge'
├── name (text, required)
├── description (text)
├── icon_url (text)
├── rarity (text) - 'common' | 'rare' | 'legendary'
├── cost_credits (integer)
├── cost_usd (numeric)
├── is_active (boolean)
├── created_at (timestamptz)
└── updated_at (timestamptz)
```

**Indexes**
- `idx_virtual_items_type` on `item_type`
- `idx_virtual_items_is_active` on `is_active`

**RLS Policies**
- All authenticated users can read active items

---

## 9. Internationalization

### `languages`

Supported languages.

```sql
languages
├── code (text, PK) - ISO 639-1 (e.g., 'en', 'es')
├── name (text) - English name
├── native_name (text) - Native name
├── is_active (boolean)
└── created_at (timestamptz)
```

**RLS Policies**
- Public read access

### `translation_keys`

All translatable strings in the app.

```sql
translation_keys
├── id (uuid, PK)
├── key (text, unique, required) - Dot-notation key (e.g., 'home.welcome')
├── context (text) - Where it's used
├── description (text) - What it means
└── created_at (timestamptz)
```

**RLS Policies**
- Public read access

### `translations`

Actual translations for each key.

```sql
translations
├── id (uuid, PK)
├── translation_key_id (uuid, FK → translation_keys, required)
├── language_code (text, FK → languages, required)
├── value (text, required) - Translated string
├── updated_at (timestamptz)
└── created_at (timestamptz)
```

**Constraints**
- Unique `(translation_key_id, language_code)`

**Indexes**
- `idx_translations_key_language` on `(translation_key_id, language_code)`
- `idx_translations_language_code` on `language_code`

**RLS Policies**
- Public read access

---

## 10. Reference Data

### `countries`

Supported countries with settings.

```sql
countries
├── code (text, PK) - ISO 3166-1 alpha-2
├── name (text, required)
├── drinking_age (integer, required)
├── default_units (text) - 'metric' | 'imperial'
├── default_temperature (text) - 'celsius' | 'fahrenheit'
├── default_time_format (text) - '12h' | '24h'
├── currency_code (text) - ISO 4217
├── phone_code (text) - E.164 prefix (e.g., '+1')
├── emergency_number (text) - Primary emergency number
├── timezone (text) - Primary timezone
├── is_active (boolean)
└── created_at (timestamptz)
```

**RLS Policies**
- Public read access

### `emergency_numbers`

Country-specific emergency contact numbers.

```sql
emergency_numbers
├── id (uuid, PK)
├── country_code (text, FK → countries, required)
├── service_type (text) - 'police' | 'medical' | 'fire' | 'general'
├── number (text, required)
├── name (text) - Service name
└── created_at (timestamptz)
```

**Indexes**
- `idx_emergency_numbers_country_code` on `country_code`

**RLS Policies**
- Public read access

### `drink_types`

Reference data for drink preferences.

```sql
drink_types
├── id (uuid, PK)
├── name (text, required)
├── category (text) - 'beer' | 'wine' | 'cocktail' | 'spirits' | 'non-alcoholic'
├── icon (text) - Icon name or URL
├── is_active (boolean)
└── created_at (timestamptz)
```

**RLS Policies**
- Public read access

---

## 11. Analytics & Logging

### `event_log`

General event tracking for analytics.

```sql
event_log
├── id (uuid, PK)
├── user_id (uuid, FK → users)
├── event_type (text) - 'page_view' | 'button_click' | 'feature_used'
├── event_name (text)
├── properties (jsonb)
├── session_id (text)
└── created_at (timestamptz)
```

**Indexes**
- `idx_event_log_user_id` on `user_id`
- `idx_event_log_event_type` on `event_type`
- `idx_event_log_created_at` on `created_at`

**Retention**: Aggregated monthly, raw data deleted after 90 days

### `google_api_logs`

Google Places API usage tracking.

```sql
google_api_logs
├── id (uuid, PK)
├── api_endpoint (text) - 'place_details' | 'place_photo' | 'nearby_search'
├── place_id (text)
├── request_params (jsonb)
├── response_status (text)
├── response_data (jsonb)
├── error_message (text)
├── execution_time_ms (integer)
└── created_at (timestamptz)
```

**Indexes**
- `idx_google_api_logs_endpoint` on `api_endpoint`
- `idx_google_api_logs_created_at` on `created_at`
- `idx_google_api_logs_place_id` on `place_id`

### `google_place_cache`

Cached Google Places responses.

```sql
google_place_cache
├── place_id (text, PK)
├── details (jsonb) - Full place details response
├── photos (jsonb[]) - Photo metadata
├── fetched_at (timestamptz)
└── expires_at (timestamptz)
```

**Indexes**
- `idx_google_place_cache_expires_at` on `expires_at`

**RLS Policies**
- System access only

### `weather_cache`

Cached weather data by location.

```sql
weather_cache
├── id (uuid, PK)
├── city (text, required)
├── country_code (text, required)
├── latitude (numeric)
├── longitude (numeric)
├── weather_data (jsonb) - OpenWeatherMap response
├── temperature_celsius (numeric)
├── condition (text)
├── fetched_at (timestamptz)
└── expires_at (timestamptz)
```

**Constraints**
- Unique `(city, country_code)`

**Indexes**
- `idx_weather_cache_expires_at` on `expires_at`
- `idx_weather_cache_location` on `(city, country_code)`

---

## 12. Storage Buckets

Supabase Storage buckets for media files.

### `profiles`
- **Purpose**: User avatar images
- **Public**: Yes (read), authenticated (write)
- **Path**: `{user_id}/avatar.{ext}`
- **Max Size**: 5MB
- **Allowed Types**: image/jpeg, image/png, image/webp

**RLS Policies**
- Anyone can view
- Users can upload to their own folder only
- Users can update/delete their own files

### `venue-photos`
- **Purpose**: Venue photos
- **Public**: Yes (read), admin (write)
- **Path**: `{venue_id}/{photo_id}.{ext}`
- **Max Size**: 10MB
- **Allowed Types**: image/jpeg, image/png, image/webp

### `message-media`
- **Purpose**: Photos sent in messages
- **Public**: No
- **Path**: `{conversation_id}/{message_id}.{ext}`
- **Max Size**: 10MB
- **Allowed Types**: image/jpeg, image/png, image/webp

**RLS Policies**
- Only conversation participants can access
- Authenticated users can upload
- Sender can delete

---

## 13. Indexes & Performance

### Critical Indexes

**Geographic Queries**
- GIST indexes on all `geography(Point)` columns
- Enables fast proximity searches

**Foreign Keys**
- All foreign key columns indexed
- Prevents slow joins and cascades

**Composite Indexes**
- `(user_id, created_at)` on activity tables
- `(venue_id, entered_at)` on sessions
- `(conversation_id, created_at)` on messages

**Partial Indexes**
- Active records: WHERE `is_active = true`
- Unread: WHERE `is_read = false`
- Current sessions: WHERE `exited_at IS NULL`

### Query Optimization

**Materialized Views** (Future)
- Popular venues by region
- User statistics
- Trending swarms

**Denormalization**
- `venue_name` in swarms (avoid join)
- `demo_people_count` in bars (testing)
- `current_venue_id` in users (fast lookup)

---

## 14. Security Policies

### Row Level Security (RLS) Principles

**1. Default Deny**
- All tables have RLS enabled
- No access unless explicitly granted

**2. User Isolation**
- Users can only access their own data by default
- Friends' data visible with explicit policy

**3. Blocking Enforcement**
- All read policies check `user_blocks` table
- Blocked users are invisible in all queries

**4. Ghost Mode**
- Location queries respect `ghost_mode` flag
- Ghost users hidden from proximity searches

**5. Privacy Layers**
- Session visibility controlled by `is_visible`
- Activity visibility controlled by user settings
- Conversation privacy by participant list

### Example RLS Patterns

**Own Data Access**
```sql
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);
```

**Friend Data Access**
```sql
CREATE POLICY "Users can view friends' profiles"
  ON users FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT friend_id FROM friendships
      WHERE user_id = auth.uid()
      AND status = 'accepted'
    )
    AND NOT EXISTS (
      SELECT 1 FROM user_blocks
      WHERE blocker_id = id
      AND blocked_id = auth.uid()
    )
  );
```

**Privacy-Filtered Location**
```sql
CREATE POLICY "View non-ghost friends' presence"
  ON user_venue_presence FOR SELECT
  TO authenticated
  USING (
    user_id IN (
      SELECT friend_id FROM friendships
      WHERE user_id = auth.uid()
      AND status = 'accepted'
    )
    AND is_visible = true
    AND NOT EXISTS (
      SELECT 1 FROM users
      WHERE id = user_venue_presence.user_id
      AND ghost_mode = true
    )
  );
```

---

## 15. Data Retention & Cleanup

### Automatic Cleanup

**Location Pings**: 30 days
- Background job deletes old pings
- Preserves privacy and reduces storage

**Event Log**: 90 days raw, permanent aggregated
- Analytics aggregated monthly
- Raw events deleted after 90 days

**Weather Cache**: 1 hour
- Automatic expiry on `expires_at`
- Re-fetch on next request

**Google Place Cache**: 24 hours
- Business info can change frequently
- Automatic refresh after expiry

### User Data Export

Users can request full data export:
- Profile information
- Location history
- Messages (sent)
- Transactions
- Activity history

### Account Deletion

Soft delete with cleanup:
1. Mark user as deleted
2. Remove from public searches
3. Anonymize messages (7 days)
4. Delete location data (immediate)
5. Remove profile data (30 days)
6. Keep transaction records (legal requirement)

---

## 16. Database Functions

### Utility Functions

**`get_distance_km(lat1, lon1, lat2, lon2)`**
- Returns: numeric (kilometers)
- Calculates distance between two points

**`get_nearby_venues(user_lat, user_lon, radius_km)`**
- Returns: bars[]
- Finds venues within radius

**`is_friends_with(user_id, friend_id)`**
- Returns: boolean
- Checks if users are friends

**`get_venue_people_count(venue_id)`**
- Returns: integer
- Counts active users at venue

**`create_notification(user_id, type, data)`**
- Returns: void
- Creates notification for user

### Triggers

**`auto_create_user_profile`**
- Table: auth.users
- Event: AFTER INSERT
- Action: Create user profile in users table

**`update_updated_at`**
- Tables: users, bars, swarms, conversations, etc.
- Event: BEFORE UPDATE
- Action: Set updated_at = NOW()

**`notify_new_message`**
- Table: messages
- Event: AFTER INSERT
- Action: Create notification for recipients

**`update_conversation_timestamp`**
- Table: messages
- Event: AFTER INSERT
- Action: Update conversation.updated_at

**`track_venue_session`**
- Table: geofence_events
- Event: AFTER INSERT
- Action: Create/update venue_session

---

## 17. Edge Functions & Database Interaction

### Database-Heavy Edge Functions

**`bars-nearby`**
- Queries: bars, venue_sessions, user_venue_presence
- Returns: Venues with current people counts

**`enter-venue` / `leave-venue`**
- Inserts: venue_sessions, location_events
- Updates: user_venue_presence, users.current_venue_id

**`radar-webhook`**
- Inserts: geofence_events, location_pings
- Triggers: venue session creation

**`delete-account`**
- Complex deletion cascade
- Anonymizes data
- Preserves legal records

---

## Summary

The Barfliz database is designed for:

1. **Real-time social interactions** - Optimized for live updates and subscriptions
2. **Geographic queries** - PostGIS for accurate location-based features
3. **Privacy & security** - Comprehensive RLS on every table
4. **Global scale** - Multi-country support with regional settings
5. **Performance** - Strategic indexing and denormalization
6. **Data integrity** - Foreign keys, constraints, and validation
7. **Compliance** - GDPR/CCPA-ready data retention and export

**Total Tables**: 40+
**Storage Buckets**: 3
**Edge Functions**: 20+
**Indexes**: 100+
**RLS Policies**: 150+

This architecture supports both the current web PWA and future native mobile apps with full feature parity.
