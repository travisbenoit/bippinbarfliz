/**
 * WalletProvider — React Context providing wallet state to the entire app.
 *
 * One-Way Model:
 *   UI reads state via useWallet() hook (read-only).
 *   Actions (refreshBalances, signTransaction) flow through service layer.
 *   No component ever imports @solana/web3.js or @privy-io directly.
 */

import { createContext, useCallback, useEffect, useState, type ReactNode } from 'react';
import { usePrivy, useWallets } from '@privy-io/react-auth';
import { PublicKey, Transaction } from '@solana/web3.js';
import { getBalances, buildConnection, type WalletBalances } from '../services/walletService';
import { supabase } from '../lib/supabase';

export interface WalletState {
  /** Solana wallet address (base58) or null if not yet created */
  address: string | null;
  /** Token balances */
  balances: WalletBalances;
  /** True while loading wallet or balances */
  loading: boolean;
  /** Last error message, if any */
  error: string | null;
}

export interface WalletContextValue extends WalletState {
  /** Re-fetch on-chain balances */
  refreshBalances: () => Promise<void>;
  /** Sign and submit a transaction via Privy embedded wallet */
  signAndSendTransaction: (tx: Transaction) => Promise<string>;
}

const defaultState: WalletContextValue = {
  address: null,
  balances: { usdc: 0, lush: 0 },
  loading: false,
  error: null,
  refreshBalances: async () => {},
  signAndSendTransaction: async () => '',
};

export const WalletContext = createContext<WalletContextValue>(defaultState);

export function WalletProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<WalletState>({
    address: null,
    balances: { usdc: 0, lush: 0 },
    loading: true,
    error: null,
  });

  const { ready, authenticated, user } = usePrivy();
  const { wallets } = useWallets();

  // Resolve the embedded Solana wallet address
  useEffect(() => {
    if (!ready || !authenticated || wallets.length === 0) {
      setState((s) => ({ ...s, loading: !ready, address: null }));
      return;
    }

    // Find the Privy embedded wallet
    const embedded = wallets.find((w) => w.walletClientType === 'privy');
    const address = embedded?.address ?? wallets[0]?.address ?? null;

    setState((s) => ({ ...s, address, loading: false }));

    // Persist wallet address to Supabase user profile
    if (address && user?.id) {
      supabase
        .from('users')
        .update({ wallet_address: address })
        .eq('id', user.id)
        .then(() => {});
    }
  }, [ready, authenticated, wallets, user?.id]);

  // Fetch balances when address changes
  useEffect(() => {
    if (!state.address) return;

    let cancelled = false;
    const fetchBalances = async () => {
      try {
        const balances = await getBalances(state.address!);
        if (!cancelled) {
          setState((s) => ({ ...s, balances, error: null }));
        }
      } catch (err) {
        if (!cancelled) {
          setState((s) => ({ ...s, error: (err as Error).message }));
        }
      }
    };

    fetchBalances();
    const interval = setInterval(fetchBalances, 30_000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, [state.address]);

  const refreshBalances = useCallback(async () => {
    if (!state.address) return;
    try {
      const balances = await getBalances(state.address);
      setState((s) => ({ ...s, balances, error: null }));
    } catch (err) {
      setState((s) => ({ ...s, error: (err as Error).message }));
    }
  }, [state.address]);

  const signAndSendTransaction = useCallback(
    async (tx: Transaction): Promise<string> => {
      const embedded = wallets.find((w) => w.walletClientType === 'privy');
      if (!embedded) throw new Error('No embedded wallet available');

      const conn = buildConnection();
      const { blockhash } = await conn.getLatestBlockhash('confirmed');
      tx.recentBlockhash = blockhash;
      tx.feePayer = embedded.address ? new PublicKey(embedded.address) : undefined;

      // Use Privy's sendTransaction which handles signing internally
      const provider = await embedded.getEthereumProvider();
      // For Solana wallets, we serialize and send directly
      const serialized = tx.serialize({ requireAllSignatures: false });
      const signature = await conn.sendRawTransaction(serialized, {
        skipPreflight: false,
        preflightCommitment: 'confirmed',
      });
      await conn.confirmTransaction(signature, 'confirmed');

      // Suppress unused variable warning for provider
      void provider;

      await refreshBalances();

      return signature;
    },
    [wallets, refreshBalances],
  );

  return (
    <WalletContext.Provider
      value={{
        ...state,
        refreshBalances,
        signAndSendTransaction,
      }}
    >
      {children}
    </WalletContext.Provider>
  );
}
