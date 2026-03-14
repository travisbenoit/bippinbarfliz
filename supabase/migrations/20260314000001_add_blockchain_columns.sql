-- Add blockchain-related columns for Solana integration (v1.6.0)
-- All columns are nullable — existing rows unaffected.
-- Idempotent: safe to run multiple times.

-- Wallet address on user profile
ALTER TABLE users ADD COLUMN IF NOT EXISTS wallet_address TEXT;

-- Transaction signature (Solana tx hash) on payment records
ALTER TABLE payment_transactions ADD COLUMN IF NOT EXISTS tx_signature TEXT;
ALTER TABLE payment_transactions ADD COLUMN IF NOT EXISTS token_mint TEXT;

-- Transaction signature on gift records
ALTER TABLE user_gifts ADD COLUMN IF NOT EXISTS tx_signature TEXT;
