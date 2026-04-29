import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { isDemoPhone, DEMO_OTP_CODE } from "../_shared/demoNumbers.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const { phone, code, storedOtp } = await req.json();

    if (!phone || !code) {
      return new Response(
        JSON.stringify({ error: "Phone and code are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Demo / App Store reviewer bypass: accept DEMO_OTP_CODE for allowlisted numbers,
    // independent of whatever storedOtp was passed.
    if (isDemoPhone(phone) && code === DEMO_OTP_CODE) {
      console.log(`Demo phone verified (${phone}).`);
      return new Response(
        JSON.stringify({ success: true, status: "approved", demo: true }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!storedOtp) {
      return new Response(
        JSON.stringify({ error: "Phone, code, and storedOtp are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (code === storedOtp) {
      return new Response(
        JSON.stringify({ success: true, status: "approved" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ error: "Invalid verification code" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Error:", err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : "Internal error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
