import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const STALE_MINUTES = 25;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const staleThreshold = new Date(Date.now() - STALE_MINUTES * 60 * 1000).toISOString();

    const { data: stalePresences, error: fetchError } = await supabase
      .from("user_venue_presence")
      .select("id, user_id, venue_id, entered_at, last_seen_at")
      .eq("status", "IN_VENUE")
      .is("left_at", null)
      .lt("last_seen_at", staleThreshold);

    if (fetchError) throw fetchError;

    if (!stalePresences || stalePresences.length === 0) {
      return new Response(
        JSON.stringify({ status: "success", message: "No stale presences found", closed_count: 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const presenceIds = stalePresences.map((p) => p.id);
    const now = new Date().toISOString();

    const updates = stalePresences.map((p) => {
      const dwellSeconds = Math.floor(
        (Date.now() - new Date(p.entered_at).getTime()) / 1000
      );
      return supabase
        .from("user_venue_presence")
        .update({
          status: "LEFT_VENUE",
          left_at: now,
          dwell_seconds: dwellSeconds,
        })
        .eq("id", p.id);
    });

    await Promise.all(updates);

    return new Response(
      JSON.stringify({
        status: "success",
        message: `Closed ${stalePresences.length} stale presence record(s)`,
        closed_count: stalePresences.length,
        presence_ids: presenceIds,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error cleaning up stale presences:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", message: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
