/**
 * CryptoProviders — bundles PrivyProvider + WalletProvider.
 * Only loaded when CRYPTO_ENABLED is true (lazy import in main.tsx).
 * When @privy-io/react-auth is not installed this falls back to a passthrough.
 */

import type { ReactNode } from 'react';
import { WalletProvider } from './WalletProvider';

let PrivyProvider: React.ComponentType<{ appId: string; config: unknown; children: ReactNode }> | null = null;
let PRIVY_APP_ID = '';
let privyConfig: unknown = {};

try {
  // String split prevents Vite's static scanner from trying to resolve optional packages
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const privy = require('@privy-io' + '/react-auth');
  PrivyProvider = privy.PrivyProvider;
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const cfg = require('../lib/privy');
  PRIVY_APP_ID = cfg.PRIVY_APP_ID;
  privyConfig = cfg.privyConfig;
} catch {
  // Package not installed — crypto features disabled at runtime
}

export function CryptoProviders({ children }: { children: ReactNode }) {
  if (PrivyProvider && PRIVY_APP_ID) {
    return (
      <PrivyProvider appId={PRIVY_APP_ID} config={privyConfig}>
        <WalletProvider>{children}</WalletProvider>
      </PrivyProvider>
    );
  }
  return <WalletProvider>{children}</WalletProvider>;
}
