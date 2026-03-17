import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { supabase } from '../lib/supabase';
import { getUserCountryCode } from '../services/regionService';
import { logger } from '../lib/logger';

interface RegionalSettings {
  locale: string;
  distanceUnit: 'miles' | 'kilometers';
  temperatureUnit: 'F' | 'C';
  currencyCode: string;
  currencySymbol: string;
  dateFormat: string;
  timeFormat: string;
  loading: boolean;
}

interface RegionalSettingsContextType extends RegionalSettings {
  convertDistance: (meters: number, includeUnit?: boolean) => string;
  convertTemperature: (celsius: number, includeUnit?: boolean) => string;
  convertSpeed: (metersPerSecond: number, includeUnit?: boolean) => string;
  formatDistance: (meters: number) => string;
  setDistanceUnit: (unit: 'miles' | 'kilometers') => void;
  setTemperatureUnit: (unit: 'F' | 'C') => void;
}

const defaultSettings: RegionalSettings = {
  locale: 'en-US',
  distanceUnit: 'miles',
  temperatureUnit: 'F',
  currencyCode: 'USD',
  currencySymbol: '$',
  dateFormat: 'MM/DD/YYYY',
  timeFormat: 'h:mm A',
  loading: true,
};

const RegionalSettingsContext = createContext<RegionalSettingsContextType | undefined>(undefined);

