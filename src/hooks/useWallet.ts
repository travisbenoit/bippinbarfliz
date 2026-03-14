import { useContext } from 'react';
import { WalletContext, type WalletContextValue } from '../providers/WalletProvider';

/**
 * Read wallet state and actions from WalletProvider.
 * Components use this hook instead of importing Solana/Privy directly.
 */
export function useWallet(): WalletContextValue {
  return useContext(WalletContext);
}
