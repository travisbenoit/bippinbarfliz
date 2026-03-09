# Barfliz Flutter App

A social drinking app to find drinking partners and make new friends at bars.

## Features

- **Onboarding**: 3-slide introduction to the app
- **Authentication**: Email/password sign up and sign in with Supabase
- **Profile Setup**: Create user profile with name, DOB, and city
- **Permissions**: Request location and notification permissions
- **Discover**: Tinder-style swipe cards to find drinking partners
- **Home**: Browse nearby people, venues, and swarms
- **Map View**: See users and venues on an interactive map
- **Messages**: Real-time chat with matches
- **Swarms**: Create and join group meetups
- **Premium Subscription**: Unlock premium features with Stripe
- **Gift Drinks**: Send virtual drink gifts to other users
- **Profile & Settings**: Manage your account

## Tech Stack

- **Flutter** - Cross-platform mobile framework
- **Supabase** - Backend (auth, database, realtime)
- **Riverpod** - State management
- **GoRouter** - Navigation
- **Stripe** - Payments
- **Google Maps** - Location features
- **Firebase** - Push notifications

## Setup Instructions

### 1. Environment Variables

Create a `.env` file in the root with:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### 2. Update Configuration

Edit `lib/config/app_config.dart` with your credentials.

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── config/              # App configuration and theme
├── models/              # Data models
├── providers/           # Riverpod providers
├── routes/              # App routing
├── screens/             # UI screens
│   ├── onboarding/
│   ├── auth/
│   ├── profile_setup/
│   ├── permissions/
│   ├── home/
│   ├── discover/
│   ├── map/
│   ├── messages/
│   ├── profile/
│   ├── settings/
│   ├── swarms/
│   ├── premium/
│   └── gifts/
├── services/            # Business logic services
└── widgets/             # Reusable widgets
```

## Database Schema

The app uses Supabase with the following tables:

- **users** - User profiles
- **venues** - Bars and drinking establishments
- **swarms** - Group meetups
- **swarm_members** - Swarm participants
- **messages** - Chat messages
- **gifts** - Virtual drink gifts
- **subscriptions** - Premium subscriptions
- **blocks** - Blocked users
- **reports** - User reports
- **payment_transactions** - Payment records

## Key Features Implementation

### Authentication Flow

1. Onboarding (3 slides)
2. Sign Up / Sign In
3. Profile Setup
4. Permissions Request
5. Home Screen

### Discover (Swipe Feature)

Uses `flutter_card_swiper` package for Tinder-style swipe cards. Users can swipe right to like or left to pass on potential drinking partners.

### Premium Features

Premium users get:
- Unlimited swipes
- See who liked them
- Advanced filters
- No ads
- Priority support

### Gifting System

Users can send virtual drinks to other users:
- Choose drink type
- Add personal message
- Pay with Stripe
- Recipient can redeem at participating venues

## Payments Integration

Uses Stripe for:
- Premium subscriptions (monthly/yearly)
- Gift purchases
- In-app purchases

### Stripe Setup

1. Get Stripe publishable key
2. Create Supabase Edge Functions for:
   - `create-subscription`
   - `send-gift`
   - `webhook` (handle Stripe events)

## Push Notifications

Uses Firebase Cloud Messaging for:
- New matches
- New messages
- Swarm invitations
- Gift notifications

## Maps Integration

Uses Google Maps to show:
- Nearby users (with privacy controls)
- Bars and venues
- Swarm locations

## Deployment

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## Environment Setup

This app requires:
- Flutter 3.0+
- Dart 3.0+
- Supabase account
- Stripe account
- Google Maps API key
- Firebase project

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

Proprietary - All rights reserved
