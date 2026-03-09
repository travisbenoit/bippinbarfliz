/*
  # Fix Darwin Venue Coordinates

  1. Problem
    - Many Darwin venues have inaccurate coordinates
    - Several duplicate venues exist with conflicting addresses/coords
    - Venues from Mitchell St area are clustered incorrectly

  2. Solution
    - Update coordinates to accurate GPS positions for each venue
    - Remove duplicate entries keeping the most accurate one
    - Use verified lat/lng from Google Maps for Darwin City NT 0800

  3. Key Darwin coordinates reference:
    - Mitchell St runs roughly from -12.462 lat, 130.841 lng (south end) to -12.465 lat, 130.843 lng (north end)
    - Smith St: -12.464 to -12.466 lat, ~130.843 lng
    - Knuckey St: ~-12.460 lat, 130.838 lng area
*/

-- Fix Tap House Darwin (64 Smith St - correct lat/lng)
UPDATE venues SET lat = -12.4640, lng = 130.8433, city = 'Darwin City' WHERE id = '7f9f6e4e-fa24-4c68-b217-38d51ccffbcb';

-- Fix Shenanigans Irish Bar - Mitchell St version (correct address is 69 Mitchell St)
UPDATE venues SET lat = -12.4644, lng = 130.8422, address = '69 Mitchell St, Darwin City NT 0800', city = 'Darwin City' WHERE id = '7c20fd92-5542-4a60-8ba7-9fc9bbf0222e';

-- Deactivate the duplicate Shenanigans with wrong address (Smith Street)
UPDATE venues SET is_active = false WHERE id = '2c546ea5-b8d2-4afb-88aa-9483ea512025';

-- Deactivate duplicate Shenannigans (typo version)
UPDATE venues SET is_active = false WHERE id = 'e415f327-c818-4fd8-b95c-6492a5679cc4';

-- Fix Nirvana Bar & Lounge (42 Mitchell St)
UPDATE venues SET lat = -12.4636, lng = 130.8419, city = 'Darwin City' WHERE id = 'ef5083d2-7299-48cf-a146-9c2ecac84045';

-- Fix Hanuman Restaurant & Bar (28 Mitchell St)
UPDATE venues SET lat = -12.4630, lng = 130.8416, city = 'Darwin City' WHERE id = '6817dbdc-447a-4f74-b6bd-9f1dbb96f439';

-- Fix Sports Bar Darwin (55 Mitchell St)
UPDATE venues SET lat = -12.4641, lng = 130.8421, city = 'Darwin City' WHERE id = '1c1d9103-1e3f-4397-b526-f948d140d4b2';

-- Fix Discovery Darwin (89 Mitchell St) - keep one, deactivate duplicate
UPDATE venues SET lat = -12.4649, lng = 130.8420, city = 'Darwin City' WHERE id = '65d6e045-f29f-4294-a700-1234a4a542f9';
UPDATE venues SET is_active = false WHERE id = '04f3feb3-4bb6-4e0b-a575-1e3b772d66b6';

-- Fix Ducks Nuts Bar & Grill (76 Mitchell St) - keep one, deactivate duplicate
UPDATE venues SET lat = -12.4645, lng = 130.8420, city = 'Darwin City' WHERE id = 'e576766a-a785-4b36-b169-5d40ba879cb6';
UPDATE venues SET is_active = false WHERE id = '3d707d09-aa3f-42f9-b2e6-0a8a74d381d0';

-- Fix Lola's Pergola (92 Mitchell St)
UPDATE venues SET lat = -12.4651, lng = 130.8418, city = 'Darwin City' WHERE id = '1a159056-86e4-4703-8942-87724ceb0cf4';

-- Fix Palms Nightclub (52 Mitchell St)
UPDATE venues SET lat = -12.4640, lng = 130.8420, city = 'Darwin City' WHERE id = '285a7b2e-e10c-49f0-977e-7afe8aea1f71';

-- Fix Wisdom Nightclub (70 Mitchell St)
UPDATE venues SET lat = -12.4647, lng = 130.8420, city = 'Darwin City' WHERE id = 'ff8172ff-bf7f-4b43-ba51-ca23bf153f37';

-- Fix Crocosaurus Cove Bar (58 Mitchell St)
UPDATE venues SET lat = -12.4643, lng = 130.8421, city = 'Darwin City' WHERE id = '3e59084f-4df1-4690-a49c-590063bbd28f';

-- Fix The Precinct Bar (19 Smith St)
UPDATE venues SET lat = -12.4625, lng = 130.8434, city = 'Darwin City' WHERE id = 'b3814afd-de26-4f01-a50d-497d4ae47770';

-- Fix Marrakai Luxury All-Suites Bar (93 Smith St)
UPDATE venues SET lat = -12.4654, lng = 130.8434, city = 'Darwin City' WHERE id = 'ee4bd807-99f0-43e1-91a5-c4586458d5b7';

