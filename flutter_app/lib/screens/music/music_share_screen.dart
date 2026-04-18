import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/itunes_music_service.dart';

class MusicShareScreen extends StatefulWidget {
  const MusicShareScreen({Key? key}) : super(key: key);

  @override
  State<MusicShareScreen> createState() => _MusicShareScreenState();
}

class _MusicShareScreenState extends State<MusicShareScreen> {
  final _musicService = ITunesMusicService();
  final _searchController = TextEditingController();

  List<ITunesTrack> _searchResults = [];
  bool _isSearching = false;
  ITunesTrack? _selectedTrack;
  bool _isSharing = false;
  String? _shareError;

  @override
  void dispose() {
    _searchController.dispose();
    _musicService.dispose();
    super.dispose();
  }

  Future<void> _searchTracks(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() {
      _isSearching = true;
      _shareError = null;
    });

    try {
      final results = await _musicService.searchTracks(query);
      setState(() => _searchResults = results);
    } catch (e) {
      setState(() => _shareError = 'Search failed: ${e.toString()}');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _shareTrack(ITunesTrack track) async {
    setState(() {
      _isSharing = true;
      _shareError = null;
    });

    try {
      final share = await _musicService.createPublicShare(
        itunesTrackId: track.id,
        trackName: track.name,
        artistName: track.artist,
        artworkUrl: track.artworkUrl,
        previewUrl: track.previewUrl,
        collectionName: track.collectionName,
      );

      if (share != null) {
        _musicService.shareTrack(
          trackName: track.name,
          artistName: track.artist,
          shareId: share.id,
          artworkUrl: track.artworkUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Song shared successfully!')),
          );
          context.pop();
        }
      }
    } catch (e) {
      setState(() => _shareError = 'Failed to share: ${e.toString()}');
    } finally {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share a Song'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search on Apple Music...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchTracks,
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_shareError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _shareError!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              )
            else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('No songs found'),
                ),
              )
            else if (_searchResults.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final track = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: track.artworkUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                track.artworkUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.music_note),
                              ),
                            )
                          : const Icon(Icons.music_note),
                      title: Text(track.name),
                      subtitle: Text(track.artist),
                      trailing: IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: _isSharing ? null : () => _shareTrack(track),
                      ),
                    ),
                  );
                },
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('Search for a song to share'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
