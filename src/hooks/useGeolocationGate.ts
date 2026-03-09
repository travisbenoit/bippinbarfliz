import { useEffect, useState } from 'react';
import { detectCountryCode, isUSBasedCountry } from '../utils/geolocationGate';

interface GeolocationGateState {
  countryCode: string | null;
  isUS: boolean;
  isLoading: boolean;
}

export function useGeolocationGate(): GeolocationGateState {
  const [state, setState] = useState<GeolocationGateState>({
    countryCode: null,
    isUS: false,
    isLoading: true,
  });

  useEffect(() => {
    const detect = async () => {
      const code = await detectCountryCode();
      setState({
        countryCode: code,
        isUS: isUSBasedCountry(code),
        isLoading: false,
      });
    };

    detect();
  }, []);

  return state;
}
