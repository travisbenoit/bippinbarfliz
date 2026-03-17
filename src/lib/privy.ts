export const PRIVY_APP_ID = import.meta.env.VITE_PRIVY_APP_ID || '';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const privyConfig: any = {
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
