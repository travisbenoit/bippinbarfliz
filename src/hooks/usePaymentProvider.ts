import { useState, useEffect } from 'react';
import { getPaymentProvider, detectUserRegion } from '../services/regionService';

export interface PaymentProviderInfo {
  name: 'venmo' | 'beem';
  displayName: string;
  isVenmo: boolean;
  isBeem: boolean;
  loading: boolean;
  currency: string;
  currencySymbol: string;
}

export function usePaymentProvider(): PaymentProviderInfo {
  const [name, setName] = useState<'venmo' | 'beem'>('venmo');
  const [currency, setCurrency] = useState('USD');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([getPaymentProvider(), detectUserRegion()]).then(([provider, region]) => {
      setName(provider === 'beem' ? 'beem' : 'venmo');
      setCurrency(region.region === 'au' ? 'AUD' : 'USD');
      setLoading(false);
    });
  }, []);

  return {
    name,
    displayName: name === 'beem' ? 'Beem It' : 'Venmo',
    isVenmo: name === 'venmo',
    isBeem: name === 'beem',
    loading,
    currency,
    currencySymbol: currency === 'AUD' ? 'A$' : '$',
  };
}
