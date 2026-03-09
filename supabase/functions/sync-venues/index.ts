import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface SyncVenuesRequest {
  city: string;
  state?: string;
  country?: string;
  lat?: number;
  lng?: number;
  radius_meters?: number;
  types?: string[];
  google_api_key: string;
}

interface GooglePlaceResult {
  place_id: string;
  name: string;
  formatted_address: string;
  geometry: {
    location: {
      lat: number;
      lng: number;
    };
  };
  types: string[];
  rating?: number;
  user_ratings_total?: number;
  opening_hours?: {
    open_now?: boolean;
    weekday_text?: string[];
  };
  formatted_phone_number?: string;
  website?: string;
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

    const requestData: SyncVenuesRequest = await req.json();
    const {
      city,
      state,
      country = "US",
      lat,
      lng,
      radius_meters = 5000,
      types = ["bar", "night_club"],
      google_api_key,
    } = requestData;

    if (!city || !google_api_key) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing required fields: city, google_api_key" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    let searchLat = lat;
    let searchLng = lng;

    if (!searchLat || !searchLng) {
      const geocodeUrl = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(
        `${city}${state ? ", " + state : ""}, ${country}`
      )}&key=${google_api_key}`;

      const geocodeResponse = await fetch(geocodeUrl);
      const geocodeData = await geocodeResponse.json();

      if (geocodeData.status !== "OK" || !geocodeData.results[0]) {
        return new Response(
          JSON.stringify({ success: false, error: "Failed to geocode city" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      searchLat = geocodeData.results[0].geometry.location.lat;
      searchLng = geocodeData.results[0].geometry.location.lng;
    }

    const venuesAdded = [];
    const venuesUpdated = [];
    const errors = [];

    for (const placeType of types) {
      const placesUrl = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${searchLat},${searchLng}&radius=${radius_meters}&type=${placeType}&key=${google_api_key}`;

      const placesResponse = await fetch(placesUrl);
      const placesData = await placesResponse.json();

      if (placesData.status !== "OK") {
        errors.push(`Failed to fetch ${placeType}: ${placesData.status}`);
        continue;
      }

      for (const place of placesData.results as GooglePlaceResult[]) {
        try {
          const { data: existingVenue } = await supabase
            .from("venues")
            .select("id")
            .eq("google_place_id", place.place_id)
            .maybeSingle();

          const addressComponents = place.formatted_address.split(", ");
          const venueCity = addressComponents.length >= 2 ? addressComponents[addressComponents.length - 2] : city;
          const venueState = state || "";

          const venueType = place.types.includes("night_club")
            ? "club"
            : place.types.includes("bar")
            ? "bar"
            : "lounge";

          const venueData = {
            name: place.name,
            type: venueType,
            address: place.formatted_address,
            city: venueCity,
            state: venueState,
            country: country,
            lat: place.geometry.location.lat,
            lng: place.geometry.location.lng,
            geofence_radius_meters: 50,
            google_place_id: place.place_id,
            phone: place.formatted_phone_number || null,
            website: place.website || null,
            is_active: true,
            rating: place.rating || null,
            user_ratings_total: place.user_ratings_total || null,
            metadata: {
              place_types: place.types,
              opening_hours: place.opening_hours || null,
            },
          };

          if (existingVenue) {
            const { error: updateError } = await supabase
              .from("venues")
              .update(venueData)
              .eq("id", existingVenue.id);

            if (updateError) {
              errors.push(`Failed to update ${place.name}: ${updateError.message}`);
            } else {
              venuesUpdated.push(place.name);
            }
          } else {
            const { error: insertError } = await supabase
              .from("venues")
              .insert(venueData);

            if (insertError) {
              errors.push(`Failed to insert ${place.name}: ${insertError.message}`);
            } else {
              venuesAdded.push(place.name);
            }
          }
        } catch (venueError) {
          console.error(`Error processing venue ${place.name}:`, venueError);
          errors.push(`Error processing ${place.name}`);
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Venue sync completed",
        venues_added: venuesAdded.length,
        venues_updated: venuesUpdated.length,
        errors: errors.length,
        details: {
          added: venuesAdded,
          updated: venuesUpdated,
          errors: errors,
        },
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error in sync-venues function:", error);
    return new Response(
      JSON.stringify({ success: false, error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
