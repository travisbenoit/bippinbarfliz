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

    const staleThreshold = new Date(Date.now() - 25 * 60 * 1000).toISOString();

    const { data: presences, error: presenceError } = await supabase
      .from("user_venue_presence")
      .select("id, user_id, entered_at, last_seen_at, dwell_seconds, is_visible_in_venue, entry_method, metadata")
      .eq("venue_id", venueId)
      .eq("status", "IN_VENUE")
      .is("left_at", null)
      .gte("last_seen_at", staleThreshold);

    if (presenceError) throw presenceError;

    if (!presences || presences.length === 0) {
      return new Response(
        JSON.stringify({
          bar_id: venueId,
          venue_id: venueId,
          total_population: 0,
          visible_users: [],
          ghost_count: 0,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const userIds = presences.map((p) => p.user_id);

    const { data: users, error: usersError } = await supabase
      .from("users")
      .select("id, name, avatar_url, bio, vibe_tags, favorite_drinks, tonight_status, ghost_mode, is_premium, first_drink_on_me")
      .in("id", userIds);

    if (usersError) throw usersError;

    const userMap = new Map<string, any>();
    if (users) {
      for (const u of users) userMap.set(u.id, u);
    }

    const totalPopulation = presences.length;
    const visibleUsers: any[] = [];

    for (const presence of presences) {
      const user = userMap.get(presence.user_id);
      if (!user || user.ghost_mode === true || presence.is_visible_in_venue === false) continue;

      const dwellMinutes = Math.floor(
        (Date.now() - new Date(presence.entered_at).getTime()) / (1000 * 60)
      );

      visibleUsers.push({
        user_id: user.id,
        name: user.name,
        avatar_url: user.avatar_url,
        bio: user.bio,
        vibe_tags: user.vibe_tags || [],
        favorite_drinks: user.favorite_drinks || [],
        tonight_status: user.tonight_status,
        is_premium: user.is_premium,
        first_drink_on_me: user.first_drink_on_me,
        checked_in_at: presence.entered_at,
        last_seen_at: presence.last_seen_at,
        dwell_minutes: dwellMinutes,
        dwell_seconds: presence.dwell_seconds,
        entry_method: presence.entry_method,
      });
    }

    visibleUsers.sort(
      (a, b) => new Date(b.checked_in_at).getTime() - new Date(a.checked_in_at).getTime()
    );

    return new Response(
      JSON.stringify({
        bar_id: venueId,
        venue_id: venueId,
        total_population: totalPopulation,
        visible_users: visibleUsers,
        ghost_count: totalPopulation - visibleUsers.length,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in bar-people:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", message: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
