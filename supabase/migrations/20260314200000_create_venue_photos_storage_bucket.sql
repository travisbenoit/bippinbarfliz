/*
  # Storage bucket for venue photos

  Creates a public `venue-photos` bucket so venue images are served from
  Supabase Storage instead of direct Google Places Photo API URLs.

  - Public read: anyone can view venue photos
  - Write: service_role only (Edge Functions upload during enrichment)
  - No user upload policies needed — only server-side Edge Functions write here
*/

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'venue-photos',
  'venue-photos',
  true,
  10485760,
  ARRAY['image/jpeg','image/png','image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Public read access (venue photos are public)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'objects' AND policyname = 'Public can read venue photos'
  ) THEN
    CREATE POLICY "Public can read venue photos"
      ON storage.objects FOR SELECT
      TO public
      USING (bucket_id = 'venue-photos');
  END IF;
END $$;
