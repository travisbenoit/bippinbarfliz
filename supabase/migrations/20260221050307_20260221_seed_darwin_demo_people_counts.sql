/*
  # Seed Darwin venue demo people counts

  Sets realistic demo_people_count values on Darwin, AU venues so the map
  shows activity rather than appearing completely empty to new users.

  Venues near Darwin CBD get higher counts (busy nightlife area),
  suburban venues get lower counts.
*/

UPDATE venues SET demo_people_count = 8  WHERE name = 'Tap House Darwin';
UPDATE venues SET demo_people_count = 12 WHERE name = 'Discovery Darwin Nightclub';
UPDATE venues SET demo_people_count = 9  WHERE name = 'Wisdom Nightclub';
UPDATE venues SET demo_people_count = 6  WHERE name = 'Shenanigans Irish Bar';
UPDATE venues SET demo_people_count = 7  WHERE name = 'Monsoons Bar & Bistro';
UPDATE venues SET demo_people_count = 5  WHERE name = 'The Deck Bar';
UPDATE venues SET demo_people_count = 10 WHERE name = 'Palms Nightclub';
UPDATE venues SET demo_people_count = 4  WHERE name = 'Ducks Nuts Bar & Grill';
UPDATE venues SET demo_people_count = 3  WHERE name = 'Lola''s Pergola';
UPDATE venues SET demo_people_count = 6  WHERE name = 'Hanuman Restaurant & Bar';
UPDATE venues SET demo_people_count = 5  WHERE name = 'The Precinct Bar';
UPDATE venues SET demo_people_count = 3  WHERE name = 'Nirvana Bar & Lounge';
UPDATE venues SET demo_people_count = 4  WHERE name = 'Buffalo Bar & Grill';
UPDATE venues SET demo_people_count = 2  WHERE name = 'Browns Mart Theatre Bar';
UPDATE venues SET demo_people_count = 7  WHERE name = 'Crocosaurus Cove Bar';
UPDATE venues SET demo_people_count = 3  WHERE name = 'Sports Bar Darwin';
UPDATE venues SET demo_people_count = 2  WHERE name = 'Deck Chair Cinema Bar';
UPDATE venues SET demo_people_count = 4  WHERE name = 'Railway Club Hotel';
UPDATE venues SET demo_people_count = 3  WHERE name = 'The Toad Bar';
UPDATE venues SET demo_people_count = 2  WHERE name = 'Parap Village Tavern';
UPDATE venues SET demo_people_count = 5  WHERE name = 'Pee Wee''s at the Point';
UPDATE venues SET demo_people_count = 3  WHERE name = 'Darwin Ski Club';
UPDATE venues SET demo_people_count = 2  WHERE name = 'Marrakai Luxury All-Suites Bar';
UPDATE venues SET demo_people_count = 1  WHERE name = 'Casuarina Tavern';
UPDATE venues SET demo_people_count = 1  WHERE name = 'Nightcliff Hotel';
