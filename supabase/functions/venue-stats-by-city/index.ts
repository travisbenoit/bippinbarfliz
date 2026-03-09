import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface CityStats {
  city: string;
  state: string | null;
  country: string | null;
  venue_count: number;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const url = new URL(req.url);
    const countryCode = url.searchParams.get("countryCode");
    const stateFilter = url.searchParams.get("state");

    const { data: rawData, error: rawError } = await supabase
      .from("venues")
      .select("city, state, country");

    if (rawError) throw rawError;

    const statsMap = new Map<string, CityStats>();

    for (const venue of rawData || []) {
      if (!venue.city) continue;

      if (countryCode && venue.country !== countryCode) continue;
      if (stateFilter && venue.state !== stateFilter) continue;

      const key = `${venue.city}|${venue.state}|${venue.country}`;
      const existing = statsMap.get(key);

      if (existing) {
        existing.venue_count++;
      } else {
        statsMap.set(key, {
          city: venue.city,
          state: venue.state,
          country: venue.country,
          venue_count: 1,
        });
      }
    }

    const stats = Array.from(statsMap.values()).sort((a, b) => {
      const countryA = a.country || "";
      const countryB = b.country || "";
      if (countryA !== countryB) return countryA.localeCompare(countryB);

      const stateA = a.state || "";
      const stateB = b.state || "";
      if (stateA !== stateB) return stateA.localeCompare(stateB);

      return a.city.localeCompare(b.city);
    });

    return new Response(JSON.stringify(stats), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error fetching venue stats:", error);
    return new Response(
      JSON.stringify({ error: String(error) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});