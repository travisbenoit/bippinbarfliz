import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import { corsHeaders } from '../_shared/cors.ts';
import { isFeaturedMarket } from '../_shared/markets.ts';

let GOOGLE_MAPS_SERVER_KEY = Deno.env.get('GOOGLE_PLACES_API_KEY') || Deno.env.get('GOOGLE_MAPS_SERVER_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;

const MAX_DISTANCE_METERS = 50000;
const CONFIDENCE_THRESHOLD = 0.55;

interface Venue {
  id: string;
  name: string;
  lat: number;
  lng: number;
  place_id: string | null;
}

function levenshteinDistance(str1: string, str2: string): number {
  const s1 = str1.toLowerCase().trim();
  const s2 = str2.toLowerCase().trim();
  const matrix: number[][] = [];
  for (let i = 0; i <= s2.length; i++) matrix[i] = [i];
  for (let j = 0; j <= s1.length; j++) matrix[0][j] = j;
  for (let i = 1; i <= s2.length; i++) {
    for (let j = 1; j <= s1.length; j++) {
      if (s2.charAt(i - 1) === s1.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(matrix[i - 1][j - 1] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j] + 1);
      }
    }
  }
  return matrix[s2.length][s1.length];
}

function nameSimilarity(a: string, b: string): number {
  const dist = levenshteinDistance(a, b);
  const max = Math.max(a.length, b.length);
  return max === 0 ? 1 : 1 - dist / max;
}

function haversineDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371000;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function cleanVenueName(name: string): string {
  return name.replace(/\s*[–—-]\s*(weston|sunrise|davie|fort lauderdale|sawgrass|darwin|palmerston|nightcliff|rapid creek|fannie bay).*$/i, '').trim();
}

function getRegionCode(lat: number, lng: number): string {
  const market = isFeaturedMarket(lat, lng);
  if (market) return market.country_code.toLowerCase();
  return 'us';
}

async function searchGooglePlaces(venue: Venue, regionCode: string): Promise<any[]> {
  const searchName = cleanVenueName(venue.name);
  const url = new URL('https://maps.googleapis.com/maps/api/place/textsearch/json');
  url.searchParams.set('query', searchName);
  url.searchParams.set('location', `${venue.lat},${venue.lng}`);
  url.searchParams.set('radius', '500');
  url.searchParams.set('region', regionCode);
  url.searchParams.set('type', 'bar|night_club|restaurant');
  url.searchParams.set('key', GOOGLE_MAPS_SERVER_KEY!);

  const resp = await fetch(url.toString());
  const data = await resp.json();
  if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') {
    throw new Error(`Google Places search failed: ${data.status}`);
  }
  return data.results || [];
}

async function fetchPlaceDetails(placeId: string): Promise<any> {
  const fields = [
    'name', 'rating', 'user_ratings_total', 'photos',
    'opening_hours', 'formatted_address', 'formatted_phone_number', 'website',
    'url', 'price_level', 'reviews', 'types', 'geometry'
  ].join(',');

  const url = new URL('https://maps.googleapis.com/maps/api/place/details/json');
  url.searchParams.set('place_id', placeId);
  url.searchParams.set('fields', fields);
  url.searchParams.set('key', GOOGLE_MAPS_SERVER_KEY!);

  const resp = await fetch(url.toString());
  const data = await resp.json();
  if (data.status !== 'OK') {
    throw new Error(`Google Place Details failed: ${data.status}`);
  }
  return data.result;
}

function buildPhotoUrl(photoRef: string, maxWidth = 800): string {
  return `https://maps.googleapis.com/maps/api/place/photo?maxwidth=${maxWidth}&photoreference=${photoRef}&key=${GOOGLE_MAPS_SERVER_KEY}`;
}

