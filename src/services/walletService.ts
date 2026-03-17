/**
 * Wallet Service — the ONLY layer that touches Solana RPC and Privy SDK.
 *
 * One-Way Model: Components never import @solana/web3.js or @privy-io directly.
 * All blockchain reads/writes flow through this service.
 *
 * Solana packages are loaded dynamically so the build succeeds when they are
 * not installed (CRYPTO_ENABLED=false).
 */

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

// eslint-disable-next-line @typescript-eslint/no-explicit-any
let _connection: any = null;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function getConnection(): Promise<any> {
  if (!_connection) {
    const { Connection } = await import(/* @vite-ignore */ '@solana/web3.js');
    _connection = new Connection(SOLANA_RPC_URL, 'confirmed');
  }
  return _connection;
}

async function getSplBalance(
  walletAddress: string,
  mintAddress: string,
  decimals: number,
): Promise<number> {
  if (!walletAddress || !mintAddress) return 0;

  try {
    const { PublicKey } = await import(/* @vite-ignore */ '@solana/web3.js');
    const { getAssociatedTokenAddressSync, getAccount } = await import(/* @vite-ignore */ '@solana/spl-token');
    const conn = await getConnection();
    const wallet = new PublicKey(walletAddress);
    const mint = new PublicKey(mintAddress);
    const ata = getAssociatedTokenAddressSync(mint, wallet);
    const account = await getAccount(conn, ata);
    return Number(account.amount) / 10 ** decimals;
  } catch {
    return 0;
  }
}

export async function getBalances(walletAddress: string): Promise<WalletBalances> {
  const [lush, usdc] = await Promise.all([
    getSplBalance(walletAddress, LUSH_MINT_ADDRESS, LUSH_DECIMALS),
    getSplBalance(walletAddress, USDC_MINT_ADDRESS, USDC_DECIMALS),
  ]);
  return { lush, usdc };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export async function buildConnection(): Promise<any> {
  return getConnection();
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export async function sendSignedTransaction(signedTx: any): Promise<string> {
  const conn = await getConnection();
  const serialized = signedTx.serialize();
  const signature = await conn.sendRawTransaction(serialized, {
    skipPreflight: false,
    preflightCommitment: 'confirmed',
  });
  await conn.confirmTransaction(signature, 'confirmed');
  return signature;
}
