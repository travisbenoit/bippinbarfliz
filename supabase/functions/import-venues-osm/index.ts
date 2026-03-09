import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

const OVERPASS_API = "https://overpass-api.de/api/interpreter";

interface OSMElement {
  type: "node" | "way" | "relation";
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  tags?: Record<string, string>;
}

interface OverpassResponse {
  elements: OSMElement[];
}

interface ImportRequest {
  regionType: "country" | "southFlorida" | "australianState";
  countryCode?: string;
  stateCode?: string;
}

interface ImportResult {
  regionType: string;
  countryCode?: string;
  stateCode?: string;
  totalProcessed: number;
  insertedCount: number;
  updatedCount: number;
  skippedCount: number;
  errors: string[];
}

const SOUTH_FLORIDA_CITIES = [
  "West Palm Beach",
  "Boca Raton",
  "Delray Beach",
  "Boynton Beach",
  "Pompano Beach",
  "Fort Lauderdale",
  "Hollywood",
  "Hallandale Beach",
  "Aventura",
  "Miami Beach",
  "Miami",
  "Coral Gables",
  "Coconut Grove",
  "Key Biscayne",
  "Homestead",
  "Florida City",
  "Key Largo",
  "Islamorada",
  "Marathon",
  "Big Pine Key",
  "Key West",
];

const AUSTRALIAN_STATES = [
  { code: "NSW", name: "New South Wales" },
  { code: "VIC", name: "Victoria" },
  { code: "QLD", name: "Queensland" },
  { code: "WA", name: "Western Australia" },
  { code: "SA", name: "South Australia" },
  { code: "TAS", name: "Tasmania" },
  { code: "NT", name: "Northern Territory" },
  { code: "ACT", name: "Australian Capital Territory" },
];

function buildOverpassQuery(regionType: string, regionName?: string, stateCode?: string): string {
  const tags = `
    node["amenity"="bar"](area.searchArea);
    node["amenity"="pub"](area.searchArea);
    node["amenity"="nightclub"](area.searchArea);
    node["craft"="brewery"](area.searchArea);
    node["microbrewery"="yes"](area.searchArea);
    way["amenity"="bar"](area.searchArea);
    way["amenity"="pub"](area.searchArea);
    way["amenity"="nightclub"](area.searchArea);
    way["craft"="brewery"](area.searchArea);
  `;

  if (regionType === "australianState" && stateCode) {
    const state = AUSTRALIAN_STATES.find(s => s.code === stateCode);
    if (!state) throw new Error(`Unknown Australian state: ${stateCode}`);

    return `
      [out:json][timeout:180];
      area["name"="${state.name}"]["admin_level"="4"]->.searchArea;
      (
        ${tags}
      );
      out center;
    `;
  }

  if (regionType === "country") {
    return `
      [out:json][timeout:300];
      area["ISO3166-1"="${regionName}"]->.searchArea;
      (
        ${tags}
      );
      out center;
    `;
  }

  if (regionType === "city") {
    return `
      [out:json][timeout:60];
      area["name"="${regionName}"]["boundary"="administrative"]->.searchArea;
      (
        ${tags}
      );
      out center;
    `;
  }

  throw new Error(`Unknown region type: ${regionType}`);
}

function determineCategory(tags: Record<string, string>): string {
  if (tags.amenity === "nightclub") return "nightclub";
  if (tags.amenity === "pub") return "pub";
  if (tags.craft === "brewery" || tags.microbrewery === "yes") return "brewery";
  if (tags.amenity === "bar") return "bar";
  return "bar";
}

function determineSubcategory(tags: Record<string, string>): string | null {
  if (tags.microbrewery === "yes") return "microbrewery";
  if (tags.brewery === "yes") return "brewpub";
  if (tags.sports === "yes" || tags.sport) return "sports bar";
  if (tags.wine === "yes" || tags.wine_bar === "yes") return "wine bar";
  if (tags.cocktail === "yes" || tags.cocktails === "yes") return "cocktail bar";
  if (tags.karaoke === "yes") return "karaoke bar";
  if (tags.lgbtq === "yes" || tags.gay === "yes") return "lgbtq bar";
  if (tags.outdoor_seating === "yes" && tags.rooftop === "yes") return "rooftop bar";
  if (tags.live_music === "yes") return "live music venue";
  if (tags.dance === "yes" || tags.dancing === "yes") return "dance club";
  return null;
}

