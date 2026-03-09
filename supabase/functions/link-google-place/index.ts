import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import { corsHeaders } from '../_shared/cors.ts';
import { isFeaturedMarket } from '../_shared/markets.ts';

const GOOGLE_MAPS_SERVER_KEY = Deno.env.get('GOOGLE_PLACES_API_KEY') || Deno.env.get('GOOGLE_MAPS_SERVER_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;

const MAX_DISTANCE_METERS = 150;
const CONFIDENCE_THRESHOLD = 0.80;
const RATE_LIMIT_PER_MINUTE = 10;

interface LinkRequest {
  bar_id: string;
}

interface Bar {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  google_place_id: string | null;
  google_last_linked_at: string | null;
}

interface GooglePlaceCandidate {
  place_id: string;
  name: string;
  formatted_address: string;
  geometry: {
    location: {
      lat: number;
      lng: number;
    };
  };
}

interface GooglePlacesResponse {
  results: GooglePlaceCandidate[];
  status: string;
}

function levenshteinDistance(str1: string, str2: string): number {
  const s1 = str1.toLowerCase().trim();
  const s2 = str2.toLowerCase().trim();

  const matrix: number[][] = [];

  for (let i = 0; i <= s2.length; i++) {
    matrix[i] = [i];
  }

  for (let j = 0; j <= s1.length; j++) {
    matrix[0][j] = j;
  }

  for (let i = 1; i <= s2.length; i++) {
    for (let j = 1; j <= s1.length; j++) {
      if (s2.charAt(i - 1) === s1.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j] + 1
        );
      }
    }
  }

  return matrix[s2.length][s1.length];
}

function calculateNameSimilarity(name1: string, name2: string): number {
  const distance = levenshteinDistance(name1, name2);
  const maxLength = Math.max(name1.length, name2.length);
  return maxLength === 0 ? 1 : 1 - distance / maxLength;
}

function calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371000;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;

  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

const rateLimitMap = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(userId: string): boolean {
  const now = Date.now();
  const userLimit = rateLimitMap.get(userId);

  if (!userLimit || now > userLimit.resetAt) {
    rateLimitMap.set(userId, { count: 1, resetAt: now + 60000 });
    return true;
  }

  if (userLimit.count >= RATE_LIMIT_PER_MINUTE) {
    return false;
  }

  userLimit.count++;
  return true;
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

    const { data: profile } = await supabase
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

    if (!checkRateLimit(user.id)) {
      return new Response(
        JSON.stringify({ error: 'Rate limit exceeded. Maximum 10 requests per minute.' }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { bar_id }: LinkRequest = await req.json();
    if (!bar_id) {
      return new Response(
        JSON.stringify({ error: 'Missing bar_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { data: bar, error: barError } = await supabase
      .from('bars')
      .select('id, name, latitude, longitude, google_place_id, google_last_linked_at')
      .eq('id', bar_id)
      .maybeSingle();

    if (barError || !bar) {
      return new Response(
        JSON.stringify({ error: 'Bar not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (bar.google_place_id) {
      return new Response(
        JSON.stringify({
          bar_id: bar.id,
          google_place_id: bar.google_place_id,
          already_linked: true,
          linked_at: bar.google_last_linked_at
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!GOOGLE_MAPS_SERVER_KEY) {
      return new Response(
        JSON.stringify({ error: 'Google API key not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const featuredMarket = isFeaturedMarket(bar.latitude, bar.longitude);
    const regionCode = featuredMarket ? featuredMarket.country_code.toLowerCase() : 'us';

    const searchUrl = new URL('https://maps.googleapis.com/maps/api/place/textsearch/json');
    searchUrl.searchParams.append('query', bar.name);
    searchUrl.searchParams.append('location', `${bar.latitude},${bar.longitude}`);
    searchUrl.searchParams.append('radius', '300');
    searchUrl.searchParams.append('region', regionCode);
    searchUrl.searchParams.append('key', GOOGLE_MAPS_SERVER_KEY);

    const googleResponse = await fetch(searchUrl.toString());
    const googleData: GooglePlacesResponse = await googleResponse.json();

    if (googleData.status !== 'OK' && googleData.status !== 'ZERO_RESULTS') {
      console.error('Google Places API error:', googleData.status);
      return new Response(
        JSON.stringify({ error: 'Google Places API error', status: googleData.status }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const candidates = googleData.results
      .map(place => {
        const distance = calculateDistance(
          bar.latitude,
          bar.longitude,
          place.geometry.location.lat,
          place.geometry.location.lng
        );
        const nameSimilarity = calculateNameSimilarity(bar.name, place.name);
        const distanceScore = Math.max(0, 1 - (distance / MAX_DISTANCE_METERS));
        const matchConfidence = (nameSimilarity * 0.7) + (distanceScore * 0.3);

        return {
          place_id: place.place_id,
          name: place.name,
          address: place.formatted_address,
          distance_m: Math.round(distance),
          name_similarity: Math.round(nameSimilarity * 100) / 100,
          match_confidence: Math.round(matchConfidence * 100) / 100,
          location: place.geometry.location
        };
      })
      .filter(c => c.distance_m <= MAX_DISTANCE_METERS)
      .sort((a, b) => {
        if (Math.abs(b.match_confidence - a.match_confidence) > 0.01) {
          return b.match_confidence - a.match_confidence;
        }
        return a.distance_m - b.distance_m;
      });

    if (candidates.length === 0) {
      return new Response(
        JSON.stringify({
          bar_id: bar.id,
          google_place_id: null,
          needs_manual_review: true,
          reason: 'No candidates found within 150m',
          candidates: []
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const bestMatch = candidates[0];

    if (bestMatch.match_confidence >= CONFIDENCE_THRESHOLD) {
      const { error: updateError } = await supabase
        .from('bars')
        .update({
          google_place_id: bestMatch.place_id,
          google_last_linked_at: new Date().toISOString()
        })
        .eq('id', bar.id);

      if (updateError) {
        console.error('Error updating bar:', updateError);
        return new Response(
          JSON.stringify({ error: 'Failed to update bar' }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      return new Response(
        JSON.stringify({
          bar_id: bar.id,
          google_place_id: bestMatch.place_id,
          matched_name: bestMatch.name,
          distance_m: bestMatch.distance_m,
          match_confidence: bestMatch.match_confidence
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({
        bar_id: bar.id,
        google_place_id: null,
        needs_manual_review: true,
        reason: `Best match confidence ${bestMatch.match_confidence} below threshold ${CONFIDENCE_THRESHOLD}`,
        candidates: candidates.slice(0, 3).map(c => ({
          place_id: c.place_id,
          name: c.name,
          address: c.address,
          distance_m: c.distance_m,
          match_confidence: c.match_confidence
        }))
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error in link-google-place:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        message: error instanceof Error ? error.message : String(error)
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
