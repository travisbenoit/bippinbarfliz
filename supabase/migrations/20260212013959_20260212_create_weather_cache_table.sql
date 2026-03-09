/*
  # Create Weather Cache Table

  1. New Tables
    - `weather_cache`
      - `id` (uuid, primary key)
      - `latitude` (numeric, for location indexing)
      - `longitude` (numeric, for location indexing)
      - `temperature` (integer, in Celsius from Open-Meteo)
      - `weather_code` (integer, WMO weather code)
      - `condition` (text, human-readable condition)
      - `wind_speed` (numeric, m/s)
      - `humidity` (integer)
      - `feels_like` (integer, calculated from temp and wind)
      - `cached_at` (timestamp)
      - `expires_at` (timestamp, 1 hour TTL)
      - `source` (text, 'open-meteo')

  2. Security
    - Enable RLS on `weather_cache` table
    - Add policy for public read access (weather is public data)
    - Add policy for edge function writes via service role key

  3. Indexes
    - Index on (latitude, longitude, expires_at) for efficient lookups

  4. Notes
    - Weather data cached for 1 hour to reduce API calls
    - Open-Meteo API returns data in Celsius, stored as-is
    - Regional settings handle temperature unit conversion on client
*/

CREATE TABLE IF NOT EXISTS weather_cache (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  latitude numeric NOT NULL,
  longitude numeric NOT NULL,
  temperature integer NOT NULL,
  weather_code integer NOT NULL,
  condition text NOT NULL,
  wind_speed numeric NOT NULL,
  humidity integer NOT NULL,
  feels_like integer NOT NULL,
  source text NOT NULL DEFAULT 'open-meteo',
  cached_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + '1 hour'::interval),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_weather_cache_location_expiry 
  ON weather_cache (latitude, longitude, expires_at);

ALTER TABLE weather_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Weather data is publicly readable"
  ON weather_cache
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Service role can insert weather data"
  ON weather_cache
  FOR INSERT
  TO service_role
  WITH CHECK (true);

CREATE POLICY "Service role can delete expired weather data"
  ON weather_cache
  FOR DELETE
  TO service_role
  USING (true);
