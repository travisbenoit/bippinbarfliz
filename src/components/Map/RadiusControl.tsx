import { useState, useEffect } from 'react';
import { MapPin, Maximize2 } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useRegionalSettings } from '../../contexts/RegionalSettingsContext';

interface RadiusControlProps {
  currentRadius: number;
  onRadiusChange: (radius: number) => void;
}

const RADIUS_OPTIONS_METERS = [500, 1000, 2000, 5000, 10000, 25000];

export default function RadiusControl({ currentRadius, onRadiusChange }: RadiusControlProps) {
  const { convertDistance, distanceUnit } = useRegionalSettings();
  const [selectedRadius, setSelectedRadius] = useState(currentRadius);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    setSelectedRadius(currentRadius);
  }, [currentRadius]);

  const handleRadiusChange = async (radius: number) => {
    setSelectedRadius(radius);
    onRadiusChange(radius);

    setIsSaving(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        await supabase
          .from('users')
          .update({ preferred_radius_meters: radius })
          .eq('id', user.id);
      }
    } catch (error) {
      console.error('Error saving radius preference:', error);
    } finally {
      setIsSaving(false);
    }
  };

  const getRadiusLabel = (meters: number): string => {
    return convertDistance(meters, true);
  };

  const getRadiusDescription = (meters: number): string => {
    if (distanceUnit === 'miles') {
      const miles = meters / 1609.34;
      if (miles <= 0.5) return 'Very close by';
      if (miles <= 1) return 'Walking distance';
      if (miles <= 2) return 'Short trip';
      if (miles <= 5) return 'Nearby';
      if (miles <= 10) return 'Extended area';
      return 'Wide search';
    } else {
      if (meters <= 500) return 'Very close by';
      if (meters <= 1000) return 'Walking distance';
      if (meters <= 2000) return 'Short trip';
      if (meters <= 5000) return 'Nearby';
      if (meters <= 10000) return 'Extended area';
      return 'Wide search';
    }
  };

  return (
    <div className="bg-white rounded-2xl shadow-sm p-5">
      <div className="flex items-center gap-3 mb-4">
        <div className="w-10 h-10 bg-gradient-to-br from-[#E91E63] to-[#C2185B] rounded-xl flex items-center justify-center">
          <Maximize2 size={20} className="text-white" />
        </div>
        <div>
          <h3 className="font-bold text-gray-900">Search Radius</h3>
          <p className="text-sm text-gray-500">How far to look for venues</p>
        </div>
      </div>

      <div className="space-y-2">
        {RADIUS_OPTIONS_METERS.map((meters) => (
          <button
            key={meters}
            onClick={() => handleRadiusChange(meters)}
            className={`w-full flex items-center justify-between p-4 rounded-xl border-2 transition-all ${
              selectedRadius === meters
                ? 'border-[#E91E63] bg-pink-50'
                : 'border-gray-200 hover:border-gray-300 bg-white'
            }`}
          >
            <div className="flex items-center gap-3">
              <MapPin
                size={20}
                className={selectedRadius === meters ? 'text-[#E91E63]' : 'text-gray-400'}
              />
              <div className="text-left">
                <p className={`font-medium ${
                  selectedRadius === meters ? 'text-[#E91E63]' : 'text-gray-900'
                }`}>
                  {getRadiusLabel(meters)}
                </p>
                <p className="text-xs text-gray-500">{getRadiusDescription(meters)}</p>
              </div>
            </div>
            {selectedRadius === meters && (
              <div className="w-6 h-6 bg-[#E91E63] rounded-full flex items-center justify-center">
                <div className="w-2 h-2 bg-white rounded-full" />
              </div>
            )}
          </button>
        ))}
      </div>

      {isSaving && (
        <p className="text-xs text-gray-500 text-center mt-3">Saving preference...</p>
      )}
    </div>
  );
}
