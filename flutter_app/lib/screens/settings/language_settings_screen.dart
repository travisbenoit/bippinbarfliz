import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../i18n/localization_helper.dart';
import '../../providers/localization_provider.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = ref.watch(localizationServiceProvider);
    final currentLocale = ref.watch(currentLocaleProvider);

    final languages = [
      ('en', 'English', 'English'),
      ('es', 'Español', 'Spanish'),
      ('fr', 'Français', 'French'),
      ('de', 'Deutsch', 'German'),
      ('it', 'Italiano', 'Italian'),
      ('pt', 'Português', 'Portuguese'),
      ('ja', '日本語', 'Japanese'),
      ('zh', '中文', 'Chinese'),
      ('ko', '한국어', 'Korean'),
      ('ru', 'Русский', 'Russian'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.t('settings.title')),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Language',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...languages.map((lang) {
            final code = lang.$1;
            final nativeName = lang.$2;
            final englishName = lang.$3;

            return ListTile(
              title: Text(nativeName),
              subtitle: Text(englishName),
              trailing: currentLocale == code
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              selected: currentLocale == code,
              onTap: () {
                localization.changeLanguage(code);
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
