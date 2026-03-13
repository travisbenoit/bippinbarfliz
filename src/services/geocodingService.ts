export interface GeocodeResult {
  address: string;
  formattedAddress: string;
  confidence: number;
}

class GeocodingService {
  private cache = new Map<string, GeocodeResult>();

  private getCacheKey(lat: number, lng: number): string {
    return `${lat.toFixed(6)}_${lng.toFixed(6)}`;
  }

  async reverseGeocode(lat: number, lng: number): Promise<GeocodeResult | null> {
    try {
      const cacheKey = this.getCacheKey(lat, lng);
      const cached = this.cache.get(cacheKey);
      if (cached) return cached;

      const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1`;
      const response = await fetch(url, {
        headers: { 'Accept-Language': 'en', 'User-Agent': 'Barfliz/1.0' },
      });

      if (!response.ok) return null;

      const data = await response.json();
      if (!data || data.error) return null;

      const result: GeocodeResult = {
        address: data.display_name || `${lat.toFixed(4)}, ${lng.toFixed(4)}`,
        formattedAddress: data.display_name || '',
        confidence: 0.9,
      };

      this.cache.set(cacheKey, result);
      return result;
    } catch (error) {
      console.error('Error in reverseGeocode:', error);
      return null;
    }
  }

  validateAddressMatch(address1: string, address2: string): { match: boolean; confidence: number } {
    const normalize = (str: string) => str.toLowerCase().replace(/[^\w\s]/g, '').trim();
    const norm1 = normalize(address1);
    const norm2 = normalize(address2);

    if (norm1 === norm2) {
      return { match: true, confidence: 1.0 };
    }

    const words1 = norm1.split(/\s+/);
    const words2 = norm2.split(/\s+/);
    const commonWords = words1.filter(w => words2.includes(w));
    const confidence = commonWords.length / Math.max(words1.length, words2.length);

    return {
      match: confidence > 0.6,
      confidence,
    };
  }

  calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLng = ((lng2 - lng1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  getDirectionsUrl(lat: number, lng: number, address: string, platform: 'web' | 'ios' | 'android' = 'web'): string {
    const encodedAddress = encodeURIComponent(address);
    const coordinates = `${lat},${lng}`;

    switch (platform) {
      case 'ios':
        return `maps://maps.apple.com/?q=${encodedAddress}&ll=${coordinates}`;

      case 'android':
        return `geo:${lat},${lng}?q=${encodedAddress}`;

      case 'web':
      default:
        return `https://maps.google.com/?q=${lat},${lng}`;
    }
  }

  getWalkingDirectionsUrl(
    fromLat: number,
    fromLng: number,
    toLat: number,
    toLng: number,
    platform: 'web' | 'ios' | 'android' = 'web'
  ): string {
    switch (platform) {
      case 'ios':
        return `maps://maps.apple.com/?saddr=${fromLat},${fromLng}&daddr=${toLat},${toLng}&dirflg=w`;

      case 'android':
        return `google.navigation:q=${toLat},${toLng}&mode=w`;

      case 'web':
      default:
        return `https://maps.google.com/maps/dir/${fromLat},${fromLng}/${toLat},${toLng}/?travelmode=walking`;
    }
  }

  getDrivingDirectionsUrl(
    fromLat: number,
    fromLng: number,
    toLat: number,
    toLng: number,
    platform: 'web' | 'ios' | 'android' = 'web'
  ): string {
    switch (platform) {
      case 'ios':
        return `maps://maps.apple.com/?saddr=${fromLat},${fromLng}&daddr=${toLat},${toLng}&dirflg=d`;

      case 'android':
        return `google.navigation:q=${toLat},${toLng}&mode=d`;

      case 'web':
      default:
        return `https://maps.google.com/maps/dir/${fromLat},${fromLng}/${toLat},${toLng}/?travelmode=driving`;
    }
  }

  detectPlatform(): 'web' | 'ios' | 'android' {
    if (typeof window === 'undefined') return 'web';

    const ua = navigator.userAgent.toLowerCase();
    if (/iphone|ipad|ipod/.test(ua)) return 'ios';
    if (/android/.test(ua)) return 'android';

    return 'web';
  }
}

export default new GeocodingService();
