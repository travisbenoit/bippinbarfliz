# Internationalization (i18n) Implementation Guide

## Overview

This document describes the comprehensive internationalization (i18n) system implemented for Barfliz. The system supports multiple languages and regional variants with shared translation keys across both the React web app and Flutter mobile app.

## Architecture

### Database Schema

The i18n system is built on five core database tables:

#### 1. `languages`
Stores supported languages and their metadata.

```sql
- id: UUID (Primary Key)
- code: TEXT (e.g., 'en', 'es', 'fr')
- name: TEXT (English name)
- native_name: TEXT (Name in native language)
- locale_tag: TEXT (Full locale, e.g., 'en-US')
- is_active: BOOLEAN (Show in language picker)
- is_default: BOOLEAN (Default language)
- sort_order: INTEGER (Display order)
```

**Supported Languages:**
- English (en)
- Spanish (es)
- French (fr)
- German (de)
- Italian (it)
- Portuguese (pt)
- Japanese (ja)
- Chinese (zh)
- Korean (ko)
- Russian (ru)

#### 2. `regions`
Stores regional configurations for localization (date formats, currency, etc).

```sql
- id: UUID (Primary Key)
- language_id: UUID (Foreign Key to languages)
- code: TEXT (Region code, e.g., 'US', 'GB', 'MX')
- name: TEXT (Region name)
- locale_tag: TEXT (Full locale tag)
- country_code: TEXT (ISO 3166-1 alpha-2)
- is_default_for_language: BOOLEAN
- date_format: TEXT (e.g., 'MM/DD/YYYY', 'DD/MM/YYYY')
- time_format: TEXT (e.g., 'h:mm A', 'HH:mm')
- datetime_format: TEXT
- currency_code: TEXT (e.g., 'USD', 'EUR')
- currency_symbol: TEXT (e.g., '$', '€')
- currency_position: TEXT ('before' or 'after')
- decimal_separator: TEXT ('.' or ',')
- thousands_separator: TEXT (',' or '.')
- temperature_unit: TEXT ('C' or 'F')
- distance_unit: TEXT ('miles' or 'kilometers')
- week_start_day: INTEGER (0=Sunday, 1=Monday)
```

**Pre-configured Regions:**
- English: US, GB, CA, AU
- Spanish: ES, MX
- Portuguese: BR
- French: FR
- German: DE
- Japanese: JP

#### 3. `translation_keys`
Master list of all translatable string keys used across platforms.

```sql
- id: UUID (Primary Key)
- key: TEXT UNIQUE (Dot-notation key, e.g., 'nav.explore')
- description: TEXT (Purpose of this key)
- category: TEXT (e.g., 'navigation', 'authentication', 'messages')
- platform: TEXT ('web', 'mobile', 'shared')
- requires_context: BOOLEAN (Has interpolation variables)
- context_example: TEXT (Example of variable usage)
```

#### 4. `translations`
Actual translated content for each key-language combination.

```sql
- id: UUID (Primary Key)
- key_id: UUID (Foreign Key to translation_keys)
- language_id: UUID (Foreign Key to languages)
- translated_text: TEXT (The translated string)
- is_complete: BOOLEAN (Is translation finished)
- needs_review: BOOLEAN (Requires QA review)
- notes: TEXT (Translation notes)
- UNIQUE(key_id, language_id)
```

#### 5. `user_language_preferences`
User-specific language and region selections.

```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key to auth.users)
- language_id: UUID (Foreign Key to languages)
- region_id: UUID (Foreign Key to regions)
- auto_detect: BOOLEAN (Auto-detect from device)
```

### Content Reference Tables

Additional tables store content that's translatable:

- **`vibe_tags`** - Mood/activity tags (Happy Hour, Dance Party, etc.)
- **`drink_categories`** - Drink types (Whiskey, Vodka, Beer, etc.)
- **`mixed_drinks`** - Specific cocktails (Margarita, Mojito, etc.)
- **`interests`** - User interest categories (Music, Sports, Travel, etc.)
- **`looking_for_options`** - Relationship intent (New Friends, Dating, etc.)
- **`conversation_starters`** - Template prompts for profiles
- **`virtual_items`** - Emoji, drinks, gifts (already existed)

## Translation Keys Format

All translation keys use **dot notation** for hierarchical organization:

```
section.subsection.key
```

**Categories:**
- `nav.*` - Navigation items
- `auth.*` - Authentication
- `messages.*` - Messaging
- `swarms.*` - Swarms/groups
- `settings.*` - Settings
- `profile.*` - Profile pages
- `payments.*` - Payments
- `gifts.*` - Gifts/virtual items
- `music.*` - Music sharing
- `common.*` - Common actions
- `validation.*` - Validation messages
- `location.*` - Location-related
- `weather.*` - Weather
- `transport.*` - Transportation

