import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/music_track.dart';
import '../models/music_search_result.dart';
import '../services/music_service.dart';

final musicServiceProvider = Provider((ref) => MusicService());

final musicSearchQueryProvider = StateProvider<String>((ref) => '');

final musicSearchResultsProvider =
    FutureProvider.family<List<MusicSearchResult>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final service = ref.watch(musicServiceProvider);
  return service.searchItunes(query);
});

final userMusicSharesProvider = FutureProvider<List<MusicTrack>>((ref) async {
  final service = ref.watch(musicServiceProvider);
  return service.getUserMusicShares();
});

final recentMusicSharesProvider =
    StreamProvider<List<MusicTrack>>((ref) async* {
  final service = ref.watch(musicServiceProvider);
  yield* service.streamRecentMusicShares();
});

final sharedMusicProvider =
    FutureProvider.family<MusicTrack?, String>((ref, shareId) async {
  final service = ref.watch(musicServiceProvider);
  return service.getSharedMusic(shareId);
});

final shareMusicMutationProvider =
    FutureProvider.family<String?, MusicSearchResult>((ref, track) async {
  final service = ref.watch(musicServiceProvider);
  return service.shareMusic(track: track);
});
