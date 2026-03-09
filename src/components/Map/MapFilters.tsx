import { useState } from 'react';
import { X, RotateCcw, ChevronRight, ChevronLeft } from 'lucide-react';
import type { VibeTag } from '../../data/dummyData';
import { DRINK_CATEGORIES, MIXED_DRINKS, type DrinkCategory } from '../../data/drinkOptions';

type GroupSizeValue = 'small' | 'medium' | 'large' | null;

interface DistanceOption {
  readonly label: string;
  readonly value: number;
}

interface GroupSizeOption {
  readonly label: string;
  readonly value: GroupSizeValue;
  readonly min?: number;
  readonly max?: number;
}

interface MapFiltersProps {
  isOpen: boolean;
  onClose: () => void;
  distanceFilter: number;
  setDistanceFilter: (value: number) => void;
  groupSizeFilter: GroupSizeValue;
  setGroupSizeFilter: (value: GroupSizeValue) => void;
  vibeFilters: VibeTag[];
  setVibeFilters: (value: VibeTag[]) => void;
  drinkFilters: string[];
  setDrinkFilters: (value: string[]) => void;
  distanceOptions: readonly DistanceOption[];
  groupSizeOptions: readonly GroupSizeOption[];
  vibeOptions: readonly VibeTag[];
  defaultDistance?: number;
}

