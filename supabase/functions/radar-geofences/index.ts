import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

interface GeofencePayload {
  action: "create" | "delete" | "list" | "sync";
  venue?: {
    id: string;
    name: string;
    lat: number;
    lng: number;
    category?: string;
    address?: string;
    geofence_radius_meters?: number;
  };
  venue_id?: string;
  venues?: Array<{
    id: string;
    name: string;
    lat: number;
    lng: number;
    category?: string;
    address?: string;
    geofence_radius_meters?: number;
  }>;
}

async function createGeofence(
  secretKey: string,
  venue: GeofencePayload["venue"]
): Promise<{ success: boolean; error?: string }> {
  if (!venue) return { success: false, error: "Venue data required" };

  try {
    const response = await fetch("https://api.radar.io/v1/geofences", {
      method: "POST",
      headers: {
        Authorization: secretKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        description: venue.name,
        tag: "venue",
        externalId: venue.id,
        type: "circle",
        coordinates: [venue.lng, venue.lat],
        radius: venue.geofence_radius_meters || 80,
        metadata: {
          venue_category: venue.category,
          address: venue.address,
        },
      }),
    });

    if (!response.ok) {
      const errBody = await response.json().catch(() => ({}));
      return { success: false, error: errBody.message || `HTTP ${response.status}` };
    }

    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function deleteGeofence(
  secretKey: string,
  venueId: string
): Promise<{ success: boolean; error?: string }> {
  try {
    const response = await fetch(`https://api.radar.io/v1/geofences/venue/${venueId}`, {
      method: "DELETE",
      headers: { Authorization: secretKey },
    });
    return { success: response.ok };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

async function listGeofences(secretKey: string): Promise<{ geofences: any[]; error?: string }> {
  try {
    const response = await fetch("https://api.radar.io/v1/geofences?limit=1000", {
      headers: { Authorization: secretKey },
    });
    if (!response.ok) return { geofences: [], error: "Failed to fetch geofences" };
    const data = await response.json();
    return { geofences: data.geofences || [] };
  } catch (error) {
    return { geofences: [], error: error.message };
  }
}

async function syncVenues(
  secretKey: string,
  venues: GeofencePayload["venues"]
): Promise<{ success: number; failed: number; errors: string[] }> {
  const results = { success: 0, failed: 0, errors: [] as string[] };

  if (!venues || venues.length === 0) return results;

  for (const venue of venues) {
    const result = await createGeofence(secretKey, venue);
    if (result.success) {
      results.success++;
    } else {
      results.failed++;
      results.errors.push(`${venue.name}: ${result.error}`);
    }
    await new Promise((resolve) => setTimeout(resolve, 100));
  }

  return results;
}

async function syncAllVenuesFromDB(
  secretKey: string,
  supabase: any
): Promise<{ success: number; failed: number; errors: string[] }> {
  const { data: venues, error } = await supabase
    .from("venues")
    .select("id, name, lat, lng, category, address, geofence_radius_meters")
    .eq("is_active", true);

  if (error) throw error;

  return syncVenues(secretKey, venues || []);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const radarSecret = Deno.env.get("RADAR_TEST_SECRET_KEY");
    if (!radarSecret) {
      return new Response(
        JSON.stringify({ error: "Radar secret key not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: profile } = await supabase
      .from("users")
      .select("role")
      .eq("id", user.id)
      .maybeSingle();

    const isAdmin = profile?.role === "admin";

    const payload: GeofencePayload = await req.json();

    if (payload.action === "list") {
      const result = await listGeofences(radarSecret);
      return new Response(
        JSON.stringify(result),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!isAdmin) {
      return new Response(
        JSON.stringify({ error: "Admin access required for this action" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const serviceSupabase = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

    let result;
    switch (payload.action) {
      case "create":
        result = await createGeofence(radarSecret, payload.venue);
        break;
      case "delete":
        if (!payload.venue_id) {
          return new Response(
            JSON.stringify({ error: "venue_id required for delete" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
        result = await deleteGeofence(radarSecret, payload.venue_id);
        break;
      case "sync":
        if (payload.venues && payload.venues.length > 0) {
          result = await syncVenues(radarSecret, payload.venues);
        } else {
          result = await syncAllVenuesFromDB(radarSecret, serviceSupabase);
        }
        break;
      default:
        return new Response(
          JSON.stringify({ error: "Invalid action" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }

    return new Response(
      JSON.stringify(result),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", message: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
