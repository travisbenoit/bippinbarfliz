/*
  # Fix South Florida Venue Coordinates

  1. Problem
    - Many South Florida venues have incorrect coordinates
    - Some venues reference addresses from other cities

  2. Solution
    - Update coordinates to accurate GPS positions for each venue
*/

UPDATE venues SET lat = 26.1005, lng = -80.3901, address = '4443 Lyons Rd, Coconut Creek, FL 33073', city = 'Coconut Creek', state = 'FL' WHERE id = 'e495864a-ad99-47c1-8803-db7aa783804f';
UPDATE venues SET lat = 26.2071, lng = -80.2617, address = '1800 N University Dr, Coral Springs, FL 33071', city = 'Coral Springs', state = 'FL' WHERE id = '25734ecd-ea45-44d4-951e-403579b957f1';
UPDATE venues SET lat = 26.1899, lng = -80.1312, address = '3115 NE 32nd Ave, Fort Lauderdale, FL 33308', city = 'Fort Lauderdale', state = 'FL' WHERE id = 'e71bac20-ba0b-401b-91f7-7c11ee253552';
UPDATE venues SET lat = 26.2335, lng = -80.1247, address = '235 S Federal Hwy, Pompano Beach, FL 33062', city = 'Pompano Beach', state = 'FL' WHERE id = '890ce308-04a1-4a21-aec3-1e919cb09b94';
UPDATE venues SET lat = 26.1555, lng = -80.2558, address = '8000 W Broward Blvd, Plantation, FL 33388', city = 'Plantation', state = 'FL' WHERE id = 'b8450b2e-080e-427d-819e-7d074efbef53';
UPDATE venues SET lat = 26.1540, lng = -80.3397, address = '12801 W Sunrise Blvd, Sunrise, FL 33323', city = 'Sunrise', state = 'FL' WHERE id = '2eca5939-2258-479b-aa77-c9e2e25bc835';
UPDATE venues SET lat = 26.0754, lng = -80.2138, address = '6201 SW 45th St, Davie, FL 33314', city = 'Davie', state = 'FL' WHERE id = '7e279300-1980-4f9a-9c60-24e142ee227d';
UPDATE venues SET lat = 26.1557, lng = -80.2563, address = '3550 Inverrary Blvd, Lauderhill, FL 33319', city = 'Lauderhill', state = 'FL' WHERE id = 'bb6d9a70-52a6-417a-9127-f81c80f39fba';
UPDATE venues SET lat = 26.1010, lng = -80.3875, address = '1320 Weston Rd, Weston, FL 33326', city = 'Weston', state = 'FL' WHERE id = '42d93070-16ae-415e-9a0c-cc0e6fff5c91';
UPDATE venues SET lat = 26.1566, lng = -80.3397, address = '12801 W Sunrise Blvd Suite 336, Sunrise, FL 33323', city = 'Sunrise', state = 'FL' WHERE id = '04ed2e2c-e69c-4d6c-8f5b-78e4f90c61ad';
UPDATE venues SET lat = 26.0758, lng = -80.2153, address = '5960 S University Dr, Davie, FL 33328', city = 'Davie', state = 'FL' WHERE id = 'cf43b6fc-c065-473a-b2c2-239f331a0879';
UPDATE venues SET lat = 26.1838, lng = -80.2744, address = '14301 W Sunrise Blvd, Sunrise, FL 33323', city = 'Sunrise', state = 'FL' WHERE id = '9db2505a-9d85-4a38-9095-d081307002f9';
UPDATE venues SET lat = 26.0750, lng = -80.2122, address = '4500 SW 45th St, Davie, FL 33314', city = 'Davie', state = 'FL' WHERE id = 'c33160b7-16cd-41ee-9e6c-a6b938d4a08a';
UPDATE venues SET lat = 26.0631, lng = -80.1178, address = '3305 SE 14th Ave, Fort Lauderdale, FL 33316', city = 'Fort Lauderdale', state = 'FL' WHERE id = '0fe0aea5-3623-4b70-8d11-04a17cf4c4bb';
UPDATE venues SET lat = 26.1208, lng = -80.1488, address = '535 N Andrews Ave, Fort Lauderdale, FL 33301', city = 'Fort Lauderdale', state = 'FL' WHERE id = 'f1dce124-ec40-4396-82c4-62514d7d1686';
UPDATE venues SET lat = 26.2704, lng = -80.2764, address = '9503 W Sample Rd, Coral Springs, FL 33065', city = 'Coral Springs', state = 'FL' WHERE id = '1e013fbf-b11c-4d4b-9a86-48038b035087';
UPDATE venues SET lat = 26.0122, lng = -80.3526, address = '12055 Pines Blvd, Pembroke Pines, FL 33026', city = 'Pembroke Pines', state = 'FL' WHERE id = 'ec973950-5f33-4040-822b-f7f897736348';
UPDATE venues SET lat = 26.1528, lng = -80.2568, address = '2080 S University Dr, Davie, FL 33324', city = 'Davie', state = 'FL' WHERE id = 'ad987074-bf4c-4ca0-a3b7-7b4835fec1a6';
UPDATE venues SET lat = 26.0558, lng = -80.2641, address = '3401 Davie Rd, Davie, FL 33314', city = 'Davie', state = 'FL' WHERE id = '54d2f80a-a162-4d94-ad7c-0b4ad2e73196';
UPDATE venues SET lat = 26.1194, lng = -80.1336, address = '1236 S Federal Hwy, Fort Lauderdale, FL 33316', city = 'Fort Lauderdale', state = 'FL' WHERE id = '3bae127e-1de9-4681-8e4b-1dce597b773b';
UPDATE venues SET lat = 26.0722, lng = -80.1632, address = '4331 Anglers Ave, Fort Lauderdale, FL 33312', city = 'Fort Lauderdale', state = 'FL' WHERE id = 'd2542ce8-7336-4608-9aa9-6a27a382aa9e';
UPDATE venues SET lat = 26.1573, lng = -80.3380, address = '13600 W Sunrise Blvd, Sunrise, FL 33323', city = 'Sunrise', state = 'FL' WHERE id = '80ed67cb-db6b-4484-b33b-d87613401262';
UPDATE venues SET lat = 26.0107, lng = -80.3580, address = '20191 Pines Blvd, Pembroke Pines, FL 33029', city = 'Pembroke Pines', state = 'FL' WHERE id = '8f989faf-e1d5-454c-be60-be5fcc666425';
UPDATE venues SET lat = 26.1543, lng = -80.3397, address = '12801 W Sunrise Blvd, Sunrise, FL 33323', city = 'Sunrise', state = 'FL' WHERE id = 'bba12b33-4c53-43c5-9985-5f885959d95f';
UPDATE venues SET lat = 26.0746, lng = -80.3983, address = '1625 Weston Rd, Weston, FL 33326', city = 'Weston', state = 'FL' WHERE id = 'fa644fe5-b229-4013-8d3a-f7706c46e857';
UPDATE venues SET lat = 26.2048, lng = -80.2611, address = '1695 N University Dr, Coral Springs, FL 33071', city = 'Coral Springs', state = 'FL' WHERE id = 'a2595a96-6e62-4e91-95ff-ac33d438aa65';
UPDATE venues SET lat = 25.7485, lng = -80.2624, address = '5813 Ponce de Leon Blvd, Coral Gables, FL 33146', city = 'Coral Gables', state = 'FL' WHERE id = 'd7bed26a-67ab-41b6-8eb8-8abbc6cc69a2';
UPDATE venues SET lat = 26.0626, lng = -80.2641, address = '3101 S University Dr, Davie, FL 33328', city = 'Davie', state = 'FL' WHERE id = 'af37a110-868e-4e82-bfaa-1599a3597149';
UPDATE venues SET lat = 26.0548, lng = -80.2639, address = '4760 S University Dr, Davie, FL 33328', city = 'Davie', state = 'FL' WHERE id = '11f91417-2f1b-4d90-83a9-169cee4946f1';
UPDATE venues SET lat = 26.1853, lng = -80.2722, address = '7630 W Commercial Blvd, Lauderhill, FL 33351', city = 'Lauderhill', state = 'FL' WHERE id = '21fcfd3a-4e20-4215-93cf-9e1cb28cb80d';
UPDATE venues SET lat = 26.2962, lng = -80.1823, address = '2450 W Hillsboro Blvd, Deerfield Beach, FL 33442', city = 'Deerfield Beach', state = 'FL' WHERE id = '2d6a046b-5cdf-4ea7-b959-71074a2e79bd';
UPDATE venues SET lat = 26.0757, lng = -80.2148, address = '6450 SW 45th St, Davie, FL 33314', city = 'Davie', state = 'FL' WHERE id = '4970e0f3-0b48-4103-abe2-26408f703280';
UPDATE venues SET lat = 26.1014, lng = -80.2641, address = '2571 S University Dr, Davie, FL 33324', city = 'Davie', state = 'FL' WHERE id = 'd9ddcc12-0eaa-470e-8e2b-b0d47772c746';
