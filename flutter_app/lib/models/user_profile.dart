import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

enum TonightStatus {
  outNow,
  goingOutSoon,
  stayingIn;

  String get displayName {
    switch (this) {
      case TonightStatus.outNow:
        return 'Out now';
      case TonightStatus.goingOutSoon:
        return 'Going out soon';
      case TonightStatus.stayingIn:
        return 'Staying in';
    }
  }

  String get emoji {
    switch (this) {
      case TonightStatus.outNow:
        return '🟢';
      case TonightStatus.goingOutSoon:
        return '🟡';
      case TonightStatus.stayingIn:
        return '⚪';
    }
  }

  static TonightStatus fromString(String status) {
    switch (status) {
      case 'out_now':
        return TonightStatus.outNow;
      case 'going_out_soon':
        return TonightStatus.goingOutSoon;
      case 'staying_in':
        return TonightStatus.stayingIn;
      default:
        return TonightStatus.stayingIn;
    }
  }

  String toDbString() {
    switch (this) {
      case TonightStatus.outNow:
        return 'out_now';
      case TonightStatus.goingOutSoon:
        return 'going_out_soon';
      case TonightStatus.stayingIn:
        return 'staying_in';
    }
  }
}

class UserProfile {
  final String id;
  final String name;
  final String? bio;
  final String? homeCity;
  final TonightStatus tonightStatus;
  final List<String> vibeTags;
  final List<String> favoriteDrinks;
  final double? lastKnownLat;
  final double? lastKnownLng;
  final DateTime? lastActiveAt;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool isPremium;
  final int? age;

  UserProfile({
    required this.id,
    required this.name,
    this.bio,
    this.homeCity,
    required this.tonightStatus,
    this.vibeTags = const [],
    this.favoriteDrinks = const [],
    this.lastKnownLat,
    this.lastKnownLng,
    this.lastActiveAt,
    this.avatarUrl,
    required this.createdAt,
    this.isPremium = false,
    this.age,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      homeCity: json['home_city'] as String?,
      tonightStatus: TonightStatus.fromString(json['tonight_status'] as String),
      vibeTags: (json['vibe_tags'] as List<dynamic>?)?.cast<String>() ?? [],
      favoriteDrinks: (json['favorite_drinks'] as List<dynamic>?)?.cast<String>() ?? [],
      lastKnownLat: json['last_known_lat'] as double?,
      lastKnownLng: json['last_known_lng'] as double?,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPremium: json['is_premium'] as bool? ?? false,
      age: json['age'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'home_city': homeCity,
      'tonight_status': tonightStatus.toDbString(),
      'vibe_tags': vibeTags,
      'favorite_drinks': favoriteDrinks,
      'last_known_lat': lastKnownLat,
      'last_known_lng': lastKnownLng,
      'last_active_at': lastActiveAt?.toIso8601String(),
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'is_premium': isPremium,
      'age': age,
    };
  }

  UserProfile copyWith({
    String? name,
    String? bio,
    String? homeCity,
    TonightStatus? tonightStatus,
    List<String>? vibeTags,
    List<String>? favoriteDrinks,
    double? lastKnownLat,
    double? lastKnownLng,
    DateTime? lastActiveAt,
    String? avatarUrl,
    bool? isPremium,
    int? age,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      homeCity: homeCity ?? this.homeCity,
      tonightStatus: tonightStatus ?? this.tonightStatus,
      vibeTags: vibeTags ?? this.vibeTags,
      favoriteDrinks: favoriteDrinks ?? this.favoriteDrinks,
      lastKnownLat: lastKnownLat ?? this.lastKnownLat,
      lastKnownLng: lastKnownLng ?? this.lastKnownLng,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      isPremium: isPremium ?? this.isPremium,
      age: age ?? this.age,
    );
  }
}
