import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/music_track.dart';
import '../../../extensions/localization_extension.dart';
import '../../../i18n/app_strings.dart';

class MusicShareCard extends StatelessWidget {
  final MusicTrack share;
  final VoidCallback? onPlay;
  final bool isOwn;

  const MusicShareCard({
    Key? key,
    required this.share,
    this.onPlay,
    this.isOwn = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: share.artworkUrl != null
                ? CachedNetworkImage(
                    imageUrl: share.artworkUrl!,
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
              share.trackName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              share.artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: share.previewUrl != null
                ? IconButton(
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: onPlay,
                  )
                : null,
          ),
          if (share.collectionName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                share.collectionName!,
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isOwn)
                  TextButton.icon(
                    onPressed: () {
                      // Implement like/favorite functionality
                    },
                    icon: const Icon(Icons.favorite_border),
                    label: Text(context.tr(AppStrings.musicLike)),
                  ),
                TextButton.icon(
                  onPressed: () {
                    // Implement share functionality
                  },
                  icon: const Icon(Icons.share),
                  label: Text(context.tr(AppStrings.musicShare)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
