import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';

class GiftsScreen extends ConsumerWidget {
  const GiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t(AppStrings.giftsTitle)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.card_giftcard,
              size: 80,
              color: Color(0xFFE91E63),
            ),
            const SizedBox(height: 16),
            Text(
              t(AppStrings.giftsEmpty),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              t(AppStrings.giftsEmptySub),
              style: const TextStyle(),
            ),
          ],
        ),
      ),
    );
  }
}
