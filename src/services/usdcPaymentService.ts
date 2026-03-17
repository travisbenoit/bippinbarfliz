/**
 * USDC Payment Service — handles USDC transfers on Solana.
 *
 * One-Way Model: Only this service touches SPL token transfer logic.
 * Components call this through action handlers, never directly.
 *
 * Solana packages are optional — imported dynamically to avoid build errors
 * when @solana/web3.js and @solana/spl-token are not installed.
 */

import { USDC_MINT_ADDRESS, USDC_DECIMALS, SOLANA_RPC_URL } from './tokenConfig';
import { supabase } from '../lib/supabase';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;

interface PaymentResult {
  success: boolean;
  tx_signature?: string;
  error?: string;
}

/**
 * Build a USDC transfer transaction (unsigned).
 * The caller (WalletProvider.signAndSendTransaction) handles signing.
 */
export async function buildUSDCTransferTx(
  fromAddress: string,
  toAddress: string,
  amountUSD: number,
): Promise<unknown> {
  const { PublicKey, Transaction, Connection } = await import(/* @vite-ignore */ '@solana/web3.js');
  const {
    createTransferInstruction,
    getAssociatedTokenAddressSync,
    createAssociatedTokenAccountInstruction,
    getAccount,
  } = await import(/* @vite-ignore */ '@solana/spl-token');

  const connection = new Connection(SOLANA_RPC_URL, 'confirmed');
  const mint = new PublicKey(USDC_MINT_ADDRESS);
  const sender = new PublicKey(fromAddress);
  const recipient = new PublicKey(toAddress);

  const senderAta = getAssociatedTokenAddressSync(mint, sender);
  const recipientAta = getAssociatedTokenAddressSync(mint, recipient);

  const tx = new Transaction();

  try {
    await getAccount(connection, recipientAta);
  } catch {
    tx.add(createAssociatedTokenAccountInstruction(sender, recipientAta, recipient, mint));
  }

  const rawAmount = Math.round(amountUSD * 10 ** USDC_DECIMALS);

  tx.add(
    createTransferInstruction(senderAta, recipientAta, sender, rawAmount),
  );

  return tx;
}

/**
 * Verify a USDC payment on-chain and record in payment_transactions.
 */
export async function verifyAndRecordPayment(
  txSignature: string,
  fromUserId: string,
  toUserId: string,
  amount: number,
  description?: string,
): Promise<PaymentResult> {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return { success: false, error: 'Not authenticated' };

  const response = await fetch(`${SUPABASE_URL}/functions/v1/verify-payment`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${session.access_token}`,
    },
    body: JSON.stringify({
      tx_signature: txSignature,
      from_user_id: fromUserId,
      to_user_id: toUserId,
      amount,
      currency: 'USDC',
      description,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    return { success: false, error: text || `HTTP ${response.status}` };
  }

  return await response.json();
}
