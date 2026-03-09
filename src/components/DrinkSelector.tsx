import { useState } from 'react';
import { X, ChevronRight, ChevronLeft } from 'lucide-react';
import { DRINK_CATEGORIES, MIXED_DRINKS, formatDrinkForStorage, parseDrinkFromStorage, type DrinkCategory } from '../data/drinkOptions';

interface DrinkSelectorProps {
  selectedDrinks: string[];
  onDrinksChange: (drinks: string[]) => void;
  maxSelections?: number;
}

export default function DrinkSelector({ selectedDrinks, onDrinksChange, maxSelections = 5 }: DrinkSelectorProps) {
  const [showMixedDrinks, setShowMixedDrinks] = useState(false);
  const [customMixedDrink, setCustomMixedDrink] = useState('');

  const isDrinkSelected = (category: DrinkCategory, mixedDrink?: string) => {
    const formatted = formatDrinkForStorage(category, mixedDrink);
    return selectedDrinks.includes(formatted);
  };

  const toggleDrink = (category: DrinkCategory, mixedDrink?: string) => {
    const formatted = formatDrinkForStorage(category, mixedDrink);

    if (selectedDrinks.includes(formatted)) {
      onDrinksChange(selectedDrinks.filter(d => d !== formatted));
    } else if (selectedDrinks.length < maxSelections) {
      onDrinksChange([...selectedDrinks, formatted]);
    }
  };

  const handleCategoryClick = (category: DrinkCategory) => {
    if (category === 'Mixed Drinks') {
      setShowMixedDrinks(true);
    } else {
      toggleDrink(category);
    }
  };

  const addCustomMixedDrink = () => {
    if (customMixedDrink.trim() && selectedDrinks.length < maxSelections) {
      const formatted = formatDrinkForStorage('Mixed Drinks', customMixedDrink.trim());
      if (!selectedDrinks.includes(formatted)) {
        onDrinksChange([...selectedDrinks, formatted]);
        setCustomMixedDrink('');
      }
    }
  };

  const getMixedDrinksCount = () => {
    return selectedDrinks.filter(d => d.startsWith('Mixed Drinks: ')).length;
  };

  const getSelectedMixedDrinks = () => {
    return selectedDrinks
      .filter(d => d.startsWith('Mixed Drinks: '))
      .map(d => d.replace('Mixed Drinks: ', ''));
  };

  if (showMixedDrinks) {
    return (
      <div className="space-y-4">
        <div className="flex items-center gap-2 mb-2">
          <button
            type="button"
            onClick={() => setShowMixedDrinks(false)}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
          >
            <ChevronLeft className="w-5 h-5 text-gray-600" />
          </button>
          <span className="font-semibold text-gray-900">Mixed Drinks</span>
          <span className="text-sm text-gray-500 ml-auto">{getMixedDrinksCount()} selected</span>
        </div>

        <div className="flex flex-wrap gap-2">
          {MIXED_DRINKS.map((drink) => (
            <button
              key={drink}
              type="button"
              onClick={() => toggleDrink('Mixed Drinks', drink)}
              disabled={selectedDrinks.length >= maxSelections && !isDrinkSelected('Mixed Drinks', drink)}
              className={`px-4 py-2.5 rounded-full text-sm font-medium transition-all ${
                isDrinkSelected('Mixed Drinks', drink)
                  ? 'bg-[#E91E63] text-white shadow-md'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed'
              }`}
            >
              {drink}
              {isDrinkSelected('Mixed Drinks', drink) && <X className="w-3.5 h-3.5 inline ml-1.5" />}
            </button>
          ))}
        </div>

        <div className="pt-2 border-t border-gray-200">
          <p className="text-sm text-gray-600 mb-2">Other mixed drink</p>
          <div className="flex gap-2">
            <input
              type="text"
              value={customMixedDrink}
              onChange={(e) => setCustomMixedDrink(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), addCustomMixedDrink())}
              placeholder="Type your favorite..."
              className="flex-1 px-4 py-2.5 rounded-xl border border-gray-300 focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all text-sm"
            />
            <button
              type="button"
              onClick={addCustomMixedDrink}
              disabled={selectedDrinks.length >= maxSelections || !customMixedDrink.trim()}
              className="px-4 py-2.5 bg-[#E91E63] text-white rounded-xl font-medium text-sm hover:bg-[#C2185B] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Add
            </button>
          </div>
        </div>

        {getSelectedMixedDrinks().length > 0 && (
          <div className="pt-2">
            <p className="text-xs text-gray-500 mb-2">Your mixed drinks:</p>
            <div className="flex flex-wrap gap-1.5">
              {getSelectedMixedDrinks().map((drink) => (
                <span
                  key={drink}
                  className="inline-flex items-center gap-1 px-3 py-1.5 bg-[#E91E63]/10 text-[#E91E63] rounded-full text-xs font-medium"
                >
                  {drink}
                  <button
                    type="button"
                    onClick={() => toggleDrink('Mixed Drinks', drink)}
                    className="hover:bg-[#E91E63]/20 rounded-full p-0.5"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </span>
              ))}
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap gap-2">
        {DRINK_CATEGORIES.map((category) => {
          const isMixedDrinks = category === 'Mixed Drinks';
          const mixedCount = getMixedDrinksCount();
          const isSelected = isMixedDrinks ? mixedCount > 0 : isDrinkSelected(category);

          return (
            <button
              key={category}
              type="button"
              onClick={() => handleCategoryClick(category)}
              disabled={!isMixedDrinks && selectedDrinks.length >= maxSelections && !isSelected}
              className={`px-4 py-2.5 rounded-full text-sm font-medium transition-all flex items-center gap-1.5 ${
                isSelected
                  ? 'bg-[#E91E63] text-white shadow-md'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed'
              }`}
            >
              {category}
              {isMixedDrinks && (
                <>
                  {mixedCount > 0 && <span className="bg-white/20 px-1.5 py-0.5 rounded-full text-xs">{mixedCount}</span>}
                  <ChevronRight className="w-4 h-4" />
                </>
              )}
              {!isMixedDrinks && isSelected && <X className="w-3.5 h-3.5 ml-0.5" />}
            </button>
          );
        })}
      </div>

      {selectedDrinks.length > 0 && (
        <div className="pt-2">
          <p className="text-xs text-gray-500 mb-2">Selected ({selectedDrinks.length}/{maxSelections}):</p>
          <div className="flex flex-wrap gap-1.5">
            {selectedDrinks.map((drink) => {
              const parsed = parseDrinkFromStorage(drink);
              const displayName = parsed.mixedDrink || parsed.category;
              return (
                <span
                  key={drink}
                  className="inline-flex items-center gap-1 px-3 py-1.5 bg-[#E91E63]/10 text-[#E91E63] rounded-full text-xs font-medium"
                >
                  {displayName}
                  <button
                    type="button"
                    onClick={() => onDrinksChange(selectedDrinks.filter(d => d !== drink))}
                    className="hover:bg-[#E91E63]/20 rounded-full p-0.5"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </span>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
