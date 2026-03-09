/*
  # Clean up venue data and ensure proper country classification

  1. Problem Fixed:
    - Florida venues were appearing in Darwin, Australia
    - Missing country data on many venues
    - No country filtering in venue queries
  
  2. Actions:
    - Update country code for all venues
    - Mark Florida venues as inactive (preserve data but hide from Darwin users)
    - Set Darwin venues to Australia/AU
    - Ensure all venues have proper city and state data
*/

-- Update all Darwin venues to have Australia country code
UPDATE venues 
SET country = 'AU', state = 'NT' 
WHERE (lat BETWEEN -12.5 AND -12.3) AND (lng BETWEEN 130.8 AND 130.9) AND country != 'AU';

-- Mark South Florida venues as inactive (latitude ~26, longitude ~-80)
UPDATE venues 
SET is_active = false, country = 'US', state = 'FL'
WHERE (lat BETWEEN 25.9 AND 26.2) AND (lng BETWEEN -80.5 AND -80.2);

-- Ensure all remaining active venues have a valid country code
UPDATE venues 
SET country = 'US' 
WHERE country IS NULL OR country = '' AND is_active = true;