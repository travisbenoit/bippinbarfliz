class Venue {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
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
    this.category,
    this.verified = false,
    this.photoUrl,
    this.placeId,
    this.rating,
    this.userRatingsTotal,
    required this.createdAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      category: json['category'] as String?,
      verified: json['verified'] as bool? ?? false,
      photoUrl: json['photo_url'] as String?,
      placeId: json['place_id'] as String?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      userRatingsTotal: json['user_ratings_total'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
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