function buildAddress(tags: Record<string, string>): string | null {
  if (tags["addr:full"]) return tags["addr:full"];

  const parts: string[] = [];
  if (tags["addr:housenumber"]) parts.push(tags["addr:housenumber"]);
  if (tags["addr:street"]) parts.push(tags["addr:street"]);

  return parts.length > 0 ? parts.join(" ") : null;
}

function getWikimediaImageUrl(commonsFile: string): string | null {
  if (!commonsFile) return null;

  const filename = commonsFile.replace("File:", "").replace(/ /g, "_");
  const encoded = encodeURIComponent(filename);
  return `https://commons.wikimedia.org/wiki/Special:FilePath/${encoded}?width=800`;
}

function getImageUrl(tags: Record<string, string>): string | null {
  if (tags.image && tags.image.startsWith("http")) {
    return tags.image;
  }
  if (tags.wikimedia_commons) {
    return getWikimediaImageUrl(tags.wikimedia_commons);
  }
  if (tags["image:wikimedia_commons"]) {
    return getWikimediaImageUrl(tags["image:wikimedia_commons"]);
  }
  return null;
}

function mapOSMElementToVenue(
  element: OSMElement,
  defaultCountry: string,
  defaultState?: string
): Record<string, unknown> | null {
  const tags = element.tags || {};

  if (!tags.name) return null;

  const lat = element.lat ?? element.center?.lat;
  const lon = element.lon ?? element.center?.lon;

  if (!lat || !lon) return null;

  const id = `osm:${element.type}:${element.id}`;
  const osmId = `${element.type}/${element.id}`;

  return {
    id,
    name: tags.name,
    lat,
    lng: lon,
    category: determineCategory(tags),
    subcategory: determineSubcategory(tags),
    address: buildAddress(tags),
    city: tags["addr:city"] || tags["addr:suburb"] || null,
    state: tags["addr:state"] || defaultState || null,
    country: tags["addr:country"] || defaultCountry,
    osm_id: osmId,
    osm_tags: tags,
    image_url_osm: getImageUrl(tags),
    verified_flag: false,
    geofence_radius_m: 75,
    updated_at: new Date().toISOString(),
  };
}

