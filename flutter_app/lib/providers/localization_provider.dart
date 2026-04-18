import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../i18n/localization_service.dart';

final localizationServiceProvider =
    ChangeNotifierProvider<LocalizationService>((ref) {
  return LocalizationService();
});

final currentLocaleProvider = Provider<String>((ref) {
  final service = ref.watch(localizationServiceProvider);
  return service.currentLocale.languageCode;
});

final translationsProvider = Provider<Map<String, String>>((ref) {
  final service = ref.watch(localizationServiceProvider);
  return service.translations;
});

final regionalConfigProvider = Provider<RegionalConfig?>((ref) {
  final service = ref.watch(localizationServiceProvider);
  return service.regionalConfig;
});

final isLoadingProvider = Provider<bool>((ref) {
  final service = ref.watch(localizationServiceProvider);
  return service.isLoading;
});
