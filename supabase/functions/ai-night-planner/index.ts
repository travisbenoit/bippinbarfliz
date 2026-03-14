import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { callClaudeJSON } from "../_shared/claude.ts";

interface PlanStop {
  order: number;
  venue_id: string;
  venue_name: string;
  category: string;
  suggested_arrival: string;
  suggested_departure: string;
  reason: string;
}

interface NightPlan {
  plan_name: string;
  overview: string;
  stops: PlanStop[];
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceKey);

    // Auth
    const token = req.headers.get("Authorization")?.replace("Bearer ", "");
    if (!token) {
      return new Response(JSON.stringify({ success: false, error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const { data: { user }, error: authErr } = await supabase.auth.getUser(token);
    if (authErr || !user) {
      return new Response(JSON.stringify({ success: false, error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { user_lat, user_lng, radius_meters = 8000, prompt, group_size } = await req.json();

    if (!prompt) {
      return new Response(JSON.stringify({ success: false, error: "Missing prompt" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Nearby venues
    const { data: venues } = await supabase
      .from("venues")
      .select("id, name, category, address, lat, lng, rating, user_ratings_total")
      .eq("is_active", true)
      .limit(60);

    if (!venues || venues.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        data: { plan_name: "No venues found", overview: "We couldn't find any venues in your area.", stops: [] },
      }), {
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Live occupancy counts
    const venueIds = venues.map(v => v.id);
    const { data: presences } = await supabase
      .from("user_venue_presence")
      .select("venue_id")
      .in("venue_id", venueIds)
      .eq("status", "IN_VENUE");

    const occupancy: Record<string, number> = {};
    for (const p of presences || []) {
      occupancy[p.venue_id] = (occupancy[p.venue_id] || 0) + 1;
    }

    // 3. Historical busyness (last 30 days, same day-of-week)
    const today = new Date();
    const dow = today.getDay();
    const { data: historicalData } = await supabase
      .from("user_venue_presence")
      .select("venue_id, entered_at")
      .in("venue_id", venueIds)
      .gte("entered_at", new Date(Date.now() - 30 * 86400000).toISOString());

    // Aggregate by venue + hour for same day-of-week
    const busyness: Record<string, Record<number, number>> = {};
    for (const h of historicalData || []) {
      const d = new Date(h.entered_at);
      if (d.getDay() !== dow) continue;
      const hour = d.getHours();
      if (!busyness[h.venue_id]) busyness[h.venue_id] = {};
      busyness[h.venue_id][hour] = (busyness[h.venue_id][hour] || 0) + 1;
    }

    // 4. Recent vibe votes
    const { data: vibeVotes } = await supabase
      .from("vibe_votes")
      .select("venue_id, vibe")
      .in("venue_id", venueIds)
      .gte("created_at", new Date(Date.now() - 6 * 3600000).toISOString());

    const vibeByVenue: Record<string, string[]> = {};
    for (const vv of vibeVotes || []) {
      if (!vibeByVenue[vv.venue_id]) vibeByVenue[vv.venue_id] = [];
      vibeByVenue[vv.venue_id].push(vv.vibe);
    }

    // 5. Friends going out
    const { data: friendships } = await supabase
      .from("friendships")
      .select("user_id, friend_id")
      .eq("status", "accepted")
      .or(`user_id.eq.${user.id},friend_id.eq.${user.id}`);
    const friendIds = (friendships || []).map(f => f.user_id === user.id ? f.friend_id : f.user_id);

    let friendsOut: string[] = [];
    if (friendIds.length > 0) {
      const { data: goingOut } = await supabase
        .from("users")
        .select("name, tonight_status")
        .in("id", friendIds)
        .in("tonight_status", ["out_now", "going_out_soon"]);
      friendsOut = (goingOut || []).map(u => u.name);
    }

    // Build prompt
    const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    const currentDay = dayNames[dow];
    const currentHour = today.getHours();

    const venueList = venues.map(v => {
      const occ = occupancy[v.id] || 0;
      const vibes = vibeByVenue[v.id]?.join(", ") || "unknown";
      const peak = busyness[v.id]
        ? Object.entries(busyness[v.id]).sort(([, a], [, b]) => b - a)[0]
        : null;
      const peakStr = peak ? `peak ~${peak[0]}:00` : "no data";
      return `- ${v.name} (${v.category}) | ${occ} now | vibes: ${vibes} | ${peakStr} | rating: ${v.rating || "?"} | id: ${v.id}`;
    }).join("\n");

    const system = `You are the Smart Night Planner for Barfliz, a nightlife app. Given the user's request and available venues, create the perfect multi-stop night plan.

Consider:
- Venue categories and vibes matching the request
- Logical geographic ordering (minimize travel)
- Time progression (chill → energetic typically)
- Historical busyness patterns for optimal arrival times
- Current occupancy levels

Respond with ONLY JSON:
{
  "plan_name": "catchy name for this night",
  "overview": "1-2 sentence description of the plan",
  "stops": [
    {
      "order": 1,
      "venue_id": "...",
      "venue_name": "...",
      "category": "...",
      "suggested_arrival": "9:00 PM",
      "suggested_departure": "10:30 PM",
      "reason": "why this venue at this time (1 sentence)"
    }
  ]
}

Plan 2-5 stops. Use realistic times starting from now or the next reasonable hour.`;

    const userMessage = `Request: "${prompt}"
Group size: ${group_size || "not specified"}
Current: ${currentDay} ${currentHour}:00
Friends going out tonight: ${friendsOut.length > 0 ? friendsOut.join(", ") : "none known"}

Available venues:
${venueList}`;

    const plan = await callClaudeJSON<NightPlan>({
      system,
      messages: [{ role: "user", content: userMessage }],
      max_tokens: 1000,
      temperature: 0.7,
    });

    return new Response(JSON.stringify({ success: true, data: plan }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("ai-night-planner error:", error);
    return new Response(JSON.stringify({ success: false, error: (error as Error).message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
