/**
 * WalletProvider — React Context providing wallet state to the entire app.
 *
 * When @privy-io/react-auth / @solana/web3.js are not installed (CRYPTO_ENABLED=false),
 * this provider is a no-op stub. Install the optional packages and set
 * VITE_CRYPTO_ENABLED=true to activate on-chain features.
 */

import { createContext, useCallback, useEffect, useState, type ReactNode } from 'react';
import { supabase } from '../lib/supabase';

export interface WalletBalances {
  usdc: number;
  lush: number;
}

export interface WalletState {
  address: string | null;
  balances: WalletBalances;
  loading: boolean;
  error: string | null;
}

export interface WalletContextValue extends WalletState {
  refreshBalances: () => Promise<void>;
  signAndSendTransaction: (tx: unknown) => Promise<string>;
}

const defaultState: WalletContextValue = {
  address: null,
  balances: { usdc: 0, lush: 0 },
  loading: false,
  error: null,
  refreshBalances: async () => {},
  signAndSendTransaction: async () => { throw new Error('Crypto not enabled'); },
};

export const WalletContext = createContext<WalletContextValue>(defaultState);

// Dynamically load optional packages at runtime so the build doesn't fail when absent
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let privyHooks: any = null;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let solanaWeb3: any = null;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let walletServiceModule: any = null;

try {
  // String split prevents Vite's static scanner from trying to resolve optional packages
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  privyHooks = require('@privy-io' + '/react-auth');
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  solanaWeb3 = require('@solana' + '/web3.js');
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  walletServiceModule = require('../services/walletService');
} catch {
  // Optional crypto packages not installed — no-op mode
}

function WalletProviderWithPrivy({ children }: { children: ReactNode }) {
  const { usePrivy, useWallets } = privyHooks;
  const [state, setState] = useState<WalletState>({
    address: null,
    balances: { usdc: 0, lush: 0 },
    loading: true,
    error: null,
  });

  const { ready, authenticated, user } = usePrivy();
  const { wallets } = useWallets();

  useEffect(() => {
    if (!ready || !authenticated || wallets.length === 0) {
      setState((s) => ({ ...s, loading: !ready, address: null }));
      return;
    }
    const embedded = wallets.find((w: { walletClientType: string }) => w.walletClientType === 'privy');
    const address = embedded?.address ?? wallets[0]?.address ?? null;
    setState((s) => ({ ...s, address, loading: false }));
    if (address && user?.id) {
      supabase.from('users').update({ wallet_address: address }).eq('id', user.id).then(() => {});
    }
  }, [ready, authenticated, wallets, user?.id]);

  useEffect(() => {
    if (!state.address || !walletServiceModule) return;
    let cancelled = false;
    const fetchBalances = async () => {
      try {
        const balances = await walletServiceModule.getBalances(state.address);
        if (!cancelled) setState((s) => ({ ...s, balances, error: null }));
      } catch (err) {
        if (!cancelled) setState((s) => ({ ...s, error: (err as Error).message }));
      }
    };
    fetchBalances();
    const interval = setInterval(fetchBalances, 30_000);
    return () => { cancelled = true; clearInterval(interval); };
  }, [state.address]);

  const refreshBalances = useCallback(async () => {
    if (!state.address || !walletServiceModule) return;
    try {
      const balances = await walletServiceModule.getBalances(state.address);
      setState((s) => ({ ...s, balances, error: null }));
    } catch (err) {
      setState((s) => ({ ...s, error: (err as Error).message }));
    }
  }, [state.address]);

  const signAndSendTransaction = useCallback(async (tx: unknown): Promise<string> => {
    if (!solanaWeb3 || !walletServiceModule) throw new Error('Crypto packages not installed');
    const embedded = wallets.find((w: { walletClientType: string }) => w.walletClientType === 'privy');
    if (!embedded) throw new Error('No embedded wallet available');
    const conn = walletServiceModule.buildConnection();
    const { blockhash } = await conn.getLatestBlockhash('confirmed');
    const transaction = tx as { recentBlockhash: string; feePayer: unknown; serialize: (o: unknown) => Uint8Array };
    transaction.recentBlockhash = blockhash;
    transaction.feePayer = new solanaWeb3.PublicKey(embedded.address);
    const serialized = transaction.serialize({ requireAllSignatures: false });
    const signature = await conn.sendRawTransaction(serialized, { skipPreflight: false, preflightCommitment: 'confirmed' });
    await conn.confirmTransaction(signature, 'confirmed');
    await refreshBalances();
    return signature;
  }, [wallets, refreshBalances]);

  return (
    <WalletContext.Provider value={{ ...state, refreshBalances, signAndSendTransaction }}>
      {children}
    </WalletContext.Provider>
  );
}

export function WalletProvider({ children }: { children: ReactNode }) {
  if (privyHooks) {
    return <WalletProviderWithPrivy>{children}</WalletProviderWithPrivy>;
  }
  return (
    <WalletContext.Provider value={defaultState}>
      {children}
    </WalletContext.Provider>
  );
}
