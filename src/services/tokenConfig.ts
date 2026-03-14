/**
 * Solana token configuration — mint addresses and constants.
 * All values read from environment; empty string when not configured.
 */

/** LUSH token mint address (SPL, decimals: 0) */
export const LUSH_MINT_ADDRESS = import.meta.env.VITE_LUSH_MINT_ADDRESS || '';

/** USDC mint address on Solana (SPL, decimals: 6) */
export const USDC_MINT_ADDRESS =
  import.meta.env.VITE_USDC_MINT_ADDRESS || 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';

/** Solana RPC endpoint */
export const SOLANA_RPC_URL =
  import.meta.env.VITE_SOLANA_RPC_URL || 'https://api.devnet.solana.com';

/** Network: 'devnet' | 'mainnet-beta' */
export const SOLANA_NETWORK = import.meta.env.VITE_SOLANA_NETWORK || 'devnet';

/** LUSH token has 0 decimals (whole coins, matches existing integer system) */
export const LUSH_DECIMALS = 0;

/** USDC has 6 decimals */
export const USDC_DECIMALS = 6;
