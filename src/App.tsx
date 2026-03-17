import { lazy, Suspense, useEffect, useState, useCallback, useRef } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router';
import { useAuth } from './contexts/AuthContext';
import { supabase } from './lib/supabase';
import { ErrorBoundary } from './components/ErrorBoundary';
import MainLayout from './components/Layout/MainLayout';
import AgeGate from './components/Auth/AgeGate';
import { GeofenceProvider } from './geolocation/GeofenceProvider';
import { CheckinRewardToast } from './components/Gamification/CheckinRewardToast';

const Onboarding = lazy(() => import('./components/Onboarding'));
const SignIn = lazy(() => import('./components/Auth/SignIn'));
const SignUp = lazy(() => import('./components/Auth/SignUp'));
const PhoneVerification = lazy(() => import('./components/Auth/PhoneVerification'));
const NameSetup = lazy(() => import('./components/Auth/NameSetup'));
const ProfileSetup = lazy(() => import('./components/ProfileSetup'));
const LocationPermission = lazy(() => import('./components/Permissions/LocationPermission'));
const ContactsPermission = lazy(() => import('./components/Permissions/ContactsPermission'));
const NotificationsPermission = lazy(() => import('./components/Permissions/NotificationsPermission'));
const MapView = lazy(() => import('./components/Map/MapView'));
const MessagesView = lazy(() => import('./components/Messages/MessagesView'));
const ProfileView = lazy(() => import('./components/Profile/ProfileView'));
const SwarmsView = lazy(() => import('./components/Swarms/SwarmsView'));
const CreateSwarm = lazy(() => import('./components/Swarms/CreateSwarm'));
const SettingsView = lazy(() => import('./components/Settings/SettingsView'));
const EditProfile = lazy(() => import('./components/Settings/EditProfile'));
const NotificationsSettings = lazy(() => import('./components/Settings/NotificationsSettings'));
const SafetySecurity = lazy(() => import('./components/Settings/SafetySecurity'));
const RadarSettings = lazy(() => import('./components/Settings/RadarSettings'));
const HelpCenter = lazy(() => import('./components/Settings/HelpCenter'));
const AdminGooglePlaces = lazy(() => import('./components/Settings/AdminGooglePlaces'));
const AdminGeofences = lazy(() => import('./components/Settings/AdminGeofences'));
const AdminOSMImport = lazy(() => import('./components/Settings/AdminOSMImport'));
const AdminVenueAnalytics = lazy(() => import('./components/Settings/AdminVenueAnalytics'));
const AdminVenues = lazy(() => import('./pages/AdminVenues'));
const PaymentsView = lazy(() => import('./components/Payments/PaymentsView').then(m => ({ default: m.PaymentsView })));
const PaymentSettings = lazy(() => import('./components/Payments/PaymentSettings').then(m => ({ default: m.PaymentSettings })));
const VenmoSetup = lazy(() => import('./components/Payments/VenmoSetup').then(m => ({ default: m.VenmoSetup })));
const SendPayment = lazy(() => import('./components/Payments/SendPayment').then(m => ({ default: m.SendPayment })));
const ReceivePayment = lazy(() => import('./components/Payments/ReceivePayment').then(m => ({ default: m.ReceivePayment })));
const GiftsInbox = lazy(() => import('./components/Gifts/GiftsInbox').then(m => ({ default: m.GiftsInbox })));
const LushCoinPage = lazy(() => import('./components/Payments/LushCoinPage').then(m => ({ default: m.LushCoinPage })));
const LeaderboardView = lazy(() => import('./components/Community/LeaderboardView').then(m => ({ default: m.LeaderboardView })));
const Home = lazy(() => import('./components/Home/Home'));
const FriendsView = lazy(() => import('./components/Friends/FriendsView'));
const HistoryView = lazy(() => import('./components/History/HistoryView'));
const PeopleNearbyView = lazy(() => import('./components/People/PeopleNearbyView'));
const CompleteDemoWalkthrough = lazy(() => import('./components/Demo/CompleteDemoWalkthrough').then(m => ({ default: m.CompleteDemoWalkthrough })));
const PrivacyPolicy = lazy(() => import('./components/Legal/PrivacyPolicy'));
const TermsOfService = lazy(() => import('./components/Legal/TermsOfService'));

function PageLoader() {
  return (
    <div className="min-h-screen bg-[#FFF5F0] flex items-center justify-center">
      <div className="text-center">
        <div className="w-12 h-12 border-4 border-[#E91E63] border-t-transparent rounded-full animate-spin mx-auto mb-3"></div>
        <p className="text-gray-500 text-sm">Loading...</p>
      </div>
    </div>
  );
}

