import { getPaymentProvider } from './regionService';

export interface PaymentProvider {
  name: string;
  displayName: string;
  setupUrl?: string;
  logoUrl?: string;
  description: string;
}

export const PAYMENT_PROVIDERS: Record<string, PaymentProvider> = {
  venmo: {
    name: 'venmo',
    displayName: 'Venmo',
    description: 'Send and receive money with your Venmo account',
  },
  beem: {
    name: 'beem',
    displayName: 'Beem',
    description: 'Send and receive money with your Beem account',
  },
};

export async function getCurrentPaymentProvider(): Promise<PaymentProvider> {
  const providerName = await getPaymentProvider();
  return PAYMENT_PROVIDERS[providerName] || PAYMENT_PROVIDERS.venmo;
}

export function getPaymentProviderByName(name: string): PaymentProvider {
  return PAYMENT_PROVIDERS[name] || PAYMENT_PROVIDERS.venmo;
}

export function isVenmo(provider: PaymentProvider): boolean {
  return provider.name === 'venmo';
}

export function isBeem(provider: PaymentProvider): boolean {
  return provider.name === 'beem';
}
