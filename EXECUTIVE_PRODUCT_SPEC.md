# Barfliz Executive Product Specification

## Executive Summary

Barfliz is a global social nightlife application that connects people at bars, clubs, and entertainment venues in real-time. The platform combines location-based services, social networking, and venue discovery to create a dynamic nightlife experience.

**Current Status**: Web PWA (Progressive Web App) - Production Ready
**Planned**: Native iOS & Android Apps via Flutter

---

## 1. Core Product Vision

Barfliz helps users:
- Discover who's out tonight at nearby venues
- Connect with friends and meet new people
- Plan group outings ("Swarms")
- Share their nightlife experiences
- Stay safe while enjoying the nightlife

---

## 2. Global Market Coverage

### Supported Countries (23 Total)

**Americas (6)**
- United States (21+ drinking age)
- Canada (18/19+ provincial)
- Mexico (18+)
- Brazil (18+)
- Argentina (18+)
- Chile (18+)

**Europe (9)**
- United Kingdom (18+)
- Ireland (18+)
- Germany (16/18+)
- France (18+)
- Spain (18+)
- Italy (18+)
- Netherlands (18+)
- Belgium (18+)
- Portugal (18+)

**Asia-Pacific (5)**
- Australia (18+)
- New Zealand (18+)
- Japan (20+)
- Singapore (18+)
- Thailand (20+)

**Middle East & Africa (3)**
- South Africa (18+)
- Israel (18+)
- UAE (21+)

### Regional Adaptations

**United States**
- Venmo integration for payments/splitting bills
- Imperial units (miles, feet)
- Fahrenheit temperature
- 12-hour time format
- State-specific emergency numbers

**Other Countries**
- Local payment providers (region-specific)
- Metric units (kilometers, meters)
- Celsius temperature
- 24-hour time format
- Country-specific emergency services

---

## 3. Current Implementation (Web PWA)

### 3.1 User Onboarding

**Step 1: Age Gate**
- Country auto-detection via IP/browser
- Manual country selection available
- Age verification (18, 20, or 21 based on country)
- Birthday input with validation

**Step 2: Phone Verification**
- Twilio SMS verification (global coverage)
- Country code automatic selection
- 6-digit OTP code
- Rate limiting and security

**Step 3: Profile Setup**
- Name and display name
- Profile photo upload
- Preferred drink selection
- Social preferences

**Step 4: Permissions**
- Location access (required)
- Notifications (recommended)
- Contacts (optional for friend finding)

### 3.2 Core Features

#### Home Dashboard
- "Tonight Status" - Set availability and plans
- Active friends feed showing who's out
- Nearby venue activity
- Swarm invitations
- Quick actions (create swarm, find friends)

#### Map View
- Real-time venue locations with people counts
- Custom radius control (0.5 - 5 miles/km)
- Venue filtering by type (bar, club, lounge, etc.)
- Live user locations (friends only)
- Venue details with photos, ratings, hours
- Google Places integration for rich data

#### Swarms (Group Plans)
- Create public or private group meetups
- Set venue, time, and date
- Invite friends or make discoverable
- RSVP tracking (going/maybe/declined/invited)
- Group chat for attendees
- Swarm discovery for joining others

#### Messaging
- Direct messages between users
- Group chats for swarms
- Real-time delivery
- Read receipts
- Photo sharing
- Music track sharing (Spotify integration)

#### Friends System
- Add friends via search or contacts
- Friend requests and acceptance
- View friends' locations and status
- See friends' swarms and activity
- Block/unblock users

#### People Nearby
- Discover users currently at venues
- Filtered by distance and preferences
- View profiles and send friend requests
- See common friends and interests

#### Venue Discovery
- Browse all venues in area
- Trending venues with high activity
- Ratings and reviews
- Popular times
- Photo galleries
- Business information

#### Payments (US Only - Current)
- Venmo integration
- Send/request money between users
- Split bills with groups
- Transaction history
- Payment notifications

#### Safety Features
- Safe arrival check-ins
- Emergency contacts
- Ghost mode (hide location)
- User blocking and reporting
- Venue reporting
- Country-specific emergency numbers

#### Activity & Social
- Activity feed of friends' check-ins
- Emoji reactions to activities
- Virtual gift sending
- Music sharing via Spotify
- Photo sharing at venues
- Tonight status updates

### 3.3 Technology Stack

**Frontend**
- React 18 with TypeScript
- Vite build system
- Tailwind CSS for styling
- Leaflet for maps
- Lucide React for icons
- PWA capabilities (installable, offline-ready)

**Backend**
- Supabase (PostgreSQL database)
- Row Level Security (RLS) for data protection
- Real-time subscriptions
- Edge Functions for serverless logic
- Storage for photos/media

**Third-Party Integrations**
- Radar.io: Geofencing and location tracking
- Twilio: SMS verification globally
- Google Places API: Venue data enrichment
- Spotify API: Music sharing
- Venmo: Payments (US only)
- OpenWeatherMap: Weather data