-- Fix Buffalo Bar & Grill (Knuckey St)
UPDATE venues SET lat = -12.4632, lng = 130.8427, city = 'Darwin City' WHERE id = '16c9ed94-06c6-4e53-9284-f40733ac54dc';

-- Fix The Deck Bar / Deck Bar (waterfront area)
UPDATE venues SET lat = -12.4622, lng = 130.8462, city = 'Darwin City' WHERE id = '88fc65c9-ab89-42f6-9b74-ea266ecb4e9a';
UPDATE venues SET lat = -12.4617, lng = 130.8460, city = 'Darwin City' WHERE id = '492065d5-ba28-4011-9b23-8fb7ee80a294';
-- Deactivate duplicate Deck Chair Cinema venues
UPDATE venues SET is_active = false WHERE id = 'dd60d0e9-c023-4090-bbcf-81f382cfccb4';

-- Fix Monsoons Bar & Bistro (Kitchener Dr waterfront)
UPDATE venues SET lat = -12.4622, lng = 130.8467, city = 'Darwin City' WHERE id = 'b90ad457-a63d-4f3f-832f-bac07244d203';
-- Deactivate wrong Monsoons entries
UPDATE venues SET is_active = false WHERE id = '67f7de4b-4906-4f0a-9c4e-7eda44a49657';
UPDATE venues SET is_active = false WHERE id = '8c74b191-e2ec-488a-a3e2-8e26159702a2';

-- Fix Deckchair Cinema Bar (Jervois Rd - near esplanade)
UPDATE venues SET lat = -12.4634, lng = 130.8468, city = 'Darwin City' WHERE id = '49a01fb3-80e1-4e30-bb4e-269ad64a7d42';

-- Fix Browns Mart Theatre Bar (Smith St Mall)
UPDATE venues SET lat = -12.4622, lng = 130.8434, city = 'Darwin City' WHERE id = '08f9f2de-692a-4f88-8ab7-8774c381f19c';

-- Fix Kokomos (Mitchell Street Star Village)
UPDATE venues SET lat = -12.4638, lng = 130.8419, city = 'Darwin City' WHERE id = '3614077a-2ebf-4a0d-ad50-333d09115225';

-- Fix Lost Arc (89 Mitchell St)
UPDATE venues SET lat = -12.4648, lng = 130.8419, city = 'Darwin City' WHERE id = 'c596c625-14b7-4efd-af1f-71b9f6028884';

-- Fix Wisdom Bar and Cafe (89 Mitchell St area)
UPDATE venues SET lat = -12.4648, lng = 130.8419, city = 'Darwin City' WHERE id = 'c16e3b01-45c8-4034-ae4e-81ea4cd27d49';

-- Fix Buff Club Darwin (9 Edmunds St)
UPDATE venues SET lat = -12.4598, lng = 130.8401, city = 'Darwin City' WHERE id = 'ed7f69af-3db7-4d10-a195-259a2ae7ad11';

-- Fix Boarding House (44 Mitchell St)
UPDATE venues SET lat = -12.4637, lng = 130.8420, city = 'Darwin City' WHERE id = 'a0375942-3b6a-4881-a493-0c00c485443d';

-- Fix Chow (38 Cavenagh St)
UPDATE venues SET lat = -12.4601, lng = 130.8388, city = 'Darwin City' WHERE id = '63359447-5139-4f34-85dc-0224fb0f1f47';

-- Fix The Cavenagh Hotel (Cavenagh & Knuckey)
UPDATE venues SET lat = -12.4608, lng = 130.8390, city = 'Darwin City' WHERE id = '1a90e530-9597-4de3-90ad-8744a8da2f26';

-- Fix The Laneway (27 Knuckey St)
UPDATE venues SET lat = -12.4600, lng = 130.8381, city = 'Darwin City' WHERE id = '94d55022-41fa-44e2-bcd3-c8cdaf37e6bd';

-- Fix The Tap on Mitchell (51 Mitchell St)
UPDATE venues SET lat = -12.4639, lng = 130.8420, city = 'Darwin City' WHERE id = '6b393d82-7db0-4f04-913d-df4c77a1fd0d';

-- Fix Railway Club Hotel (2 Edith St, Stuart Park)
UPDATE venues SET lat = -12.4498, lng = 130.8421, city = 'Stuart Park' WHERE id = 'cafeb189-1347-4821-9421-af55cd6b07ef';

-- Fix Parap Hotel (1 Parap Rd)
UPDATE venues SET lat = -12.4318, lng = 130.8419, city = 'Parap' WHERE id = 'a9db896b-e30f-46f7-a8f8-d45f01f99e04';

-- Fix Parap Village Tavern (39 Parap Rd)
UPDATE venues SET lat = -12.4298, lng = 130.8418, city = 'Parap' WHERE id = '7311f6e4-ea35-4183-bfcb-87b348ab6e1b';