## React Web Implementation

### Setup

1. **Installation**
```bash
npm install i18next i18next-browser-languagedetector i18next-http-backend react-i18next
```

2. **Configuration** (`src/i18n/config.ts`)
   - Initializes i18next with language detection
   - Loads English translations as fallback
   - Configures interpolation for variable substitution

3. **Translation Keys** (`src/i18n/translationKeys.ts`)
   - TypeScript constants for all keys
   - Provides IDE autocomplete
   - Matches Flutter implementation for consistency

4. **Custom Hook** (`src/i18n/useI18n.ts`)
   - `useI18n()` hook provides translation and formatting utilities
   - Loads regional configuration from database
   - Provides formatting helpers for dates, times, currencies, distances, temperatures

### Usage in React Components

#### Basic Translation
```typescript
import { useI18n } from '@/i18n';
import { TRANSLATION_KEYS } from '@/i18n';

function MyComponent() {
  const { t } = useI18n();

  return <h1>{t(TRANSLATION_KEYS.nav.swarms)}</h1>;
}
```

#### With Interpolation
```typescript
const { t } = useI18n();
const text = t('location.miles_away', { distance: '2.5' });
// Output: "2.5 miles away"
```

#### Regional Formatting
```typescript
const { formatDate, formatCurrency, formatDistance, formatTemperature } = useI18n();

<div>
  <p>Date: {formatDate(new Date())}</p>
  <p>Price: {formatCurrency(19.99)}</p>
  <p>Distance: {formatDistance(5000)}</p>
  <p>Temp: {formatTemperature(25)}</p>
</div>
```

#### Change Language
```typescript
const { changeLanguage } = useI18n();

<button onClick={() => changeLanguage('es')}>
  Cambiar a Español
</button>
```

## Flutter Mobile Implementation

### Setup

1. **Translation Keys** (`lib/i18n/translation_keys.dart`)
   - Dart class with static string constants
   - Exactly matches React implementation
   - Provides same IDE autocomplete benefits

2. **Localization Service** (`lib/i18n/localization_service.dart`)
   - Extends `ChangeNotifier` for reactive updates
   - Loads translations from Supabase database
   - Provides regional configuration and formatting utilities
   - `RegionalConfig` class mirrors database schema

### Usage in Flutter

#### Basic Setup
```dart
import 'package:provider/provider.dart';
import 'package:barfliz/i18n/localization_service.dart';

void main() async {
  final localizationService = LocalizationService();
  await localizationService.initialize();

  runApp(
    ChangeNotifierProvider<LocalizationService>.value(
      value: localizationService,
      child: const MyApp(),
    ),
  );
}
```

#### Basic Translation
```dart
import 'package:provider/provider.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context);

    return Text(
      localizationService.translate(
        TranslationKeys.swarmsTitle
      ),
    );
  }
}
```

#### With Interpolation
```dart
final text = localizationService.translate(
  TranslationKeys.locationMilesAway,
  parameters: {'distance': '2.5'},
);
```

#### Regional Formatting
```dart
final localizationService =
    Provider.of<LocalizationService>(context);

Column(
  children: [
    Text(localizationService.formatDate(DateTime.now())),
    Text(localizationService.formatCurrency(19.99)),
    Text(localizationService.formatDistance(5000)),
    Text(localizationService.formatTemperature(25)),
  ],
)
```

#### Change Language
```dart
await localizationService.changeLanguage('es');
```

## Database Workflow

### Adding New Translation Keys

1. **Create the key** in `translation_keys` table:
```sql
INSERT INTO translation_keys (key, description, category, platform)
VALUES ('payment.send_money', 'Send money action', 'payments', 'shared');
```

2. **Add English translation**:
```sql
INSERT INTO translations (key_id, language_id, translated_text)
SELECT tk.id, l.id, 'Send Money'
FROM translation_keys tk, languages l
WHERE tk.key = 'payment.send_money' AND l.code = 'en';
```

3. **Add other language translations** as needed

4. **Update TypeScript constants** (`TRANSLATION_KEYS`)

5. **Update Dart constants** (`TranslationKeys`)

### Translating to a New Language

1. **Create language record** (if not exists):
```sql
INSERT INTO languages (code, name, native_name, locale_tag, is_active)
VALUES ('de', 'German', 'Deutsch', 'de-DE', true);
```

2. **Create default region**:
```sql
INSERT INTO regions (
  language_id, code, name, locale_tag, country_code,
  is_default_for_language, date_format, time_format,
  currency_code, currency_symbol, ...
)
VALUES (...);
```

