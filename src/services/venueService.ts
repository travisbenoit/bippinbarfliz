import { supabase } from '../lib/supabase';
import geocodingService from './geocodingService';
import type {
  Venue,
  VenuePhoto,
  VenueReview,
  VenueStats,
  VenueWithStats,
  OSMImportRequest,
  OSMImportResult,
} from '../types/venue';

export async function getVenuesInBounds(
  minLat: number,
  minLng: number,
  maxLat: number,
  maxLng: number,
  category?: string
): Promise<Venue[]> {
  let query = supabase
    .from('venues')
    .select('*')
    .gte('lat', minLat)
    .lte('lat', maxLat)
    .gte('lng', minLng)
    .lte('lng', maxLng);

  if (category) {
    query = query.eq('category', category);
  }

  const { data, error } = await query.limit(500);

  if (error) throw error;
  return data || [];
}

export async function getVenueById(venueId: string): Promise<VenueWithStats | null> {
  const { data: venue, error } = await supabase
    .from('venues')
    .select('*')
    .eq('id', venueId)
    .maybeSingle();

  if (error) throw error;
  if (!venue) return null;

  const [stats, photos, reviews] = await Promise.all([
    getVenueStats(venueId),
    getVenuePhotos(venueId),
    getVenueReviews(venueId),
  ]);

  return {
    ...venue,
    stats,
    photos,
    reviews,
  };
}

export async function getVenueStats(venueId: string): Promise<VenueStats> {
  const { data, error } = await supabase.rpc('get_venue_stats', {
    p_venue_id: venueId,
  });

  if (error) {
    console.error('Error fetching venue stats:', error);
    return { avg_rating: 0, review_count: 0, photo_count: 0 };
  }

  return data?.[0] || { avg_rating: 0, review_count: 0, photo_count: 0 };
}

export async function getVenuePhotos(venueId: string): Promise<VenuePhoto[]> {
  const { data, error } = await supabase
    .from('venue_photos')
    .select('*')
    .eq('venue_id', venueId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
}

export async function getVenueReviews(venueId: string): Promise<VenueReview[]> {
  const { data, error } = await supabase
    .from('venue_reviews')
    .select('*')
    .eq('venue_id', venueId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
}

export async function createVenueReview(
  venueId: string,
  rating: number,
  title?: string,
  body?: string
): Promise<VenueReview> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Must be logged in to create a review');

  const { data, error } = await supabase
    .from('venue_reviews')
    .insert({
      venue_id: venueId,
      rating,
      title: title || null,
      body: body || null,
      created_by_user_id: user.id,
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function uploadVenuePhoto(
  venueId: string,
  imageUrl: string,
  caption?: string
): Promise<VenuePhoto> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Must be logged in to upload a photo');

  const { data, error } = await supabase
    .from('venue_photos')
    .insert({
      venue_id: venueId,
      source: 'user_upload',
      image_url: imageUrl,
      caption: caption || null,
      created_by_user_id: user.id,
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export async function searchVenues(
  searchTerm: string,
  limit = 20
): Promise<Venue[]> {
  const { data, error } = await supabase
    .from('venues')
    .select('*')
    .ilike('name', `%${searchTerm}%`)
    .limit(limit);

  if (error) throw error;
  return data || [];
}

export async function getVenuesByCity(
  city: string,
  country?: string
): Promise<Venue[]> {
  let query = supabase
    .from('venues')
    .select('*')
    .ilike('city', city);

  if (country) {
    query = query.eq('country', country);
  }

  const { data, error } = await query.order('name');

  if (error) throw error;
  return data || [];
}

export async function getVenuesByCategory(
  category: string,
  limit = 100
): Promise<Venue[]> {
  const { data, error } = await supabase
    .from('venues')
    .select('*')
    .eq('category', category)
    .limit(limit);

  if (error) throw error;
  return data || [];
}

export async function triggerOSMImport(
  request: OSMImportRequest
): Promise<OSMImportResult> {
  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

  const response = await fetch(
    `${supabaseUrl}/functions/v1/import-venues-osm`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${supabaseAnonKey}`,
      },
      body: JSON.stringify(request),
    }
  );

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Import failed: ${error}`);
  }

  return response.json();
}

export function getVenueImageUrl(venue: Venue): string | null {
  if (venue.image_url_osm) return venue.image_url_osm;
  return null;
}

export function formatVenueAddress(venue: Venue): string {
  const parts: string[] = [];
  if (venue.address) parts.push(venue.address);
  if (venue.city) parts.push(venue.city);
  if (venue.state) parts.push(venue.state);
  if (venue.country) parts.push(venue.country);
  return parts.join(', ');
}

export function getVenueCategoryLabel(category: string): string {
  const labels: Record<string, string> = {
    bar: 'Bar',
    pub: 'Pub',
    nightclub: 'Nightclub',
    brewery: 'Brewery',
    winery: 'Winery',
    cocktail_bar: 'Cocktail Bar',
    restaurant: 'Restaurant',
  };
  return labels[category] || category;
}

export interface AddressValidationResult {
  isValid: boolean;
  addressMatch: boolean;
  matchConfidence: number;
  distanceMeters: number;
  warnings: string[];
}

export async function validateVenueCoordinates(
  venue: Venue
): Promise<AddressValidationResult> {
  const warnings: string[] = [];

  if (!venue.lat || !venue.lng) {
    return {
      isValid: false,
      addressMatch: false,
      matchConfidence: 0,
      distanceMeters: 0,
      warnings: ['Missing venue coordinates'],
    };
  }

  if (!venue.address) {
    return {
      isValid: true,
      addressMatch: false,
      matchConfidence: 0,
      distanceMeters: 0,
      warnings: ['No address available for validation'],
    };
  }

  const geocodeResult = await geocodingService.reverseGeocode(
    venue.lat,
    venue.lng
  );

  if (!geocodeResult) {
    return {
      isValid: true,
      addressMatch: false,
      matchConfidence: 0,
      distanceMeters: 0,
      warnings: ['Could not reverse geocode coordinates'],
    };
  }

  const { match, confidence } = geocodingService.validateAddressMatch(
    venue.address,
    geocodeResult.address
  );

  if (!match && confidence < 0.5) {
    warnings.push(
      `Address may not match coordinates (confidence: ${(confidence * 100).toFixed(0)}%)`
    );
  }

  return {
    isValid: true,
    addressMatch: match,
    matchConfidence: confidence,
    distanceMeters: 0,
    warnings,
  };
}

export function ensureCoordinatesInBounds(
  venue: Venue,
  bounds: { minLat: number; maxLat: number; minLng: number; maxLng: number }
): boolean {
  if (!venue.lat || !venue.lng) return false;

  return (
    venue.lat >= bounds.minLat &&
    venue.lat <= bounds.maxLat &&
    venue.lng >= bounds.minLng &&
    venue.lng <= bounds.maxLng
  );
}