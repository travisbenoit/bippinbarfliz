import { createClient } from 'npm:@supabase/supabase-js@2.57.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
};

interface PlacesResponse {
  results: Array<{
    place_id: string;
    name: string;
    vicinity: string;
    geometry: {
      location: {
        lat: number;
        lng: number;
      };
    };
    types: string[];
    rating?: number;
    opening_hours?: {
      open_now?: boolean;
    };
  }>;
  status: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const { lat, lng, radius = 5000, country = 'US' } = await req.json();

    if (!lat || !lng) {
      return new Response(
        JSON.stringify({ error: 'Latitude and longitude are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const googleApiKey = Deno.env.get('GOOGLE_PLACES_API_KEY');

    if (googleApiKey) {
      const placesUrl = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=${radius}&type=bar&keyword=bar|pub|brewery|cocktail&key=${googleApiKey}`;

      const placesResponse = await fetch(placesUrl);
      const placesData: PlacesResponse = await placesResponse.json();

      if (placesData.status === 'OK' && placesData.results.length > 0) {
        const venues = placesData.results.map((place) => ({
          name: place.name,
          address: place.vicinity,
          lat: place.geometry.location.lat,
          lng: place.geometry.location.lng,
          category: place.types.includes('night_club') ? 'nightclub' :
                    place.types.includes('brewery') ? 'brewery' :
                    place.types.includes('restaurant') ? 'bar_restaurant' : 'bar',
          rating: place.rating || null,
          is_active: true,
          hours: {},
        }));

        for (const venue of venues) {
          const { data: existing } = await supabase
            .from('venues')
            .select('id')
            .eq('name', venue.name)
            .eq('address', venue.address)
            .maybeSingle();

          if (!existing) {
            await supabase.from('venues').insert({
              ...venue,
              country: country,
            });
          }
        }
      }
    }

    const radiusDegrees = radius / 111000;
    const { data: allVenues, error } = await supabase
      .from('venues')
      .select('*')
      .eq('is_active', true)
      .eq('country', country)
      .gte('lat', lat - radiusDegrees)
      .lte('lat', lat + radiusDegrees)
      .gte('lng', lng - radiusDegrees)
      .lte('lng', lng + radiusDegrees)
      .order('name', { ascending: true })
      .limit(60);

    if (error) {
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ venues: allVenues || [] }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
