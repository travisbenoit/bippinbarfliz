/*
  # Auto-Activate Venues by Region

  1. Purpose
    - Automatically activate venues when inserted for populated regions
    - Eliminates need to manually activate venues for each new market
    - Ensures new venues are immediately available to users
  
  2. Populated Regions (Auto-Activated)
    - Darwin, Australia (city = 'Darwin')
    - Florida, USA (state = 'FL', country = 'United States')
    - Fort Lauderdale, USA (city = 'Fort Lauderdale')
    - Sunrise, USA (city = 'Sunrise')
    - Davie, USA (city = 'Davie')
    - Weston, USA (city = 'Weston')
  
  3. Implementation
    - Creates a trigger that auto-activates on INSERT
    - Checks region criteria before activation
    - Allows manual control for other regions
  
  4. How to Add New Regions
    - New regions auto-activate by adding conditions to the trigger
    - Simply add another OR clause with the region's city/state/country criteria
    - No schema changes needed for future expansions
*/

CREATE OR REPLACE FUNCTION auto_activate_venue_by_region()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.city = 'Darwin' AND NEW.country = 'Australia')
     OR (NEW.state = 'FL' AND NEW.country = 'United States')
     OR (NEW.city = 'Fort Lauderdale' AND NEW.country = 'United States')
     OR (NEW.city = 'Sunrise' AND NEW.country = 'United States')
     OR (NEW.city = 'Davie' AND NEW.country = 'United States')
     OR (NEW.city = 'Weston' AND NEW.country = 'United States')
  THEN
    NEW.is_active := true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS auto_activate_venue_by_region_trigger ON venues;

CREATE TRIGGER auto_activate_venue_by_region_trigger
BEFORE INSERT ON venues
FOR EACH ROW
EXECUTE FUNCTION auto_activate_venue_by_region();
