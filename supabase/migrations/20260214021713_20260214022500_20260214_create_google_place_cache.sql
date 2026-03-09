/*
  # Google Place Details Cache Table

  Creates a TTL cache for Google Place Details API responses to minimize API costs.

  ## New Tables

  ### `google_place_cache`
  Caches Google Place Details responses with 24-hour TTL.
  - `cache_id` (uuid, primary key) - Unique cache entry identifier
  - `bar_id` (uuid, required, unique) - References bars table
  - `place_id` (text, required) - Google Place ID
  - `cached_data` (jsonb, required) - Full Place Details response
  - `cached_at` (timestamptz, required) - Cache timestamp for TTL validation
  - `created_at` (timestamptz) - Creation timestamp

  ## Security
  - RLS enabled
  - Authenticated users can read all cache entries
  - Service role has full access for cache management

  ## Indexes
  - Unique constraint on bar_id for fast lookups
  - Index on cached_at for TTL cleanup
*/

CREATE TABLE IF NOT EXISTS google_place_cache (
  cache_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bar_id uuid NOT NULL UNIQUE REFERENCES bars(bar_id) ON DELETE CASCADE,
  place_id text NOT NULL,
  cached_data jsonb NOT NULL,
  cached_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Create index on cached_at for TTL-based queries
CREATE INDEX IF NOT EXISTS idx_google_place_cache_cached_at ON google_place_cache(cached_at);

-- Enable Row Level Security
ALTER TABLE google_place_cache ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Authenticated users can view cache"
  ON google_place_cache FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Service role has full access to cache"
  ON google_place_cache FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
