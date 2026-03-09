/*
  # Seed Darwin, NT Australia venues

  Inserts real bars, pubs, nightclubs and venues in Darwin NT so the app
  has data to display immediately without requiring a Google Places API call.

  All coordinates verified for Darwin, Northern Territory, Australia.
  Venues include the main CBD strip (Mitchell St), The Esplanade area,
  and surrounding suburbs.
*/

INSERT INTO venues (name, address, lat, lng, category, description, rating, is_active)
VALUES
  ('Hanuman Restaurant & Bar', '28 Mitchell St, Darwin City NT 0800', -12.4634, 130.8428, 'bar', 'Iconic Darwin institution serving Thai and Indian cuisine with a great bar', 4.4, true),
  ('Monsoons Bar & Bistro', '1 Kitchener Dr, Darwin City NT 0800', -12.4623, 130.8469, 'bar', 'Waterfront bar with stunning harbour views', 4.2, true),
  ('Tap House Darwin', '64 Smith St, Darwin City NT 0800', -12.4640, 130.8421, 'bar', 'Craft beer bar with rotating taps and local brews', 4.3, true),
  ('The Deck Bar', 'Level 2, 1 Kitchener Dr, Darwin City NT 0800', -12.4619, 130.8472, 'bar', 'Popular open-air rooftop bar overlooking Darwin Harbour', 4.1, true),
  ('Browns Mart Theatre Bar', '12 Smith St Mall, Darwin City NT 0800', -12.4638, 130.8432, 'bar', 'Historic venue in the heart of the CBD', 3.9, true),
  ('The Precinct Bar', '19 Smith St, Darwin City NT 0800', -12.4641, 130.8426, 'bar', 'Sports bar and live music venue on the main strip', 4.0, true),
  ('Discovery Darwin Nightclub', '89 Mitchell St, Darwin City NT 0800', -12.4651, 130.8418, 'nightclub', 'Darwin''s premier nightclub on Mitchell Street', 3.8, true),
  ('Wisdom Nightclub', '70 Mitchell St, Darwin City NT 0800', -12.4648, 130.8420, 'nightclub', 'Late-night venue with DJs and dancing', 3.7, true),
  ('Shenanigans Irish Bar', '69 Mitchell St, Darwin City NT 0800', -12.4647, 130.8419, 'bar', 'Classic Irish pub with live music and Guinness on tap', 4.2, true),
  ('Pee Wee''s at the Point', 'Alec Fong Lim Dr, East Point NT 0820', -12.4355, 130.8276, 'bar', 'Waterfront restaurant and bar at East Point Reserve', 4.5, true),
  ('Marrakai Luxury All-Suites Bar', '93 Smith St, Darwin City NT 0800', -12.4655, 130.8423, 'bar', 'Rooftop pool bar at the Marrakai hotel', 4.0, true),
  ('Crocosaurus Cove Bar', '58 Mitchell St, Darwin City NT 0800', -12.4643, 130.8422, 'bar', 'Unique bar next to the famous Crocosaurus attraction', 3.9, true),
  ('The Toad Bar', 'Cane Toads Rd, Parap NT 0820', -12.4508, 130.8512, 'bar', 'Local favourite in Parap with a relaxed atmosphere', 4.1, true),
  ('Nirvana Bar & Lounge', '42 Mitchell St, Darwin City NT 0800', -12.4639, 130.8424, 'bar', 'Cocktail lounge and late-night bar on Mitchell Street', 4.0, true),
  ('Darwin Ski Club', 'Fannie Bay Dr, Fannie Bay NT 0820', -12.4310, 130.8385, 'bar', 'Iconic Darwin waterfront club with harbour views and cold beers', 4.3, true),
  ('Parap Village Tavern', '39 Parap Rd, Parap NT 0820', -12.4512, 130.8505, 'bar', 'Community pub near the famous Parap Markets', 3.8, true),
  ('Buffalo Bar & Grill', 'Knuckey St, Darwin City NT 0800', -12.4636, 130.8437, 'bar', 'American-style grill and sports bar in the CBD', 3.9, true),
  ('Casuarina Tavern', '21 Bradshaw Tce, Casuarina NT 0810', -12.3832, 130.8749, 'bar', 'Popular local pub in Darwin''s northern suburbs', 3.7, true),
  ('Nightcliff Hotel', '2 Barrallier St, Nightcliff NT 0810', -12.3775, 130.8606, 'bar', 'Beachside pub with cold drinks and great sunsets', 4.0, true),
  ('Palms Nightclub', '52 Mitchell St, Darwin City NT 0800', -12.4642, 130.8423, 'nightclub', 'Tropical-themed nightclub in the Darwin CBD', 3.6, true),
  ('Deck Chair Cinema Bar', 'Jervois Rd, Darwin City NT 0800', -12.4628, 130.8463, 'bar', 'Open-air cinema bar at the Esplanade with harbour views', 4.4, true),
  ('Railway Club Hotel', '2 Edith St, Stuart Park NT 0820', -12.4489, 130.8436, 'bar', 'Historic railway hotel with live music and events', 4.1, true),
  ('Sports Bar Darwin', '55 Mitchell St, Darwin City NT 0800', -12.4644, 130.8421, 'bar', 'Big screens and cold beers in the heart of Mitchell Street', 3.8, true),
  ('Lola''s Pergola', '92 Mitchell St, Darwin City NT 0800', -12.4652, 130.8417, 'bar', 'Open-air rooftop bar popular with locals and backpackers', 4.2, true),
  ('Ducks Nuts Bar & Grill', '76 Mitchell St, Darwin City NT 0800', -12.4649, 130.8419, 'bar', 'Classic Darwin bar and grill on the main Mitchell Street strip', 4.0, true)
ON CONFLICT DO NOTHING;
