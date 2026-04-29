import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { isDemoPhone, DEMO_OTP_CODE } from "../_shared/demoNumbers.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

const TWILIO_ACCOUNT_SID = Deno.env.get("TWILIO_ACCOUNT_SID");
const TWILIO_AUTH_TOKEN = Deno.env.get("TWILIO_AUTH_TOKEN");
const TWILIO_PHONE_NUMBER = Deno.env.get("TWILIO_PHONE_NUMBER");

function generateOTP(): string {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const { phone } = await req.json();

    if (!phone) {
      return new Response(
        JSON.stringify({ error: "Phone number is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Demo / App Store reviewer bypass: skip Twilio, return the static demo code.
    if (isDemoPhone(phone)) {
      console.log(`Demo phone detected (${phone}). Returning static demo OTP, skipping Twilio.`);
      return new Response(
        JSON.stringify({ success: true, otp: DEMO_OTP_CODE, sms_sent: false, demo: true }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const otp = generateOTP();
    const twilioConfigured = !!(TWILIO_ACCOUNT_SID && TWILIO_AUTH_TOKEN && TWILIO_PHONE_NUMBER);
    let smsSent = false;

    if (twilioConfigured) {
      try {
        const credentials = btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`);
        const response = await fetch(
          `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`,
          {
            method: "POST",
            headers: {
              "Authorization": `Basic ${credentials}`,
              "Content-Type": "application/x-www-form-urlencoded",
            },
            body: new URLSearchParams({
              To: phone,
              From: TWILIO_PHONE_NUMBER!,
              Body: `Your Barfliz verification code is: ${otp}`,
            }),
          }
        );

        const data = await response.json();
        if (response.ok) {
          smsSent = true;
          console.log("SMS sent via Twilio:", data.sid);
        } else {
          console.error("Twilio error:", data);
        }
      } catch (smsErr) {
        console.error("Twilio request failed:", smsErr);
      }
    } else {
      console.log("Twilio not configured — OTP generated but SMS skipped:", otp);
    }

    return new Response(
      JSON.stringify({ success: true, otp, sms_sent: smsSent }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Error:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : "Internal error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
