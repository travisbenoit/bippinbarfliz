import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { isFeaturedMarket } from "../_shared/markets.ts";

const IS_TEST_MODE = Deno.env.get("RADAR_ENV") === "test";

interface RadarEvent {
  _id: string;
  type: string;
  createdAt: string;
  occurredAt?: string;
  user?: {
    userId?: string;
    externalId?: string;
    deviceId?: string;
    metadata?: Record<string, any>;
  };
  location?: {
    coordinates: [number, number];
    accuracy?: number;
  };
  place?: {
    _id: string;
    name: string;
    categories?: string[];
    chain?: { name: string; slug: string };
  };
  geofence?: {
    _id: string;
    tag?: string;
    externalId?: string;
    description: string;
  };
  confidence?: number;
  duration?: number;
}

async function verifyRadarSignature(
  signature: string,
  payload: string,
  secret: string
): Promise<boolean> {
  try {
    if (!signature || !signature.includes("v1=")) return false;

    const parts = signature.split(",");
    const timestamp = parts.find((p) => p.startsWith("t="))?.split("=")[1];
    const receivedSig = parts.find((p) => p.startsWith("v1="))?.split("=")[1];

    if (!timestamp || !receivedSig) return false;

    const now = Math.floor(Date.now() / 1000);
    if (Math.abs(now - parseInt(timestamp)) > 300) {
      if (IS_TEST_MODE) console.log("Timestamp outside 5-minute window");
      return false;
    }

    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const sigBytes = await crypto.subtle.sign("HMAC", key, encoder.encode(`${timestamp}.${payload}`));
    const computedSig = Array.from(new Uint8Array(sigBytes))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    return computedSig === receivedSig;
  } catch (error) {
    if (IS_TEST_MODE) console.error("Signature verification error:", error);
    return false;
  }
}

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

function floor5MinuteBucket(timestamp: string): string {
  const date = new Date(timestamp);
  date.setMinutes(Math.floor(date.getMinutes() / 5) * 5, 0, 0);
  return date.toISOString();
}

function mapRadarEventType(radarType: string): string | null {
  if (radarType === "user.entered_place" || radarType === "user.entered_geofence") return "enter";
  if (radarType === "user.exited_place" || radarType === "user.exited_geofence") return "exit";
  if (radarType === "user.dwelling_at_place") return "dwell";
  return null;
}

async function findVenueId(
  supabase: any,
  radarPlaceId: string | null,
  geofenceExternalId: string | null,
  lat: number,
  lng: number
): Promise<string | null> {
  if (geofenceExternalId) {
    const { data } = await supabase
      .from("venues")
      .select("id")
      .eq("id", geofenceExternalId)
      .eq("is_active", true)
      .maybeSingle();
    if (data) return data.id;
  }

  if (radarPlaceId) {
    const { data } = await supabase
      .from("venues")
      .select("id")
      .eq("place_id", radarPlaceId)
      .eq("is_active", true)
      .maybeSingle();
    if (data) return data.id;
  }

  const { data: allVenues } = await supabase
    .from("venues")
    .select("id, lat, lng, geofence_radius_meters")
    .eq("is_active", true);

  if (!allVenues || allVenues.length === 0) return null;

  let closestId: string | null = null;
  let minDistance = 150;

  for (const venue of allVenues) {
    const dist = haversineDistance(lat, lng, venue.lat, venue.lng);
    const radius = venue.geofence_radius_meters || 80;
    if (dist < minDistance && dist <= radius) {
      minDistance = dist;
      closestId = venue.id;
    }
  }

  return closestId;
}

async function handleEnterEvent(
  supabase: any,
  userId: string,
  venueId: string,
  confidence: number | undefined,
  occurredAt: string,
  dedupeKey: string
) {
  const { data: existingPresences } = await supabase
    .from("user_venue_presence")
    .select("id, venue_id, entered_at")
    .eq("user_id", userId)
    .eq("status", "IN_VENUE")
    .is("left_at", null);

  if (existingPresences && existingPresences.length > 0) {
    for (const presence of existingPresences) {
      if (presence.venue_id === venueId) {
        await supabase
          .from("user_venue_presence")
          .update({ last_seen_at: occurredAt })
          .eq("id", presence.id);
        if (IS_TEST_MODE) console.log(`Updated existing presence at same venue: ${presence.id}`);
        return;
      } else {
        const dwellSeconds = Math.floor(
          (new Date(occurredAt).getTime() - new Date(presence.entered_at).getTime()) / 1000
        );
        await supabase
          .from("user_venue_presence")
          .update({
            status: "LEFT_VENUE",
            left_at: occurredAt,
            dwell_seconds: dwellSeconds,
          })
          .eq("id", presence.id);
        if (IS_TEST_MODE) console.log(`Closed old presence at different venue (${dwellSeconds}s): ${presence.id}`);
      }
    }
  }

  const { error } = await supabase.from("user_venue_presence").insert({
    user_id: userId,
    venue_id: venueId,
    status: "IN_VENUE",
    entered_at: occurredAt,
    last_seen_at: occurredAt,
    is_visible_in_venue: true,
    entry_method: "AUTO_GEOFENCE",
    dwell_seconds: 0,
    metadata: { radar_confidence: confidence, dedupe_key: dedupeKey },
  });

  if (error) {
    if (IS_TEST_MODE) console.error("Error creating presence:", error);
    throw error;
  }

  if (IS_TEST_MODE) console.log(`Created presence for user ${userId} at venue ${venueId}`);
}