async function fetchOverpassData(query: string): Promise<OSMElement[]> {
  const response = await fetch(OVERPASS_API, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `data=${encodeURIComponent(query)}`,
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Overpass API error: ${response.status} - ${errorText}`);
  }

  const data: OverpassResponse = await response.json();
  return data.elements || [];
}

async function upsertVenues(
  supabase: ReturnType<typeof createClient>,
  venues: Record<string, unknown>[]
): Promise<{ inserted: number; updated: number }> {
  let inserted = 0;
  let updated = 0;

  for (const venue of venues) {
    const { data: existing } = await supabase
      .from("venues")
      .select("id")
      .eq("osm_id", venue.osm_id)
      .maybeSingle();

    if (existing) {
      const { error } = await supabase
        .from("venues")
        .update(venue)
        .eq("osm_id", venue.osm_id);

      if (!error) updated++;
    } else {
      const { error } = await supabase
        .from("venues")
        .insert({ ...venue, created_at: new Date().toISOString() });

      if (!error) inserted++;
    }
  }

  return { inserted, updated };
}

async function importSouthFlorida(
  supabase: ReturnType<typeof createClient>
): Promise<ImportResult> {
  const result: ImportResult = {
    regionType: "southFlorida",
    totalProcessed: 0,
    insertedCount: 0,
    updatedCount: 0,
    skippedCount: 0,
    errors: [],
  };

  const allVenues: Map<string, Record<string, unknown>> = new Map();

  for (const city of SOUTH_FLORIDA_CITIES) {
    try {
      console.log(`Fetching venues for ${city}...`);
      const query = buildOverpassQuery("city", city);
      const elements = await fetchOverpassData(query);

      for (const element of elements) {
        const venue = mapOSMElementToVenue(element, "United States", "FL");
        if (venue) {
          if (!venue.city) venue.city = city;
          allVenues.set(venue.osm_id as string, venue);
        } else {
          result.skippedCount++;
        }
      }

      await new Promise(resolve => setTimeout(resolve, 1000));
    } catch (error) {
      result.errors.push(`Error fetching ${city}: ${error}`);
    }
  }

  result.totalProcessed = allVenues.size + result.skippedCount;

  const venueArray = Array.from(allVenues.values());
  const batchSize = 50;

  for (let i = 0; i < venueArray.length; i += batchSize) {
    const batch = venueArray.slice(i, i + batchSize);
    const { inserted, updated } = await upsertVenues(supabase, batch);
    result.insertedCount += inserted;
    result.updatedCount += updated;
  }

  return result;
}

async function importAustralianState(
  supabase: ReturnType<typeof createClient>,
  stateCode: string
): Promise<ImportResult> {
  const result: ImportResult = {
    regionType: "australianState",
    stateCode,
    totalProcessed: 0,
    insertedCount: 0,
    updatedCount: 0,
    skippedCount: 0,
    errors: [],
  };

  try {
    console.log(`Fetching venues for Australian state: ${stateCode}...`);
    const query = buildOverpassQuery("australianState", undefined, stateCode);
    const elements = await fetchOverpassData(query);

    const venues: Record<string, unknown>[] = [];

    for (const element of elements) {
      const venue = mapOSMElementToVenue(element, "Australia", stateCode);
      if (venue) {
        venues.push(venue);
      } else {
        result.skippedCount++;
      }
    }

    result.totalProcessed = venues.length + result.skippedCount;

    const batchSize = 50;
    for (let i = 0; i < venues.length; i += batchSize) {
      const batch = venues.slice(i, i + batchSize);
      const { inserted, updated } = await upsertVenues(supabase, batch);
      result.insertedCount += inserted;
      result.updatedCount += updated;
    }
  } catch (error) {
    result.errors.push(`Error fetching ${stateCode}: ${error}`);
  }

  return result;
}

async function importAustralia(
  supabase: ReturnType<typeof createClient>
): Promise<ImportResult> {
  const result: ImportResult = {
    regionType: "country",
    countryCode: "AU",
    totalProcessed: 0,
    insertedCount: 0,
    updatedCount: 0,
    skippedCount: 0,
    errors: [],
  };

  for (const state of AUSTRALIAN_STATES) {
    try {
      console.log(`Processing Australian state: ${state.name}...`);
      const stateResult = await importAustralianState(supabase, state.code);

      result.totalProcessed += stateResult.totalProcessed;
      result.insertedCount += stateResult.insertedCount;
      result.updatedCount += stateResult.updatedCount;
      result.skippedCount += stateResult.skippedCount;
      result.errors.push(...stateResult.errors);

      await new Promise(resolve => setTimeout(resolve, 2000));
    } catch (error) {
      result.errors.push(`Error processing state ${state.name}: ${error}`);
    }
  }

  return result;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body: ImportRequest = await req.json();
    const { regionType, countryCode, stateCode } = body;

    const logEntry = await supabase
      .from("osm_import_logs")
      .insert({
        region_type: regionType,
        country_code: countryCode || null,
        status: "running",
      })
      .select()
      .single();

    let result: ImportResult;

    if (regionType === "country" && countryCode === "AU") {
      result = await importAustralia(supabase);
    } else if (regionType === "southFlorida") {
      result = await importSouthFlorida(supabase);
    } else if (regionType === "australianState" && stateCode) {
      result = await importAustralianState(supabase, stateCode);
    } else {
      throw new Error(`Unsupported region: ${regionType} ${countryCode || ""}`);
    }

    if (logEntry.data) {
      await supabase
        .from("osm_import_logs")
        .update({
          total_processed: result.totalProcessed,
          inserted_count: result.insertedCount,
          updated_count: result.updatedCount,
          skipped_count: result.skippedCount,
          errors: result.errors.length > 0 ? result.errors : null,
          completed_at: new Date().toISOString(),
          status: result.errors.length > 0 ? "completed" : "completed",
        })
        .eq("id", logEntry.data.id);
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Import error:", error);
    return new Response(
      JSON.stringify({ error: String(error) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});