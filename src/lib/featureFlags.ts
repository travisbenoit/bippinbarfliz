/**
 * Feature flags — gate experimental features via environment variables.
 * All flags default to OFF (false) when the env var is missing.
 */

/** Enable Solana blockchain integration (Privy wallets, on-chain LUSH, USDC payments) */
export const CRYPTO_ENABLED = import.meta.env.VITE_CRYPTO_ENABLED === 'true';
