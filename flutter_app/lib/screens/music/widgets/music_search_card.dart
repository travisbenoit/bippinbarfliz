import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/music_search_result.dart';
import '../../../providers/music_provider.dart';
import '../../../extensions/localization_extension.dart';
import '../../../i18n/app_strings.dart';
import '../../../providers/localization_provider.dart';

class MusicSearchCard extends ConsumerWidget {
  final MusicSearchResult track;

  const MusicSearchCard({
    super.key,
    required this.track,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        leading: track.artworkUrl != null
            ? CachedNetworkImage(
                imageUrl: track.artworkUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.music_note),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.music_note),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.music_note),
              ),
        title: Text(
          track.trackName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artistName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareMusic(context, ref),
        ),
      ),
    );
  }

  void _shareMusic(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr(AppStrings.musicShare)),
        content: Text(
            '${track.trackName}\n${context.tr(AppStrings.musicBy)} ${track.artistName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr(AppStrings.cancel)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performShare(context, ref);
            },
            child: Text(context.tr(AppStrings.share)),
          ),
        ],
      ),
    );
  }

  Future<void> _performShare(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final successMsg = context.tr(AppStrings.musicSharedOk);
    final failMsg = context.tr(AppStrings.musicShareFailed);
    final result = await ref.read(
      shareMusicMutationProvider(track).future,
    );

    if (result != null) {
      messenger.showSnackBar(SnackBar(content: Text(successMsg)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(failMsg)));
    }
  }
}
