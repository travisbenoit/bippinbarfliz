import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const venueId = url.searchParams.get("bar_id") || url.searchParams.get("venue_id");

    if (!venueId) {
      return new Response(
        JSON.stringify({ error: "Missing required parameter: bar_id or venue_id" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data: venue, error: venueError } = await supabase
      .from("venues")
      .select("*")
      .eq("id", venueId)
      .maybeSingle();

    if (venueError) throw venueError;

    if (!venue) {
      return new Response(
        JSON.stringify({ error: "Venue not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const staleThreshold = new Date(Date.now() - 25 * 60 * 1000).toISOString();

    const { count: populationCount } = await supabase
      .from("user_venue_presence")
      .select("id", { count: "exact", head: true })
      .eq("venue_id", venueId)
      .eq("status", "IN_VENUE")
      .is("left_at", null)
      .gte("last_seen_at", staleThreshold);

    return new Response(
      JSON.stringify({
        bar_id: venue.id,
        venue_id: venue.id,
        name: venue.name,
        address: venue.address,
        lat: venue.lat,
        lng: venue.lng,
        category: venue.category,
        description: venue.description,
        rating: venue.rating,
        photo_url: venue.photo_url,
        place_id: venue.place_id,
        geofence_radius_meters: venue.geofence_radius_meters,
        phone: venue.phone,
        website: venue.website,
        hours: venue.hours,
        is_active: venue.is_active,
        created_at: venue.created_at,
        updated_at: venue.updated_at,
        current_population: populationCount || 0,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in bar-detail:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", message: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
