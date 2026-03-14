import { useState, useEffect } from 'react';
import { getPaymentProvider, detectUserRegion } from '../services/regionService';
import { CRYPTO_ENABLED } from '../lib/featureFlags';

export interface PaymentProviderInfo {
  name: 'venmo' | 'beem' | 'crypto';
  displayName: string;
  isVenmo: boolean;
  isBeem: boolean;
  isCrypto: boolean;
  loading: boolean;
  currency: string;
  currencySymbol: string;
}

export function usePaymentProvider(): PaymentProviderInfo {
  const [name, setName] = useState<'venmo' | 'beem' | 'crypto'>('venmo');
  const [currency, setCurrency] = useState('USD');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([getPaymentProvider(), detectUserRegion()]).then(([provider, region]) => {
      setName(provider === 'beem' ? 'beem' : 'venmo');
      setCurrency(region.region === 'au' ? 'AUD' : 'USD');
      setLoading(false);
    });
  }, []);

  const displayName = CRYPTO_ENABLED
    ? `${name === 'beem' ? 'Beem It' : 'Venmo'} + USDC`
    : name === 'beem' ? 'Beem It' : 'Venmo';

  return {
    name,
    displayName,
    isVenmo: name === 'venmo',
    isBeem: name === 'beem',
    isCrypto: CRYPTO_ENABLED,
    loading,
    currency,
    currencySymbol: currency === 'AUD' ? 'A$' : '$',
  };
}
