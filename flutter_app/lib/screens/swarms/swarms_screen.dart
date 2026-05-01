import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';

class SwarmsScreen extends ConsumerWidget {
  const SwarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t(AppStrings.swarmsTitle)),
      ),
      body: Center(
        child: Text(t(AppStrings.swarmsComingSoon)),
      ),
    );
  }
}