3. **Bulk insert translations** from English originals:
```sql
INSERT INTO translations (key_id, language_id, translated_text)
SELECT tk.id, l.id, t_en.translated_text
FROM translation_keys tk
JOIN translations t_en ON tk.id = t_en.key_id
JOIN languages l_en ON t_en.language_id = l_en.id
CROSS JOIN languages l
WHERE l_en.code = 'en' AND l.code = 'de'
  AND NOT EXISTS (
    SELECT 1 FROM translations t_existing
    WHERE t_existing.key_id = tk.id AND t_existing.language_id = l.id
  );
```

4. **Update translations** with actual translations (not just English copies)

5. **Review and mark complete**:
```sql
UPDATE translations SET needs_review = false, is_complete = true
WHERE language_id = (SELECT id FROM languages WHERE code = 'de');
```

## Regional Configurations

### Date Formats
- **US**: MM/DD/YYYY (12-hour time)
- **EU**: DD/MM/YYYY (24-hour time)
- **ISO**: YYYY-MM-DD (24-hour time)
- **Japan**: YYYY/MM/DD (24-hour time)

### Currency Formatting
- **Position**: Before ($100.00) or After (100,00 €)
- **Decimal**: . or ,
- **Thousands**: , or .

### Temperature
- **Fahrenheit**: US, AU (English)
- **Celsius**: Most other countries

### Distance
- **Miles**: US, UK, AU
- **Kilometers**: Most other countries

### Week Start
- **Sunday**: US, AU, JP
- **Monday**: Most EU countries

## Best Practices

### In React
1. Always use `TRANSLATION_KEYS` constants for type safety
2. Use `useI18n()` hook instead of `useTranslation()` directly
3. Format dates, currencies, and distances using regional helpers
4. Store user language preference in database
5. Lazy-load translations for large language files

### In Flutter
1. Use `TranslationKeys` constants consistently
2. Initialize `LocalizationService` before app startup
3. Always use `Provider` for accessing the service
4. Handle loading states while fetching translations
5. Test with multiple regions to verify formatting

### Translation Keys
1. Use consistent naming across platforms
2. Use past tense for completed actions (e.g., "Payment sent")
3. Use imperative for buttons (e.g., "Send Payment")
4. Keep keys organized by feature
5. Document context when adding new keys

### Database
1. Always mark `is_complete = false` while translating
2. Use `needs_review = true` for translations needing QA
3. Keep `is_active = false` for deprecated languages
4. Test with actual regional settings
5. Use transactions for bulk updates

## Fallback Chain

When a translation is not available, the system falls back in this order:

1. **User's selected language and region** (e.g., es-MX)
2. **Language default region** (e.g., es-ES if es-MX not available)
3. **English default region** (en-US)
4. **Translation key** (last resort, returns the key itself)

## Performance Considerations

### React
- i18next caches translations in localStorage
- Language detection happens once on app load
- Regional config loaded on language change
- Lazy-load large translation bundles

### Flutter
- Translations loaded asynchronously on app start
- `ChangeNotifier` batches updates
- Consider offline-first caching for translations
- Use `FutureBuilder` for async translation loading

## Security Considerations

1. **RLS Policies**: All tables have RLS enabled
   - Languages and regions are public-readable
   - Translations are public-readable
   - User preferences are user-specific

2. **Validation**: Always validate translation keys exist
3. **Injection**: Use parameterized formatting for interpolation
4. **Rate Limiting**: Consider rate limits on translation API calls

## Migration Guide

If moving from hardcoded strings to i18n:

### Phase 1: Setup (Done)
- Create i18n infrastructure
- Create translation keys
- Load English translations

### Phase 2: Integration
- Replace hardcoded strings with translation keys
- Update React components to use `useI18n()`
- Update Flutter screens to use `LocalizationService`
- Test all UI with translations

### Phase 3: Content
- Translate to priority languages
- Add regional configurations
- Review translations for context accuracy

### Phase 4: Optimization
- Measure performance impact
- Optimize bundle sizes
- Implement lazy loading
- Monitor translation coverage

## Troubleshooting

### Missing Translations
- Check if key exists in `translation_keys` table
- Verify language is `is_active = true`
- Check `translations` table for key-language combo

### Wrong Regional Formatting
- Verify region `is_default_for_language = true`
- Check regional config format strings
- Test with different locale_tag values

### React App Not Loading Translations
- Ensure i18n initialized in main.tsx
- Check browser localStorage for saved language
- Verify LanguageDetector plugin working

### Flutter Translations Empty
- Ensure `LocalizationService.initialize()` awaited
- Check Supabase connection
- Verify user has read permissions on translations table

## References

- i18next Documentation: https://www.i18next.com/
- React-i18next: https://react.i18next.com/
- Flutter Internationalization: https://docs.flutter.dev/development/accessibility-and-localization/internationalization
- CLDR (Common Locale Data Repository): https://cldr.unicode.org/
