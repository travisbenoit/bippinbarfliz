import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'localization_service.dart';
import '../providers/localization_provider.dart';

extension LocalizationHelper on BuildContext {
  LocalizationService get localization {
    return ProviderScope.containerOf(this).read(localizationServiceProvider);
  }

  String translate(String key, {Map<String, String>? parameters}) {
    return localization.translate(key, parameters: parameters);
  }

  String t(String key) => translate(key);

  String formatDate(DateTime date) => localization.formatDate(date);

  String formatTime(DateTime dateTime) => localization.formatTime(dateTime);

  String formatCurrency(double amount) => localization.formatCurrency(amount);

  String formatDistance(double meters) => localization.formatDistance(meters);

  String formatTemperature(double celsius) => localization.formatTemperature(celsius);

  RegionalConfig? get regionalConfig => localization.regionalConfig;
}

extension LocalizationHelperRef on WidgetRef {
  LocalizationService get localization => read(localizationServiceProvider);

  String translate(String key, {Map<String, String>? parameters}) {
    return localization.translate(key, parameters: parameters);
  }

  String t(String key) => translate(key);

  String formatDate(DateTime date) => localization.formatDate(date);

  String formatTime(DateTime dateTime) => localization.formatTime(dateTime);

  String formatCurrency(double amount) => localization.formatCurrency(amount);

  String formatDistance(double meters) => localization.formatDistance(meters);

  String formatTemperature(double celsius) => localization.formatTemperature(celsius);

  RegionalConfig? get regionalConfig => localization.regionalConfig;
}