async function handleDwellEvent(
  supabase: any,
  userId: string,
  venueId: string,
  occurredAt: string
) {
  const { data: presence } = await supabase
    .from("user_venue_presence")
    .select("id, entered_at")
    .eq("user_id", userId)
    .eq("venue_id", venueId)
    .eq("status", "IN_VENUE")
    .is("left_at", null)
    .maybeSingle();

  if (presence) {
    const dwellSeconds = Math.floor(
      (new Date(occurredAt).getTime() - new Date(presence.entered_at).getTime()) / 1000
    );
    await supabase
      .from("user_venue_presence")
      .update({ last_seen_at: occurredAt, dwell_seconds: dwellSeconds })
      .eq("id", presence.id);
    if (IS_TEST_MODE) console.log(`Updated dwell for presence: ${presence.id}`);
  }
}

async function handleExitEvent(
  supabase: any,
  userId: string,
  venueId: string,
  occurredAt: string
) {
  const { data: presence } = await supabase
    .from("user_venue_presence")
    .select("id, entered_at")
    .eq("user_id", userId)
    .eq("venue_id", venueId)
    .eq("status", "IN_VENUE")
    .is("left_at", null)
    .maybeSingle();

  if (presence) {
    const dwellSeconds = Math.floor(
      (new Date(occurredAt).getTime() - new Date(presence.entered_at).getTime()) / 1000
    );
    await supabase
      .from("user_venue_presence")
      .update({
        status: "LEFT_VENUE",
        left_at: occurredAt,
        dwell_seconds: dwellSeconds,
      })
      .eq("id", presence.id);
    if (IS_TEST_MODE) console.log(`Closed presence (${dwellSeconds}s): ${presence.id}`);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const radarSecret = Deno.env.get("RADAR_TEST_SECRET_KEY");
    if (!radarSecret) {
      console.error("RADAR_TEST_SECRET_KEY not configured");
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const signature = req.headers.get("Radar-Signature") || req.headers.get("X-Radar-Signature");
    const body = await req.text();

    if (signature) {
      const isValid = await verifyRadarSignature(signature, body, radarSecret);
      if (!isValid) {
        console.error("Invalid webhook signature");
        return new Response(
          JSON.stringify({ error: "Invalid signature" }),
          { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    } else if (!IS_TEST_MODE) {
      console.error("Missing webhook signature");
      return new Response(
        JSON.stringify({ error: "Missing signature" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const event: RadarEvent = JSON.parse(body);

    const userId = event.user?.externalId || event.user?.userId;
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "No user ID in event" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const coordinates = event.location?.coordinates;
    if (!coordinates || coordinates.length !== 2) {
      return new Response(
        JSON.stringify({ error: "Invalid location coordinates" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const [lng, lat] = coordinates;
    const accuracy = event.location?.accuracy;
    const confidence = event.confidence;
    const occurredAt = event.occurredAt || event.createdAt;
    const radarPlaceId = event.place?._id || null;
    const geofenceExternalId = event.geofence?.externalId || null;

    const featuredMarket = isFeaturedMarket(lat, lng);
    if (IS_TEST_MODE) console.log(`Event at (${lat}, ${lng}) — market: ${featuredMarket?.name || "global"}`);

    if (accuracy && accuracy > 50) {
      if (IS_TEST_MODE) console.log(`Low accuracy (${accuracy}m), ignoring event`);
      return new Response(
        JSON.stringify({ status: "ignored", reason: "Low GPS accuracy" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (confidence !== undefined) {
      const isLowConfidence = confidence < 0.6 || (confidence >= 1 && confidence < 2);
      if (isLowConfidence) {
        if (IS_TEST_MODE) console.log(`Low confidence (${confidence}), ignoring event`);
        return new Response(
          JSON.stringify({ status: "ignored", reason: "Low confidence" }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const venueId = await findVenueId(supabase, radarPlaceId, geofenceExternalId, lat, lng);

    if (!venueId) {
      if (IS_TEST_MODE) console.log(`No venue matched for location ${lat}, ${lng}`);
      await supabase.from("location_events").insert({
        user_id: userId,
        venue_id: null,
        radar_place_id: radarPlaceId,
        event_type: mapRadarEventType(event.type) || "enter",
        occurred_at: occurredAt,
        lat,
        lng,
        accuracy_m: accuracy,
        confidence,
        raw_payload: event,
      });
      return new Response(
        JSON.stringify({ status: "ignored", reason: "No venue matched" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const eventType = mapRadarEventType(event.type);
    if (!eventType) {
      if (IS_TEST_MODE) console.log(`Unknown event type: ${event.type}`);
      return new Response(
        JSON.stringify({ status: "ignored", reason: "Unknown event type" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    await supabase.from("location_events").insert({
      user_id: userId,
      venue_id: venueId,
      radar_place_id: radarPlaceId,
      event_type: eventType,
      occurred_at: occurredAt,
      lat,
      lng,
      accuracy_m: accuracy,
      confidence,
      raw_payload: event,
    });

    const timeBucket = floor5MinuteBucket(occurredAt);
    const dedupeKey = `${userId}|${venueId}|${eventType}|${timeBucket}`;

    if (eventType === "enter") {
      await handleEnterEvent(supabase, userId, venueId, confidence, occurredAt, dedupeKey);
    } else if (eventType === "dwell") {
      await handleDwellEvent(supabase, userId, venueId, occurredAt);
    } else if (eventType === "exit") {
      await handleExitEvent(supabase, userId, venueId, occurredAt);
    }

    if (IS_TEST_MODE) console.log(`Processed ${eventType} for user ${userId} at venue ${venueId} — market: ${featuredMarket?.name || "global"}`);

    return new Response(
      JSON.stringify({
        status: "success",
        event_type: eventType,
        venue_id: venueId,
        user_id: userId,
        market: featuredMarket?.name || null,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error processing webhook:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", message: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
