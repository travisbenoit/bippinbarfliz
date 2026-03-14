import type { PrivyClientConfig } from '@privy-io/react-auth';

export const PRIVY_APP_ID = import.meta.env.VITE_PRIVY_APP_ID || '';

export const privyConfig: PrivyClientConfig = {
  loginMethods: ['sms', 'email'],
  appearance: {
    theme: 'dark',
    accentColor: '#E91E63',
    showWalletLoginFirst: false,
  },
  embeddedWallets: {
    createOnLogin: 'all-users',
  },
};