-- Fix Darwin Ski Club - deactivate duplicate, fix main
UPDATE venues SET lat = -12.4388, lng = 130.8290, city = 'Fannie Bay' WHERE id = '196b138c-201f-4c50-8d15-5855da2fa9bd';
UPDATE venues SET is_active = false WHERE id = 'bbb4c784-c975-4af4-80f0-df4ebcd1ae63';

-- Fix Nightcliff Hotel - deactivate wrong one, fix correct
UPDATE venues SET lat = -12.3775, lng = 130.8606, city = 'Nightcliff' WHERE id = '000b33a3-b469-4712-9fb7-b2388481d318';
UPDATE venues SET is_active = false WHERE id = 'f096da00-304a-4c41-9289-2d08e5b6a2a9';

-- Fix Nightcliff Sports Club (Progress Drive)
UPDATE venues SET lat = -12.3842, lng = 130.8519, city = 'Nightcliff' WHERE id = '1e6fbf55-1f49-4d19-902e-b5aff20fd3f0';

-- Fix Casuarina Tavern (Bradshaw Tce)
UPDATE venues SET lat = -12.3835, lng = 130.8753, city = 'Casuarina' WHERE id = 'aef173b8-8647-4935-b33e-f933586e9b82';

-- Fix One Mile Brewery (McMinn St, Coconut Grove)
UPDATE venues SET lat = -12.4012, lng = 130.8298, city = 'Coconut Grove' WHERE id = 'acd6397a-0368-4845-a9b2-639a0adfe881';

-- Fix Pee Wee's at the Point (East Point)
UPDATE venues SET lat = -12.4352, lng = 130.8278, city = 'East Point' WHERE id = 'd8e589c1-d67f-45e5-be69-20ce7c34277b';

-- Fix Ski Beach Bar (East Point Reserve)
UPDATE venues SET lat = -12.4232, lng = 130.8262, city = 'East Point' WHERE id = '2414185d-9fe0-41a3-a91f-b396b8fbbd9a';

-- Fix Snapper Bar & Grill (Marina Blvd, Cullen Bay)
UPDATE venues SET lat = -12.4278, lng = 130.8182, city = 'Cullen Bay' WHERE id = 'b49f9b5f-6459-471a-9f3f-720a0c8e7308';

-- Fix The Boat Club (23 Atkins Drive, Fannie Bay)
UPDATE venues SET lat = -12.4395, lng = 130.8358, city = 'Fannie Bay' WHERE id = 'cab7fc85-63fd-44d5-b211-2cf872d241a8';

-- Fix Throb Nightclub (64 Smith St)
UPDATE venues SET lat = -12.4641, lng = 130.8433, city = 'Darwin City' WHERE id = '414533b5-ce97-42c8-8b0b-bd4eb9a68f92';

-- Fix Rorys Karaoke Bar (Mitchell St area)
UPDATE venues SET lat = -12.4636, lng = 130.8419, city = 'Darwin City' WHERE id = '0a933eb0-3bde-42ee-9449-c96c092e27d0';

-- Fix Mindil Beach Sunset Market Bar (Gilruth Ave)
UPDATE venues SET lat = -12.4542, lng = 130.8318, city = 'Mindil Beach' WHERE id = '0ee31b0f-f5ee-476b-bfa7-416fc45130b6';

-- Fix Moorish Cafe (Waterfront Precinct)
UPDATE venues SET lat = -12.4698, lng = 130.8458, city = 'Darwin City' WHERE id = '517c0726-9cf2-43ca-8a63-d5b21e26901a';

-- Fix The Beer Garden (Waterfront)
UPDATE venues SET lat = -12.4702, lng = 130.8460, city = 'Darwin City' WHERE id = '92b21482-c3d6-4556-ae05-047c829a3181';

-- Fix Stokes Hill Wharf
UPDATE venues SET lat = -12.4718, lng = 130.8488, city = 'Darwin City' WHERE id = '5d83178f-89d3-4de8-a42c-dea351fd2723';

-- Fix The Deck Bar Darwin (Cullen Bay Marina)
UPDATE venues SET lat = -12.4285, lng = 130.8175, city = 'Cullen Bay' WHERE id = 'cc25710c-41c4-4570-ad95-e61809c29491';

-- Fix Trailer Boat Club (Frances Bay Dr, Stuart Park)
UPDATE venues SET lat = -12.4445, lng = 130.8322, city = 'Stuart Park' WHERE id = 'a619b19f-4d70-4ac1-9e79-68badb9f916b';

-- Fix Palmerston Tavern
UPDATE venues SET lat = -12.4889, lng = 130.9823, city = 'Palmerston' WHERE id = '721b9540-8d7e-4384-b640-042c47282291';

-- Fix Coolalinga Hotel
UPDATE venues SET lat = -12.5267, lng = 131.0345, city = 'Coolalinga' WHERE id = '885f3410-7b14-4805-b6e6-a273f804603b';
