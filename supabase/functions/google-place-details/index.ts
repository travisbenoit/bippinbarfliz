import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import { corsHeaders } from '../_shared/cors.ts';

const GOOGLE_MAPS_SERVER_KEY = Deno.env.get('GOOGLE_PLACES_API_KEY') || Deno.env.get('GOOGLE_MAPS_SERVER_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;

const CACHE_TTL_HOURS = 24;

const PLACES_API_FIELDS = [
  'name',
  'rating',
  'user_ratings_total',
  'photos',
  'opening_hours',
  'formatted_address',
].join(',');

interface Bar {
  bar_id: string;
  name: string;
  lat: number;
  lng: number;
  google_place_id: string | null;
  google_last_fetched_at: string | null;
}

interface PlaceDetailsResponse {
  bar_id: string;
  google_place_id: string;
  name: string;
  rating: number | null;
  review_count: number;
  address: string | null;
  opening_hours: any;
  photos: string[];
  cache_hit: boolean;
}

async function getPlaceDetailsFromGoogle(placeId: string): Promise<any> {
  if (!GOOGLE_MAPS_SERVER_KEY) {
    throw new Error('Google Maps API key not configured');
  }

  const url = new URL('https://maps.googleapis.com/maps/api/place/details/json');
  url.searchParams.set('place_id', placeId);
  url.searchParams.set('fields', PLACES_API_FIELDS);
  url.searchParams.set('key', GOOGLE_MAPS_SERVER_KEY);

  const response = await fetch(url.toString());

  if (!response.ok) {
    throw new Error(`Google Places API error: ${response.statusText}`);
  }

  const data = await response.json();

  if (data.status !== 'OK') {
    throw new Error(`Google Places API status: ${data.status}`);
  }

  return data.result || null;
}

function extractPhotoReferences(photos: any[] | undefined): string[] {
  if (!photos || !Array.isArray(photos)) {
    return [];
  }

  return photos.slice(0, 10).map((photo) => photo.photo_reference || photo.name || '').filter(Boolean);
}

function normalizeResponse(barId: string, placeId: string, placeData: any, cacheHit: boolean): PlaceDetailsResponse {
  return {
    bar_id: barId,
    google_place_id: placeId,
    name: placeData.name || '',
    rating: placeData.rating || null,
    review_count: placeData.user_ratings_total || 0,
    address: placeData.formatted_address || null,
    opening_hours: placeData.opening_hours || null,
    photos: extractPhotoReferences(placeData.photos),
    cache_hit: cacheHit,
  };
}

async function isCacheValid(supabase: any, barId: string): Promise<boolean> {
  const { data: cache } = await supabase
    .from('google_place_cache')
    .select('cached_at')
    .eq('bar_id', barId)
    .maybeSingle();

  if (!cache) {
    return false;
  }

  const cacheAge = Date.now() - new Date(cache.cached_at).getTime();
  const cacheAgeHours = cacheAge / (1000 * 60 * 60);

  return cacheAgeHours < CACHE_TTL_HOURS;
}

async function getCachedData(supabase: any, barId: string): Promise<any | null> {
  const { data: cache } = await supabase
    .from('google_place_cache')
    .select('cached_data')
    .eq('bar_id', barId)
    .maybeSingle();

  return cache?.cached_data || null;
}

async function updateCache(supabase: any, barId: string, placeId: string, cachedJson: any): Promise<void> {
  await supabase.from('google_place_cache').upsert({
    bar_id: barId,
    place_id: placeId,
    cached_data: cachedJson,
    cached_at: new Date().toISOString(),
  }, {
    onConflict: 'bar_id'
  });
}

async function updateBarFetchTime(supabase: any, barId: string): Promise<void> {
  await supabase.from('bars').update({
    google_last_fetched_at: new Date().toISOString()
  }).eq('bar_id', barId);
}

async function syncDenormalizedData(supabase: any, barId: string, placeData: PlaceDetailsResponse): Promise<void> {
  await supabase.from('bars').update({
    rating: placeData.rating,
    review_count: placeData.review_count,
    photo_urls: placeData.photos,
    address: placeData.address,
    opening_hours: placeData.opening_hours,
    google_last_synced_at: new Date().toISOString()
  }).eq('bar_id', barId);
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    if (req.method !== 'GET') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed. Use GET.' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } }
    });

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const url = new URL(req.url);
    const barId = url.searchParams.get('bar_id');

    if (!barId) {
      return new Response(
        JSON.stringify({ error: 'Missing bar_id query parameter' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { data: bar, error: barError } = await supabase
      .from('bars')
      .select('bar_id, name, lat, lng, google_place_id, google_last_fetched_at')
      .eq('bar_id', barId)
      .maybeSingle();

    if (barError || !bar) {
      return new Response(
        JSON.stringify({ error: 'Bar not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!bar.google_place_id) {
      return new Response(
        JSON.stringify({
          needs_linking: true,
          message: 'Bar not yet linked to Google Place. Call /link-google-place first.'
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const cacheValid = await isCacheValid(supabase, barId);

    if (cacheValid) {
      const cachedData = await getCachedData(supabase, barId);
      if (cachedData) {
        return new Response(
          JSON.stringify({
            ...cachedData,
            cache_hit: true
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    const placeData = await getPlaceDetailsFromGoogle(bar.google_place_id);

    if (!placeData) {
      return new Response(
        JSON.stringify({ error: 'Unable to fetch place details from Google Places' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const normalizedData = normalizeResponse(barId, bar.google_place_id, placeData, false);

    await updateCache(supabase, barId, bar.google_place_id, normalizedData);
    await updateBarFetchTime(supabase, barId);
    await syncDenormalizedData(supabase, barId, normalizedData);

    return new Response(
      JSON.stringify(normalizedData),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in google-place-details:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        message: error instanceof Error ? error.message : String(error)
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
