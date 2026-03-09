/*
  # Add demo_people_count to venues

  ## Summary
  Adds a nullable integer column `demo_people_count` to the venues table.
  This allows us to seed a static "people here now" count for demo/preview
  purposes without needing real auth users or real presence records.

  The frontend adds this value on top of real presence counts so the demo
  map always shows realistic activity at Weston/33326-area venues.

  ## Changes
  - venues: new column `demo_people_count` integer DEFAULT 0
  - Seeds counts for 7 Weston/Sunrise area venues
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'demo_people_count'
  ) THEN
    ALTER TABLE venues ADD COLUMN demo_people_count integer NOT NULL DEFAULT 0;
  END IF;
END $$;

UPDATE venues SET demo_people_count = 3 WHERE name ILIKE '%Bokampers%';
UPDATE venues SET demo_people_count = 2 WHERE name ILIKE '%Bar Louie%Weston%';
UPDATE venues SET demo_people_count = 4 WHERE name ILIKE '%Duffy%Weston%';
UPDATE venues SET demo_people_count = 2 WHERE name ILIKE '%World of Beer%Weston%';
UPDATE venues SET demo_people_count = 3 WHERE name ILIKE '%Buffalo Wild Wings%';
UPDATE venues SET demo_people_count = 1 WHERE name ILIKE '%Flanigan%Davie%';
UPDATE venues SET demo_people_count = 2 WHERE name ILIKE '%Walk-On%';
UPDATE venues SET demo_people_count = 2 WHERE name ILIKE '%Duffy%Sunrise%';
UPDATE venues SET demo_people_count = 1 WHERE name ILIKE '%Flanigan%Sunrise%';
UPDATE venues SET demo_people_count = 2 WHERE name ILIKE '%Dave%Buster%';
UPDATE venues SET demo_people_count = 3 WHERE name ILIKE '%World of Beer%Sunrise%';
