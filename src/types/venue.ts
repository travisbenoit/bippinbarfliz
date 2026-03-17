export interface Venue {
  id: string;
  name: string;
  lat: number;
  lng: number;
  category: VenueCategory;
  subcategory: string | null;
  address: string | null;
  city: string | null;
  state: string | null;
  country: string | null;
  osm_id: string | null;
  osm_tags: Record<string, string> | null;
  image_url_osm: string | null;
  google_place_id: string | null;
  foursquare_id: string | null;
  verified_flag: boolean;
  geofence_radius_meters: number;
  created_at: string;
  updated_at: string;
}

export type VenueCategory =
  | 'bar'
  | 'pub'
  | 'nightclub'
  | 'brewery'
  | 'winery'
  | 'cocktail_bar'
  | 'restaurant';

export interface VenuePhoto {
  id: string;
  venue_id: string;
  source: 'user_upload' | 'owner_upload' | 'osm';
  image_url: string;
  caption: string | null;
  created_by_user_id: string | null;
  created_at: string;
}

export interface VenueReview {
  id: string;
  venue_id: string;
  rating: 1 | 2 | 3 | 4 | 5;
  title: string | null;
  body: string | null;
  created_by_user_id: string | null;
  created_at: string;
}

export interface VenueStats {
  avg_rating: number;
  review_count: number;
  photo_count: number;
}

export interface VenueWithStats extends Venue {
  stats?: VenueStats;
  photos?: VenuePhoto[];
  reviews?: VenueReview[];
}

export interface OSMImportRequest {
  regionType: 'country' | 'southFlorida' | 'australianState';
  countryCode?: string;
  stateCode?: string;
}

export interface OSMImportResult {
  regionType: string;
  countryCode?: string;
  stateCode?: string;
  totalProcessed: number;
  insertedCount: number;
  updatedCount: number;
  skippedCount: number;
  errors: string[];
}

export interface RadarGeofencePayload {
  description: string;
  type: 'circle';
  coordinates: [number, number];
  radius: number;
  metadata: {
    venue_id: string;
    category: string;
    name: string;
  };
}