export default function MapFilters({
  isOpen,
  onClose,
  distanceFilter,
  setDistanceFilter,
  groupSizeFilter,
  setGroupSizeFilter,
  vibeFilters,
  setVibeFilters,
  drinkFilters,
  setDrinkFilters,
  distanceOptions,
  groupSizeOptions,
  vibeOptions,
  defaultDistance,
}: MapFiltersProps) {
  const [showMixedDrinks, setShowMixedDrinks] = useState(false);

  const toggleVibe = (vibe: VibeTag) => {
    if (vibeFilters.includes(vibe)) {
      setVibeFilters(vibeFilters.filter(v => v !== vibe));
    } else {
      setVibeFilters([...vibeFilters, vibe]);
    }
  };

  const toggleDrink = (drink: string) => {
    if (drinkFilters.includes(drink)) {
      setDrinkFilters(drinkFilters.filter(d => d !== drink));
    } else {
      setDrinkFilters([...drinkFilters, drink]);
    }
  };

  const toggleMixedDrink = (mixedDrink: string) => {
    const formatted = `Mixed Drinks: ${mixedDrink}`;
    if (drinkFilters.includes(formatted)) {
      setDrinkFilters(drinkFilters.filter(d => d !== formatted));
    } else {
      setDrinkFilters([...drinkFilters, formatted]);
    }
  };

  const isMixedDrinkSelected = (mixedDrink: string) => {
    return drinkFilters.includes(`Mixed Drinks: ${mixedDrink}`);
  };

  const getMixedDrinksCount = () => {
    return drinkFilters.filter(d => d.startsWith('Mixed Drinks: ')).length;
  };

  const defaultDistanceValue = defaultDistance ?? distanceOptions[distanceOptions.length - 2]?.value ?? 16;

  const resetFilters = () => {
    setDistanceFilter(defaultDistanceValue);
    setGroupSizeFilter(null);
    setVibeFilters([]);
    setDrinkFilters([]);
    setShowMixedDrinks(false);
  };

  const hasActiveFilters = vibeFilters.length > 0 || groupSizeFilter !== null || distanceFilter !== defaultDistanceValue || drinkFilters.length > 0;

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[2000] flex items-end justify-center">
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />
      <div className="relative bg-white rounded-t-3xl w-full max-w-lg max-h-[85vh] flex flex-col animate-slide-up">
        <div className="flex-shrink-0 bg-white border-b border-gray-100 px-6 py-4">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold text-gray-900">Filters</h2>
            <div className="flex items-center gap-2">
              {hasActiveFilters && (
                <button
                  onClick={resetFilters}
                  className="flex items-center gap-1 px-3 py-1.5 text-sm text-gray-600 hover:text-gray-900 transition-colors"
                >
                  <RotateCcw className="w-4 h-4" />
                  Reset
                </button>
              )}
              <button
                onClick={onClose}
                className="p-2 hover:bg-gray-100 rounded-full transition-colors"
              >
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-8">
          <div>
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Distance</h3>
            <div className="space-y-4">
              <input
                type="range"
                min={0}
                max={distanceOptions.length - 1}
                value={distanceOptions.findIndex(opt => opt.value === distanceFilter)}
                onChange={(e) => setDistanceFilter(distanceOptions[parseInt(e.target.value)].value)}
                className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-pink-500"
              />
              <div className="flex justify-between">
                {distanceOptions.map((opt, idx) => (
                  <button
                    key={opt.value}
                    onClick={() => setDistanceFilter(opt.value)}
                    className={`text-xs px-2 py-1 rounded transition-colors ${
                      distanceFilter === opt.value
                        ? 'text-pink-600 font-semibold'
                        : 'text-gray-500 hover:text-gray-700'
                    }`}
                  >
                    {opt.label}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div>
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Group Size</h3>
            <div className="flex flex-wrap gap-2">
              {groupSizeOptions.map((opt) => (
                <button
                  key={opt.label}
                  onClick={() => setGroupSizeFilter(opt.value)}
                  className={`px-4 py-2.5 rounded-full text-sm font-medium transition-all ${
                    groupSizeFilter === opt.value
                      ? 'bg-pink-500 text-white shadow-md'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Vibes</h3>
            <div className="flex flex-wrap gap-2">
              {vibeOptions.map((vibe) => (
                <button
                  key={vibe}
                  onClick={() => toggleVibe(vibe)}
                  className={`px-4 py-2.5 rounded-full text-sm font-medium transition-all ${
                    vibeFilters.includes(vibe)
                      ? 'bg-pink-500 text-white shadow-md'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {vibe}
                </button>
              ))}
            </div>
            {vibeFilters.length > 0 && (
              <p className="text-xs text-gray-500 mt-3">
                Showing swarms, venues, and people matching any selected vibe
              </p>
            )}
          </div>

          <div>
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Favorite Drinks</h3>
            {showMixedDrinks ? (
              <div className="space-y-4">
                <button
                  onClick={() => setShowMixedDrinks(false)}
                  className="flex items-center gap-2 text-sm text-gray-600 hover:text-gray-900 transition-colors"
                >
                  <ChevronLeft className="w-4 h-4" />
                  Back to categories
                </button>
                <p className="text-xs text-gray-500">Select specific mixed drinks:</p>
                <div className="flex flex-wrap gap-2">
                  {MIXED_DRINKS.map((drink) => (
                    <button
                      key={drink}
                      onClick={() => toggleMixedDrink(drink)}
                      className={`px-4 py-2.5 rounded-full text-sm font-medium transition-all ${
                        isMixedDrinkSelected(drink)
                          ? 'bg-pink-500 text-white shadow-md'
                          : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                      }`}
                    >
                      {drink}
                    </button>
                  ))}
                </div>
              </div>
            ) : (
              <div className="flex flex-wrap gap-2">
                {DRINK_CATEGORIES.map((category) => {
                  const isMixedDrinks = category === 'Mixed Drinks';
                  const mixedCount = getMixedDrinksCount();
                  const isSelected = isMixedDrinks ? mixedCount > 0 : drinkFilters.includes(category);

                  return (
                    <button
                      key={category}
                      onClick={() => {
                        if (isMixedDrinks) {
                          setShowMixedDrinks(true);
                        } else {
                          toggleDrink(category);
                        }
                      }}
                      className={`px-4 py-2.5 rounded-full text-sm font-medium transition-all flex items-center gap-1.5 ${
                        isSelected
                          ? 'bg-pink-500 text-white shadow-md'
                          : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                      }`}
                    >
                      {category}
                      {isMixedDrinks && (
                        <>
                          {mixedCount > 0 && (
                            <span className="bg-white/20 px-1.5 py-0.5 rounded-full text-xs">{mixedCount}</span>
                          )}
                          <ChevronRight className="w-4 h-4" />
                        </>
                      )}
                    </button>
                  );
                })}
              </div>
            )}
            {drinkFilters.length > 0 && (
              <p className="text-xs text-gray-500 mt-3">
                Showing people who enjoy these drinks
              </p>
            )}
          </div>
        </div>

        <div className="flex-shrink-0 bg-white border-t border-gray-100 p-4">
          <button
            onClick={onClose}
            className="w-full py-3.5 bg-pink-500 text-white rounded-xl font-semibold hover:bg-pink-600 transition-colors shadow-lg"
          >
            Apply Filters
          </button>
        </div>
      </div>
    </div>
  );
}
