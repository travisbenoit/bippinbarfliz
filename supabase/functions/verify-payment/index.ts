import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { Connection } from "npm:@solana/web3.js@1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

/**
 * Verify a USDC payment on Solana and record it in payment_transactions.
 *
 * Body: {
 *   tx_signature: string,
 *   from_user_id: string,
 *   to_user_id: string,
 *   amount: number,
 *   currency: string,
 *   description?: string
 * }
 */
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ success: false, error: "Missing auth" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ success: false, error: "Invalid token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { tx_signature, from_user_id, to_user_id, amount, currency, description } = await req.json();

    // Verify caller is the sender
    if (from_user_id !== user.id) {
      return new Response(JSON.stringify({ success: false, error: "Unauthorized" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!tx_signature || !to_user_id || !amount) {
      return new Response(JSON.stringify({ success: false, error: "Missing fields" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify the transaction on Solana
    const rpcUrl = Deno.env.get("SOLANA_RPC_URL") || "https://api.devnet.solana.com";
    const connection = new Connection(rpcUrl, "confirmed");

    const txInfo = await connection.getTransaction(tx_signature, {
      commitment: "confirmed",
      maxSupportedTransactionVersion: 0,
    });

    if (!txInfo) {
      return new Response(JSON.stringify({ success: false, error: "Transaction not found on chain" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (txInfo.meta?.err) {
      return new Response(JSON.stringify({ success: false, error: "Transaction failed on chain" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Check for duplicate
    const { data: existing } = await supabase
      .from("payment_transactions")
      .select("id")
      .eq("tx_signature", tx_signature)
      .maybeSingle();

    if (existing) {
      return new Response(JSON.stringify({ success: true, duplicate: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Record the verified payment
    const { error: insertError } = await supabase.from("payment_transactions").insert({
      from_user_id,
      to_user_id,
      amount,
      currency: currency || "USDC",
      status: "completed",
      tx_signature,
      token_mint: currency === "USDC" ? "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" : null,
      transaction_type: "drink_payment",
      description: description || "USDC payment",
    });

    if (insertError) {
      console.error("Insert error:", insertError);
      return new Response(JSON.stringify({ success: false, error: "Failed to record payment" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({ success: true, tx_signature }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("verify-payment error:", err);
    return new Response(
      JSON.stringify({ success: false, error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
