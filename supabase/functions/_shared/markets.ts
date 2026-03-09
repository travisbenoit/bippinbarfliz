export interface MarketBounds {
  name: string;
  country_code: string;
  north: number;
  south: number;
  west: number;
  east: number;
  default_center: [number, number];
}

export const FEATURED_MARKETS: MarketBounds[] = [
  {
    name: "Darwin, NT, Australia",
    country_code: "AU",
    north: -12.35,
    south: -12.55,
    west: 130.75,
    east: 131.05,
    default_center: [-12.4634, 130.8456],
  },
  {
    name: "South Florida, US (Weston / Sunrise / Davie)",
    country_code: "US",
    north: 26.35,
    south: 25.95,
    west: -80.45,
    east: -80.10,
    default_center: [26.1003, -80.3882],
  },
];

export const ACTIVE_MARKETS = FEATURED_MARKETS;

export function isFeaturedMarket(lat: number, lng: number): MarketBounds | null {
  for (const market of FEATURED_MARKETS) {
    if (
      lat >= market.south &&
      lat <= market.north &&
      lng >= market.west &&
      lng <= market.east
    ) {
      return market;
    }
  }
  return null;
}

export function isWithinActiveMarket(lat: number, lng: number): MarketBounds | null {
  return isFeaturedMarket(lat, lng);
}

export function getMarketByCountryCode(countryCode: string): MarketBounds | null {
  return FEATURED_MARKETS.find((m) => m.country_code === countryCode) || null;
}
