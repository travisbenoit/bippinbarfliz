import { createClient } from 'npm:@supabase/supabase-js@2.57.4';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const BUCKET = 'venue-photos';

export async function uploadVenuePhoto(
  photoReference: string,
  venueId: string,
  googleApiKey: string,
  maxWidth = 800
): Promise<string | null> {
  try {
    const googleUrl = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=${maxWidth}&photoreference=${photoReference}&key=${googleApiKey}`;
    const response = await fetch(googleUrl, { redirect: 'follow' });

    if (!response.ok) {
      console.error(`Failed to fetch Google photo: ${response.status}`);
      return null;
    }

    const contentType = response.headers.get('content-type') || 'image/jpeg';
    const imageBuffer = await response.arrayBuffer();

    if (imageBuffer.byteLength < 1000) {
      console.error('Photo too small, likely an error response');
      return null;
    }

    const ext = contentType.includes('png') ? 'png' : contentType.includes('webp') ? 'webp' : 'jpg';
    const fileName = `${venueId}/photo.${ext}`;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { error } = await supabase.storage
      .from(BUCKET)
      .upload(fileName, imageBuffer, {
        contentType,
        upsert: true,
      });

    if (error) {
      console.error(`Storage upload failed for ${venueId}:`, error.message);
      return null;
    }

    const { data } = supabase.storage.from(BUCKET).getPublicUrl(fileName);
    return data.publicUrl;
  } catch (err) {
    console.error(`uploadVenuePhoto error for ${venueId}:`, err);
    return null;
  }
}
