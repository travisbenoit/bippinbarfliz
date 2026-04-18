class MusicTrack {
  final String? id;
  final String itunesTrackId;
  final String trackName;
  final String artistName;
  final String? artworkUrl;
  final String? previewUrl;
  final String? collectionName;
  final DateTime? createdAt;
  final String? sharedByUserId;

  MusicTrack({
    this.id,
    required this.itunesTrackId,
    required this.trackName,
    required this.artistName,
    this.artworkUrl,
    this.previewUrl,
    this.collectionName,
    this.createdAt,
    this.sharedByUserId,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] as String?,
      itunesTrackId: json['itunes_track_id'] as String,
      trackName: json['track_name'] as String,
      artistName: json['artist_name'] as String,
      artworkUrl: json['artwork_url'] as String?,
      previewUrl: json['preview_url'] as String?,
      collectionName: json['collection_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      sharedByUserId: json['shared_by_user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itunes_track_id': itunesTrackId,
      'track_name': trackName,
      'artist_name': artistName,
      'artwork_url': artworkUrl,
      'preview_url': previewUrl,
      'collection_name': collectionName,
      'created_at': createdAt?.toIso8601String(),
      'shared_by_user_id': sharedByUserId,
    };
  }

  MusicTrack copyWith({
    String? id,
    String? itunesTrackId,
    String? trackName,
    String? artistName,
    String? artworkUrl,
    String? previewUrl,
    String? collectionName,
    DateTime? createdAt,
    String? sharedByUserId,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      itunesTrackId: itunesTrackId ?? this.itunesTrackId,
      trackName: trackName ?? this.trackName,
      artistName: artistName ?? this.artistName,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      collectionName: collectionName ?? this.collectionName,
      createdAt: createdAt ?? this.createdAt,
      sharedByUserId: sharedByUserId ?? this.sharedByUserId,
    );
  }
}
