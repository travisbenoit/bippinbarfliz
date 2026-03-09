import type { Coordinates, Venue, NearbyVenue, GeofenceShape } from './types';

export function calculateDistanceMeters(
  point1: Coordinates,
  point2: Coordinates
): number {
  const R = 6371000;
  const lat1Rad = toRadians(point1.lat);
  const lat2Rad = toRadians(point2.lat);
  const deltaLat = toRadians(point2.lat - point1.lat);
  const deltaLng = toRadians(point2.lng - point1.lng);

  const a =
    Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
    Math.cos(lat1Rad) *
      Math.cos(lat2Rad) *
      Math.sin(deltaLng / 2) *
      Math.sin(deltaLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

export function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

export function toDegrees(radians: number): number {
  return radians * (180 / Math.PI);
}

export function isPointInCircle(
  point: Coordinates,
  center: Coordinates,
  radiusMeters: number
): boolean {
  const distance = calculateDistanceMeters(point, center);
  return distance <= radiusMeters;
}

export function isPointInPolygon(
  point: Coordinates,
  polygon: Coordinates[]
): boolean {
  let inside = false;
  const x = point.lng;
  const y = point.lat;

  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const xi = polygon[i].lng;
    const yi = polygon[i].lat;
    const xj = polygon[j].lng;
    const yj = polygon[j].lat;

    const intersect =
      yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi;

    if (intersect) inside = !inside;
  }

  return inside;
}

export function isPointInGeofence(
  point: Coordinates,
  venue: Venue
): boolean {
  if (venue.geofence_shape) {
    if (venue.geofence_shape.type === 'circle') {
      return isPointInCircle(
        point,
        venue.geofence_shape.center || { lat: venue.lat, lng: venue.lng },
        venue.geofence_shape.radius || venue.geofence_radius_meters
      );
    } else if (venue.geofence_shape.type === 'polygon' && venue.geofence_shape.coordinates) {
      return isPointInPolygon(point, venue.geofence_shape.coordinates);
    }
  }

  return isPointInCircle(
    point,
    { lat: venue.lat, lng: venue.lng },
    venue.geofence_radius_meters
  );
}

export function findNearestVenue(
  userLocation: Coordinates,
  venues: Venue[]
): NearbyVenue | null {
  if (venues.length === 0) return null;

  let nearest: NearbyVenue | null = null;
  let minDistance = Infinity;

  for (const venue of venues) {
    const distance = calculateDistanceMeters(userLocation, {
      lat: venue.lat,
      lng: venue.lng,
    });

    if (distance < minDistance) {
      minDistance = distance;
      nearest = {
        ...venue,
        distance_meters: distance,
        is_in_geofence: isPointInGeofence(userLocation, venue),
      };
    }
  }

  return nearest;
}

export function findVenuesWithinRadius(
  userLocation: Coordinates,
  venues: Venue[],
  radiusMeters: number
): NearbyVenue[] {
  return venues
    .map((venue) => {
      const distance = calculateDistanceMeters(userLocation, {
        lat: venue.lat,
        lng: venue.lng,
      });

      return {
        ...venue,
        distance_meters: distance,
        is_in_geofence: isPointInGeofence(userLocation, venue),
      };
    })
    .filter((venue) => venue.distance_meters <= radiusMeters)
    .sort((a, b) => a.distance_meters - b.distance_meters);
}

export function findActiveGeofence(
  userLocation: Coordinates,
  venues: Venue[]
): NearbyVenue | null {
  const venuesInGeofence = venues.filter((venue) =>
    isPointInGeofence(userLocation, venue)
  );

  if (venuesInGeofence.length === 0) return null;

  if (venuesInGeofence.length === 1) {
    const venue = venuesInGeofence[0];
    return {
      ...venue,
      distance_meters: calculateDistanceMeters(userLocation, {
        lat: venue.lat,
        lng: venue.lng,
      }),
      is_in_geofence: true,
    };
  }

  return findNearestVenue(userLocation, venuesInGeofence);
}

export function shouldUseHighPrecision(
  userLocation: Coordinates,
  venues: Venue[],
  thresholdMeters: number
): boolean {
  if (venues.length === 0) return false;

  const nearestVenue = findNearestVenue(userLocation, venues);
  if (!nearestVenue) return false;

  return nearestVenue.distance_meters <= thresholdMeters;
}

export function getBoundingBox(
  center: Coordinates,
  radiusMeters: number
): {
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
} {
  const latDelta = (radiusMeters / 111000);
  const lngDelta = radiusMeters / (111000 * Math.cos(toRadians(center.lat)));

  return {
    minLat: center.lat - latDelta,
    maxLat: center.lat + latDelta,
    minLng: center.lng - lngDelta,
    maxLng: center.lng + lngDelta,
  };
}

export function calculateDwellTime(enteredAt: string): number {
  const entered = new Date(enteredAt).getTime();
  const now = Date.now();
  return Math.floor((now - entered) / 1000);
}

export function formatDistance(meters: number): string {
  if (meters < 1000) {
    return `${Math.round(meters)}m`;
  }
  return `${(meters / 1000).toFixed(1)}km`;
}

export function formatDwellTime(seconds: number): string {
  if (seconds < 60) {
    return `${seconds}s`;
  }
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) {
    return `${minutes}m`;
  }
  const hours = Math.floor(minutes / 60);
  const remainingMinutes = minutes % 60;
  return `${hours}h ${remainingMinutes}m`;
}

export function isValidCoordinate(coord: Coordinates): boolean {
  return (
    typeof coord.lat === 'number' &&
    typeof coord.lng === 'number' &&
    coord.lat >= -90 &&
    coord.lat <= 90 &&
    coord.lng >= -180 &&
    coord.lng <= 180
  );
}

export function createCircularGeofence(
  center: Coordinates,
  radiusMeters: number
): GeofenceShape {
  return {
    type: 'circle',
    center,
    radius: radiusMeters,
  };
}

export function createPolygonGeofence(
  coordinates: Coordinates[]
): GeofenceShape {
  return {
    type: 'polygon',
    coordinates,
  };
}

export function getOptimalMonitoringDistance(
  nearestVenueDistance: number | null
): number {
  if (!nearestVenueDistance) return 500;

  if (nearestVenueDistance < 100) return 10;
  if (nearestVenueDistance < 300) return 50;
  if (nearestVenueDistance < 1000) return 100;
  return 200;
}

export function shouldTriggerLocationUpdate(
  lastUpdate: number,
  isHighPrecision: boolean,
  highPrecisionInterval: number = 5000,
  lowPrecisionInterval: number = 60000
): boolean {
  const now = Date.now();
  const interval = isHighPrecision ? highPrecisionInterval : lowPrecisionInterval;
  return now - lastUpdate >= interval;
}
