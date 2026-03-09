# BarFliz Database Infrastructure

## Complete Supabase Database Schema

All data is securely stored in Supabase PostgreSQL with Row Level Security enabled on every table.

---

## Core Tables

### 1. **users** (17 Columns)
**Primary user profiles and settings**

Stores:
- Profile info: name, dob, age, bio, photos, avatar
- Status: tonight_status (out_now/going_out_soon/staying_in)
- Preferences: vibe_tags, favorite_drinks, venue_preferences
- Location: last_known_lat/lng, home_city, preferred_radius_meters
- Privacy: privacy_mode (invisible/friends_only/nearby)
- Premium: is_premium, lush_coin_balance
- Payments: venmo_username, venmo_linked
- Weather: weather_location, weather_enabled
- Timestamps: last_active_at, created_at

**RLS**: Users can only read/update their own profile

---

### 2. **venues** (22 Columns)
**Bar, club, and event venue data**

Stores:
- Basic: name, address, city, state, country, postal_code
- Location: lat, lng, place_id
- Details: category, type, hours, photo_url
- Ratings: rating, user_ratings_total
- Geofencing: geofence_shape, geofence_radius_meters (50m default)
- Status: verified, is_active
- Metadata: metadata (JSON), updated_at, created_at

**RLS**: Public read access, admin-only write

**Geofencing**: Each venue has a 50-500m radius trigger zone

---

### 3. **swarms** (11 Columns)
**Group meetup events**

Stores:
- Host: host_user_id
- Details: title, description, vibe_tags
- Location: venue_id (optional)
- Schedule: start_time, end_time
- Settings: max_attendees, join_mode (open/request_approval)
- Status: status (active/ended/cancelled)
- Timestamps: created_at

**RLS**: Public read for active swarms, host controls updates

---

### 4. **swarm_members** (6 Columns)
**Tracks who joined which swarms**

Stores:
- Relationships: swarm_id, user_id
- Role: role (host/member)
- RSVP: rsvp (going/maybe)
- Timestamps: joined_at

**RLS**: Members can read their own swarms

---

### 5. **messages** (10 Columns)
**Direct messages and swarm chat**

Stores:
- Type: conversation_type (dm/swarm)
- DM Mode: dm_user_a, dm_user_b
- Swarm Mode: swarm_id
- Content: sender_user_id, body, media_url
- Status: read_at
- Timestamps: created_at

**RLS**: Only conversation participants can read/write

---

## Payment & Gift Tables

### 6. **payment_transactions** (11 Columns)
**Venmo payment tracking**

Stores:
- Transfer: from_user_id, to_user_id, amount, currency
- Type: transaction_type (drink_request/payment/transfer/gift/split_tab)
- Context: swarm_id, description, drink_name
- Status: status (pending/completed/failed/refunded)
- Integration: provider_ref (Venmo transaction ID)
- Timestamps: created_at

**RLS**: Users can only see their own transactions

---

### 7. **gifts** (10 Columns)
**Physical drink gifts sent between users**

Stores:
- Transfer: from_user_id, to_user_id
- Details: drink_type, amount, message
- Location: venue_id (where gift can be redeemed)
- Status: status (pending/redeemed/expired)
- Timestamps: created_at, redeemed_at

**RLS**: Sender and recipient can view

---

### 8. **virtual_items** (11 Columns)
**Catalog of emoji items, stickers, gifts**

Stores:
- Basic: name, emoji, description
- Classification: category (emoji/drink/gift/sticker/celebration/seasonal)
- Economy: price (in LushCoins), is_premium, rarity (common/rare/epic/legendary)
- Display: animation_url
- Status: is_active
- Timestamps: created_at

**RLS**: Public read access

---

### 9. **user_gifts** (11 Columns)
**Virtual items sent between users**

Stores:
- Transfer: from_user_id, to_user_id, item_id
- Content: message, reaction
- Context: context_type (direct_message/profile/swarm/venue), context_id
- Status: status (sent/viewed/reacted)
- Timestamps: created_at, viewed_at

**RLS**: Sender and recipient can view

---

### 10. **user_inventory** (6 Columns)
**User's collection of virtual items**

Stores:
- Ownership: user_id, item_id, quantity
- Timestamps: acquired_at, updated_at

**RLS**: Users can only see their own inventory

---

### 11. **emoji_reactions** (6 Columns)
**Emoji reactions on messages, profiles, venues**

Stores:
- User: user_id
- Target: target_type (message/post/profile/venue/swarm), target_id
- Content: emoji
- Timestamps: created_at

**RLS**: Public read, authenticated write

---

## Music & Social Tables

### 12. **music_shares** (17 Columns)
**Music recommendations between users**

Stores:
- Transfer: sender_id, recipient_id
- Song: song_id, song_title, artist_name, album_art_url
- Links: preview_url, external_url
- Platform: platform (spotify/apple_music/youtube_music)
- Context: message, swarm_id, venue_id
- Status: status (pending/played/saved/expired)
- Timestamps: created_at, played_at, expires_at (30 day default)