---

## 4. Platform Differences: Web PWA vs Native Apps

### Current Web PWA Capabilities

**Advantages**
- Instant access via browser (no download)
- Cross-platform (iOS, Android, Desktop)
- Single codebase for all platforms
- Automatic updates (no app store approval)
- Easy sharing via URL
- Lower development cost

**Limitations**
- Limited background location tracking
- No push notifications on iOS (web)
- Reduced geofencing precision
- Cannot access full device APIs
- Less discoverable (not in app stores)
- Requires browser open for some features

### Planned Native Apps (Flutter)

**Additional Capabilities**
- Full background location services
- True push notifications (iOS & Android)
- Precise geofencing (Radar SDK native)
- App Store & Google Play presence
- Better device integration
- Offline-first capabilities
- Smoother animations and performance
- Access to device sensors
- Deep linking support

**Key Differences in User Experience**

| Feature | Web PWA | Native App |
|---------|---------|------------|
| Location Tracking | Foreground only | Background + foreground |
| Push Notifications | Android only | iOS + Android |
| Geofencing Accuracy | Limited | High precision |
| Installation | Add to home screen | App Store download |
| Updates | Automatic | User initiated |
| Startup Time | Browser load | Instant launch |
| Device Integration | Limited | Full access |
| Discoverability | Web search | App Store search |

---

## 5. Location & Geofencing Architecture

### Current Implementation (Web - Radar.io Web SDK)

**Location Services**
- Manual location updates when app is active
- Periodic polling when map is open
- User-initiated check-ins to venues
- Approximate venue proximity detection

**Geofence Behavior**
- Server-side geofence matching
- Client reports location → server checks venue proximity
- Entry/exit events generated server-side
- Limited precision (50-100m accuracy)

**Limitations**
- Requires app/browser to be open
- No automatic background tracking
- Battery intensive if polling frequently
- Delayed venue entry/exit detection

### Native App Implementation (Flutter - Radar SDK Native)

**Location Services**
- Continuous background tracking
- Intelligent battery optimization
- Automatic venue detection
- Precise location history

**Geofence Behavior**
- Native OS-level geofencing
- Automatic entry/exit triggers
- High precision (10-20m accuracy)
- Instant notifications on venue events

