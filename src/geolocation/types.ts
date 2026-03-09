export interface Coordinates {
  lat: number;
  lng: number;
}

export interface Venue {
  id: string;
  name: string;
  type: string;
  address?: string;
  city: string;
  state?: string;
  country: string;
  postal_code?: string;
  lat: number;
  lng: number;
  geofence_shape?: GeofenceShape;
  geofence_radius_meters: number;
  google_place_id?: string;
  phone?: string;
  website?: string;
  is_active: boolean;
  metadata?: Record<string, any>;
  rating?: number;
  user_ratings_total?: number;
  created_at: string;
  updated_at?: string;
}

export interface GeofenceShape {
  type: 'circle' | 'polygon';
  center?: Coordinates;
  radius?: number;
  coordinates?: Coordinates[];
}

export type PresenceStatus = 'IN_VENUE' | 'LEFT_VENUE';

export interface UserVenuePresence {
  id: string;
  user_id: string;
  venue_id: string;
  status: PresenceStatus;
  entered_at: string;
  left_at?: string;
  last_seen_at: string;
  is_visible_in_venue: boolean;
  dwell_seconds: number;
  entry_method: 'AUTO_GEOFENCE' | 'MANUAL_CHECKIN';
  metadata?: Record<string, any>;
  created_at: string;
  updated_at?: string;
}

export interface VenueCluster {
  id: string;
  name: string;
  city: string;
  center_lat: number;
  center_lng: number;
  radius_meters: number;
  venue_ids: string[];
  is_active: boolean;
  created_at: string;
  updated_at?: string;
}

export interface NearbyVenue extends Venue {
  distance_meters: number;
  is_in_geofence: boolean;
}

export interface GeofenceState {
  currentVenue?: Venue;
  currentPresence?: UserVenuePresence;
  nearbyVenues: NearbyVenue[];
  nearbyClusters: VenueCluster[];
  isTracking: boolean;
  lastLocation?: Coordinates;
  lastUpdateTime?: number;
}

export interface GeofenceEvent {
  type: 'ENTER' | 'EXIT' | 'DWELL' | 'NEARBY';
  venue?: Venue;
  presence?: UserVenuePresence;
  timestamp: number;
  coordinates?: Coordinates;
}

export type GeofenceEventListener = (event: GeofenceEvent) => void;

export interface GeofenceConfig {
  minDwellTimeSeconds: number;
  exitDelaySeconds: number;
  highPrecisionThresholdMeters: number;
  clusterProximityMeters: number;
  updateIntervalLowPrecision: number;
  updateIntervalHighPrecision: number;
  venueGeofenceBufferMeters: number;
  privacyMode: 'visible' | 'invisible' | 'friends_only';
}

export interface LocationPermissionStatus {
  granted: boolean;
  accuracy: 'none' | 'coarse' | 'fine';
  canRequestBackground: boolean;
  backgroundGranted: boolean;
}

export interface GeofenceMonitoringOptions {
  enableHighAccuracy: boolean;
  distanceFilter: number;
  interval?: number;
  fastestInterval?: number;
  activityType?: 'other' | 'automotiveNavigation' | 'fitness' | 'otherNavigation';
  showsBackgroundLocationIndicator?: boolean;
  deferredUpdatesInterval?: number;
}
