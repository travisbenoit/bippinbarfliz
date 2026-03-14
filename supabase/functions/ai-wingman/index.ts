import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";
import { callClaudeJSON } from "../_shared/claude.ts";

interface WingmanInsight {
  type: string;
  message: string;
  data_point: string;
}

interface WingmanResult {
  insights: WingmanInsight[];
  ice_breakers: string[];
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

    const { target_user_id } = await req.json();
    if (!target_user_id) {
      return new Response(JSON.stringify({ success: false, error: "Missing target_user_id" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Privacy checks: ghost mode and blocks
    const { data: targetUser } = await supabase
      .from("users")
      .select("id, name, vibe_tags, favorite_drinks, bio, ghost_mode")
      .eq("id", target_user_id)
      .maybeSingle();

    if (!targetUser) {
      return new Response(JSON.stringify({ success: false, error: "User not found" }), {
        status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (targetUser.ghost_mode) {
      return new Response(JSON.stringify({
        success: true,
        data: { insights: [], ice_breakers: ["Hey! How's your night going?"] },
      }), {
        status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check blocks
    const { data: block } = await supabase
      .from("user_blocks")
      .select("id")
      .or(`and(blocker_id.eq.${user.id},blocked_id.eq.${target_user_id}),and(blocker_id.eq.${target_user_id},blocked_id.eq.${user.id})`)
      .maybeSingle();

    if (block) {
      return new Response(JSON.stringify({ success: false, error: "Cannot view this user" }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Current user's profile
    const { data: myProfile } = await supabase
      .from("users")
      .select("name, vibe_tags, favorite_drinks, bio")
      .eq("id", user.id)
      .maybeSingle();

    // 1. Shared venue history (venues both visited in last 90 days)
    const ninetyDaysAgo = new Date(Date.now() - 90 * 86400000).toISOString();

    const { data: myCheckins } = await supabase
      .from("user_venue_presence")
      .select("venue_id")
      .eq("user_id", user.id)
      .gte("entered_at", ninetyDaysAgo);

    const { data: theirCheckins } = await supabase
      .from("user_venue_presence")
      .select("venue_id")
      .eq("user_id", target_user_id)
      .gte("entered_at", ninetyDaysAgo);

    const myVenueIds = new Set((myCheckins || []).map(c => c.venue_id));
    const theirVenueIds = new Set((theirCheckins || []).map(c => c.venue_id));
    const sharedVenueIds = [...myVenueIds].filter(id => theirVenueIds.has(id));

    let sharedVenues: string[] = [];
    if (sharedVenueIds.length > 0) {
      const { data: venueNames } = await supabase
        .from("venues")
        .select("name")
        .in("id", sharedVenueIds.slice(0, 10));
      sharedVenues = (venueNames || []).map(v => v.name);
    }

    // 2. Mutual friends
    const { data: myFriends } = await supabase
      .from("friendships")
      .select("user_id, friend_id")
      .eq("status", "accepted")
      .or(`user_id.eq.${user.id},friend_id.eq.${user.id}`);

    const { data: theirFriends } = await supabase
      .from("friendships")
      .select("user_id, friend_id")
      .eq("status", "accepted")
      .or(`user_id.eq.${target_user_id},friend_id.eq.${target_user_id}`);

    const myFriendIds = new Set((myFriends || []).map(f => f.user_id === user.id ? f.friend_id : f.user_id));
    const theirFriendIds = new Set((theirFriends || []).map(f => f.user_id === target_user_id ? f.friend_id : f.user_id));
    const mutualFriendIds = [...myFriendIds].filter(id => theirFriendIds.has(id));

    let mutualFriendNames: string[] = [];
    if (mutualFriendIds.length > 0) {
      const { data: names } = await supabase
        .from("users")
        .select("name")
        .in("id", mutualFriendIds.slice(0, 5));
      mutualFriendNames = (names || []).map(u => u.name);
    }

    // 3. Shared music taste
    const { data: myMusic } = await supabase
      .from("music_shares")
      .select("artist_name")
      .eq("sender_id", user.id)
      .limit(30);

    const { data: theirMusic } = await supabase
      .from("music_shares")
      .select("artist_name")
      .eq("sender_id", target_user_id)
      .limit(30);

    const myArtists = new Set((myMusic || []).map(m => m.artist_name?.toLowerCase()));
    const sharedArtists = (theirMusic || [])
      .filter(m => myArtists.has(m.artist_name?.toLowerCase()))
      .map(m => m.artist_name);
    const uniqueSharedArtists = [...new Set(sharedArtists)].slice(0, 5);

    // 4. Overlapping vibe tags
    const myVibes = new Set(myProfile?.vibe_tags || []);
    const sharedVibes = (targetUser.vibe_tags || []).filter((v: string) => myVibes.has(v));

    // Build prompt
    const system = `You are Wingman, the social AI for Barfliz nightlife app. Given data about two users' shared interests, generate insights and ice-breaker conversation starters.

Rules:
- Be casual, fun, and non-creepy
- Never reveal exact dates, timestamps, or specific visit counts
- Use patterns ("you both love breweries") not specifics ("you were both at Joe's Bar on March 5")
- Ice breakers should be natural conversation openers, not pickup lines
- Reference specific shared interests when possible

Respond with ONLY JSON:
{
  "insights": [
    {
      "type": "shared_venue|mutual_friend|music_taste|vibe_match|crossing_paths",
      "message": "user-facing insight (1 sentence, casual)",
      "data_point": "the specific shared element"
    }
  ],
  "ice_breakers": ["suggestion 1", "suggestion 2", "suggestion 3"]
}

Return 2-4 insights and exactly 3 ice breakers. If there's no shared data, generate generic but contextual ice breakers for a nightlife setting.`;

    const userMessage = `You: ${myProfile?.name || "User"} — bio: ${myProfile?.bio || "none"}, vibes: ${(myProfile?.vibe_tags || []).join(", ") || "none"}, drinks: ${(myProfile?.favorite_drinks || []).join(", ") || "none"}

Them: ${targetUser.name} — bio: ${targetUser.bio || "none"}, vibes: ${(targetUser.vibe_tags || []).join(", ") || "none"}, drinks: ${(targetUser.favorite_drinks || []).join(", ") || "none"}

Shared venues: ${sharedVenues.length > 0 ? sharedVenues.join(", ") : "none found"}
Mutual friends: ${mutualFriendNames.length > 0 ? mutualFriendNames.join(", ") : "none"}
Shared music artists: ${uniqueSharedArtists.length > 0 ? uniqueSharedArtists.join(", ") : "none found"}
Shared vibe tags: ${sharedVibes.length > 0 ? sharedVibes.join(", ") : "none"}`;

    const result = await callClaudeJSON<WingmanResult>({
      system,
      messages: [{ role: "user", content: userMessage }],
      max_tokens: 600,
      temperature: 0.8,
    });

    return new Response(JSON.stringify({ success: true, data: result }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("ai-wingman error:", error);
    return new Response(JSON.stringify({ success: false, error: (error as Error).message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
