export interface CountryInfo {
  countryCode: string;
  countryName: string;
  dialCode: string;
  flag: string;
  minDrinkingAge: number;
  phoneFormat: string;
  phonePlaceholder: string;
}

export const COUNTRY_DATA: Record<string, CountryInfo> = {
  US: {
    countryCode: 'US',
    countryName: 'United States',
    dialCode: '+1',
    flag: '🇺🇸',
    minDrinkingAge: 21,
    phoneFormat: '(###) ###-####',
    phonePlaceholder: '(555) 123-4567'
  },
  AU: {
    countryCode: 'AU',
    countryName: 'Australia',
    dialCode: '+61',
    flag: '🇦🇺',
    minDrinkingAge: 18,
    phoneFormat: '### ### ###',
    phonePlaceholder: '412 345 678'
  },
  GB: {
    countryCode: 'GB',
    countryName: 'United Kingdom',
    dialCode: '+44',
    flag: '🇬🇧',
    minDrinkingAge: 18,
    phoneFormat: '#### ######',
    phonePlaceholder: '7911 123456'
  },
  CA: {
    countryCode: 'CA',
    countryName: 'Canada',
    dialCode: '+1',
    flag: '🇨🇦',
    minDrinkingAge: 18,
    phoneFormat: '(###) ###-####',
    phonePlaceholder: '(555) 123-4567'
  },
  DE: {
    countryCode: 'DE',
    countryName: 'Germany',
    dialCode: '+49',
    flag: '🇩🇪',
    minDrinkingAge: 18,
    phoneFormat: '### ########',
    phonePlaceholder: '151 12345678'
  },
  FR: {
    countryCode: 'FR',
    countryName: 'France',
    dialCode: '+33',
    flag: '🇫🇷',
    minDrinkingAge: 18,
    phoneFormat: '# ## ## ## ##',
    phonePlaceholder: '6 12 34 56 78'
  },
  ES: {
    countryCode: 'ES',
    countryName: 'Spain',
    dialCode: '+34',
    flag: '🇪🇸',
    minDrinkingAge: 18,
    phoneFormat: '### ### ###',
    phonePlaceholder: '612 345 678'
  },
  IT: {
    countryCode: 'IT',
    countryName: 'Italy',
    dialCode: '+39',
    flag: '🇮🇹',
    minDrinkingAge: 18,
    phoneFormat: '### ### ####',
    phonePlaceholder: '312 345 6789'
  },
  NZ: {
    countryCode: 'NZ',
    countryName: 'New Zealand',
    dialCode: '+64',
    flag: '🇳🇿',
    minDrinkingAge: 18,
    phoneFormat: '## ### ####',
    phonePlaceholder: '21 123 4567'
  },
  JP: {
    countryCode: 'JP',
    countryName: 'Japan',
    dialCode: '+81',
    flag: '🇯🇵',
    minDrinkingAge: 18,
    phoneFormat: '##-####-####',
    phonePlaceholder: '90-1234-5678'
  },
  MX: {
    countryCode: 'MX',
    countryName: 'Mexico',
    dialCode: '+52',
    flag: '🇲🇽',
    minDrinkingAge: 18,
    phoneFormat: '## #### ####',
    phonePlaceholder: '55 1234 5678'
  },
  BR: {
    countryCode: 'BR',
    countryName: 'Brazil',
    dialCode: '+55',
    flag: '🇧🇷',
    minDrinkingAge: 18,
    phoneFormat: '## #####-####',
    phonePlaceholder: '11 91234-5678'
  },
  IN: {
    countryCode: 'IN',
    countryName: 'India',
    dialCode: '+91',
    flag: '🇮🇳',
    minDrinkingAge: 18,
    phoneFormat: '##### #####',
    phonePlaceholder: '98765 43210'
  },
  IE: {
    countryCode: 'IE',
    countryName: 'Ireland',
    dialCode: '+353',
    flag: '🇮🇪',
    minDrinkingAge: 18,
    phoneFormat: '## ### ####',
    phonePlaceholder: '85 123 4567'
  },
  NL: {
    countryCode: 'NL',
    countryName: 'Netherlands',
    dialCode: '+31',
    flag: '🇳🇱',
    minDrinkingAge: 18,
    phoneFormat: '# ########',
    phonePlaceholder: '6 12345678'
  },
  SE: {
    countryCode: 'SE',
    countryName: 'Sweden',
    dialCode: '+46',
    flag: '🇸🇪',
    minDrinkingAge: 18,
    phoneFormat: '##-### ## ##',
    phonePlaceholder: '70-123 45 67'
  },
  NO: {
    countryCode: 'NO',
    countryName: 'Norway',
    dialCode: '+47',
    flag: '🇳🇴',
    minDrinkingAge: 18,
    phoneFormat: '### ## ###',
    phonePlaceholder: '412 34 567'
  },
  DK: {
    countryCode: 'DK',
    countryName: 'Denmark',
    dialCode: '+45',
    flag: '🇩🇰',
    minDrinkingAge: 18,
    phoneFormat: '## ## ## ##',
    phonePlaceholder: '20 12 34 56'
  },
  PH: {
    countryCode: 'PH',
    countryName: 'Philippines',
    dialCode: '+63',
    flag: '🇵🇭',
    minDrinkingAge: 18,
    phoneFormat: '### ### ####',
    phonePlaceholder: '917 123 4567'
  },
  SG: {
    countryCode: 'SG',
    countryName: 'Singapore',
    dialCode: '+65',
    flag: '🇸🇬',
    minDrinkingAge: 18,
    phoneFormat: '#### ####',
    phonePlaceholder: '9123 4567'
  },
  KR: {
    countryCode: 'KR',
    countryName: 'South Korea',
    dialCode: '+82',
    flag: '🇰🇷',
    minDrinkingAge: 18,
    phoneFormat: '##-####-####',
    phonePlaceholder: '10-1234-5678'
  },
  ZA: {
    countryCode: 'ZA',
    countryName: 'South Africa',
    dialCode: '+27',
    flag: '🇿🇦',
    minDrinkingAge: 18,
    phoneFormat: '## ### ####',
    phonePlaceholder: '71 234 5678'
  }
};

