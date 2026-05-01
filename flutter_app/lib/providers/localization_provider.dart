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

// Convenience provider — watch this in any ConsumerWidget to get a translate
// function that triggers a rebuild when the language changes.
//
// Usage:
//   final t = ref.watch(tProvider);
//   Text(t(AppStrings.someKey))
final tProvider = Provider<String Function(String)>((ref) {
  final service = ref.watch(localizationServiceProvider);
  // Wrap in a new closure each rebuild — method tearoffs from the same
  // instance are equal in modern Dart, so returning `service.translate`
  // directly would make Provider see "no change" and skip widget rebuilds.
  return (String key) => service.translate(key);
});
