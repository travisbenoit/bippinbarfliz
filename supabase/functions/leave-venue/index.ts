import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface LeaveVenueRequest {
  venue_id?: string;
  presence_id?: string;
  user_lat?: number;
  user_lng?: number;
  force?: boolean;
}

interface LeaveVenueResponse {
  success: boolean;
  message?: string;
  dwell_seconds?: number;
  error?: string;
}

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

    const requestData: LeaveVenueRequest = await req.json();
    const { venue_id, presence_id, user_lat, user_lng, force } = requestData;

    let presenceQuery = supabase
      .from("user_venue_presence")
      .select("*")
      .eq("user_id", user.id)
      .eq("status", "IN_VENUE")
      .is("left_at", null);

    if (presence_id) {
      presenceQuery = presenceQuery.eq("id", presence_id);
    } else if (venue_id) {
      presenceQuery = presenceQuery.eq("venue_id", venue_id);
    }

    const { data: presence, error: presenceError } = await presenceQuery.maybeSingle();

    if (presenceError || !presence) {
      return new Response(
        JSON.stringify({ success: false, error: "No active presence found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (user_lat && user_lng && !force) {
      const { data: venue } = await supabase
        .from("venues")
        .select("lat, lng, geofence_radius_meters")
        .eq("id", presence.venue_id)
        .maybeSingle();

      if (venue) {
        const distanceResult = await supabase.rpc("calculate_distance_meters", {
          lat1: user_lat,
          lng1: user_lng,
          lat2: venue.lat,
          lng2: venue.lng,
        });

        const distance = distanceResult.data as number;
        const geofenceRadius = venue.geofence_radius_meters || 50;

        if (distance <= geofenceRadius) {
          return new Response(
            JSON.stringify({
              success: false,
              error: "User is still within venue geofence",
              distance_meters: Math.round(distance),
              geofence_radius: geofenceRadius,
            }),
            {
              status: 400,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        }
      }
    }

    const leftAt = new Date();
    const enteredAt = new Date(presence.entered_at);
    const dwellSeconds = Math.floor((leftAt.getTime() - enteredAt.getTime()) / 1000);

    const updateData: any = {
      status: "LEFT_VENUE",
      left_at: leftAt.toISOString(),
      dwell_seconds: dwellSeconds,
    };

    if (user_lat && user_lng) {
      updateData.metadata = {
        ...presence.metadata,
        exit_location: { lat: user_lat, lng: user_lng },
      };
    }

    const { error: updateError } = await supabase
      .from("user_venue_presence")
      .update(updateData)
      .eq("id", presence.id);

    if (updateError) {
      console.error("Error updating presence:", updateError);
      return new Response(
        JSON.stringify({ success: false, error: "Failed to update presence record" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const response: LeaveVenueResponse = {
      success: true,
      message: "Successfully left venue",
      dwell_seconds: dwellSeconds,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error in leave-venue function:", error);
    return new Response(
      JSON.stringify({ success: false, error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