export const ALL_COUNTRIES = Object.values(COUNTRY_DATA).sort((a, b) =>
  a.countryName.localeCompare(b.countryName)
);

export async function detectUserCountry(): Promise<CountryInfo> {
  const savedCode = localStorage.getItem('userCountryCode');
  if (savedCode && COUNTRY_DATA[savedCode]) {
    return COUNTRY_DATA[savedCode];
  }

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);
    const response = await fetch('https://ipapi.co/json/', {
      signal: controller.signal
    });
    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error('Failed to detect location');
    }

    const data = await response.json();
    const countryCode = data.country_code;

    if (countryCode && COUNTRY_DATA[countryCode]) {
      return COUNTRY_DATA[countryCode];
    }

    return COUNTRY_DATA.US;
  } catch {
    return COUNTRY_DATA.US;
  }
}

export function getCountryByCode(code: string): CountryInfo {
  return COUNTRY_DATA[code] || COUNTRY_DATA.US;
}

export function formatPhoneNumber(phone: string, countryCode: string): string {
  const digits = phone.replace(/\D/g, '');
  const country = getCountryByCode(countryCode);
  const format = country.phoneFormat;

  let result = '';
  let digitIndex = 0;

  for (const char of format) {
    if (digitIndex >= digits.length) break;

    if (char === '#') {
      result += digits[digitIndex];
      digitIndex++;
    } else {
      result += char;
    }
  }

  return result;
}

const COUNTRIES_WITH_TRUNK_PREFIX_ZERO = new Set([
  'AF', 'AL', 'DZ', 'AR', 'AM', 'AT', 'AU', 'AZ',
  'BE', 'BO', 'BA', 'BR', 'BG',
  'KH', 'CN', 'CD', 'HR', 'CU', 'CW',
  'EC', 'EG', 'ER', 'ET',
  'FI', 'FR', 'GF',
  'GA', 'GE', 'DE', 'GH', 'GP',
  'IN', 'IR', 'IE', 'IL',
  'JO',
  'XK', 'KG',
  'LA', 'LB', 'LY',
  'MG', 'MY', 'MQ', 'YT', 'MD', 'MN', 'ME', 'MA', 'MM',
  'NA', 'NP', 'NL', 'NZ', 'NG', 'MK', 'NO',
  'PK', 'PS', 'PY', 'PE', 'PH',
  'QA',
  'RO',
  'SA', 'RS', 'SL', 'SK', 'SI', 'SO', 'ZA', 'LK', 'SD', 'SR', 'SE', 'CH', 'SY',
  'TW', 'TZ', 'TH', 'TR',
  'UG', 'UA', 'AE', 'GB', 'UY', 'UZ',
  'VE', 'VN',
  'ZM', 'ZW'
]);

export function getFullPhoneNumber(phone: string, countryCode: string): string {
  let digits = phone.replace(/\D/g, '');
  const country = getCountryByCode(countryCode);

  if (COUNTRIES_WITH_TRUNK_PREFIX_ZERO.has(countryCode) && digits.startsWith('0')) {
    digits = digits.substring(1);
  }

  return `${country.dialCode}${digits}`;
}

export function validatePhoneLength(phone: string, countryCode: string): boolean {
  const digits = phone.replace(/\D/g, '');
  const minLength = countryCode === 'US' || countryCode === 'CA' ? 10 : 8;
  const maxLength = 15;
  return digits.length >= minLength && digits.length <= maxLength;
}

export function getMinDrinkingAge(countryCode: string): number {
  const country = COUNTRY_DATA[countryCode];
  return country ? country.minDrinkingAge : 18;
}
