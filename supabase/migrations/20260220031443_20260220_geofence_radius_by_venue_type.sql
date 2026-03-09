/*
  # Geofence Radius Column and Per-Category Defaults

  ## Summary
  Adds geofence_radius_meters column to venues table (if not already present)
  and a helper function that returns the recommended radius per venue category.

  ## Rationale
  | Category      | Radius | Reason |
  |---------------|--------|--------|
  | dive_bar      | 60m    | Tight footprint, high neighbor density |
  | bar / pub     | 80m    | Standard footprint + GPS drift buffer  |
  | lounge        | 80m    | Similar to bar                         |
  | rooftop       | 80m    | Vertical building, not wide            |
  | nightclub     | 100m   | Larger floor plan + queue areas        |
  | brewery       | 100m   | Includes outdoor beer garden           |
  | taproom       | 100m   | Same as brewery                        |
  | sports_bar    | 120m   | Big rooms, multi-floor or patio        |
  | festival      | 200m   | Large open area, poor GPS accuracy     |
  | outdoor       | 200m   | Same as festival                       |
  | default       | 80m    | Safe fallback for unknown types        |
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'geofence_radius_meters'
  ) THEN
    ALTER TABLE venues ADD COLUMN geofence_radius_meters integer NOT NULL DEFAULT 80;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'venues' AND column_name = 'geofence_shape'
  ) THEN
    ALTER TABLE venues ADD COLUMN geofence_shape jsonb;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION geofence_radius_for_category(cat text)
RETURNS integer
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE cat
    WHEN 'bar'        THEN 80
    WHEN 'pub'        THEN 80
    WHEN 'dive_bar'   THEN 60
    WHEN 'club'       THEN 100
    WHEN 'nightclub'  THEN 100
    WHEN 'sports_bar' THEN 120
    WHEN 'brewery'    THEN 100
    WHEN 'taproom'    THEN 100
    WHEN 'rooftop'    THEN 80
    WHEN 'lounge'     THEN 80
    WHEN 'festival'   THEN 200
    WHEN 'outdoor'    THEN 200
    ELSE 80
  END;
$$;

UPDATE venues
SET geofence_radius_meters = geofence_radius_for_category(category)
WHERE geofence_radius_meters = 80;
