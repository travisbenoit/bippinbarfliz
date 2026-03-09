import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { isFeaturedMarket } from "../_shared/markets.ts";

function haversineDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371000;
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const latParam = url.searchParams.get("lat");
    const lngParam = url.searchParams.get("lng");
    const radiusParam = url.searchParams.get("radius_m");

    if (!latParam || !lngParam) {
      return new Response(
        JSON.stringify({ error: "Missing required parameters: lat, lng" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const lat = parseFloat(latParam);
    const lng = parseFloat(lngParam);
    const radius_m = radiusParam ? parseFloat(radiusParam) : 5000;

    if (isNaN(lat) || isNaN(lng) || isNaN(radius_m)) {
      return new Response(
        JSON.stringify({ error: "Invalid numeric parameters" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const featuredMarket = isFeaturedMarket(lat, lng);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const degreeOffset = (radius_m / 1000) / 111;
    const { data: venues, error: venuesError } = await supabase
      .from("venues")
      .select("id, name, lat, lng, address, category, rating, geofence_radius_meters, photo_url, place_id")
      .eq("is_active", true)
      .gte("lat", lat - degreeOffset)
      .lte("lat", lat + degreeOffset)
      .gte("lng", lng - degreeOffset)
      .lte("lng", lng + degreeOffset);

    if (venuesError) throw venuesError;

    if (!venues || venues.length === 0) {
      return new Response(
        JSON.stringify({ bars: [], market: featuredMarket?.name || null }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const venuesWithDistance = venues
      .map((v) => ({ ...v, distance_m: haversineDistance(lat, lng, v.lat, v.lng) }))
      .filter((v) => v.distance_m <= radius_m);

    if (venuesWithDistance.length === 0) {
      return new Response(
        JSON.stringify({ bars: [], market: featuredMarket?.name || null }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const venueIds = venuesWithDistance.map((v) => v.id);
    const staleThreshold = new Date(Date.now() - 25 * 60 * 1000).toISOString();

    const { data: presenceCounts } = await supabase
      .from("user_venue_presence")
      .select("venue_id")
      .in("venue_id", venueIds)
      .eq("status", "IN_VENUE")
      .is("left_at", null)
      .gte("last_seen_at", staleThreshold);

    const populationMap = new Map<string, number>();
    if (presenceCounts) {
      for (const p of presenceCounts) {
        populationMap.set(p.venue_id, (populationMap.get(p.venue_id) || 0) + 1);
      }
    }

    const result = venuesWithDistance
      .map((v) => ({
        bar_id: v.id,
        venue_id: v.id,
        name: v.name,
        lat: v.lat,
        lng: v.lng,
        address: v.address,
        category: v.category,
        rating: v.rating,
        photo_url: v.photo_url,
        place_id: v.place_id,
        geofence_radius_meters: v.geofence_radius_meters,
        distance_m: Math.round(v.distance_m),
        population_count: populationMap.get(v.id) || 0,
      }))
      .sort((a, b) => a.distance_m - b.distance_m);

    return new Response(
      JSON.stringify({ bars: result, market: featuredMarket?.name || null }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in bars-nearby:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", message: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