**RLS**: Sender and recipient can view

---

### 13. **subscriptions** (8 Columns)
**Premium subscription management**

Stores:
- User: user_id
- Plan: plan_type (monthly/yearly)
- Status: status (active/cancelled/expired)
- Billing: stripe_subscription_id, current_period_start/end
- Timestamps: created_at

**RLS**: Users can only see their own subscription

---

## Safety & Security Tables

### 14. **safety_friends** (5 Columns)
**Emergency contacts for safety features**

Stores:
- User: user_id
- Contact: friend_name, friend_phone
- Timestamps: created_at

**RLS**: Users can only manage their own safety contacts

---

### 15. **safety_alerts** (7 Columns)
**Emergency location sharing alerts**

Stores:
- User: user_id
- Location: latitude, longitude, location_url
- Type: alert_type (default: location_share)
- Timestamps: created_at

**RLS**: Only user and their safety_friends can view

---

### 16. **reports** (7 Columns)
**User reports for moderation**

Stores:
- Parties: reporter_user_id, reported_user_id
- Details: context (dm/swarm/profile), reason, details
- Status: status (pending/reviewed/actioned)
- Timestamps: created_at

**RLS**: Reporter can view their reports, admins see all

---

### 17. **blocks** (4 Columns)
**Blocked user relationships**

Stores:
- Relationship: blocker_user_id, blocked_user_id
- Timestamps: created_at

**RLS**: Users can only manage their own blocks

---

## Venue Intelligence Tables

### 18. **user_venue_presence** (13 Columns)
**Real-time tracking of who's at which venue**

Stores:
- Relationship: user_id, venue_id
- Status: status (IN_VENUE/LEFT_VENUE)
- Tracking: entered_at, left_at, last_seen_at, dwell_seconds
- Visibility: is_visible_in_venue
- Method: entry_method (AUTO_GEOFENCE/MANUAL/QR_CODE)
- Data: metadata (JSON)
- Timestamps: created_at, updated_at

**RLS**: Users can see others in venue if visible

**How it works**:
- Geofencing automatically detects entry/exit
- Tracks time spent at venue
- Shows who's there right now
- Privacy controls per user

---

### 19. **venue_clusters** (9 Columns)
**Grouped venues in popular districts**

Stores:
- Identity: name, city
- Location: center_lat, center_lng, radius_meters (500m default)
- Venues: venue_ids (array of venue UUIDs)
- Status: is_active
- Timestamps: created_at, updated_at

**RLS**: Public read access

**Purpose**: Group nearby bars (e.g., "Downtown District", "Gaslamp Quarter")

---

## Database Migrations Applied

1. **20260109030042** - Initial schema (users, venues, swarms, messages, reports, blocks)
2. **20260109034256** - Gifts and premium features (gifts, subscriptions, lush coins)
3. **20260109040141** - Venmo payment integration
4. **20260109043504** - Venue preferences for users
5. **20260114011014** - Safety features (safety_friends, safety_alerts)
6. **20260129035818** - Music sharing system
7. **20260129040819** - Virtual items and emoji system
8. **20260207010143** - Venue geofencing (geofence_shape, radius)
9. **20260207013844** - User radius preferences and weather location

---

## Security Architecture

### Row Level Security (RLS)
- **EVERY TABLE** has RLS enabled
- No data accessible without proper policies
- Users can only access their own data by default
- Public data (venues, virtual_items) has read-only policies

### Authentication
- Supabase Auth handles user authentication
- Email/password by default
- JWT tokens for all API requests
- Session management built-in

### Data Privacy
- `privacy_mode` controls visibility (invisible/friends_only/nearby)
- Block system prevents unwanted interactions
- Safety features protect user location data
- Reports system for moderation

---

## Edge Functions Deployed

### Active Functions:
1. **enter-venue** - Handles geofence entry events
2. **leave-venue** - Handles geofence exit events
3. **fetch-venues** - Gets nearby venues from Google Places API
4. **sync-venues** - Syncs venue data with database

All functions deployed with CORS headers and proper authentication.

---

## What Gets Stored:

✅ **User Data**: Profiles, preferences, location, status
✅ **Social Data**: Messages, swarms, memberships
✅ **Venue Data**: Bars, clubs, geofences, ratings
✅ **Payment Data**: Transactions, gifts, subscriptions
✅ **Music Data**: Shared songs, playlists, recommendations
✅ **Safety Data**: Emergency contacts, location alerts
✅ **Virtual Economy**: Items, inventory, reactions
✅ **Presence Data**: Real-time venue check-ins
✅ **Moderation Data**: Reports, blocks

---

## Connection Details

All stored in `.env`:
```
VITE_SUPABASE_URL=https://[your-project].supabase.co
VITE_SUPABASE_ANON_KEY=[your-anon-key]
```

Every feature is backed by persistent database storage with proper relationships and security.
