import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../services/analytics_service.dart';
import '../screens/shell/main_shell.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/profile_setup/profile_setup_screen.dart';
import '../screens/permissions/permissions_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/discover/discover_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/edit_profile_screen.dart';
import '../screens/settings/notifications_settings_screen.dart';
import '../screens/settings/safety_settings_screen.dart';
import '../screens/settings/language_settings_screen.dart';
import '../screens/swarms/swarms_screen.dart';
import '../screens/swarms/create_swarm_screen.dart';
import '../screens/premium/premium_screen.dart';
import '../screens/gifts/send_gift_screen.dart';
import '../screens/gifts/gifts_screen.dart';
import '../screens/friends/friends_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/people/people_nearby_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/payments/payments_screen.dart';
import '../screens/social/night_recap_screen.dart';
import '../screens/safety/safe_arrival_screen.dart';
import '../screens/room/the_room_screen.dart';
import '../screens/music/music_shares_screen.dart';
import '../screens/music/music_search_screen.dart';
import '../screens/settings/blocked_users_screen.dart';
import '../screens/auth/reset_password_screen.dart';

final _analyticsObserver = AnalyticsNavigatorObserver();
final _homeObserver = AnalyticsNavigatorObserver();
final _mapObserver = AnalyticsNavigatorObserver();
final _messagesObserver = AnalyticsNavigatorObserver();
final _profileObserver = AnalyticsNavigatorObserver();

// ---------------------------------------------------------------------------
// RouterNotifier
// Holds redirect logic and notifies GoRouter when auth/profile state changes,
// so GoRouter re-evaluates the redirect WITHOUT recreating the router instance.
// ---------------------------------------------------------------------------

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
      final signedOut =
          next.when(data: (u) => u, error: (_, __) => null, loading: () => null) == null;
      if (signedOut) _ref.read(profileSetupDoneProvider.notifier).reset();
      notifyListeners();
    });
    _ref.listen<AsyncValue<UserProfile?>>(currentUserProfileProvider, (_, next) {
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final profileState = _ref.read(currentUserProfileProvider);

    final isAuthenticated = authState.value != null;
    final loc = state.matchedLocation;
    final isOnboarding = loc == '/onboarding';
    final isAuth = loc.startsWith('/signin') ||
        loc.startsWith('/signup') ||
        loc.startsWith('/verify-email') ||
        loc == '/reset-password';
    final isSetupRoute = loc == '/profile-setup' || loc == '/permissions';

    if (!isAuthenticated && !isOnboarding && !isAuth && !isSetupRoute) {
      return '/onboarding';
    }

    if (isAuthenticated) {
      // Wait for profile to finish loading before deciding.
      if (profileState.isLoading) return null;

      // profileSetupDoneProvider is set to true immediately after the upsert
      // in profile_setup_screen, before the realtime stream propagates the
      // change.  This prevents bouncing back to /profile-setup while the
      // stream is still catching up.
      final setupDone = _ref.read(profileSetupDoneProvider);
      final profile = profileState.when(data: (p) => p, error: (_, __) => null, loading: () => null);
      final hasProfile = setupDone || (profile != null && profile.age != null);

      // No complete profile yet → must complete setup first.
      if (!hasProfile && !isSetupRoute) return '/profile-setup';

      // Profile complete, no reason to stay on auth/onboarding screens.
      if (hasProfile && (isOnboarding || isAuth)) return '/home';
    }

    return null;
  }
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

// Used by NotificationService to navigate from outside the widget tree.
GoRouter? _activeRouter;
void navigateFromNotification(String location) => _activeRouter?.go(location);

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);
  final router = GoRouter(
    observers: [_analyticsObserver],
    initialLocation: '/onboarding',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Auth (no shell) ───────────────────────────────────────────────
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/signin', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
      GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/permissions', builder: (_, __) => const PermissionsScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => VerifyEmailScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),

      // ── Main shell with persistent bottom nav ─────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Branch 0 – Home
          StatefulShellBranch(
            observers: [_homeObserver],
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            ],
          ),
          // Branch 1 – Map
          StatefulShellBranch(
            observers: [_mapObserver],
            routes: [
              GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
            ],
          ),
          // Branch 2 – Messages
          StatefulShellBranch(
            observers: [_messagesObserver],
            routes: [
              GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
            ],
          ),
          // Branch 3 – Profile
          StatefulShellBranch(
            observers: [_profileObserver],
            routes: [
              GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
            ],
          ),
        ],
      ),

      // ── Full-screen routes pushed over the shell ───────────────────────
      GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
      GoRoute(
        path: '/chat/:userId',
        builder: (_, state) => ChatScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/notifications-settings', builder: (_, __) => const NotificationsSettingsScreen()),
      GoRoute(path: '/safety-settings', builder: (_, __) => const SafetySettingsScreen()),
      GoRoute(path: '/language-settings', builder: (_, __) => const LanguageSettingsScreen()),
      GoRoute(path: '/swarms', builder: (_, __) => const SwarmsScreen()),
      GoRoute(path: '/create-swarm', builder: (_, __) => const CreateSwarmScreen()),
      GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
      GoRoute(path: '/gifts', builder: (_, __) => const GiftsScreen()),
      GoRoute(
        path: '/send-gift/:userId',
        builder: (_, state) => SendGiftScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(path: '/friends', builder: (_, __) => const FriendsScreen()),
      GoRoute(path: '/people-nearby', builder: (_, __) => const PeopleNearbyScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/night-recap', builder: (_, __) => const NightRecapScreen()),
      GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/payments', builder: (_, __) => const PaymentsScreen()),
      GoRoute(path: '/safe-arrival', builder: (_, __) => const SafeArrivalScreen()),
      GoRoute(
        path: '/room/:venueId',
        builder: (_, state) => TheRoomScreen(
          venueId: state.pathParameters['venueId']!,
          venueName: state.uri.queryParameters['name'],
        ),
      ),
      GoRoute(path: '/music', builder: (_, __) => const MusicSharesScreen()),
      GoRoute(path: '/music-search', builder: (_, __) => const MusicSearchScreen()),
      GoRoute(path: '/blocked-users', builder: (_, __) => const BlockedUsersScreen()),
    ],
  );
  _activeRouter = router;
  return router;
});
