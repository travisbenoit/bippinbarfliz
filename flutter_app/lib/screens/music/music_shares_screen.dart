import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/music_provider.dart';
import 'widgets/music_share_card.dart';

class MusicSharesScreen extends ConsumerWidget {
  const MusicSharesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentShares = ref.watch(recentMusicSharesProvider);
    final userShares = ref.watch(userMusicSharesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Music'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Discover'),
              Tab(text: 'My Shares'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Discover Tab
            recentShares.when(
              data: (shares) {
                if (shares.isEmpty) {
                  return Center(
                    child: Text(
                      'No music shared yet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: shares.length,
                  itemBuilder: (context, index) {
                    final share = shares[index];
                    return MusicShareCard(
                      share: share,
                      onPlay: () => _launchUrl(share.previewUrl),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),

            // My Shares Tab
            userShares.when(
              data: (shares) {
                if (shares.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You haven\'t shared any music yet',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: shares.length,
                  itemBuilder: (context, index) {
                    final share = shares[index];
                    return MusicShareCard(
                      share: share,
                      onPlay: () => _launchUrl(share.previewUrl),
                      isOwn: true,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Navigate to music search screen
            Navigator.of(context).pushNamed('/music-search');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null) return;

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Could not launch URL: $e');
    }
  }
}
