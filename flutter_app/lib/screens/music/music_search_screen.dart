import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/music_search_result.dart';
import '../../providers/music_provider.dart';
import 'widgets/music_search_card.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../widgets/app_loader.dart';

class MusicSearchScreen extends ConsumerWidget {
  const MusicSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final searchQuery = ref.watch(musicSearchQueryProvider);
    final searchResults = ref.watch(musicSearchResultsProvider(searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: Text(t(AppStrings.musicSearchTitle)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                ref.read(musicSearchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: t(AppStrings.musicSearchHintFull),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: searchResults.when(
              data: (results) {
                if (searchQuery.isEmpty) {
                  return Center(
                    child: Text(
                      t(AppStrings.musicStartTyping),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                if (results.isEmpty) {
                  return Center(
                    child: Text(
                      t(AppStrings.musicNoResults),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final track = results[index];
                    return MusicSearchCard(track: track);
                  },
                );
              },
              loading: () => const AppFullLoader(),
              error: (error, stack) => Center(
                child: Text('${t(AppStrings.error)}: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
