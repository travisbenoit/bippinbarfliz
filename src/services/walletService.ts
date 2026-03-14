/**
 * Wallet Service — the ONLY layer that touches Solana RPC and Privy SDK.
 *
 * One-Way Model: Components never import @solana/web3.js or @privy-io directly.
 * All blockchain reads/writes flow through this service.
 */

import { Connection, PublicKey, Transaction } from '@solana/web3.js';
import { getAssociatedTokenAddressSync, getAccount } from '@solana/spl-token';
import {
  SOLANA_RPC_URL,
  LUSH_MINT_ADDRESS,
  USDC_MINT_ADDRESS,
  LUSH_DECIMALS,
  USDC_DECIMALS,
} from './tokenConfig';

export interface WalletBalances {
  usdc: number;
  lush: number;
}

let connection: Connection | null = null;

function getConnection(): Connection {
  if (!connection) {
    connection = new Connection(SOLANA_RPC_URL, 'confirmed');
  }
  return connection;
}

/**
 * Fetch SPL token balance for a given wallet and mint.
 * Returns 0 if the token account doesn't exist.
 */
async function getSplBalance(
  walletAddress: string,
  mintAddress: string,
  decimals: number,
): Promise<number> {
  if (!walletAddress || !mintAddress) return 0;

  try {
    const conn = getConnection();
    const wallet = new PublicKey(walletAddress);
    const mint = new PublicKey(mintAddress);
    const ata = getAssociatedTokenAddressSync(mint, wallet);
    const account = await getAccount(conn, ata);
    return Number(account.amount) / 10 ** decimals;
  } catch {
    // Token account doesn't exist yet — balance is 0
    return 0;
  }
}

/**
 * Get all token balances for a wallet address.
 */
export async function getBalances(walletAddress: string): Promise<WalletBalances> {
  const [lush, usdc] = await Promise.all([
    getSplBalance(walletAddress, LUSH_MINT_ADDRESS, LUSH_DECIMALS),
    getSplBalance(walletAddress, USDC_MINT_ADDRESS, USDC_DECIMALS),
  ]);
  return { lush, usdc };
}

/**
 * Build a serialized transaction for signing by Privy.
 * This is used by the WalletProvider to sign + send transactions.
 */
export function buildConnection(): Connection {
  return getConnection();
}

/**
 * Submit a signed transaction to Solana and wait for confirmation.
 */
export async function sendSignedTransaction(signedTx: Transaction): Promise<string> {
  const conn = getConnection();
  const serialized = signedTx.serialize();
  const signature = await conn.sendRawTransaction(serialized, {
    skipPreflight: false,
    preflightCommitment: 'confirmed',
  });
  await conn.confirmTransaction(signature, 'confirmed');
  return signature;
}
