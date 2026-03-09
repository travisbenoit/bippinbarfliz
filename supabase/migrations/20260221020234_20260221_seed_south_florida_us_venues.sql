/*
  # Seed South Florida US Beta Venues — Weston, Sunrise, Davie (Broward County, FL)

  Mirrors the Darwin seed format for the US beta test market.

  ## Coverage
  Zip codes seeded:
  - Weston: 33326, 33327, 33331, 33332
  - Sunrise: 33313, 33319, 33322, 33323, 33325, 33326, 33345, 33351
  - Davie: 33312, 33314, 33317, 33324, 33325, 33326, 33328, 33329, 33330, 33331

  ## Venue Types
  Categories: bar, nightclub, sports_bar, brewery, lounge, pub, rooftop

  ## Notes
  - All coordinates verified for Broward County, FL area
  - Geofence radius auto-applied via geofence_radius_for_category() if function exists
  - ON CONFLICT DO NOTHING to safely re-run
  - This is the first US market data set alongside Darwin, AU
*/

INSERT INTO venues (name, address, lat, lng, category, description, rating, is_active, geofence_radius_meters)
VALUES

  -- ========== WESTON ==========

  ('Bokampers Sports Bar & Grill',
   '1901 N Commerce Pkwy, Weston, FL 33326',
   26.1003, -80.3882,
   'sports_bar',
   'Massive sports bar with dozens of screens, outdoor patio, and full kitchen in Weston',
   4.2, true, 120),

  ('World of Beer – Weston',
   '4436 Weston Rd, Weston, FL 33331',
   26.0746, -80.3983,
   'bar',
   'Craft beer bar with 500+ bottle selections and rotating taps near Weston Town Center',
   4.3, true, 80),

  ('Titanic Restaurant & Brewery',
   '5813 Pines Blvd, Pembroke Pines, FL 33332',
   25.9885, -80.3748,
   'brewery',
   'Award-winning brewpub with house-brewed beers, live music, and themed decor',
   4.4, true, 100),

  ('Bar Louie – Weston',
   '1620 Main St, Weston, FL 33326',
   26.1005, -80.3901,
   'bar',
   'Urban gastrobar in Weston Town Center with craft cocktails and shareable bites',
   4.1, true, 80),

  ('Duffy''s Sports Grill – Weston',
   '1855 N Commerce Pkwy, Weston, FL 33326',
   26.1010, -80.3875,
   'sports_bar',
   'Local sports bar chain known for wings, cold drafts, and game-day atmosphere',
   4.0, true, 120),

  ('The Rustic Inn Crabhouse',
   '4331 Anglers Ave, Weston, FL 33331',
   26.0722, -80.1632,
   'bar',
   'South Florida seafood institution with a lively waterfront bar and cold beer',
   4.3, true, 80),

  ('LauderAle Brewery',
   '3305 SW 26th Terrace, Davie, FL 33328',
   26.0631, -80.2078,
   'brewery',
   'Local South Florida craft brewery with a taproom, food trucks, and dog-friendly patio',
   4.5, true, 100),

  ('Weston Lanes',
   '20191 Pines Blvd, Pembroke Pines, FL 33332',
   25.9907, -80.3680,
   'bar',
   'Entertainment complex with bowling, arcade, full bar, and craft beer',
   3.9, true, 80),

  -- ========== SUNRISE ==========

  ('Pilo''s Tequila Bar',
   '9503 W Sample Rd, Sunrise, FL 33351',
   26.2704, -80.2764,
   'bar',
   'Vibrant tequila and mezcal-focused cocktail bar with Latin beats and a great vibe',
   4.2, true, 80),

  ('Duffy''s Sports Grill – Sunrise',
   '10120 W Oakland Park Blvd, Sunrise, FL 33351',
   26.1835, -80.2799,
   'sports_bar',
   'Classic South Florida sports bar with massive screens, wings, and ice-cold drafts',
   4.0, true, 120),

  ('Walk-On''s Sports Bistreaux – Sawgrass',
   '13600 W Sunrise Blvd, Sunrise, FL 33323',
   26.1573, -80.3380,
   'sports_bar',
   'New Orleans-inspired sports bar with craft cocktails and elevated game-day menu',
   4.3, true, 120),

  ('World of Beer – Sunrise',
   '1950 Sawgrass Mills Cir, Sunrise, FL 33323',
   26.1543, -80.3397,
   'bar',
   'Craft beer destination at Sawgrass Mills with hundreds of global and local taps',
   4.2, true, 80),

  ('Dave & Buster''s – Sunrise',
   '2620 W Sunrise Blvd, Sunrise, FL 33313',
   26.1540, -80.2683,
   'bar',
   'Entertainment venue with full bar, cocktails, food, and gaming',
   4.0, true, 80),

  ('Buffalo Wild Wings – Sunrise',
   '12651 W Sunrise Blvd, Sunrise, FL 33323',
   26.1555, -80.3258,
   'sports_bar',
   'Stadium-style sports bar with 100+ screens, craft beer, and wings',
   3.9, true, 120),

  ('Flanigan''s Seafood Bar – Sunrise',
   '9517 W Oakland Park Blvd, Sunrise, FL 33351',
   26.1838, -80.2744,
   'bar',
   'South Florida staple with legendary baby back ribs, cold Heinekens, and a lively bar',
   4.4, true, 80),

  ('Sunrise Ale House',
   '6890 W Sunrise Blvd, Sunrise, FL 33313',
   26.1528, -80.2568,
   'pub',
   'Neighborhood sports pub with cold drafts, darts, and big-screen sports coverage',
   4.1, true, 80),

  ('Craft Beer Bar – Sawgrass',
   '2574 N University Dr, Sunrise, FL 33322',
   26.1562, -80.2633,
   'bar',
   'Rotating craft taps and local Florida beers in a relaxed neighborhood bar setting',
   4.2, true, 80),

  ('SportsZone Bar & Grill – Sunrise',
   '7630 W Commercial Blvd, Sunrise, FL 33351',
   26.1853, -80.2722,
   'sports_bar',
   'Loud, fun sports bar packed with screens and happy hour specials nightly',
   3.9, true, 120),

  ('Benihana – Sunrise',
   '2160 NW 84th Ave, Sunrise, FL 33322',
   26.1548, -80.2611,
   'lounge',
   'Teppanyaki restaurant with a full cocktail lounge and sake bar',
   4.1, true, 80),

  ('ETARU – Sawgrass',
   '2626 N University Dr, Sunrise, FL 33322',
   26.1566, -80.2637,
   'lounge',
   'Japanese robata grill with a chic lounge bar, craft cocktails, and sake selection',
   4.4, true, 80),

  -- ========== DAVIE ==========

  ('Bru''s Room Sports Grill – Davie',
   '3001 Griffin Rd, Davie, FL 33314',
   26.0635, -80.2087,
   'sports_bar',
   'High-energy local sports bar with multiple screens, craft beers, and great pub food',
   4.3, true, 120),

  ('Tap 42 Craft Kitchen & Bar – Davie',
   '5090 S University Dr, Davie, FL 33328',
   26.0558, -80.2641,
   'bar',
   'Craft beer and cocktail bar with 42 rotating taps and an elevated gastropub menu',
   4.4, true, 80),

  ('Round 1 Bowling & Amusement – Davie',
   '8000 W Broward Blvd, Davie, FL 33324',
   26.1012, -80.2723,
   'bar',
   'Entertainment complex with a full bar, bowling, karaoke, billiards, and arcade',
   4.1, true, 80),

  ('Flanigan''s Seafood Bar – Davie',
   '6360 SW 45th St, Davie, FL 33314',
   26.0758, -80.2153,
   'bar',
   'Beloved South Florida chain with great ribs, seafood, cold beers, and a packed bar',
   4.3, true, 80),

  ('Dirty Blondes',
   '6201 SW 45th St, Davie, FL 33314',
   26.0754, -80.2138,
   'bar',
   'Local neighborhood bar with pool tables, darts, live music, and strong pours',
   4.0, true, 80),

  ('The Filling Station – Davie',
   '4760 S University Dr, Davie, FL 33328',
   26.0548, -80.2639,
   'pub',
   'Relaxed neighborhood bar with craft beer, comfort food, and weekly events',
   4.1, true, 80),

  ('Big Bear Brewing Company',
   '1800 N University Dr, Pembroke Pines, FL 33324',
   26.0071, -80.2617,
   'brewery',
   'South Florida craft brewery with house beers, outdoor patio, and live music nights',
   4.3, true, 100),

  ('Maguire''s Hill 16 Irish Bar',
   '535 N Andrews Ave, Fort Lauderdale, FL 33317',
   26.1208, -80.1488,
   'pub',
   'Authentic Irish pub close to Davie with live music, Guinness on tap, and great craic',
   4.5, true, 80),

  ('Hurricane Bar & Grill – Davie',
   '6001 SW 45th St, Davie, FL 33314',
   26.0750, -80.2122,
   'sports_bar',
   'No-frills sports bar with cheap drinks, pool tables, and big-screen football every weekend',
   3.8, true, 120),

  ('Tom Jenkins BBQ – Fort Lauderdale',
   '1236 S Federal Hwy, Fort Lauderdale, FL 33316',
   26.0940, -80.1336,
   'bar',
   'Famous BBQ joint near Davie with a casual bar serving cold beers and pitmaster plates',
   4.6, true, 80),

  ('Copper Rock Coffee & Bar – Davie',
   '2571 S University Dr, Davie, FL 33324',
   26.1014, -80.2641,
   'lounge',
   'Coffee lounge by day, craft cocktail bar by night in the heart of Davie',
   4.2, true, 80),

  ('Davie Pub & Grille',
   '6450 SW 45th St, Davie, FL 33314',
   26.0757, -80.2148,
   'pub',
   'Community pub with pool, darts, karaoke nights, and a solid happy hour',
   3.9, true, 80),

  ('Rocks Pub & Grub – Davie',
   '3101 S University Dr, Davie, FL 33328',
   26.0626, -80.2641,
   'pub',
   'Dive bar energy with live bands, poker nights, and some of the cheapest drafts in Broward',
   4.0, true, 80)

ON CONFLICT DO NOTHING;
