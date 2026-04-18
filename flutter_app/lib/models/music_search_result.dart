class MusicSearchResult {
  final String itunesTrackId;
  final String trackName;
  final String artistName;
  final String? artworkUrl;
  final String? previewUrl;
  final String? collectionName;
  final String? releaseDate;
  final String? platform;

  MusicSearchResult({
    required this.itunesTrackId,
    required this.trackName,
    required this.artistName,
    this.artworkUrl,
    this.previewUrl,
    this.collectionName,
    this.releaseDate,
    this.platform = 'iTunes',
  });

  factory MusicSearchResult.fromItunes(Map<String, dynamic> json) {
    return MusicSearchResult(
      itunesTrackId: json['trackId'].toString(),
      trackName: json['trackName'] ?? 'Unknown',
      artistName: json['artistName'] ?? 'Unknown',
      artworkUrl: json['artworkUrl100'] ?? json['artworkUrl60'],
      previewUrl: json['previewUrl'],
      collectionName: json['collectionName'],
      releaseDate: json['releaseDate'],
      platform: 'iTunes',
    );
  }

  factory MusicSearchResult.fromSpotify(Map<String, dynamic> json) {
    final tracks = json['tracks'] as Map<String, dynamic>?;
    if (tracks == null) return _emptySpotify();

    final items = tracks['items'] as List?;
    if (items == null || items.isEmpty) return _emptySpotify();

    final track = items[0] as Map<String, dynamic>;
    final artists = track['artists'] as List?;
    final artistName =
        artists != null && artists.isNotEmpty ? artists[0]['name'] : 'Unknown';

    final images = track['images'] as List?;
    final artworkUrl = images != null && images.isNotEmpty
        ? (images[0] as Map<String, dynamic>)['url']
        : null;

    return MusicSearchResult(
      itunesTrackId: track['id'] ?? 'unknown',
      trackName: track['name'] ?? 'Unknown',
      artistName: artistName,
      artworkUrl: artworkUrl,
      collectionName: track['album']?['name'],
      releaseDate: track['album']?['release_date'],
      platform: 'Spotify',
    );
  }

  static MusicSearchResult _emptySpotify() {
    return MusicSearchResult(
      itunesTrackId: 'unknown',
      trackName: 'Unknown',
      artistName: 'Unknown',
    );
  }
}
