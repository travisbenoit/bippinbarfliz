import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/music_search_result.dart';
import '../../../providers/music_provider.dart';

class MusicSearchCard extends ConsumerWidget {
  final MusicSearchResult track;

  const MusicSearchCard({
    Key? key,
    required this.track,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  color: Colors.grey[300],
                  child: const Icon(Icons.music_note),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.music_note),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: Colors.grey[300],
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
      builder: (context) => AlertDialog(
        title: const Text('Share This Track?'),
        content: Text('${track.trackName}\nby ${track.artistName}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performShare(context, ref);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _performShare(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(
      shareMusicMutationProvider(track).future,
    );

    if (result != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Music shared successfully!')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to share music')),
      );
    }
  }
}
