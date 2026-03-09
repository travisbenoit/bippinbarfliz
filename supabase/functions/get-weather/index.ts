import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface WeatherRequest {
  latitude: number;
  longitude: number;
}

interface OpenMeteoResponse {
  current: {
    temperature_2m: number;
    weather_code: number;
    wind_speed_10m: number;
    relative_humidity_2m: number;
  };
}

interface WeatherResponse {
  temperature: number;
  feelsLike: number;
  condition: string;
  windSpeed: number;
  humidity: number;
  weatherCode: number;
  cached: boolean;
}

function getWeatherCondition(weatherCode: number): string {
  if (weatherCode === 0 || weatherCode === 1) return "Clear";
  if (weatherCode === 2) return "Partly Cloudy";
  if (weatherCode === 3) return "Overcast";
  if (weatherCode === 45 || weatherCode === 48) return "Foggy";
  if (weatherCode >= 51 && weatherCode <= 67) return "Drizzle";
  if (weatherCode >= 80 && weatherCode <= 82) return "Rain Showers";
  if (weatherCode >= 71 && weatherCode <= 77) return "Snow";
  if (weatherCode >= 85 && weatherCode <= 86) return "Snow Showers";
  if (weatherCode >= 80 && weatherCode <= 82) return "Rain";
  if (weatherCode === 95 || weatherCode === 96 || weatherCode === 99) return "Thunderstorm";
  return "Unknown";
}

function calculateFeelsLike(temp: number, windSpeed: number): number {
  if (windSpeed < 4.8) return temp;
  const windChill = 13.12 + 0.6215 * temp - 11.37 * Math.pow(windSpeed, 0.16) + 0.3965 * temp * Math.pow(windSpeed, 0.16);
  return Math.round(windChill);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const url = new URL(req.url);
    const latitude = parseFloat(url.searchParams.get("latitude") || "0");
    const longitude = parseFloat(url.searchParams.get("longitude") || "0");

    if (!latitude || !longitude) {
      return new Response(
        JSON.stringify({ error: "Missing latitude or longitude" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase environment variables");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { data: cachedWeather, error: cacheError } = await supabase
      .from("weather_cache")
      .select("*")
      .eq("latitude", latitude)
      .eq("longitude", longitude)
      .gt("expires_at", new Date().toISOString())
      .maybeSingle();

    if (cachedWeather && !cacheError) {
      return new Response(
        JSON.stringify({
          temperature: cachedWeather.temperature,
          feelsLike: cachedWeather.feels_like,
          condition: cachedWeather.condition,
          windSpeed: cachedWeather.wind_speed,
          humidity: cachedWeather.humidity,
          weatherCode: cachedWeather.weather_code,
          cached: true,
        } as WeatherResponse),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const openMeteoResponse = await fetch(
      `https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m`
    );

    if (!openMeteoResponse.ok) {
      throw new Error("Failed to fetch from Open-Meteo");
    }

    const weatherData: OpenMeteoResponse = await openMeteoResponse.json();
    const current = weatherData.current;

    const condition = getWeatherCondition(current.weather_code);
    const feelsLike = calculateFeelsLike(current.temperature_2m, current.wind_speed_10m);

    const { error: insertError } = await supabase
      .from("weather_cache")
      .insert({
        latitude,
        longitude,
        temperature: Math.round(current.temperature_2m),
        weather_code: current.weather_code,
        condition,
        wind_speed: current.wind_speed_10m,
        humidity: current.relative_humidity_2m,
        feels_like: feelsLike,
        expires_at: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
      });

    if (insertError) {
      console.error("Error caching weather:", insertError);
    }

    const response: WeatherResponse = {
      temperature: Math.round(current.temperature_2m),
      feelsLike,
      condition,
      windSpeed: current.wind_speed_10m,
      humidity: current.relative_humidity_2m,
      weatherCode: current.weather_code,
      cached: false,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error in get-weather function:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
