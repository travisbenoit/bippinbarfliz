import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface RideRequest {
  action: "get_estimates" | "request_ride" | "get_status";
  pickup_latitude?: number;
  pickup_longitude?: number;
  dropoff_latitude?: number;
  dropoff_longitude?: number;
  product_id?: string;
  ride_id?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const body: RideRequest = await req.json();
    const serverToken = Deno.env.get("UBER_SERVER_TOKEN");

    if (!serverToken) {
      throw new Error("Uber server token not configured");
    }

    const uberApiUrl = "https://api.uber.com/v2";
    let response;

    if (body.action === "get_estimates") {
      if (!body.pickup_latitude || !body.pickup_longitude || !body.dropoff_latitude || !body.dropoff_longitude) {
        throw new Error("Missing required coordinates for estimates");
      }

      response = await fetch(
        `${uberApiUrl}/estimates/price?start_latitude=${body.pickup_latitude}&start_longitude=${body.pickup_longitude}&end_latitude=${body.dropoff_latitude}&end_longitude=${body.dropoff_longitude}`,
        {
          headers: {
            Authorization: `Bearer ${serverToken}`,
            "Content-Type": "application/json",
          },
        }
      );
    } else if (body.action === "request_ride") {
      if (!body.pickup_latitude || !body.pickup_longitude || !body.dropoff_latitude || !body.dropoff_longitude || !body.product_id) {
        throw new Error("Missing required data for ride request");
      }

      response = await fetch(`${uberApiUrl}/requests`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${serverToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          start_latitude: body.pickup_latitude,
          start_longitude: body.pickup_longitude,
          end_latitude: body.dropoff_latitude,
          end_longitude: body.dropoff_longitude,
          product_id: body.product_id,
        }),
      });
    } else if (body.action === "get_status") {
      if (!body.ride_id) {
        throw new Error("Missing ride ID");
      }

      response = await fetch(`${uberApiUrl}/requests/${body.ride_id}`, {
        headers: {
          Authorization: `Bearer ${serverToken}`,
          "Content-Type": "application/json",
        },
      });
    } else {
      throw new Error("Invalid action");
    }

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message || "Uber API request failed");
    }

    return new Response(JSON.stringify(data), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error";

    return new Response(
      JSON.stringify({
        error: errorMessage,
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  }
});
