export type PaymentRegion = 'au' | 'us' | 'other';

interface RegionData {
  region: PaymentRegion;
  country: string;
  confidence: 'high' | 'medium' | 'low';
}

const SESSION_KEY = 'barfliz_region';
let memCache: RegionData | null = null;

async function detectByIP(): Promise<{ country: string; confidence: 'high' | 'low' }> {
  try {
    const response = await fetch('https://ipapi.co/json/');
    const data = await response.json();
    const country = data.country_code?.toUpperCase() || '';
    if (country) return { country, confidence: 'high' };
  } catch (_) {}
  return { country: 'US', confidence: 'low' };
}

async function detectByGeolocation(): Promise<string | null> {
  return new Promise((resolve) => {
    if (!('geolocation' in navigator)) { resolve(null); return; }
    navigator.geolocation.getCurrentPosition(
      async (position) => {
        try {
          const { latitude, longitude } = position.coords;
          const response = await fetch(
            `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${latitude}&longitude=${longitude}&localityLanguage=en`
          );
          if (response.ok) {
            const data = await response.json();
            resolve(data.countryCode?.toUpperCase() || null);
          } else {
            resolve(null);
          }
        } catch (_) {
          resolve(null);
        }
      },
      () => resolve(null),
      { timeout: 5000, maximumAge: 60000 }
    );
  });
}

function countryToRegion(country: string): PaymentRegion {
  if (country === 'AU') return 'au';
  if (country === 'US') return 'us';
  return 'other';
}

export async function detectUserRegion(): Promise<RegionData> {
  if (memCache) return memCache;

  const saved = sessionStorage.getItem(SESSION_KEY);
  if (saved) {
    try {
      memCache = JSON.parse(saved);
      return memCache!;
    } catch (_) {}
  }

  const [ipResult, geoCountry] = await Promise.all([
    detectByIP(),
    detectByGeolocation(),
  ]);

  let country = ipResult.country;
  let confidence = ipResult.confidence;

  if (geoCountry) {
    if (geoCountry === ipResult.country) {
      confidence = 'high';
    } else if (ipResult.confidence === 'low') {
      country = geoCountry;
      confidence = 'medium';
    }
  }

  const region = countryToRegion(country);
  const result: RegionData = { region, country, confidence };

  memCache = result;
  sessionStorage.setItem(SESSION_KEY, JSON.stringify(result));
  localStorage.setItem('userCountryCode', country);

  return result;
}

export function getPaymentProviderForRegion(region: PaymentRegion): 'beem' | 'venmo' {
  return region === 'au' ? 'beem' : 'venmo';
}

export async function getPaymentProvider(): Promise<'beem' | 'venmo'> {
  const regionData = await detectUserRegion();
  return getPaymentProviderForRegion(regionData.region);
}

export function clearRegionCache(): void {
  memCache = null;
  sessionStorage.removeItem(SESSION_KEY);
}

export async function getUserCountryCode(): Promise<string> {
  const region = await detectUserRegion();
  return region.country;
}
