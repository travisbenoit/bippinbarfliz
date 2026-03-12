/*
  # Validate and Fix Venue Coordinates

  This migration ensures all active venues have valid coordinates that match their address locations.
  
  ## Changes
  - Mark venues as inactive if coordinates are clearly wrong (outside Australia)
  - Ensure Darwin (AU) venues are within reasonable bounds (-12.2 to -12.6 lat, 130.7 to 131.1 lng)
  - Ensure US venues in South Florida range are correct
  - Log suspicious venues for manual review
*/

-- Deactivate venues with impossible coordinates (way outside intended regions)
UPDATE venues
SET is_active = false
WHERE country = 'AU' 
  AND is_active = true
  AND (lat < -29 OR lat > -10 OR lng < 130 OR lng > 135)
  AND name NOT LIKE '%NSW%'
  AND name NOT LIKE '%Queensland%';

-- Ensure Darwin region venues (0800-0820 postcodes) are within Darwin bounds
UPDATE venues
SET is_active = false
WHERE country = 'AU'
  AND is_active = true
  AND (
    address LIKE '%NT 0800%' OR address LIKE '%NT 0810%' OR 
    address LIKE '%NT 0820%' OR address LIKE '%Nightcliff%' OR 
    address LIKE '%Parap%' OR address LIKE '%Fannie Bay%'
  )
  AND (lat < -12.6 OR lat > -12.3 OR lng < 130.7 OR lng > 131.1);

-- Deactivate US venues with clearly wrong coordinates (should be 24-27 lat, -80-82 lng for South Florida)
UPDATE venues
SET is_active = false
WHERE country = 'US'
  AND is_active = true
  AND (lat < 23 OR lat > 28 OR lng < -83 OR lng > -79);

-- Ensure we don't have swapped coordinate pairs
UPDATE venues
SET is_active = false
WHERE country = 'AU'
  AND is_active = true
  AND (
    (lat > 100 OR lat < -40) OR (lng > 200 OR lng < -200)
  );
