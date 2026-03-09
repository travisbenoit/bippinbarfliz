import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.VITE_SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const GOOGLE_API_KEY = process.env.VITE_GOOGLE_PLACES_API_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function getPlaceDetails(placeId) {
  const fields = [
    'place_id',
    'name',
    'rating',
    'user_ratings_total',
    'photos',
    'formatted_address',
    'opening_hours',
    'formatted_phone_number',
    'website',
    'url',
    'price_level',
    'reviews',
    'types',
    'geometry'
  ].join(',');

  const url = new URL('https://maps.googleapis.com/maps/api/place/details/json');
  url.searchParams.set('key', GOOGLE_API_KEY);
  url.searchParams.set('place_id', placeId);
  url.searchParams.set('fields', fields);

  const response = await fetch(url.toString());
  const data = await response.json();

  if (data.status !== 'OK') {
    console.warn(`Failed to fetch ${placeId}: ${data.status}`);
    return null;
  }

  return data.result;
}

function getPhotoUrl(photoReference, maxWidth = 800) {
  const url = new URL('https://maps.googleapis.com/maps/api/place/photo');
  url.searchParams.set('key', GOOGLE_API_KEY);
  url.searchParams.set('photo_reference', photoReference);
  url.searchParams.set('maxwidth', maxWidth.toString());
  return url.toString();
}

async function enrichVenue(venue) {
  if (!venue.google_place_id) {
    console.log(`⚠️  ${venue.name} - No Google Place ID`);
    return false;
  }

  console.log(`🔍 Fetching details for: ${venue.name}`);

  const details = await getPlaceDetails(venue.google_place_id);
  if (!details) {
    return false;
  }

  const photoUrl = details.photos && details.photos.length > 0
    ? getPhotoUrl(details.photos[0].photo_reference, 800)
    : null;

  const updateData = {
    rating: details.rating || null,
    user_ratings_total: details.user_ratings_total || 0,
    photo_url: photoUrl,
    address: details.formatted_address || venue.address,
    phone: details.formatted_phone_number || null,
    website: details.website || null,
    hours: details.opening_hours || null,
    price_level: details.price_level || null,
    metadata: {
      ...venue.metadata,
      google_url: details.url,
      google_types: details.types,
      google_reviews: details.reviews || [],
      last_google_sync: new Date().toISOString()
    },
    lat: details.geometry?.location?.lat || venue.lat,
    lng: details.geometry?.location?.lng || venue.lng,
  };

  const { error } = await supabase
    .from('venues')
    .update(updateData)
    .eq('id', venue.id);

  if (error) {
    console.error(`❌ Error updating ${venue.name}:`, error);
    return false;
  }

  console.log(`✅ ${venue.name} - Updated with photo, rating: ${details.rating}, reviews: ${details.user_ratings_total}`);
  return true;
}

async function enrichAllVenues() {
  console.log('🚀 Starting venue enrichment...\n');

  const { data: venues, error } = await supabase
    .from('venues')
    .select('*')
    .eq('is_active', true)
    .in('country', ['US', 'AU'])
    .not('google_place_id', 'is', null)
    .order('name');

  if (error) {
    console.error('Error fetching venues:', error);
    return;
  }

  console.log(`📊 Found ${venues.length} venues to enrich\n`);

  let successCount = 0;
  let failCount = 0;

  for (const venue of venues) {
    const success = await enrichVenue(venue);
    if (success) {
      successCount++;
    } else {
      failCount++;
    }

    await new Promise(resolve => setTimeout(resolve, 200));
  }

  console.log(`\n✨ Enrichment complete!`);
  console.log(`   ✅ Success: ${successCount}`);
  console.log(`   ❌ Failed: ${failCount}`);
  console.log(`   📊 Total: ${venues.length}`);
}

enrichAllVenues().catch(console.error);
