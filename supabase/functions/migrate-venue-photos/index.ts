import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import { corsHeaders } from '../_shared/cors.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;

const BUCKET = 'venue-photos';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const userSupabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authError } = await userSupabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: profile } = await userSupabase
      .from('user_profiles')
      .select('is_admin')
      .eq('id', user.id)
      .maybeSingle();

    if (!profile?.is_admin) {
      const { data: userRow } = await userSupabase
        .from('users')
        .select('is_admin')
        .eq('id', user.id)
        .maybeSingle();
      if (!userRow?.is_admin) {
        return new Response(JSON.stringify({ error: 'Admin access required' }), {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    }

    const body = await req.json().catch(() => ({}));
    const limit = body.limit || 100;
    const dryRun = body.dry_run === true;

    const adminSupabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: venues, error: queryError } = await adminSupabase
      .from('venues')
      .select('id, name, photo_url')
      .not('photo_url', 'is', null)
      .like('photo_url', '%googleapis.com/maps/api/place/photo%')
      .limit(limit);

    if (queryError) {
      return new Response(JSON.stringify({ error: queryError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!venues || venues.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No venues with Google photo URLs found', migrated: 0 }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const results: Array<{ id: string; name: string; status: string; new_url?: string }> = [];
    let migrated = 0;
    let failed = 0;

    for (const venue of venues) {
      try {
        if (dryRun) {
          results.push({ id: venue.id, name: venue.name, status: 'would_migrate' });
          migrated++;
          continue;
        }

        const response = await fetch(venue.photo_url, { redirect: 'follow' });
        if (!response.ok) {
          results.push({ id: venue.id, name: venue.name, status: `fetch_failed_${response.status}` });
          failed++;
          continue;
        }

        const contentType = response.headers.get('content-type') || 'image/jpeg';
        const imageBuffer = await response.arrayBuffer();

        if (imageBuffer.byteLength < 1000) {
          results.push({ id: venue.id, name: venue.name, status: 'too_small' });
          failed++;
          continue;
        }

        const ext = contentType.includes('png') ? 'png' : contentType.includes('webp') ? 'webp' : 'jpg';
        const fileName = `${venue.id}/photo.${ext}`;

        const { error: uploadError } = await adminSupabase.storage
          .from(BUCKET)
          .upload(fileName, imageBuffer, { contentType, upsert: true });

        if (uploadError) {
          results.push({ id: venue.id, name: venue.name, status: `upload_failed: ${uploadError.message}` });
          failed++;
          continue;
        }

        const { data } = adminSupabase.storage.from(BUCKET).getPublicUrl(fileName);
        const newUrl = data.publicUrl;

        const { error: updateError } = await adminSupabase
          .from('venues')
          .update({ photo_url: newUrl, updated_at: new Date().toISOString() })
          .eq('id', venue.id);

        if (updateError) {
          results.push({ id: venue.id, name: venue.name, status: `db_update_failed: ${updateError.message}` });
          failed++;
          continue;
        }

        results.push({ id: venue.id, name: venue.name, status: 'migrated', new_url: newUrl });
        migrated++;

        await new Promise(r => setTimeout(r, 200));
      } catch (err) {
        results.push({
          id: venue.id,
          name: venue.name,
          status: `error: ${err instanceof Error ? err.message : String(err)}`,
        });
        failed++;
      }
    }

    return new Response(
      JSON.stringify({
        message: dryRun ? 'Dry run complete' : 'Migration complete',
        total: venues.length,
        migrated,
        failed,
        results,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
