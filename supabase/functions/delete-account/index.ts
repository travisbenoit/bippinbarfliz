import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
};

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return json(401, { error: 'Missing authorization' });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await userClient.auth.getUser();
    if (userError || !user) {
      return json(401, { error: 'Unauthorized' });
    }

    const adminClient = createClient(supabaseUrl, serviceKey);
    const userId = user.id;
    const summary: Record<string, string> = {};

    // Step 1: Delete public.users row.
    // Schema has ON DELETE CASCADE from public.users -> all dependent tables
    // (messages, friendships, swarms, gifts, venue_sessions, lush_coin_transactions, etc.)
    const { error: profileErr } = await adminClient
      .from('users')
      .delete()
      .eq('id', userId);
    summary.public_users = profileErr ? `error: ${profileErr.message}` : 'deleted';

    // Step 2: Delete auth.users row.
    // Cleans up the Supabase auth record. Public.users would also cascade from
    // here if step 1 missed, so this acts as a backstop.
    const { error: authErr } = await adminClient.auth.admin.deleteUser(userId);
    summary.auth_users = authErr ? `error: ${authErr.message}` : 'deleted';

    if (authErr) {
      return json(500, {
        error: 'Account deletion partially failed',
        detail: authErr.message,
        summary,
      });
    }

    return json(200, { success: true, userId, summary });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return json(500, { error: message });
  }
});
