/*
  # Remove Duplicate SELECT Policies

  ## Problem
  Four tables have two identical SELECT policies (same role, same condition)
  created at different times with different names. Duplicate policies are
  flagged by the security advisor and add maintenance overhead.

  ## Changes
  Drop the redundant "Public can view …" variant on each table, keeping the
  earlier "Anyone can view …" / "… are publicly readable" policy intact.

  - translation_keys: drop "Public can view translation keys"
  - translations: drop "Public can view translations"
  - venue_photos: drop "Public can view venue photos"
  - venue_reviews: drop "Public can view venue reviews"
*/

DROP POLICY IF EXISTS "Public can view translation keys" ON translation_keys;
DROP POLICY IF EXISTS "Public can view translations" ON translations;
DROP POLICY IF EXISTS "Public can view venue photos" ON venue_photos;
DROP POLICY IF EXISTS "Public can view venue reviews" ON venue_reviews;
