import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/radar_service.dart';

final radarServiceProvider = Provider<RadarService>((ref) {
  return RadarService();
});

final radarTrackingStateProvider = StateNotifierProvider<RadarTrackingNotifier, RadarTrackingState>((ref) {
  final radarService = ref.watch(radarServiceProvider);
  return RadarTrackingNotifier(radarService);
});

class RadarTrackingState {
  final bool isTracking;
  final bool isInitialized;
  final String? userId;
  final LocationCheckResult? lastLocationCheck;
  final String? errorMessage;

  RadarTrackingState({
    this.isTracking = false,
    this.isInitialized = false,
    this.userId,
    this.lastLocationCheck,
    this.errorMessage,
  });

  RadarTrackingState copyWith({
    bool? isTracking,
    bool? isInitialized,
    String? userId,
    LocationCheckResult? lastLocationCheck,
    String? errorMessage,
  }) {
    return RadarTrackingState(
      isTracking: isTracking ?? this.isTracking,
      isInitialized: isInitialized ?? this.isInitialized,
      userId: userId ?? this.userId,
      lastLocationCheck: lastLocationCheck ?? this.lastLocationCheck,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class RadarTrackingNotifier extends StateNotifier<RadarTrackingState> {
  final RadarService _radarService;

  RadarTrackingNotifier(this._radarService) : super(RadarTrackingState());

  Future<void> initialize() async {
    try {
      await _radarService.initialize();
      state = state.copyWith(
        isInitialized: true,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialized: false,
        errorMessage: 'Failed to initialize Radar: $e',
      );
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      await _radarService.setUserId(userId);
      state = state.copyWith(
        userId: userId,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to set user ID: $e',
      );
    }
  }

  Future<bool> startTracking({String? userId}) async {
    final locationCheck = await _radarService.checkDarwinLocation();
    state = state.copyWith(lastLocationCheck: locationCheck);

    if (!locationCheck.isInBounds) {
      state = state.copyWith(
        isTracking: false,
        errorMessage: locationCheck.errorMessage,
      );
      return false;
    }

    final success = await _radarService.startTracking(userId: userId);
    state = state.copyWith(
      isTracking: success,
      userId: userId ?? state.userId,
      errorMessage: success ? null : 'Failed to start tracking',
    );

    return success;
  }

  Future<void> stopTracking() async {
    await _radarService.stopTracking();
    state = state.copyWith(
      isTracking: false,
      errorMessage: null,
    );
  }

  Future<LocationCheckResult> checkDarwinLocation() async {
    final result = await _radarService.checkDarwinLocation();
    state = state.copyWith(lastLocationCheck: result);
    return result;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
