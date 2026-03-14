/**
 * Lush Coin Service — on-chain mint/burn operations via Edge Functions.
 *
 * One-Way Model: This service is the sole bridge between the app and
 * the Lush Coin SPL token. Components never call this directly —
 * they go through xpService.earnCoins/spendCoins which delegates here
 * when CRYPTO_ENABLED is true.
 */

import { supabase } from '../lib/supabase';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;

interface MintResponse {
  success: boolean;
  tx_signature?: string;
  new_balance?: number;
  error?: string;
}

interface BurnResponse {
  success: boolean;
  tx_signature?: string;
  new_balance?: number;
  error?: string;
}

/**
 * Request the server to mint LUSH tokens to a user's wallet.
 * Called by xpService.earnCoins when CRYPTO_ENABLED.
 */
export async function mintLushCoins(
  userId: string,
  amount: number,
  event: string,
): Promise<MintResponse> {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return { success: false, error: 'Not authenticated' };

  const response = await fetch(`${SUPABASE_URL}/functions/v1/mint-lush-coins`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${session.access_token}`,
    },
    body: JSON.stringify({ user_id: userId, amount, event }),
  });

  if (!response.ok) {
    const text = await response.text();
    return { success: false, error: text || `HTTP ${response.status}` };
  }

  return await response.json();
}

/**
 * Request the server to burn LUSH tokens from a user's wallet.
 * Called by xpService.spendCoins when CRYPTO_ENABLED.
 */
export async function burnLushCoins(
  userId: string,
  amount: number,
  itemId?: string,
): Promise<BurnResponse> {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return { success: false, error: 'Not authenticated' };

  const response = await fetch(`${SUPABASE_URL}/functions/v1/burn-lush-coins`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${session.access_token}`,
    },
    body: JSON.stringify({ user_id: userId, amount, item_id: itemId }),
  });

  if (!response.ok) {
    const text = await response.text();
    return { success: false, error: text || `HTTP ${response.status}` };
  }

  return await response.json();
}
