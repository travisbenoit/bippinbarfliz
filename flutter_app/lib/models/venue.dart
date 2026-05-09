class Venue {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? city;
  final String? category;
  final bool verified;
  final String? photoUrl;
  final String? placeId;
  final double? rating;
  final int? userRatingsTotal;
  final DateTime createdAt;

  Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.city,
    this.category,
    this.verified = false,
    this.photoUrl,
    this.placeId,
    this.rating,
    this.userRatingsTotal,
    required this.createdAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    // bars table uses bar_id as primary key; fall back to id for other sources
    final id = (json['bar_id'] ?? json['id']) as String;

    // photo_urls in bars is a text[], photo_url in other sources is a single string
    final photoUrl = json['photo_url'] as String? ??
        ((json['photo_urls'] as List?)?.cast<String>().firstOrNull);

    return Venue(
      id: id,
      name: json['name'] as String,
      address: (json['address'] as String?) ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      city: json['city'] as String?,
      category: json['category'] as String?,
      verified: json['verified'] as bool? ?? false,
      photoUrl: photoUrl,
      placeId: json['place_id'] as String? ?? json['google_place_id'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      userRatingsTotal: json['user_ratings_total'] as int? ?? json['review_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'category': category,
      'verified': verified,
      'photo_url': photoUrl,
      'place_id': placeId,
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
