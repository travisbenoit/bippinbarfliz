import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'config/theme.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'providers/localization_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Stripe.publishableKey = AppConfig.stripePublishableKey;
  // await Stripe.instance.applySettings();

  await NotificationService.initialize();

  await AnalyticsService.instance.initialize(
    apiKey: AppConfig.posthogApiKey,
    host: AppConfig.posthogHost,
  );

  runApp(
    const ProviderScope(
      child: BarflizApp(),
    ),
  );
}

class BarflizApp extends ConsumerStatefulWidget {
  const BarflizApp({super.key});

  @override
  ConsumerState<BarflizApp> createState() => _BarflizAppState();
}

class _BarflizAppState extends ConsumerState<BarflizApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localizationService = ref.read(localizationServiceProvider);
      localizationService.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final currentLocale = ref.watch(currentLocaleProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final themeMode = ref.watch(themeModeProvider);

    if (isLoading) {
      return MaterialApp(
        title: 'Barfliz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('es', 'ES'),
          Locale('fr', 'FR'),
          Locale('de', 'DE'),
          Locale('it', 'IT'),
          Locale('pt', 'BR'),
          Locale('ja', 'JP'),
          Locale('zh', 'CN'),
          Locale('ko', 'KR'),
          Locale('ru', 'RU'),
        ],
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Barfliz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: Locale(currentLocale),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
        Locale('de', 'DE'),
        Locale('it', 'IT'),
        Locale('pt', 'BR'),
        Locale('ja', 'JP'),
        Locale('zh', 'CN'),
        Locale('ko', 'KR'),
        Locale('ru', 'RU'),
      ],
      routerConfig: router,
    );
  }
}
