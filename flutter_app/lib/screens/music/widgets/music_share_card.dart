import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/music_track.dart';
import '../../../extensions/localization_extension.dart';
import '../../../i18n/app_strings.dart';

class MusicShareCard extends StatefulWidget {
  final MusicTrack share;
  final VoidCallback? onPlay;
  final bool isOwn;

  const MusicShareCard({
    super.key,
    required this.share,
    this.onPlay,
    this.isOwn = false,
  });

  @override
  State<MusicShareCard> createState() => _MusicShareCardState();
}

class _MusicShareCardState extends State<MusicShareCard> {
  bool _liked = false;

  void _toggleLike() => setState(() => _liked = !_liked);

  void _share() {
    final track = widget.share;
    final text = StringBuffer('🎵 ${track.trackName} by ${track.artistName}');
    if (track.collectionName != null) text.write(' — ${track.collectionName}');
    if (track.previewUrl != null) text.write('\n${track.previewUrl}');
    text.write('\n\nShared via Barfliz 🍸');
    SharePlus.instance.share(ShareParams(text: text.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: widget.share.artworkUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.share.artworkUrl!,
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
              widget.share.trackName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              widget.share.artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: widget.share.previewUrl != null
                ? IconButton(
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: widget.onPlay,
                  )
                : null,
          ),
          if (widget.share.collectionName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.share.collectionName!,
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
                if (!widget.isOwn)
                  TextButton.icon(
                    onPressed: _toggleLike,
                    icon: Icon(
                      _liked ? Icons.favorite : Icons.favorite_border,
                      color: _liked ? const Color(0xFFE91E63) : null,
                    ),
                    label: Text(
                      context.tr(AppStrings.musicLike),
                      style: TextStyle(
                        color: _liked ? const Color(0xFFE91E63) : null,
                      ),
                    ),
                  ),
                TextButton.icon(
                  onPressed: _share,
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
