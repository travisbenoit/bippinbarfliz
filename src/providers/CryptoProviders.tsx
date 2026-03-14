/**
 * CryptoProviders — bundles PrivyProvider + WalletProvider.
 * Only loaded when CRYPTO_ENABLED is true (lazy import in main.tsx).
 */

import type { ReactNode } from 'react';
import { PrivyProvider } from '@privy-io/react-auth';
import { PRIVY_APP_ID, privyConfig } from '../lib/privy';
import { WalletProvider } from './WalletProvider';

export function CryptoProviders({ children }: { children: ReactNode }) {
  return (
    <PrivyProvider appId={PRIVY_APP_ID} config={privyConfig}>
      <WalletProvider>{children}</WalletProvider>
    </PrivyProvider>
  );
}
