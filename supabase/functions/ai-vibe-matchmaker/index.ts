import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { callClaudeJSON } from "../_shared/claude.ts";

interface Recommendation {
  venue_id: string;
  venue_name: string;
  category: string;
  score: number;
  contextual_message: string;
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

    const { user_lat, user_lng, radius_meters = 8000 } = await req.json();

    // 1. User profile
    const { data: profile } = await supabase
      .from("users")
      .select("name, vibe_tags, favorite_drinks, bio")
      .eq("id", user.id)
      .maybeSingle();

    // 2. Check-in history (last 90 days)
    const { data: checkins } = await supabase
      .from("user_venue_presence")
      .select("venue_id, entered_at, dwell_seconds")
      .eq("user_id", user.id)
      .gte("entered_at", new Date(Date.now() - 90 * 86400000).toISOString())
      .order("entered_at", { ascending: false })
      .limit(150);

    // Get unique venue IDs from check-ins for enrichment
    const checkinVenueIds = [...new Set((checkins || []).map(c => c.venue_id))];
    let checkinVenues: Record<string, any> = {};
    if (checkinVenueIds.length > 0) {
      const { data: vData } = await supabase
        .from("venues")
        .select("id, name, category")
        .in("id", checkinVenueIds);
      if (vData) checkinVenues = Object.fromEntries(vData.map(v => [v.id, v]));
    }

    // Build check-in summary
    const categoryFreq: Record<string, number> = {};
    const dayOfWeekFreq: Record<number, number> = {};
    for (const c of checkins || []) {
      const v = checkinVenues[c.venue_id];
      if (v?.category) categoryFreq[v.category] = (categoryFreq[v.category] || 0) + 1;
      const dow = new Date(c.entered_at).getDay();
      dayOfWeekFreq[dow] = (dayOfWeekFreq[dow] || 0) + 1;
    }

    // 3. Nearby venues with live occupancy
    const { data: nearbyVenues } = await supabase.rpc("get_nearby_venues_with_count", {
      p_lat: user_lat,
      p_lng: user_lng,
      p_radius: radius_meters,
    }).limit(40);

    // If the RPC doesn't exist, fall back to a simple query
    let venues = nearbyVenues;
    if (!venues || venues.length === 0) {
      const { data: fallback } = await supabase
        .from("venues")
        .select("id, name, category, address, lat, lng")
        .eq("is_active", true)
        .limit(40);
      venues = (fallback || []).map(v => ({ ...v, current_occupancy: 0 }));
    }

    if (!venues || venues.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        data: [],
      }), {
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 4. Recent vibe votes
    const venueIds = venues.map((v: any) => v.id);
    const { data: vibeVotes } = await supabase
      .from("vibe_votes")
      .select("venue_id, vibe")
      .in("venue_id", venueIds)
      .gte("created_at", new Date(Date.now() - 3 * 3600000).toISOString());

    const vibeByVenue: Record<string, string[]> = {};
    for (const vv of vibeVotes || []) {
      if (!vibeByVenue[vv.venue_id]) vibeByVenue[vv.venue_id] = [];
      vibeByVenue[vv.venue_id].push(vv.vibe);
    }

    // Build prompt
    const now = new Date();
    const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    const currentDay = dayNames[now.getDay()];
    const currentHour = now.getHours();

    const venueList = venues.map((v: any) => {
      const vibes = vibeByVenue[v.id]?.join(", ") || "no vibe data";
      return `- ${v.name} (${v.category}) | ${v.current_occupancy || 0} people now | vibes: ${vibes} | id: ${v.id}`;
    }).join("\n");

    const topCategories = Object.entries(categoryFreq)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)
      .map(([cat, count]) => `${cat}: ${count} visits`)
      .join(", ");

    const favDays = Object.entries(dayOfWeekFreq)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 3)
      .map(([d, count]) => `${dayNames[Number(d)]}: ${count}`)
      .join(", ");

    const system = `You are the Vibe Matchmaker for Barfliz, a nightlife app. Given a user's history and nearby venues, recommend the top 5 venues they'd enjoy tonight. Be casual, fun, and specific. Reference their patterns.

Respond with ONLY a JSON array of objects: [{"venue_id": "...", "venue_name": "...", "category": "...", "score": 85, "contextual_message": "..."}]
- score: 0-100 how well this matches the user
- contextual_message: 1-2 sentences, casual tone, reference their habits. Max 140 chars.
- Return at most 5 venues, sorted by score descending.`;

    const userMessage = `Current: ${currentDay} ${currentHour}:00
User: ${profile?.name || "User"}
Bio: ${profile?.bio || "none"}
Vibe tags: ${(profile?.vibe_tags || []).join(", ") || "none"}
Favorite drinks: ${(profile?.favorite_drinks || []).join(", ") || "none"}
Top venue categories: ${topCategories || "no history yet"}
Most active days: ${favDays || "no history yet"}
Total check-ins (90d): ${(checkins || []).length}

Nearby venues right now:
${venueList}`;

    const recommendations = await callClaudeJSON<Recommendation[]>({
      system,
      messages: [{ role: "user", content: userMessage }],
      max_tokens: 800,
      temperature: 0.7,
    });

    // Enrich with address and occupancy
    const venueMap = Object.fromEntries(venues.map((v: any) => [v.id, v]));
    const enriched = recommendations.map(r => ({
      ...r,
      address: venueMap[r.venue_id]?.address || null,
      current_occupancy: venueMap[r.venue_id]?.current_occupancy || 0,
    }));

    return new Response(JSON.stringify({ success: true, data: enriched }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("ai-vibe-matchmaker error:", error);
    return new Response(JSON.stringify({ success: false, error: (error as Error).message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
