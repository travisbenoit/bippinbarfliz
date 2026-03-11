import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// Supports VAPID Web Push (browser) and direct APNS (iOS native via Capacitor)
// Android native push requires FCM — not used here; Android falls back to web push.
//
// Env vars:
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT   — web push
//   APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRIVATE_KEY  — iOS push
//   APNS_SANDBOX=true  — set during development (omit or set to false for production)

interface WebPushSubscription {
  endpoint: string;
  p256dh: string;
  auth: string;
}

interface PushPayload {
  title: string;
  body: string;
  url?: string;
  tag?: string;
}

// ── VAPID helpers ─────────────────────────────────────────────────────────────

function base64urlToUint8Array(base64url: string): Uint8Array {
  const padding = "=".repeat((4 - (base64url.length % 4)) % 4);
  const base64 = (base64url + padding).replace(/-/g, "+").replace(/_/g, "/");
  const raw = atob(base64);
  return Uint8Array.from([...raw].map((c) => c.charCodeAt(0)));
}

function uint8ArrayToBase64url(arr: Uint8Array): string {
  return btoa(String.fromCharCode(...arr))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
}

async function importVapidPrivateKey(privKeyBase64url: string): Promise<CryptoKey> {
  const keyData = base64urlToUint8Array(privKeyBase64url);
  try {
    return await crypto.subtle.importKey(
      "pkcs8", keyData, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]
    );
  } catch {
    return await crypto.subtle.importKey(
      "raw", keyData, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]
    );
  }
}

async function buildJwt(
  header: Record<string, string>,
  payload: Record<string, unknown>,
  privateKey: CryptoKey
): Promise<string> {
  const encode = (obj: object) =>
    uint8ArrayToBase64url(new TextEncoder().encode(JSON.stringify(obj)));
  const unsigned = `${encode(header)}.${encode(payload)}`;
  const sig = await crypto.subtle.sign(
    { name: "ECDSA", hash: { name: "SHA-256" } },
    privateKey,
    new TextEncoder().encode(unsigned)
  );
  return `${unsigned}.${uint8ArrayToBase64url(new Uint8Array(sig))}`;
}

async function sendWebPush(
  sub: WebPushSubscription,
  payload: PushPayload,
  vapidPublicKey: string,
  vapidPrivateKey: string,
  vapidSubject: string
): Promise<{ ok: boolean; status?: number }> {
  const url = new URL(sub.endpoint);
  const audience = `${url.protocol}//${url.host}`;
  const privKey = await importVapidPrivateKey(vapidPrivateKey);
  const now = Math.floor(Date.now() / 1000);
  const jwt = await buildJwt(
    { typ: "JWT", alg: "ES256" },
    { aud: audience, exp: now + 12 * 3600, sub: vapidSubject },
    privKey
  );
  const resp = await fetch(sub.endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "TTL": "86400",
      "Authorization": `vapid t=${jwt},k=${vapidPublicKey}`,
    },
    body: JSON.stringify(payload),
  });
  return { ok: resp.ok, status: resp.status };
}

// ── APNS direct HTTP/2 (iOS) ──────────────────────────────────────────────────

async function importApnsPrivateKey(pemOrBase64: string): Promise<CryptoKey> {
  // Accept raw PEM or bare base64 (p8 file content without headers)
  const b64 = pemOrBase64
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/-----BEGIN EC PRIVATE KEY-----/g, "")
    .replace(/-----END EC PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const keyData = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );
}

async function sendApnsPush(
  deviceToken: string,
  payload: PushPayload,
  keyId: string,
  teamId: string,
  bundleId: string,
  apnsPrivateKey: string,
  sandbox: boolean
): Promise<{ ok: boolean; status?: number }> {
  const privKey = await importApnsPrivateKey(apnsPrivateKey);
  const now = Math.floor(Date.now() / 1000);
  const jwt = await buildJwt(
    { alg: "ES256", kid: keyId },
    { iss: teamId, iat: now },
    privKey
  );

  const host = sandbox
    ? "api.sandbox.push.apple.com"
    : "api.push.apple.com";

  const apnsPayload = {
    aps: {
      alert: { title: payload.title, body: payload.body },
      sound: "default",
      badge: 1,
    },
    url: payload.url ?? "",
    tag: payload.tag ?? "",
  };

  const resp = await fetch(`https://${host}/3/device/${deviceToken}`, {
    method: "POST",
    headers: {
      "authorization": `bearer ${jwt}`,
      "apns-topic": bundleId,
      "apns-push-type": "alert",
      "content-type": "application/json",
    },
    body: JSON.stringify(apnsPayload),
  });

  return { ok: resp.ok, status: resp.status };
}

// ── Handler ───────────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { user_id, title, body, url, tag } = await req.json();

    if (!user_id || !title) {
      return new Response(JSON.stringify({ error: "user_id and title required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const vapidPublicKey = Deno.env.get("VAPID_PUBLIC_KEY");
    const vapidPrivateKey = Deno.env.get("VAPID_PRIVATE_KEY");
    const vapidSubject = Deno.env.get("VAPID_SUBJECT") ?? "mailto:hello@barfliz.com";

    const apnsKeyId = Deno.env.get("APNS_KEY_ID");
    const apnsTeamId = Deno.env.get("APNS_TEAM_ID");
    const apnsBundleId = Deno.env.get("APNS_BUNDLE_ID") ?? "com.barfliz.app";
    const apnsPrivateKey = Deno.env.get("APNS_PRIVATE_KEY");
    const apnsSandbox = Deno.env.get("APNS_SANDBOX") === "true";

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: subs, error } = await supabase
      .from("push_subscriptions")
      .select("endpoint, p256dh, auth, native_token, platform")
      .eq("user_id", user_id);

    if (error || !subs?.length) {
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const payload: PushPayload = { title, body: body ?? "", url, tag };
    const webSubs = subs.filter((s) => s.platform === "web" && s.endpoint && s.p256dh && s.auth);
    const iosSubs = subs.filter((s) => s.platform === "ios" && s.native_token);
    // Android native push requires FCM — skipped

    let sent = 0;
    const staleEndpoints: string[] = [];

    // Web push (VAPID)
    if (vapidPublicKey && vapidPrivateKey && webSubs.length) {
      const results = await Promise.allSettled(
        webSubs.map((s) =>
          sendWebPush(s as WebPushSubscription, payload, vapidPublicKey, vapidPrivateKey, vapidSubject)
        )
      );
      results.forEach((r, i) => {
        if (r.status === "fulfilled") {
          if (r.value.ok) sent++;
          if (r.value.status === 404 || r.value.status === 410) {
            staleEndpoints.push(webSubs[i].endpoint);
          }
        }
      });
    }

    // iOS direct APNS
    if (apnsKeyId && apnsTeamId && apnsPrivateKey && iosSubs.length) {
      const results = await Promise.allSettled(
        iosSubs.map((s) =>
          sendApnsPush(s.native_token, payload, apnsKeyId, apnsTeamId, apnsBundleId, apnsPrivateKey, apnsSandbox)
        )
      );
      results.forEach((r) => {
        if (r.status === "fulfilled" && r.value.ok) sent++;
      });
    }

    // Clean up stale web subscriptions
    if (staleEndpoints.length) {
      await supabase.from("push_subscriptions").delete().in("endpoint", staleEndpoints);
    }

    return new Response(JSON.stringify({ sent }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
