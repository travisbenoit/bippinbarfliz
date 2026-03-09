export async function detectCountryCode(): Promise<string> {
  return new Promise((resolve) => {
    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          try {
            const { latitude, longitude } = position.coords;

            const response = await fetch(
              `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${latitude}&longitude=${longitude}&localityLanguage=en`
            );

            if (response.ok) {
              const data = await response.json();
              const countryCode = data.countryCode || 'US';
              resolve(countryCode);
            } else {
              resolve('US');
            }
          } catch (error) {
            console.error('Error reverse geocoding:', error);
            resolve('US');
          }
        },
        () => {
          resolve('US');
        }
      );
    } else {
      resolve('US');
    }
  });
}

export function isUSBasedCountry(countryCode: string): boolean {
  return countryCode === 'US';
}