export function RegionalSettingsProvider({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<RegionalSettings>(defaultSettings);
  const [userDistanceUnit, setUserDistanceUnit] = useState<'miles' | 'kilometers' | null>(null);
  const [userTemperatureUnit, setUserTemperatureUnit] = useState<'F' | 'C' | null>(null);

  useEffect(() => {
    const savedDistanceUnit = localStorage.getItem('userDistanceUnit') as 'miles' | 'kilometers' | null;
    const savedTemperatureUnit = localStorage.getItem('userTemperatureUnit') as 'F' | 'C' | null;
    if (savedDistanceUnit) setUserDistanceUnit(savedDistanceUnit);
    if (savedTemperatureUnit) setUserTemperatureUnit(savedTemperatureUnit);
    loadUserPreferencesAndRegion(savedDistanceUnit, savedTemperatureUnit);
  }, []);

  const loadUserPreferencesAndRegion = async (
    localDistUnit: 'miles' | 'kilometers' | null,
    localTempUnit: 'F' | 'C' | null
  ) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();

      if (user) {
        const { data: userPrefs } = await supabase
          .from('users')
          .select('distance_unit, temperature_unit')
          .eq('id', user.id)
          .maybeSingle();

        if (userPrefs?.distance_unit) {
          const du = userPrefs.distance_unit as 'miles' | 'kilometers';
          setUserDistanceUnit(du);
          localStorage.setItem('userDistanceUnit', du);
          localDistUnit = du;
        }
        if (userPrefs?.temperature_unit) {
          const tu = userPrefs.temperature_unit as 'F' | 'C';
          setUserTemperatureUnit(tu);
          localStorage.setItem('userTemperatureUnit', tu);
          localTempUnit = tu;
        }
      }

      const countryCode = await getUserCountryCode();
      const { data: regionData, error } = await supabase
        .from('regions')
        .select('locale_tag, distance_unit, temperature_unit, currency_code, currency_symbol, date_format, time_format')
        .eq('country_code', countryCode)
        .maybeSingle();

      if (error || !regionData) {
        setSettings({ ...defaultSettings, loading: false });
        return;
      }

      setSettings({
        locale: regionData.locale_tag,
        distanceUnit: regionData.distance_unit === 'miles' ? 'miles' : 'kilometers',
        temperatureUnit: regionData.temperature_unit === 'F' ? 'F' : 'C',
        currencyCode: regionData.currency_code,
        currencySymbol: regionData.currency_symbol,
        dateFormat: regionData.date_format,
        timeFormat: regionData.time_format,
        loading: false,
      });

      if (!localDistUnit) {
        const du = regionData.distance_unit === 'miles' ? 'miles' : 'kilometers';
        setUserDistanceUnit(du);
        localStorage.setItem('userDistanceUnit', du);
      }
      if (!localTempUnit) {
        const tu = regionData.temperature_unit === 'F' ? 'F' : 'C';
        setUserTemperatureUnit(tu);
        localStorage.setItem('userTemperatureUnit', tu);
      }
    } catch (error) {
      logger.error('Error loading regional settings:', error);
      setSettings({ ...defaultSettings, loading: false });
    }
  };

  const getActiveDistanceUnit = (): 'miles' | 'kilometers' => {
    return userDistanceUnit || settings.distanceUnit;
  };

  const getActiveTemperatureUnit = (): 'F' | 'C' => {
    return userTemperatureUnit || settings.temperatureUnit;
  };

  const convertDistance = (meters: number, includeUnit = true): string => {
    const unit = getActiveDistanceUnit();
    if (unit === 'miles') {
      const miles = meters / 1609.34;
      if (miles < 0.1) {
        const feet = Math.round(miles * 5280);
        return includeUnit ? `${feet} ft` : feet.toString();
      }
      const value = miles < 1 ? miles.toFixed(2) : miles.toFixed(1);
      return includeUnit ? `${value} mi` : value;
    } else {
      const km = meters / 1000;
      if (km < 0.1) {
        return includeUnit ? `${Math.round(meters)} m` : Math.round(meters).toString();
      }
      const value = km < 1 ? km.toFixed(2) : km.toFixed(1);
      return includeUnit ? `${value} km` : value;
    }
  };

  const formatDistance = (meters: number): string => {
    const unit = getActiveDistanceUnit();
    if (unit === 'miles') {
      const miles = meters / 1609.34;
      if (miles < 1) return `${miles.toFixed(1)} miles`;
      return `${Math.round(miles)} miles`;
    } else {
      const km = meters / 1000;
      if (km < 1) return `${km.toFixed(1)} km`;
      return `${Math.round(km)} km`;
    }
  };

  const convertTemperature = (celsius: number, includeUnit = true): string => {
    const unit = getActiveTemperatureUnit();
    if (unit === 'F') {
      const fahrenheit = Math.round((celsius * 9) / 5 + 32);
      return includeUnit ? `${fahrenheit}\u00b0F` : fahrenheit.toString();
    } else {
      return includeUnit ? `${Math.round(celsius)}\u00b0C` : Math.round(celsius).toString();
    }
  };

  const convertSpeed = (metersPerSecond: number, includeUnit = true): string => {
    const unit = getActiveDistanceUnit();
    if (unit === 'miles') {
      const mph = Math.round(metersPerSecond * 2.237);
      return includeUnit ? `${mph} mph` : mph.toString();
    } else {
      const kmh = Math.round(metersPerSecond * 3.6);
      return includeUnit ? `${kmh} km/h` : kmh.toString();
    }
  };

  const persistUnitPreference = async (field: 'distance_unit' | 'temperature_unit', value: string) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        await supabase
          .from('users')
          .update({ [field]: value })
          .eq('id', user.id);
      }
    } catch (err) {
      logger.error('Error saving unit preference:', err);
    }
  };

  const handleSetDistanceUnit = (unit: 'miles' | 'kilometers') => {
    setUserDistanceUnit(unit);
    localStorage.setItem('userDistanceUnit', unit);
    persistUnitPreference('distance_unit', unit);
  };

  const handleSetTemperatureUnit = (unit: 'F' | 'C') => {
    setUserTemperatureUnit(unit);
    localStorage.setItem('userTemperatureUnit', unit);
    persistUnitPreference('temperature_unit', unit);
  };

  const getEffectiveSettings = (): RegionalSettings => ({
    ...settings,
    distanceUnit: getActiveDistanceUnit(),
    temperatureUnit: getActiveTemperatureUnit(),
  });

  return (
    <RegionalSettingsContext.Provider
      value={{
        ...getEffectiveSettings(),
        convertDistance,
        convertTemperature,
        convertSpeed,
        formatDistance,
        setDistanceUnit: handleSetDistanceUnit,
        setTemperatureUnit: handleSetTemperatureUnit,
      }}
    >
      {children}
    </RegionalSettingsContext.Provider>
  );
}

export function useRegionalSettings() {
  const context = useContext(RegionalSettingsContext);
  if (context === undefined) {
    throw new Error('useRegionalSettings must be used within a RegionalSettingsProvider');
  }
  return context;
}
