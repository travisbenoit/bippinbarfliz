import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// Supports both VAPID Web Push (browser) and FCM (iOS/Android native via Capacitor)
// Env vars: VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT, FCM_SERVER_KEY

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
      "pkcs8",
      keyData,
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["sign"]
    );
  } catch {
    return await crypto.subtle.importKey(
      "raw",
      keyData,
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["sign"]
    );
  }
}

async function buildVapidJwt(
  subject: string,
  audience: string,
  vapidPublicKey: string,
  privateKey: CryptoKey
): Promise<string> {
  const header = { typ: "JWT", alg: "ES256" };
  const now = Math.floor(Date.now() / 1000);
  const payload = { aud: audience, exp: now + 12 * 3600, sub: subject };
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
  const jwt = await buildVapidJwt(vapidSubject, audience, vapidPublicKey, privKey);

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

// ── FCM helper (HTTP v1 API) ──────────────────────────────────────────────────

async function sendFcmPush(
  token: string,
  payload: PushPayload,
  fcmServerKey: string
): Promise<{ ok: boolean; status?: number }> {
  // FCM Legacy HTTP API — still widely supported and simpler than v1 OAuth2
  const resp = await fetch("https://fcm.googleapis.com/fcm/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `key=${fcmServerKey}`,
    },
    body: JSON.stringify({
      to: token,
      notification: {
        title: payload.title,
        body: payload.body,
        sound: "default",
        badge: "1",
      },
      data: {
        url: payload.url ?? "",
        tag: payload.tag ?? "",
      },
      priority: "high",
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    }),
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
    const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");

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
    const nativeSubs = subs.filter((s) => (s.platform === "ios" || s.platform === "android") && s.native_token);

    let sent = 0;
    const staleEndpoints: string[] = [];

    // Web push (VAPID)
    if (vapidPublicKey && vapidPrivateKey && webSubs.length) {
      const webResults = await Promise.allSettled(
        webSubs.map((sub) =>
          sendWebPush(
            sub as WebPushSubscription,
            payload,
            vapidPublicKey,
            vapidPrivateKey,
            vapidSubject
          )
        )
      );
      webResults.forEach((result, i) => {
        if (result.status === "fulfilled") {
          if (result.value.ok) sent++;
          if (result.value.status === 404 || result.value.status === 410) {
            staleEndpoints.push(webSubs[i].endpoint);
          }
        }
      });
    }

    // Native push (FCM — covers both iOS via APNS-FCM bridge and Android)
    if (fcmServerKey && nativeSubs.length) {
      const nativeResults = await Promise.allSettled(
        nativeSubs.map((sub) => sendFcmPush(sub.native_token, payload, fcmServerKey))
      );
      nativeResults.forEach((result) => {
        if (result.status === "fulfilled" && result.value.ok) sent++;
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
