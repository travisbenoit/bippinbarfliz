import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/localization_provider.dart';

// Usage in any widget that has a BuildContext:
//   context.tr(AppStrings.someKey)
//
// The read is non-listening on purpose — child StatelessWidgets get rebuilt
// automatically when their ConsumerWidget ancestor watches tProvider and the
// language changes, so we only need the current value here.
extension LocalizationContextX on BuildContext {
  String tr(String key) =>
      ProviderScope.containerOf(this, listen: false)
          .read(localizationServiceProvider)
          .translate(key);
}
