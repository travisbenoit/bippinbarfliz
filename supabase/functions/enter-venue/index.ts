import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface EnterVenueRequest {
  venue_id: string;
  user_lat: number;
  user_lng: number;
  is_visible?: boolean;
  entry_method?: string;
}

interface EnterVenueResponse {
  success: boolean;
  presence_id?: string;
  venue?: any;
  error?: string;
  message?: string;
}

const MIN_DWELL_SECONDS = 30;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase environment variables");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: "Unauthorized" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const requestData: EnterVenueRequest = await req.json();
    const { venue_id, user_lat, user_lng, is_visible = true, entry_method = "MANUAL_CHECKIN" } = requestData;

    if (!venue_id || typeof user_lat !== "number" || typeof user_lng !== "number") {
      return new Response(
        JSON.stringify({ success: false, error: "Missing or invalid required fields" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { data: venue, error: venueError } = await supabase
      .from("venues")
      .select("*")
      .eq("id", venue_id)
      .eq("is_active", true)
      .maybeSingle();

    if (venueError || !venue) {
      return new Response(
        JSON.stringify({ success: false, error: "Venue not found or inactive" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const distanceResult = await supabase.rpc("calculate_distance_meters", {
      lat1: user_lat,
      lng1: user_lng,
      lat2: venue.lat,
      lng2: venue.lng,
    });

    const distance = distanceResult.data as number;
    const geofenceRadius = venue.geofence_radius_meters || 150;

    if (distance > geofenceRadius) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "User is not within venue geofence",
          distance_meters: Math.round(distance),
          required_distance: geofenceRadius,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { data: existingPresence } = await supabase
      .from("user_venue_presence")
      .select("*")
      .eq("user_id", user.id)
      .eq("status", "IN_VENUE")
      .is("left_at", null)
      .maybeSingle();

    if (existingPresence) {
      if (existingPresence.venue_id === venue_id) {
        await supabase
          .from("user_venue_presence")
          .update({
            last_seen_at: new Date().toISOString(),
            is_visible_in_venue: is_visible,
          })
          .eq("id", existingPresence.id);

        return new Response(
          JSON.stringify({
            success: true,
            message: "Presence updated",
            presence_id: existingPresence.id,
            venue,
          }),
          {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      } else {
        const dwellSeconds = Math.floor(
          (new Date().getTime() - new Date(existingPresence.entered_at).getTime()) / 1000
        );

        await supabase
          .from("user_venue_presence")
          .update({
            status: "LEFT_VENUE",
            left_at: new Date().toISOString(),
            dwell_seconds: dwellSeconds,
          })
          .eq("id", existingPresence.id);
      }
    }

    const { data: newPresence, error: presenceError } = await supabase
      .from("user_venue_presence")
      .insert({
        user_id: user.id,
        venue_id: venue_id,
        status: "IN_VENUE",
        entered_at: new Date().toISOString(),
        last_seen_at: new Date().toISOString(),
        is_visible_in_venue: is_visible,
        entry_method: entry_method,
        dwell_seconds: 0,
        metadata: {
          entry_distance_meters: Math.round(distance),
          entry_location: { lat: user_lat, lng: user_lng },
        },
      })
      .select()
      .single();

    if (presenceError) {
      console.error("Error creating presence:", presenceError);
      return new Response(
        JSON.stringify({ success: false, error: "Failed to create presence record" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const response: EnterVenueResponse = {
      success: true,
      message: "Successfully entered venue",
      presence_id: newPresence.id,
      venue,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error in enter-venue function:", error);
    return new Response(
      JSON.stringify({ success: false, error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