async function enrichVenue(adminSupabase: any, venue: Venue, regionCode: string): Promise<{
  id: string;
  name: string;
  status: 'linked' | 'low_confidence' | 'no_match' | 'error';
  place_id?: string;
  confidence?: number;
  error?: string;
}> {
  try {
    const results = await searchGooglePlaces(venue, regionCode);

    const candidates = results
      .map((place: any) => {
        const dist = haversineDistance(venue.lat, venue.lng, place.geometry.location.lat, place.geometry.location.lng);
        const sim = nameSimilarity(cleanVenueName(venue.name), place.name);
        const confidence = sim;
        return { place_id: place.place_id, name: place.name, lat: place.geometry.location.lat, lng: place.geometry.location.lng, dist, confidence };
      })
      .filter((c: any) => c.dist <= MAX_DISTANCE_METERS)
      .sort((a: any, b: any) => b.confidence - a.confidence);

    if (candidates.length === 0) {
      return { id: venue.id, name: venue.name, status: 'no_match' };
    }

    const best = candidates[0];

    if (best.confidence < CONFIDENCE_THRESHOLD) {
      return { id: venue.id, name: venue.name, status: 'low_confidence', confidence: best.confidence };
    }

    const details = await fetchPlaceDetails(best.place_id);

    const photoRef = details.photos?.[0]?.photo_reference;
    const photoUrl = photoRef ? buildPhotoUrl(photoRef) : null;

    const { error: updateError } = await adminSupabase.from('venues').update({
      google_place_id: best.place_id,
      place_id: best.place_id,
      rating: details.rating || null,
      user_ratings_total: details.user_ratings_total || null,
      photo_url: photoUrl,
      phone: details.formatted_phone_number || null,
      website: details.website || null,
      hours: details.opening_hours || null,
      address: details.formatted_address || null,
      price_level: details.price_level || null,
      lat: details.geometry?.location?.lat || venue.lat,
      lng: details.geometry?.location?.lng || venue.lng,
      metadata: {
        google_url: details.url,
        google_types: details.types,
        google_reviews: details.reviews?.slice(0, 5) || [],
        last_google_sync: new Date().toISOString()
      },
      updated_at: new Date().toISOString(),
    }).eq('id', venue.id);

    if (updateError) {
      throw new Error(`DB update failed: ${updateError.message}`);
    }

    return { id: venue.id, name: venue.name, status: 'linked', place_id: best.place_id, confidence: best.confidence };
  } catch (err) {
    return { id: venue.id, name: venue.name, status: 'error', error: err instanceof Error ? err.message : String(err) };
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed. Use POST.' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const internalSecret = req.headers.get('x-internal-secret');
    const INTERNAL_SECRET = Deno.env.get('INTERNAL_ENRICH_SECRET');

    const authHeader = req.headers.get('Authorization');

    if (INTERNAL_SECRET && internalSecret === INTERNAL_SECRET) {
      // trusted internal call — skip user auth
    } else {
      if (!authHeader) {
        return new Response(
          JSON.stringify({ error: 'Missing authorization header' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const userSupabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
        global: { headers: { Authorization: authHeader } }
      });

      const { data: { user }, error: authError } = await userSupabase.auth.getUser();
      if (authError || !user) {
        return new Response(
          JSON.stringify({ error: 'Unauthorized' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const { data: profile } = await userSupabase
        .from('user_profiles')
        .select('is_admin')
        .eq('id', user.id)
        .maybeSingle();

      if (!profile?.is_admin) {
        return new Response(
          JSON.stringify({ error: 'Admin access required' }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    const body = await req.json().catch(() => ({}));
    const marketName: string | undefined = body.market;
    const reEnrich: boolean = body.re_enrich === true;

    if (body.api_key) {
      GOOGLE_MAPS_SERVER_KEY = body.api_key;
    }

    if (!GOOGLE_MAPS_SERVER_KEY) {
      return new Response(
        JSON.stringify({ error: 'Google API key not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const adminSupabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    let venueQuery = adminSupabase
      .from('venues')
      .select('id, name, lat, lng, place_id, google_place_id')
      .eq('is_active', true);

    if (!reEnrich) {
      venueQuery = venueQuery.or('place_id.is.null,google_place_id.is.null');
    }

    const { data: allVenues, error: venueError } = await venueQuery.order('name');

    if (venueError) {
      return new Response(
        JSON.stringify({ error: 'Failed to fetch venues', details: venueError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const venues: Venue[] = (allVenues || []).filter((v: Venue) => {
      if (marketName) {
        const market = isFeaturedMarket(v.lat, v.lng);
        if (!market || market.name !== marketName) return false;
      }
      return true;
    });

    if (venues.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No venues to enrich', linked: 0, skipped: 0, errors: 0, results: [] }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const results = [];
    let linked = 0;
    let skipped = 0;
    let errors = 0;

    for (const venue of venues) {
      const regionCode = getRegionCode(venue.lat, venue.lng);
      const result = await enrichVenue(adminSupabase, venue, regionCode);
      results.push(result);

      if (result.status === 'linked') linked++;
      else if (result.status === 'error') errors++;
      else skipped++;

      await new Promise(r => setTimeout(r, 150));
    }

    return new Response(
      JSON.stringify({
        message: `Enrichment complete for ${venues.length} venues`,
        total: venues.length,
        linked,
        skipped,
        errors,
        results,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in enrich-venues:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        message: error instanceof Error ? error.message : String(error)
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
