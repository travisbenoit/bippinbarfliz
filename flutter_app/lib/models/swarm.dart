class Swarm {
  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final String? venueId;
  final String? venueName;
  final DateTime startTime;
  final int maxSize;
  final int currentSize;
  final String status;
  final List<String> vibeTags;
  final DateTime createdAt;
  final String? imageUrl;

  Swarm({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    this.venueId,
    this.venueName,
    required this.startTime,
    required this.maxSize,
    this.currentSize = 1,
    required this.status,
    this.vibeTags = const [],
    required this.createdAt,
    this.imageUrl,
  });

  factory Swarm.fromJson(Map<String, dynamic> json) {
    return Swarm(
      id: json['id'] as String,
      creatorId: json['host_user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      venueId: json['venue_id'] as String?,
      venueName: json['venue_name'] as String?,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : DateTime.now(),
      maxSize: (json['max_size'] as int?) ?? 50,
      currentSize: () {
        // Prefer the live count from the joined swarm_members relation.
        final members = json['swarm_members'];
        if (members is List && members.isNotEmpty) {
          final count = members.first['count'];
          if (count is int) return count;
        }
        return (json['current_size'] as int?) ?? 1;
      }(),
      status: json['status'] as String? ?? 'active',
      vibeTags: (json['vibe_tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      imageUrl: json['cover_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_user_id': creatorId,
      'title': title,
      'description': description,
      'venue_id': venueId,
      'venue_name': venueName,
      'start_time': startTime.toIso8601String(),
      'max_size': maxSize,
      'current_size': currentSize,
      'status': status,
      'vibe_tags': vibeTags,
      'created_at': createdAt.toIso8601String(),
      'cover_image_url': imageUrl,
    };
  }
}