function AppRouter() {
  const { user, loading } = useAuth();
  const [hasProfile, setHasProfile] = useState(false);
  const [checkingProfile, setCheckingProfile] = useState(true);
  const [ghostMode, setGhostMode] = useState(false);
  const checkingRef = useRef(false);

  const checkUserProfile = useCallback(async () => {
    if (!user || checkingRef.current) return;
    checkingRef.current = true;

    const isDemoMode = localStorage.getItem('demo_mode') === 'true';

    const { data } = await supabase
      .from('users')
      .select('id, name, ghost_mode, favorite_drinks, vibe_tags, home_city, phone_country_code, registration_country')
      .eq('id', user.id)
      .maybeSingle();

    if (!data && isDemoMode) {
      const demoCountry = localStorage.getItem('userCountryCode') || 'US';
      const isDarwinDemo = demoCountry === 'AU';
      await supabase.from('users').upsert({
        id: user.id,
        name: isDarwinDemo ? 'Sam Demo' : 'Alex Demo',
        username: isDarwinDemo ? 'samdemo_darwin' : 'alexdemo33326',
        bio: isDarwinDemo ? 'Just exploring Darwin nightlife' : 'Just exploring Weston nightlife',
        home_city: isDarwinDemo ? 'Darwin, NT' : 'Weston, FL',
        vibe_tags: isDarwinDemo ? ['Happy Hour', 'Live Music', 'Craft Beer'] : ['Happy Hour', 'Sports Bar', 'Craft Beer'],
        favorite_drinks: ['Beer', 'Cocktails'],
        ghost_mode: false,
        phone_number: isDarwinDemo ? '+61400000001' : '+15550000001',
        phone_country_code: isDarwinDemo ? 'AU' : 'US',
        registration_country: isDarwinDemo ? 'AU' : 'US',
        last_known_lat: isDarwinDemo ? -12.4634 : 26.1003,
        last_known_lng: isDarwinDemo ? 130.8456 : -80.3882,
        is_21_plus_confirmed: true,
        tonight_status: 'going_out',
        privacy_mode: 'public',
      }, { onConflict: 'id' });

      localStorage.setItem('location_permission', 'granted');
      localStorage.setItem('contacts_permission', 'granted');
      localStorage.setItem('notification_permission', 'granted');
      localStorage.setItem('pendingUserName', isDarwinDemo ? 'Sam Demo' : 'Alex Demo');
      localStorage.setItem('age_verified', 'true');
      localStorage.setItem('onboarding_complete', 'true');

      setHasProfile(true);
      setGhostMode(false);
      setCheckingProfile(false);
      checkingRef.current = false;
      return;
    }

    const profileComplete = data && data.name && data.name.trim() !== '' &&
      Array.isArray(data.favorite_drinks) && data.favorite_drinks.length > 0;

    if (profileComplete) {
      localStorage.setItem('pendingUserName', data.name);
      localStorage.setItem('onboarding_complete', 'true');
      if (!localStorage.getItem('location_permission')) {
        localStorage.setItem('location_permission', 'granted');
      }
      if (!localStorage.getItem('contacts_permission')) {
        localStorage.setItem('contacts_permission', 'granted');
      }
      if (!localStorage.getItem('notification_permission')) {
        localStorage.setItem('notification_permission', 'granted');
      }
      if (!localStorage.getItem('age_verified')) {
        localStorage.setItem('age_verified', 'true');
      }
      if (data.phone_country_code || data.registration_country) {
        localStorage.setItem('userCountryCode', data.phone_country_code || data.registration_country || 'US');
      }
    }

    setHasProfile(!!profileComplete);
    setGhostMode(data?.ghost_mode === true);
    setCheckingProfile(false);
    checkingRef.current = false;
  }, [user]);

  useEffect(() => {
    if (!loading && user) {
      checkUserProfile();
    } else if (!loading && !user) {
      setCheckingProfile(false);
    }
  }, [user, loading, checkUserProfile]);

  if (loading || checkingProfile) {
    return (
      <div className="min-h-screen bg-[#FFF5F0] flex items-center justify-center">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-[#E91E63] border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (user && hasProfile) {
    const locationAlreadyGranted = localStorage.getItem('location_permission') === 'granted';
    return (
      <GeofenceProvider autoStart={locationAlreadyGranted} ghostMode={ghostMode}>
      <CheckinRewardToast />
      <Suspense fallback={<PageLoader />}>
        <Routes>
          <Route element={<MainLayout />}>
            <Route path="/home" element={<Home />} />
            <Route path="/map" element={<ErrorBoundary fallbackLabel="Map failed to load"><MapView /></ErrorBoundary>} />
            <Route path="/swarms" element={<SwarmsView />} />
            <Route path="/messages" element={<ErrorBoundary fallbackLabel="Messages failed to load"><MessagesView /></ErrorBoundary>} />
            <Route path="/gifts" element={<GiftsInbox />} />
            <Route path="/profile" element={<ProfileView />} />
            <Route path="/friends" element={<FriendsView />} />
            <Route path="/history" element={<HistoryView />} />
            <Route path="/payments" element={<PaymentsView />} />
          </Route>
          <Route path="/people-nearby" element={<PeopleNearbyView />} />
          <Route path="/create-swarm" element={<CreateSwarm />} />
          <Route path="/settings" element={<SettingsView />} />
          <Route path="/settings/edit-profile" element={<EditProfile />} />
          <Route path="/settings/notifications" element={<NotificationsSettings />} />
          <Route path="/settings/safety" element={<SafetySecurity />} />
          <Route path="/settings/help" element={<HelpCenter />} />
          <Route path="/settings/radar" element={<RadarSettings />} />
          <Route path="/settings/admin/google-places" element={<AdminGooglePlaces />} />
          <Route path="/settings/admin/geofences" element={<AdminGeofences />} />
          <Route path="/settings/admin/osm-import" element={<AdminOSMImport />} />
          <Route path="/settings/admin/venue-analytics" element={<AdminVenueAnalytics />} />
          <Route path="/admin/venues" element={<AdminVenues />} />
          <Route path="/payments/settings" element={<PaymentSettings />} />
          <Route path="/payments/setup" element={<VenmoSetup />} />
          <Route path="/payments/send" element={<SendPayment />} />
          <Route path="/payments/receive" element={<ReceivePayment />} />
          <Route path="/payments/lush-coin" element={<LushCoinPage />} />
          <Route path="/leaderboard" element={<LeaderboardView />} />
          <Route path="/privacy" element={<PrivacyPolicy />} />
          <Route path="/terms" element={<TermsOfService />} />
          <Route path="/" element={<Navigate to="/home" replace />} />
          <Route path="*" element={<Navigate to="/home" replace />} />
        </Routes>
      </Suspense>
      </GeofenceProvider>
    );
  }

  if (!user) {
    return (
      <Suspense fallback={<PageLoader />}>
        <Routes>
          <Route path="/" element={<Onboarding />} />
          <Route path="/signin" element={<SignIn />} />
          <Route path="/signup" element={<SignUp />} />
          <Route path="/verify-phone" element={<PhoneVerification />} />
          <Route path="/demo" element={<CompleteDemoWalkthrough />} />
          <Route path="/privacy" element={<PrivacyPolicy />} />
          <Route path="/terms" element={<TermsOfService />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Suspense>
    );
  }

  const getCurrentStep = () => {
    const hasName = !!localStorage.getItem('pendingUserName');
    const hasLocation = !!localStorage.getItem('location_permission');
    const hasContacts = !!localStorage.getItem('contacts_permission');
    const hasNotifications = !!localStorage.getItem('notification_permission');

    if (!hasName) return '/name-setup';
    if (!hasLocation) return '/location-permission';
    if (!hasContacts) return '/contacts-permission';
    if (!hasNotifications) return '/notifications-permission';
    return '/profile-setup';
  };

  return (
    <Suspense fallback={<PageLoader />}>
      <Routes>
        <Route path="/name-setup" element={<NameSetup />} />
        <Route path="/location-permission" element={<LocationPermission />} />
        <Route path="/contacts-permission" element={<ContactsPermission />} />
        <Route path="/notifications-permission" element={<NotificationsPermission />} />
        <Route path="/profile-setup" element={<ProfileSetup onComplete={() => { setHasProfile(true); }} />} />
        <Route path="*" element={<Navigate to={getCurrentStep()} replace />} />
      </Routes>
    </Suspense>
  );
}

function App() {
  const [ageVerified, setAgeVerified] = useState(
    () => localStorage.getItem('age_verified') === 'true'
  );

  if (!ageVerified) {
    return <AgeGate onPass={() => setAgeVerified(true)} />;
  }

  return (
    <BrowserRouter>
      <AppRouter />
    </BrowserRouter>
  );
}

export default App;
