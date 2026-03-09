# Barfliz Flutter - Quick Start (5 Minutes)

## 🚀 Get Running in 5 Minutes

### Step 1: Create Flutter Project (30 seconds)

```bash
flutter create barfliz
cd barfliz
```

### Step 2: Copy Files (30 seconds)

```bash
# From the flutter_app folder, copy everything:
cp -r ../flutter_app/lib/* lib/
cp ../flutter_app/pubspec.yaml .
```

### Step 3: Update Config (1 minute)

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  // Get these from your .env file in the React project
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Get from Stripe dashboard
  static const String stripePublishableKey = 'pk_test_...';

  // Get from Google Cloud Console
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_KEY';
}
```

### Step 4: Install Dependencies (1 minute)

```bash
flutter pub get
```

### Step 5: Add Placeholder Images (1 minute)

```bash
mkdir -p assets/images

# Create placeholder files (or add your actual images)
touch assets/images/slide1.png
touch assets/images/slide2.png
touch assets/images/slide3.png
```

### Step 6: Run! (1 minute)

```bash
# Connect your phone or start emulator, then:
flutter run
```

That's it! 🎉

## 📱 What You'll See

1. **Onboarding**: 3 slides introducing Barfliz
2. **Sign Up**: Create account with email/password
3. **Profile Setup**: Enter name, DOB, city
4. **Permissions**: Grant location & notifications
5. **Home Screen**: Browse people, venues, swarms

## ⚡ Quick Tips

### To Test Payments:
Use Stripe test cards:
- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`
- Expiry: Any future date
- CVC: Any 3 digits

### To See Users:
The database already has 9 test users from your React app!

### To Debug:
```bash
flutter run --verbose
```

## 🔧 Common Issues & Fixes

### "Supabase URL not found"
→ Update `lib/config/app_config.dart` with real values

### "Asset not found"
→ Make sure you created the assets/images folder and files

### "Dependencies error"
→ Run `flutter clean && flutter pub get`

### "Platform specific error"
→ Follow the platform setup in SETUP_GUIDE.md

## 🎯 What Works Right Now

- ✅ Authentication (sign up, sign in, sign out)
- ✅ Profile creation
- ✅ Navigation between screens
- ✅ Premium subscription UI
- ✅ Gift sending UI
- ✅ Settings
- ✅ Database integration

## 🚧 What Needs Enhancement

To make it fully functional, enhance these:

1. **Discover**: Add real swipe cards (use `flutter_card_swiper`)
2. **Home Tabs**: Fetch and display actual data from Supabase
3. **Messages**: Implement real-time chat with Supabase Realtime
4. **Map**: Add Google Maps integration
5. **Payments**: Deploy Stripe edge functions
6. **Images**: Add photo upload functionality

See SETUP_GUIDE.md for detailed instructions on each.

## 📚 Documentation

- `README.md` - Project overview
- `SETUP_GUIDE.md` - Detailed setup instructions
- `DEPLOYMENT.md` - How to deploy to stores
- `PROJECT_SUMMARY.md` - Complete feature list

## 💰 Monetization (Already Built!)

### Premium Subscription
- Monthly: $9.99
- Yearly: $79.99
- Stripe integration ready
- Premium features implemented

### Gift System
- Send virtual drinks ($5-$50)
- Stripe integration ready
- Gift tracking in database

## 🎨 Customization

### Change Colors:
Edit `lib/config/theme.dart`

### Change Text:
Edit the respective screen files in `lib/screens/`

### Add Features:
Create new screens in `lib/screens/`
Add routes in `lib/routes/app_router.dart`

## 🆘 Need Help?

1. Check the detailed guides (SETUP_GUIDE.md, DEPLOYMENT.md)
2. Flutter docs: https://docs.flutter.dev
3. Supabase docs: https://supabase.com/docs
4. Stripe docs: https://stripe.com/docs

## ✨ Pro Tips

1. Use Android Studio or VS Code with Flutter extension
2. Enable hot reload for fast development
3. Use Flutter DevTools for debugging
4. Test on real devices, not just emulators
5. Start with Android (easier to test)

## 🎊 You're Ready!

Your Barfliz Flutter app is now running. Time to make it amazing! 🍻

**Next Steps:**
1. Add your actual onboarding images
2. Test the full user flow
3. Customize the UI to match your brand perfectly
4. Deploy Stripe edge functions for payments
5. Submit to App Store & Google Play

Happy coding! 🚀
