
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

  static TonightStatus fromString(String? status) {
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
  final String? username;
  final String? bio;
  final String? homeCity;
  final TonightStatus tonightStatus;
  final List<String> vibeTags;
  final List<String> favoriteDrinks;
  final List<String> interests;
  final double? lastKnownLat;
  final double? lastKnownLng;
  final DateTime? lastActiveAt;
  final String? avatarUrl;
  final DateTime? createdAt;
  final bool isPremium;
  final int? age;
  final int lushCoinBalance;
  final bool venmoLinked;
  final String? venmoUsername;
  final bool ghostMode;
  final String privacyMode;
  final bool isDdTonight;
  final bool verifiedProfile;
  final String? occupation;
  final String? education;
  final String? lookingFor;
  final String? funFact;
  final String? instagramUsername;
  final String? spotifyUsername;
  final bool paymentProviderLinked;
  final String? paymentProvider;
  final String? paymentProviderUsername;
  final bool firstDrinkOnMe;
  final String? weatherLocation;

  UserProfile({
    required this.id,
    required this.name,
    this.username,
    this.bio,
    this.homeCity,
    required this.tonightStatus,
    this.vibeTags = const [],
    this.favoriteDrinks = const [],
    this.interests = const [],
    this.lastKnownLat,
    this.lastKnownLng,
    this.lastActiveAt,
    this.avatarUrl,
    this.createdAt,
    this.isPremium = false,
    this.age,
    this.lushCoinBalance = 0,
    this.venmoLinked = false,
    this.venmoUsername,
    this.ghostMode = false,
    this.privacyMode = 'public',
    this.isDdTonight = false,
    this.verifiedProfile = false,
    this.occupation,
    this.education,
    this.lookingFor,
    this.funFact,
    this.instagramUsername,
    this.spotifyUsername,
    this.paymentProviderLinked = false,
    this.paymentProvider,
    this.paymentProviderUsername,
    this.firstDrinkOnMe = false,
    this.weatherLocation,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown',
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      homeCity: json['home_city'] as String?,
      tonightStatus: TonightStatus.fromString(json['tonight_status'] as String?),
      vibeTags: (json['vibe_tags'] as List<dynamic>?)?.cast<String>() ?? [],
      favoriteDrinks: (json['favorite_drinks'] as List<dynamic>?)?.cast<String>() ?? [],
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      lastKnownLat: json['last_known_lat'] != null ? (json['last_known_lat'] as num).toDouble() : null,
      lastKnownLng: json['last_known_lng'] != null ? (json['last_known_lng'] as num).toDouble() : null,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : null,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      isPremium: json['is_premium'] as bool? ?? false,
      age: json['age'] as int?,
      lushCoinBalance: json['lush_coin_balance'] as int? ?? 0,
      venmoLinked: json['venmo_linked'] as bool? ?? false,
      venmoUsername: json['venmo_username'] as String?,
      ghostMode: json['ghost_mode'] as bool? ?? false,
      privacyMode: json['privacy_mode'] as String? ?? 'public',
      isDdTonight: json['is_dd_tonight'] as bool? ?? false,
      verifiedProfile: json['verified_profile'] as bool? ?? false,
      occupation: json['occupation'] as String?,
      education: json['education'] as String?,
      lookingFor: json['looking_for'] as String?,
      funFact: json['fun_fact'] as String?,
      instagramUsername: json['instagram_username'] as String?,
      spotifyUsername: json['spotify_username'] as String?,
      paymentProviderLinked: json['payment_provider_linked'] as bool? ?? false,
      paymentProvider: json['payment_provider'] as String?,
      paymentProviderUsername: json['payment_provider_username'] as String?,
      firstDrinkOnMe: json['first_drink_on_me'] as bool? ?? false,
      weatherLocation: json['weather_location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'bio': bio,
      'home_city': homeCity,
      'tonight_status': tonightStatus.toDbString(),
      'vibe_tags': vibeTags,
      'favorite_drinks': favoriteDrinks,
      'interests': interests,
      'last_known_lat': lastKnownLat,
      'last_known_lng': lastKnownLng,
      'last_active_at': lastActiveAt?.toIso8601String(),
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'is_premium': isPremium,
      'age': age,
      'lush_coin_balance': lushCoinBalance,
      'venmo_linked': venmoLinked,
      'venmo_username': venmoUsername,
      'ghost_mode': ghostMode,
      'privacy_mode': privacyMode,
      'is_dd_tonight': isDdTonight,
      'verified_profile': verifiedProfile,
      'occupation': occupation,
      'education': education,
      'looking_for': lookingFor,
      'fun_fact': funFact,
      'instagram_username': instagramUsername,
      'spotify_username': spotifyUsername,
      'payment_provider_linked': paymentProviderLinked,
      'payment_provider': paymentProvider,
      'payment_provider_username': paymentProviderUsername,
      'first_drink_on_me': firstDrinkOnMe,
      'weather_location': weatherLocation,
    };
  }

  UserProfile copyWith({
    String? name,
    String? username,
    String? bio,
    String? homeCity,
    TonightStatus? tonightStatus,
    List<String>? vibeTags,
    List<String>? favoriteDrinks,
    List<String>? interests,
    double? lastKnownLat,
    double? lastKnownLng,
    DateTime? lastActiveAt,
    String? avatarUrl,
    bool? isPremium,
    int? age,
    int? lushCoinBalance,
    bool? venmoLinked,
    String? venmoUsername,
    bool? ghostMode,
    String? privacyMode,
    bool? isDdTonight,
    bool? verifiedProfile,
    String? occupation,
    String? education,
    String? lookingFor,
    String? funFact,
    String? instagramUsername,
    String? spotifyUsername,
    bool? paymentProviderLinked,
    String? paymentProvider,
    String? paymentProviderUsername,
    bool? firstDrinkOnMe,
    String? weatherLocation,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      homeCity: homeCity ?? this.homeCity,
      tonightStatus: tonightStatus ?? this.tonightStatus,
      vibeTags: vibeTags ?? this.vibeTags,
      favoriteDrinks: favoriteDrinks ?? this.favoriteDrinks,
      interests: interests ?? this.interests,
      lastKnownLat: lastKnownLat ?? this.lastKnownLat,
      lastKnownLng: lastKnownLng ?? this.lastKnownLng,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      isPremium: isPremium ?? this.isPremium,
      age: age ?? this.age,
      lushCoinBalance: lushCoinBalance ?? this.lushCoinBalance,
      venmoLinked: venmoLinked ?? this.venmoLinked,
      venmoUsername: venmoUsername ?? this.venmoUsername,
      ghostMode: ghostMode ?? this.ghostMode,
      privacyMode: privacyMode ?? this.privacyMode,
      isDdTonight: isDdTonight ?? this.isDdTonight,
      verifiedProfile: verifiedProfile ?? this.verifiedProfile,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      lookingFor: lookingFor ?? this.lookingFor,
      funFact: funFact ?? this.funFact,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      spotifyUsername: spotifyUsername ?? this.spotifyUsername,
      paymentProviderLinked: paymentProviderLinked ?? this.paymentProviderLinked,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      paymentProviderUsername: paymentProviderUsername ?? this.paymentProviderUsername,
      firstDrinkOnMe: firstDrinkOnMe ?? this.firstDrinkOnMe,
      weatherLocation: weatherLocation ?? this.weatherLocation,
    );
  }
}
