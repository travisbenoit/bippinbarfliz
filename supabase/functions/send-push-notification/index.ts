import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// VAPID-signed Web Push using the Web Crypto API (no npm:web-push needed in Deno)
// Env vars required: VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT

interface PushSubscription {
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

// Convert base64url string to Uint8Array
function base64urlToUint8Array(base64url: string): Uint8Array {
  const padding = "=".repeat((4 - (base64url.length % 4)) % 4);
  const base64 = (base64url + padding).replace(/-/g, "+").replace(/_/g, "/");
  const raw = atob(base64);
  return Uint8Array.from([...raw].map((c) => c.charCodeAt(0)));
}

// Convert Uint8Array to base64url string
function uint8ArrayToBase64url(arr: Uint8Array): string {
  return btoa(String.fromCharCode(...arr))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
}

async function importVapidPrivateKey(privKeyBase64url: string): Promise<CryptoKey> {
  const keyData = base64urlToUint8Array(privKeyBase64url);
  return crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );
}

async function buildVapidJwt(subject: string, audience: string, publicKeyBase64url: string, privateKey: CryptoKey): Promise<string> {
  const header = { typ: "JWT", alg: "ES256" };
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    aud: audience,
    exp: now + 12 * 3600,
    sub: subject,
  };

  const encode = (obj: object) =>
    uint8ArrayToBase64url(new TextEncoder().encode(JSON.stringify(obj)));

  const unsignedToken = `${encode(header)}.${encode(payload)}`;
  const sig = await crypto.subtle.sign(
    { name: "ECDSA", hash: { name: "SHA-256" } },
    privateKey,
    new TextEncoder().encode(unsignedToken)
  );

  return `${unsignedToken}.${uint8ArrayToBase64url(new Uint8Array(sig))}`;
}

async function sendPush(sub: PushSubscription, payload: PushPayload, vapidPublicKey: string, vapidPrivateKey: string, vapidSubject: string): Promise<{ ok: boolean; status?: number }> {
  const url = new URL(sub.endpoint);
  const audience = `${url.protocol}//${url.host}`;

  let privKey: CryptoKey;
  try {
    privKey = await importVapidPrivateKey(vapidPrivateKey);
  } catch {
    // If pkcs8 fails, try raw format
    const rawKey = base64urlToUint8Array(vapidPrivateKey);
    privKey = await crypto.subtle.importKey(
      "raw",
      rawKey,
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["sign"]
    );
  }

  const jwt = await buildVapidJwt(vapidSubject, audience, vapidPublicKey, privKey);

  const body = JSON.stringify(payload);
  const resp = await fetch(sub.endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "TTL": "86400",
      "Authorization": `vapid t=${jwt},k=${vapidPublicKey}`,
    },
    body,
  });

  return { ok: resp.ok, status: resp.status };
}

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

    if (!vapidPublicKey || !vapidPrivateKey) {
      return new Response(JSON.stringify({ error: "VAPID keys not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: subs, error } = await supabase
      .from("push_subscriptions")
      .select("endpoint, p256dh, auth")
      .eq("user_id", user_id);

    if (error || !subs?.length) {
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const payload: PushPayload = { title, body: body ?? "", url, tag };

    const results = await Promise.allSettled(
      subs.map((sub) =>
        sendPush(sub as PushSubscription, payload, vapidPublicKey, vapidPrivateKey, vapidSubject)
      )
    );

    // Remove subscriptions that returned 404 or 410 (no longer valid)
    const staleEndpoints: string[] = [];
    results.forEach((result, i) => {
      if (result.status === "fulfilled" && (result.value.status === 404 || result.value.status === 410)) {
        staleEndpoints.push(subs[i].endpoint);
      }
    });
    if (staleEndpoints.length) {
      await supabase.from("push_subscriptions").delete().in("endpoint", staleEndpoints);
    }

    const sent = results.filter((r) => r.status === "fulfilled" && r.value.ok).length;
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
