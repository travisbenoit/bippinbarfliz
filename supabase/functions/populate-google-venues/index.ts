import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import { corsHeaders } from '../_shared/cors.ts';
import { uploadVenuePhoto } from '../_shared/storage-photo.ts';

const GOOGLE_PLACES_API_KEY = Deno.env.get('GOOGLE_PLACES_API_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

interface VenueRequest {
  name: string;
  lat: number;
  lng: number;
  category: string;
  subcategory?: string;
  city: string;
  state: string;
  country: string;
}

interface GooglePlaceResult {
  place_id: string;
  name: string;
  rating?: number;
  user_ratings_total?: number;
  photos?: Array<{ photo_reference: string }>;
  formatted_address?: string;
  opening_hours?: any;
  formatted_phone_number?: string;
  website?: string;
  url?: string;
}

const LOCATIONS = [
  {
    name: 'Darwin, Australia',
    cities: ['Darwin'],
    state: 'NT',
    country: 'AU',
    countryCode: 'AU',
    bounds: { lat: -12.45, lng: 130.85 },
    radius: 25000,
  },
  {
    name: 'Weston, Florida',
    cities: ['Weston'],
    state: 'FL',
    country: 'US',
    countryCode: 'US',
    bounds: { lat: 26.1, lng: -80.32 },
    radius: 8000,
  },
  {
    name: 'Sunrise, Florida',
    cities: ['Sunrise'],
    state: 'FL',
    country: 'US',
    countryCode: 'US',
    bounds: { lat: 26.17, lng: -80.26 },
    radius: 8000,
  },
  {
    name: 'Davie, Florida',
    cities: ['Davie'],
    state: 'FL',
    country: 'US',
    countryCode: 'US',
    bounds: { lat: 26.07, lng: -80.24 },
    radius: 8000,
  },
  {
    name: 'Fort Lauderdale, Florida',
    cities: ['Fort Lauderdale'],
    state: 'FL',
    country: 'US',
    countryCode: 'US',
    bounds: { lat: 26.12, lng: -80.14 },
    radius: 10000,
  },
  {
    name: 'Miami, Florida',
    cities: ['Miami'],
    state: 'FL',
    country: 'US',
    countryCode: 'US',
    bounds: { lat: 25.76, lng: -80.19 },
    radius: 15000,
  },
];

const SEARCH_QUERIES = [
  'bars',
  'nightclubs',
  'breweries',
  'wineries',
  'discos',
];

async function searchGooglePlaces(
  query: string,
  lat: number,
  lng: number,
  radius: number
): Promise<GooglePlaceResult[]> {
  if (!GOOGLE_PLACES_API_KEY) {
    throw new Error('Google Places API key not configured');
  }

  const url = new URL('https://maps.googleapis.com/maps/api/place/nearbysearch/json');
  url.searchParams.set('key', GOOGLE_PLACES_API_KEY);
  url.searchParams.set('location', `${lat},${lng}`);
  url.searchParams.set('radius', radius.toString());
  url.searchParams.set('keyword', query);
  url.searchParams.set('type', 'bar');

  const response = await fetch(url.toString());

  if (!response.ok) {
    throw new Error(`Google Places API error: ${response.statusText}`);
  }

  const data = await response.json();

  if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') {
    throw new Error(`Google Places API status: ${data.status}`);
  }

  return data.results || [];
}

async function getPlaceDetails(placeId: string): Promise<GooglePlaceResult | null> {
  if (!GOOGLE_PLACES_API_KEY) {
    throw new Error('Google Places API key not configured');
  }

  const fields = [
    'place_id',
    'name',
    'rating',
    'user_ratings_total',
    'photos',
    'formatted_address',
    'opening_hours',
    'formatted_phone_number',
    'website',
    'url',
  ].join(',');

  const url = new URL('https://maps.googleapis.com/maps/api/place/details/json');
  url.searchParams.set('key', GOOGLE_PLACES_API_KEY);
  url.searchParams.set('place_id', placeId);
  url.searchParams.set('fields', fields);

  const response = await fetch(url.toString());

  if (!response.ok) {
    throw new Error(`Google Places API error: ${response.statusText}`);
  }

  const data = await response.json();

  if (data.status !== 'OK') {
    console.warn(`Could not fetch details for ${placeId}: ${data.status}`);
    return null;
  }

  return data.result;
}

