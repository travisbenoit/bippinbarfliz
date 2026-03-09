import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class RegionalConfig {
  final String languageCode;
  final String regionCode;
  final String dateFormat;
  final String timeFormat;
  final String datetimeFormat;
  final String currencyCode;
  final String currencySymbol;
  final String currencyPosition; // 'before' or 'after'
  final String decimalSeparator;
  final String thousandsSeparator;
  final String temperatureUnit; // 'C' or 'F'
  final String distanceUnit; // 'miles' or 'kilometers'
  final int weekStartDay; // 0 = Sunday, 1 = Monday

  RegionalConfig({
    required this.languageCode,
    required this.regionCode,
    required this.dateFormat,
    required this.timeFormat,
    required this.datetimeFormat,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyPosition,
    required this.decimalSeparator,
    required this.thousandsSeparator,
    required this.temperatureUnit,
    required this.distanceUnit,
    required this.weekStartDay,
  });
}

class LocalizationService extends ChangeNotifier {
  Locale _currentLocale = const Locale('en', 'US');
  Map<String, String> _translations = {};
  RegionalConfig? _regionalConfig;
  bool _isLoading = false;

  Locale get currentLocale => _currentLocale;
  Map<String, String> get translations => _translations;
  RegionalConfig? get regionalConfig => _regionalConfig;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get system locale
      final systemLocale = PlatformDispatcher.instance.locale;
      _currentLocale = Locale(systemLocale.languageCode, systemLocale.countryCode);

      // Load translations from database
      await loadTranslations(_currentLocale.languageCode);

      // Load regional configuration
      await loadRegionalConfig(_currentLocale.languageCode);
    } catch (e) {
      debugPrint('Error initializing localization: $e');
      // Fall back to English
      _currentLocale = const Locale('en', 'US');
      await loadTranslations('en');
      await loadRegionalConfig('en');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTranslations(String languageCode) async {
    try {
      final supabase = SupabaseService.instance;

      // Get language ID
      final langResponse = await supabase.client
          .from('languages')
          .select('id')
          .eq('code', languageCode)
          .maybeSingle();

      if (langResponse == null) {
        // Fall back to English
        await loadTranslations('en');
        return;
      }

      final languageId = langResponse['id'];

      // Get all translations for this language
      final translations = await supabase.client
          .from('translations')
          .select('translation_keys(key), translated_text')
          .eq('language_id', languageId);

      _translations = {};
      for (final translation in translations) {
        final key = translation['translation_keys']['key'];
        final text = translation['translated_text'];
        _translations[key] = text;
      }
    } catch (e) {
      debugPrint('Error loading translations: $e');
      _translations = {};
    }
  }

  Future<void> loadRegionalConfig(String languageCode) async {
    try {
      final supabase = SupabaseService.instance;

      // Get language ID
      final langResponse = await supabase.client
          .from('languages')
          .select('id')
          .eq('code', languageCode)
          .maybeSingle();

      if (langResponse == null) return;

      final languageId = langResponse['id'];

      // Get default region for this language
      final region = await supabase.client
          .from('regions')
          .select('*')
          .eq('language_id', languageId)
          .eq('is_default_for_language', true)
          .maybeSingle();

      if (region != null) {
        _regionalConfig = RegionalConfig(
          languageCode: languageCode,
          regionCode: region['code'],
          dateFormat: region['date_format'],
          timeFormat: region['time_format'],
          datetimeFormat: region['datetime_format'],
          currencyCode: region['currency_code'],
          currencySymbol: region['currency_symbol'],
          currencyPosition: region['currency_position'],
          decimalSeparator: region['decimal_separator'],
          thousandsSeparator: region['thousands_separator'],
          temperatureUnit: region['temperature_unit'],
          distanceUnit: region['distance_unit'],
          weekStartDay: region['week_start_day'],
        );
      }
    } catch (e) {
      debugPrint('Error loading regional config: $e');
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == _currentLocale.languageCode) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentLocale = Locale(languageCode);
      await loadTranslations(languageCode);
      await loadRegionalConfig(languageCode);
    } catch (e) {
      debugPrint('Error changing language: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String translate(String key, {Map<String, String>? parameters}) {
    var text = _translations[key] ?? key;

    if (parameters != null) {
      parameters.forEach((paramKey, paramValue) {
        text = text.replaceAll('{{$paramKey}}', paramValue);
      });
    }

    return text;
  }

  String formatDate(DateTime date) {
    if (_regionalConfig == null) {
      return date.toString().split(' ')[0];
    }

    final format = _regionalConfig!.dateFormat;
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return format
        .replaceAll('YYYY', year.toString())
        .replaceAll('MM', month)
        .replaceAll('DD', day);
  }

  String formatTime(DateTime dateTime) {
    if (_regionalConfig == null) {
      return dateTime.toString().split(' ')[1];
    }

    final format = _regionalConfig!.timeFormat;
    final hours = dateTime.hour;
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    final seconds = dateTime.second.toString().padLeft(2, '0');

    final hour12 = hours % 12 == 0 ? 12 : hours % 12;
    final ampm = hours >= 12 ? 'PM' : 'AM';

    return format
        .replaceAll('HH', hours.toString().padLeft(2, '0'))
        .replaceAll('h', hour12.toString())
        .replaceAll('mm', minutes)
        .replaceAll('ss', seconds)
        .replaceAll('A', ampm);
  }

  String formatCurrency(double amount) {
    if (_regionalConfig == null) {
      return '\$$amount';
    }

    final config = _regionalConfig!;
    final decimalFormat = amount.toStringAsFixed(2).split('.');
    var wholePart = decimalFormat[0];
    final decimalPart = decimalFormat[1];

    // Add thousands separator
    final parts = <String>[];
    int count = 0;
    for (int i = wholePart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        parts.insert(0, config.thousandsSeparator);
      }
      parts.insert(0, wholePart[i]);
      count++;
    }

    wholePart = parts.join();

    final formatted = '$wholePart${config.decimalSeparator}$decimalPart';

    if (config.currencyPosition == 'before') {
      return '${config.currencySymbol}$formatted';
    } else {
      return '$formatted${config.currencySymbol}';
    }
  }

  String formatDistance(double meters) {
    if (_regionalConfig == null) {
      return '${(meters / 1609).toStringAsFixed(1)} miles';
    }

    if (_regionalConfig!.distanceUnit == 'kilometers') {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${(meters / 1609).toStringAsFixed(1)} miles';
    }
  }

  String formatTemperature(double celsius) {
    if (_regionalConfig == null) {
      return '$celsius°C';
    }

    if (_regionalConfig!.temperatureUnit == 'C') {
      return '${celsius.toStringAsFixed(1)}°C';
    } else {
      final fahrenheit = (celsius * 9 / 5) + 32;
      return '${fahrenheit.toStringAsFixed(1)}°F';
    }
  }
}