**Capabilities**
- Passive background tracking (user doesn't need to open app)
- Trip tracking (track user's night out journey)
- Automatic venue check-ins
- Real-time presence updates
- Venue dwell time tracking
- Venue visit history

**Regional Differences**
- Geofence radius varies by venue type
  - Bars: 30-50m
  - Nightclubs: 50-100m
  - Stadiums/Events: 100-200m
- Country-specific privacy regulations respected
- GDPR compliance (EU)
- CCPA compliance (California, US)

---

## 6. Payment Systems by Region

### United States
- **Provider**: Venmo (PayPal owned)
- **Features**: P2P payments, bill splitting, social feed
- **Integration**: Deep-linked, OAuth authentication
- **Status**: Fully implemented

### Other Countries (Planned)
Each region will integrate local payment providers:

**Europe**
- iDEAL (Netherlands)
- Bancontact (Belgium)
- Sofort (Germany)
- SEPA transfers

**UK**
- Faster Payments
- Open Banking integrations

**Australia/NZ**
- PayID
- BPAY

**Asia**
- PayNow (Singapore)
- PromptPay (Thailand)
- PayPay (Japan)

**Latin America**
- PIX (Brazil)
- Mercado Pago (Argentina, Chile, Mexico)

**Current Status**: Payment provider selection in database, UI ready, integrations pending

---

## 7. Database & Data Model

### Core Entities

**Users**
- Profile information
- Location preferences (radius, units)
- Regional settings (country, timezone, language)
- Safety settings (emergency contacts, ghost mode)
- Verification status (phone, age)

**Venues (Bars)**
- Location (lat/long, address)
- Business information
- Google Place ID linkage
- Geofence radius
- Operating hours
- Photos and ratings
- Real-time people count

**Venue Sessions**
- User presence at venues
- Entry/exit timestamps
- Session duration
- Privacy settings

**Friendships**
- Friend connections
- Status (pending, accepted, blocked)
- Request timestamps

**Swarms**
- Group meetup plans
- Venue, date, time
- Privacy (public/private)
- Creator and participants

**Messages**
- Direct messages
- Group conversations
- Read receipts
- Soft delete support

**Location Events**
- User location pings
- Geofence entry/exit events
- Movement tracking
- Privacy-filtered

**Activity Feed**
- User actions (check-ins, swarms, friendships)
- Social interactions
- Timestamp-ordered

**Notifications**
- System notifications
- Social notifications
- Delivery status

**Payments/Transactions**
- Payment provider links
- Transaction history
- Regional provider selection

### Security & Privacy

**Row Level Security (RLS)**
- Every table has RLS enabled
- User can only see their own data + friends' data
- Blocking enforced at database level
- Ghost mode respected in all queries

**Data Protection**
- Location data retention policies
- GDPR/CCPA compliant
- User data export available
- Account deletion with full cleanup

---

## 8. Admin & Management Tools

### Venue Management
- Import venues from OpenStreetMap
- Link to Google Places for enrichment
- Manual venue creation/editing
- Activate/deactivate venues by region

### Geofence Management
- View all venue geofences
- Adjust radius by venue type
- Test geofence boundaries
- Monitor geofence events

### Google Places Integration
- Fetch venue details (photos, ratings, hours)
- Cache responses for performance
- API usage monitoring
- Automatic data refresh

### Analytics (Admin View)
- Venue statistics by city
- User activity metrics
- Session tracking
- Popular venues and times

---

## 9. Internationalization (i18n)

### Current Implementation
- Translation key system in database
- English language fully populated
- UI supports dynamic language switching
- Regional date/time formatting
- Unit conversion (metric/imperial)

### Languages Planned
- Spanish (Spain & Latin America)
- Portuguese (Brazil)
- French
- German
- Japanese
- Thai
- Dutch
- Italian

---

## 10. Roadmap: Web PWA → Native Apps

### Phase 1: Current (Web PWA)
✅ Core social features
✅ Manual location tracking
✅ Venue discovery
✅ Messaging and swarms
✅ US payment integration
✅ 23 country support

### Phase 2: Native App Launch
🔄 Flutter app development
🔄 Native Radar SDK integration
🔄 Background location tracking
🔄 True push notifications
🔄 App Store submission

### Phase 3: Enhanced Native Features
📋 Passive venue detection
📋 Automatic check-ins
📋 Trip/route tracking
📋 Regional payment integrations
📋 Enhanced offline mode

### Phase 4: Scale & Growth
📋 Additional countries
📋 Premium subscription features
📋 Event partnerships
📋 Venue promotions/advertising
📋 Advanced analytics

---

## 11. Key Differentiators

### What Makes Barfliz Unique

1. **Real-Time Social Context**
   - Know who's out before you go
   - See friends' plans and join spontaneously
   - Live venue popularity metrics

2. **Safety-First Design**
   - Emergency contacts and check-ins
   - Ghost mode for privacy
   - Blocking and reporting
   - Safe arrival tracking

3. **Global & Local**
   - Works in 23 countries
   - Adapts to local norms (age, units, payment)
   - Respects regional privacy laws

4. **Venue Intelligence**
   - Real-time people counts
   - Trending venues
   - Historical popularity data
   - Rich venue information

5. **Social Planning**
   - Swarms for group coordination
   - Discoverable public events
   - Integrated messaging
   - Bill splitting

---

## 12. Monetization Strategy (Future)

### Freemium Model
- Free: Core features, limited radius
- Premium: Extended radius, ghost mode, advanced features

### Venue Partnerships
- Promoted listings
- Featured events
- Special offers distribution

### Payment Processing Fees
- Small fee on P2P transactions
- Revenue share with payment providers

### Data Analytics (Anonymized)
- Venue foot traffic trends
- Demographic insights
- Industry reports

---

## 13. Compliance & Legal

### Age Verification
- Country-specific legal drinking ages
- Birthday validation
- Access restrictions for underage users

### Privacy Regulations
- GDPR (European Union)
- CCPA (California)
- PIPEDA (Canada)
- Privacy Policy and Terms of Service
- User consent management

### Location Privacy
- Explicit permission requests
- Ghost mode functionality
- Location data minimization
- Retention policies

### Content Moderation
- User reporting system
- Content review process
- Account suspension/banning
- Automated filtering

---

## 14. Success Metrics

### User Engagement
- Daily active users (DAU)
- Monthly active users (MAU)
- Session duration
- Check-ins per user
- Swarms created/joined

### Social Metrics
- Friend connections per user
- Messages sent
- Swarm attendance rate
- Profile views

### Venue Metrics
- Venues with active users
- Average people per venue
- Venue discovery rate
- Time spent at venues

### Retention
- Day 1, 7, 30 retention
- Weekly return rate
- Feature adoption rates
- Churn analysis

---

## 15. Technical Performance

### Current Benchmarks
- Page load: <2 seconds
- API response time: <200ms
- Real-time message delivery: <500ms
- Location update frequency: 30 seconds (active)
- Database query optimization: Indexed foreign keys

### Scalability
- Supabase PostgreSQL (scales vertically)
- Edge Functions (auto-scaling)
- CDN for static assets
- Database connection pooling
- Efficient RLS policies

---

## Conclusion

Barfliz is a production-ready global nightlife platform currently deployed as a web PWA with plans for native mobile apps. The system supports 23 countries with regional adaptations, real-time social features, and a strong focus on safety and privacy.

**Current State**: Fully functional web application ready for user onboarding globally

**Next Phase**: Native mobile apps with enhanced location features and deeper platform integration

**Competitive Edge**: Real-time social context combined with safety features and global reach sets Barfliz apart from traditional nightlife apps and social networks.
