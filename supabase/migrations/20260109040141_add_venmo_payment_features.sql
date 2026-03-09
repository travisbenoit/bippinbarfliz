/*
  # Add Venmo Payment Features

  1. Changes to Users Table
    - `venmo_username` (text, nullable) - User's Venmo username
    - `venmo_linked` (boolean, default false) - Whether Venmo account is linked
    - `lush_coin_balance` (numeric, default 0) - Virtual currency balance
  
  2. Changes to Payment Transactions Table
    - `transaction_type` (text) - Type: drink_request, drink_payment, transfer, etc.
    - `description` (text, nullable) - Transaction description/note
    - `drink_name` (text, nullable) - Name of drink if applicable
  
  3. Security
    - Ensure existing RLS policies cover new columns
    - Users can only view their own Venmo info
*/

-- Add Venmo and payment columns to users table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'venmo_username'
  ) THEN
    ALTER TABLE users ADD COLUMN venmo_username text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'venmo_linked'
  ) THEN
    ALTER TABLE users ADD COLUMN venmo_linked boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'lush_coin_balance'
  ) THEN
    ALTER TABLE users ADD COLUMN lush_coin_balance numeric DEFAULT 0;
  END IF;
END $$;

-- Add transaction details to payment_transactions table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'payment_transactions' AND column_name = 'transaction_type'
  ) THEN
    ALTER TABLE payment_transactions ADD COLUMN transaction_type text DEFAULT 'transfer' 
      CHECK (transaction_type IN ('drink_request', 'drink_payment', 'transfer', 'gift', 'split_tab'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'payment_transactions' AND column_name = 'description'
  ) THEN
    ALTER TABLE payment_transactions ADD COLUMN description text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'payment_transactions' AND column_name = 'drink_name'
  ) THEN
    ALTER TABLE payment_transactions ADD COLUMN drink_name text;
  END IF;
END $$;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_payment_transactions_from_user ON payment_transactions(from_user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_to_user ON payment_transactions(to_user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_type ON payment_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_created ON payment_transactions(created_at DESC);
