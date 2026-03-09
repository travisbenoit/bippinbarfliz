import { useState, useEffect } from 'react';
import { Cloud, CloudRain, CloudSnow, Sun, Wind, Droplets, Eye, Thermometer, CloudDrizzle } from 'lucide-react';
import { useRegionalSettings } from '../../contexts/RegionalSettingsContext';

interface WeatherRaw {
  temperatureC: number;
  feelsLikeC: number;
  condition: string;
  humidity: number;
  windSpeedMs: number;
  visibilityM: number;
}

interface WeatherCardProps {
  latitude?: number;
  longitude?: number;
  location?: string;
}

export default function WeatherCard({ latitude, longitude, location = 'Current Location' }: WeatherCardProps) {
  const { temperatureUnit, convertSpeed, convertDistance, convertTemperature } = useRegionalSettings();
  const [raw, setRaw] = useState<WeatherRaw | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [localLat, setLocalLat] = useState<number | null>(latitude || null);
  const [localLng, setLocalLng] = useState<number | null>(longitude || null);
  const [initialized, setInitialized] = useState(false);

  useEffect(() => {
    if (latitude !== undefined) setLocalLat(latitude);
    if (longitude !== undefined) setLocalLng(longitude);
  }, [latitude, longitude]);

  useEffect(() => {
    if (localLat && localLng) {
      fetchWeather(localLat, localLng);
      setInitialized(true);
    } else if (!initialized) {
      attemptGeolocation();
      setInitialized(true);
    }
  }, [localLat, localLng, initialized]);

  const attemptGeolocation = () => {
    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setLocalLat(position.coords.latitude);
          setLocalLng(position.coords.longitude);
        },
        () => showDefaultWeather()
      );
    } else {
      showDefaultWeather();
    }
  };

  const showDefaultWeather = () => {
    setRaw({
      temperatureC: 22,
      feelsLikeC: 21,
      condition: 'Clear',
      humidity: 55,
      windSpeedMs: 3.5,
      visibilityM: 16000,
    });
    setLoading(false);
  };

  const fetchWeather = async (lat: number, lng: number) => {
    try {
      setLoading(true);
      const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
      const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

      const response = await fetch(
        `${supabaseUrl}/functions/v1/get-weather?latitude=${lat}&longitude=${lng}`,
        {
          headers: {
            'Authorization': `Bearer ${anonKey}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) throw new Error('Failed to fetch weather');

      const data = await response.json();

      setRaw({
        temperatureC: data.temperature,
        feelsLikeC: data.feelsLike,
        condition: data.condition,
        humidity: data.humidity,
        windSpeedMs: data.windSpeed,
        visibilityM: data.windSpeed * 5000,
      });
      setError(null);
    } catch (err) {
      console.error('Error fetching weather:', err);
      setError('Unable to load weather');
    } finally {
      setLoading(false);
    }
  };

  const getWeatherIcon = (condition: string) => {
    switch (condition.toLowerCase()) {
      case 'clear':
        return <Sun size={32} className="text-amber-500" />;
      case 'clouds':
        return <Cloud size={32} className="text-gray-400" />;
      case 'rain':
        return <CloudRain size={32} className="text-blue-500" />;
      case 'drizzle':
        return <CloudDrizzle size={32} className="text-blue-400" />;
      case 'snow':
        return <CloudSnow size={32} className="text-blue-200" />;
      default:
        return <Cloud size={32} className="text-gray-400" />;
    }
  };

  const getWeatherAdvice = (tempC: number, condition: string) => {
    if (condition.toLowerCase().includes('rain')) {
      return 'Rainy night - indoor venues recommended';
    }
    if (tempC > 24) {
      return 'Perfect for rooftop bars';
    }
    if (tempC < 13) {
      return 'Bring a jacket tonight';
    }
    return 'Great weather for going out';
  };

  if (loading) {
    return (
      <div className="bg-white rounded-2xl shadow-sm p-5">
        <div className="animate-pulse">
          <div className="h-6 bg-gray-200 rounded w-1/2 mb-4"></div>
          <div className="h-16 bg-gray-200 rounded mb-3"></div>
          <div className="h-4 bg-gray-200 rounded w-3/4"></div>
        </div>
      </div>
    );
  }

  if (!raw) {
    if (error) {
      return (
        <div className="bg-gray-50 rounded-2xl shadow-sm p-5 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gray-200 flex items-center justify-center">
              <Cloud size={20} className="text-gray-400" />
            </div>
            <div>
              <p className="font-medium text-gray-700">Weather unavailable</p>
              <p className="text-sm text-gray-500">Check back in a bit</p>
            </div>
          </div>
        </div>
      );
    }
    return null;
  }

  const displayTemp = convertTemperature(raw.temperatureC, false);
  const displayFeelsLike = convertTemperature(raw.feelsLikeC, false);

  return (
    <div className="bg-gradient-to-br from-blue-50 via-sky-50 to-cyan-50 rounded-2xl shadow-sm p-5 border border-blue-100">
      <div className="flex items-start justify-between mb-4">
        <div>
          <h3 className="font-bold text-gray-900 mb-1">Tonight's Weather</h3>
          <p className="text-sm text-gray-600">{location}</p>
        </div>
        <div className="bg-white/70 backdrop-blur-sm rounded-xl p-2">
          {getWeatherIcon(raw.condition)}
        </div>
      </div>

      <div className="flex items-baseline gap-2 mb-3">
        <span className="text-5xl font-bold text-gray-900">{displayTemp}°</span>
        <span className="text-lg text-gray-500">{temperatureUnit}</span>
      </div>

      <div className="flex items-center gap-2 mb-4">
        <Thermometer size={16} className="text-gray-400" />
        <p className="text-sm text-gray-600">
          Feels like {displayFeelsLike}°{temperatureUnit} • {raw.condition}
        </p>
      </div>

      <div className="grid grid-cols-3 gap-3 mb-4">
        <div className="bg-white/70 backdrop-blur-sm rounded-xl p-3">
          <div className="flex items-center gap-2 mb-1">
            <Droplets size={14} className="text-blue-500" />
            <span className="text-xs text-gray-500">Humidity</span>
          </div>
          <p className="text-lg font-bold text-gray-900">{raw.humidity}%</p>
        </div>

        <div className="bg-white/70 backdrop-blur-sm rounded-xl p-3">
          <div className="flex items-center gap-2 mb-1">
            <Wind size={14} className="text-gray-500" />
            <span className="text-xs text-gray-500">Wind</span>
          </div>
          <p className="text-lg font-bold text-gray-900">{convertSpeed(raw.windSpeedMs)}</p>
        </div>

        <div className="bg-white/70 backdrop-blur-sm rounded-xl p-3">
          <div className="flex items-center gap-2 mb-1">
            <Eye size={14} className="text-blue-400" />
            <span className="text-xs text-gray-500">Visibility</span>
          </div>
          <p className="text-lg font-bold text-gray-900">{convertDistance(raw.visibilityM)}</p>
        </div>
      </div>

      <div className="bg-blue-500/10 border border-blue-200 rounded-xl p-3">
        <p className="text-sm font-medium text-blue-900">
          {getWeatherAdvice(raw.temperatureC, raw.condition)}
        </p>
      </div>

    </div>
  );
}
