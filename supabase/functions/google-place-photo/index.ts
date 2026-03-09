import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import { corsHeaders } from '../_shared/cors.ts';

const GOOGLE_MAPS_SERVER_KEY = Deno.env.get('GOOGLE_PLACES_API_KEY') || Deno.env.get('GOOGLE_MAPS_SERVER_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;

const rateLimitMap = new Map<string, { count: number; resetTime: number }>();
const RATE_LIMIT_REQUESTS = 60;
const RATE_LIMIT_WINDOW_MS = 60000;

function getClientIp(req: Request): string {
  return req.headers.get('x-forwarded-for')?.split(',')[0].trim() ||
         req.headers.get('cf-connecting-ip') ||
         'unknown';
}

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const limit = rateLimitMap.get(ip);

  if (!limit || now > limit.resetTime) {
    rateLimitMap.set(ip, { count: 1, resetTime: now + RATE_LIMIT_WINDOW_MS });
    return true;
  }

  if (limit.count >= RATE_LIMIT_REQUESTS) {
    return false;
  }

  limit.count++;
  return true;
}

async function fetchPhotoFromGoogle(
  photoRef: string,
  maxWidth: number
): Promise<ArrayBuffer> {
  if (!GOOGLE_MAPS_SERVER_KEY) {
    throw new Error('Google Maps API key not configured');
  }

  const url = new URL('https://maps.googleapis.com/maps/api/place/photo');
  url.searchParams.set('photoreference', photoRef);
  url.searchParams.set('maxwidth', maxWidth.toString());
  url.searchParams.set('key', GOOGLE_MAPS_SERVER_KEY);

  const response = await fetch(url.toString());

  if (!response.ok) {
    throw new Error(`Google Places Photo API error: ${response.statusText}`);
  }

  return await response.arrayBuffer();
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

    const clientIp = getClientIp(req);
    if (!checkRateLimit(clientIp)) {
      return new Response(
        JSON.stringify({ error: 'Rate limit exceeded' }),
        {
          status: 429,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
            'Retry-After': '60'
          }
        }
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
    const photoRef = url.searchParams.get('photo_ref');
    const maxWidthStr = url.searchParams.get('max_width') || '400';

    if (!barId) {
      return new Response(
        JSON.stringify({ error: 'Missing bar_id query parameter' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!photoRef) {
      return new Response(
        JSON.stringify({ error: 'Missing photo_ref query parameter' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const maxWidth = Math.min(parseInt(maxWidthStr), 1600);
    if (isNaN(maxWidth) || maxWidth < 100) {
      return new Response(
        JSON.stringify({
          error: 'Invalid max_width. Must be between 100 and 1600'
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { data: bar, error: barError } = await supabase
      .from('bars')
      .select('bar_id, lat, lng')
      .eq('bar_id', barId)
      .maybeSingle();

    if (barError || !bar) {
      return new Response(
        JSON.stringify({ error: 'Bar not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const photoBuffer = await fetchPhotoFromGoogle(photoRef, maxWidth);

    const cacheHeaders = {
      'Content-Type': 'image/jpeg',
      'Cache-Control': 'public, max-age=86400, immutable',
      'ETag': `"${barId}-${photoRef}-${maxWidth}"`,
      'X-Content-Type-Options': 'nosniff',
    };

    return new Response(photoBuffer, {
      status: 200,
      headers: { ...corsHeaders, ...cacheHeaders }
    });

  } catch (error) {
    console.error('Error in google-place-photo:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        message: error instanceof Error ? error.message : String(error)
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
