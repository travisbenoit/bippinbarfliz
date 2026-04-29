import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';

class CreateSwarmScreen extends ConsumerWidget {
  const CreateSwarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Swarm'),
      ),
      body: const Center(
        child: Text('Create a new group meetup'),
      ),
    );
  }
}
