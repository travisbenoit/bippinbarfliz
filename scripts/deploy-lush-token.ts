/**
 * Deploy the LUSH SPL Token on Solana.
 *
 * Usage:
 *   npx tsx scripts/deploy-lush-token.ts
 *
 * Prerequisites:
 *   - Set SOLANA_RPC_URL env var (or defaults to devnet)
 *   - A funded Solana keypair at ./mint-authority.json
 *     (generate with: solana-keygen new -o mint-authority.json)
 *
 * This script:
 *   1. Creates a new SPL token with 0 decimals (whole coins)
 *   2. Outputs the mint address to add to .env as VITE_LUSH_MINT_ADDRESS
 *   3. The mint authority is the keypair used — store its secret key
 *      as MINT_AUTHORITY_KEYPAIR in Supabase secrets (JSON array format)
 */

import { Connection, Keypair, clusterApiUrl } from '@solana/web3.js';
import { createMint } from '@solana/spl-token';
import { readFileSync, existsSync } from 'fs';

const RPC_URL = process.env.SOLANA_RPC_URL || clusterApiUrl('devnet');
const KEYPAIR_PATH = process.env.KEYPAIR_PATH || './mint-authority.json';

async function main() {
  console.log('Deploying LUSH Token...');
  console.log(`RPC: ${RPC_URL}`);

  // Load or generate keypair
  let mintAuthority: Keypair;
  if (existsSync(KEYPAIR_PATH)) {
    const raw = JSON.parse(readFileSync(KEYPAIR_PATH, 'utf-8'));
    mintAuthority = Keypair.fromSecretKey(Uint8Array.from(raw));
    console.log(`Loaded keypair from ${KEYPAIR_PATH}`);
  } else {
    mintAuthority = Keypair.generate();
    console.log(`Generated new keypair. Save this to ${KEYPAIR_PATH}:`);
    console.log(JSON.stringify(Array.from(mintAuthority.secretKey)));
  }

  console.log(`Mint authority: ${mintAuthority.publicKey.toBase58()}`);

  const connection = new Connection(RPC_URL, 'confirmed');

  // Check balance
  const balance = await connection.getBalance(mintAuthority.publicKey);
  console.log(`Balance: ${balance / 1e9} SOL`);

  if (balance < 0.02 * 1e9) {
    console.log('\nInsufficient SOL. Fund this wallet:');
    console.log(`  Address: ${mintAuthority.publicKey.toBase58()}`);
    if (RPC_URL.includes('devnet')) {
      console.log('  Airdrop: solana airdrop 1 --url devnet');
    }
    process.exit(1);
  }

  // Create the token with 0 decimals
  const mint = await createMint(
    connection,
    mintAuthority,       // payer
    mintAuthority.publicKey, // mint authority
    null,                // freeze authority (none)
    0,                   // decimals: 0 = whole coins
  );

  console.log('\n=== LUSH Token Deployed ===');
  console.log(`Mint address: ${mint.toBase58()}`);
  console.log(`Decimals: 0`);
  console.log(`Mint authority: ${mintAuthority.publicKey.toBase58()}`);
  console.log('\n--- Add to .env ---');
  console.log(`VITE_LUSH_MINT_ADDRESS=${mint.toBase58()}`);
  console.log('\n--- Add to Supabase secrets ---');
  console.log(`MINT_AUTHORITY_KEYPAIR=${JSON.stringify(Array.from(mintAuthority.secretKey))}`);
  console.log(`LUSH_MINT_ADDRESS=${mint.toBase58()}`);
  console.log(`SOLANA_RPC_URL=${RPC_URL}`);
}

main().catch(console.error);
