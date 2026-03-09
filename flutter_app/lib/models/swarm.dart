class Swarm {
  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final String? venueId;
  final DateTime startTime;
  final int maxAttendees;
  final String status;
  final List<String> vibeTags;
  final double? lat;
  final double? lng;
  final DateTime createdAt;

  Swarm({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    this.venueId,
    required this.startTime,
    required this.maxAttendees,
    required this.status,
    this.vibeTags = const [],
    this.lat,
    this.lng,
    required this.createdAt,
  });

  factory Swarm.fromJson(Map<String, dynamic> json) {
    return Swarm(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      venueId: json['venue_id'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      maxAttendees: json['max_attendees'] as int,
      status: json['status'] as String,
      vibeTags: (json['vibe_tags'] as List<dynamic>?)?.cast<String>() ?? [],
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'venue_id': venueId,
      'start_time': startTime.toIso8601String(),
      'max_attendees': maxAttendees,
      'status': status,
      'vibe_tags': vibeTags,
      'lat': lat,
      'lng': lng,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