async function resolvePhotoUrl(
  photoReference: string,
  venueId: string
): Promise<string | null> {
  if (!GOOGLE_PLACES_API_KEY) return null;
  return uploadVenuePhoto(photoReference, venueId, GOOGLE_PLACES_API_KEY);
}

function categorizeVenue(name: string, types: string[]): {
  category: string;
  subcategory: string;
} {
  const nameLower = name.toLowerCase();

  if (
    nameLower.includes('brewery') ||
    nameLower.includes('craft beer') ||
    types.includes('brewery')
  ) {
    return { category: 'brewery', subcategory: 'brewery' };
  }

  if (
    nameLower.includes('winery') ||
    nameLower.includes('wine bar') ||
    types.includes('wine_bar')
  ) {
    return { category: 'winery', subcategory: 'wine_bar' };
  }

  if (
    nameLower.includes('nightclub') ||
    nameLower.includes('disco') ||
    nameLower.includes('night club') ||
    types.includes('night_club')
  ) {
    return { category: 'nightclub', subcategory: 'nightclub' };
  }

  if (nameLower.includes('disco')) {
    return { category: 'nightclub', subcategory: 'disco' };
  }

  return { category: 'bar', subcategory: 'bar' };
}

async function populateVenuesForLocation(
  location: (typeof LOCATIONS)[0]
): Promise<{ inserted: number; failed: number }> {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  let inserted = 0;
  let failed = 0;

  console.log(`\nPopulating venues for ${location.name}...`);

  for (const query of SEARCH_QUERIES) {
    console.log(`  Searching for "${query}"...`);

    const places = await searchGooglePlaces(
      query,
      location.bounds.lat,
      location.bounds.lng,
      location.radius
    );

    for (const place of places) {
      try {
        const details = await getPlaceDetails(place.place_id);

        if (!details) {
          failed++;
          continue;
        }

        const { category, subcategory } = categorizeVenue(details.name, []);

        const venueId = `gp:${place.place_id}`;

        let imageUrl = null;
        if (details.photos && details.photos.length > 0) {
          imageUrl = await resolvePhotoUrl(details.photos[0].photo_reference, venueId);
        }

        const { error } = await supabase.from('venues').upsert(
          {
            id: venueId,
            name: details.name,
            lat: place.geometry?.location?.lat || location.bounds.lat,
            lng: place.geometry?.location?.lng || location.bounds.lng,
            category,
            subcategory,
            address: details.formatted_address || '',
            city: location.cities[0],
            state: location.state,
            country: location.country,
            google_place_id: place.place_id,
            photo_url: imageUrl,
            phone: details.formatted_phone_number || null,
            website: details.website || null,
            hours: details.opening_hours || null,
            rating: details.rating || null,
            user_ratings_total: details.user_ratings_total || 0,
            price_level: details.price_level || null,
            is_active: true,
            verified_flag: false,
            geofence_radius_m: 75,
            metadata: {
              google_url: details.url || null,
              google_types: details.types || [],
              last_google_sync: new Date().toISOString(),
            },
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'id' }
        );

        if (error) {
          console.error(`  Failed to insert ${details.name}:`, error);
          failed++;
        } else {
          inserted++;
          console.log(`  ✓ ${details.name} (${category})`);
        }

        await new Promise((resolve) => setTimeout(resolve, 100));
      } catch (error) {
        console.error(`  Error processing place ${place.place_id}:`, error);
        failed++;
      }
    }

    await new Promise((resolve) => setTimeout(resolve, 500));
  }

  return { inserted, failed };
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    if (!GOOGLE_PLACES_API_KEY) {
      return new Response(
        JSON.stringify({
          error: 'Google Places API key not configured',
          status: 'error',
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('Starting venue population from Google Places...');

    const results: Record<string, { inserted: number; failed: number }> = {};

    for (const location of LOCATIONS) {
      const result = await populateVenuesForLocation(location);
      results[location.name] = result;
    }

    console.log('\nVenue population complete!');
    console.log('Results:', results);

    return new Response(
      JSON.stringify({
        status: 'success',
        message: 'Venues populated successfully',
        results,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error populating venues:', error);

    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Unknown error',
        status: 'error',
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
