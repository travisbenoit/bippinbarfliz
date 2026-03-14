import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { Connection, Keypair, PublicKey, Transaction } from "npm:@solana/web3.js@1";
import { createMintToInstruction, getAssociatedTokenAddressSync, createAssociatedTokenAccountInstruction, getAccount } from "npm:@solana/spl-token@0.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

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

    const { user_id, amount, event } = await req.json();

    if (user_id !== user.id) {
      return new Response(JSON.stringify({ success: false, error: "Unauthorized" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!amount || amount <= 0 || amount > 1000) {
      return new Response(JSON.stringify({ success: false, error: "Invalid amount" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: userData, error: userError } = await supabase
      .from("users")
      .select("wallet_address")
      .eq("id", user_id)
      .single();

    if (userError || !userData?.wallet_address) {
      await supabase.rpc("increment_lush_coins", { p_user_id: user_id, p_amount: amount });
      return new Response(JSON.stringify({ success: true, fallback: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const rpcUrl = Deno.env.get("SOLANA_RPC_URL") || "https://api.devnet.solana.com";
    const mintAuthoritySecret = Deno.env.get("MINT_AUTHORITY_KEYPAIR");
    const lushMintAddress = Deno.env.get("LUSH_MINT_ADDRESS");

    if (!mintAuthoritySecret || !lushMintAddress) {
      await supabase.rpc("increment_lush_coins", { p_user_id: user_id, p_amount: amount });
      return new Response(JSON.stringify({ success: true, fallback: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const connection = new Connection(rpcUrl, "confirmed");
    const mintAuthority = Keypair.fromSecretKey(
      Uint8Array.from(JSON.parse(mintAuthoritySecret)),
    );
    const mint = new PublicKey(lushMintAddress);
    const recipient = new PublicKey(userData.wallet_address);

    const ata = getAssociatedTokenAddressSync(mint, recipient);
    const tx = new Transaction();

    try {
      await getAccount(connection, ata);
    } catch {
      tx.add(
        createAssociatedTokenAccountInstruction(mintAuthority.publicKey, ata, recipient, mint),
      );
    }

    tx.add(createMintToInstruction(mint, ata, mintAuthority.publicKey, amount));

    const { blockhash } = await connection.getLatestBlockhash("confirmed");
    tx.recentBlockhash = blockhash;
    tx.feePayer = mintAuthority.publicKey;

    tx.sign(mintAuthority);
    const signature = await connection.sendRawTransaction(tx.serialize(), {
      skipPreflight: false,
      preflightCommitment: "confirmed",
    });
    await connection.confirmTransaction(signature, "confirmed");

    await supabase.rpc("increment_lush_coins", { p_user_id: user_id, p_amount: amount });

    await supabase.from("event_log").insert({
      event_type: "lush_mint",
      data: { user_id, amount, event, tx_signature: signature },
    });

    return new Response(
      JSON.stringify({ success: true, tx_signature: signature }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("mint-lush-coins error:", err);
    return new Response(
      JSON.stringify({ success: false, error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
