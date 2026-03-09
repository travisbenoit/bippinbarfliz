import { useState, FormEvent, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import { getMinDrinkingAge, getCountryByCode } from '../../services/geoLocationService';
import { useToast } from '../../contexts/ToastContext';

export default function BirthdaySetup() {
  const navigate = useNavigate();
  const { showError } = useToast();
  const [rawValue, setRawValue] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);

  const countryCode = localStorage.getItem('userCountryCode') || 'US';
  const minAge = getMinDrinkingAge(countryCode);
  const country = getCountryByCode(countryCode);

  const formatDate = (digits: string): string => {
    const d = digits.replace(/\D/g, '').slice(0, 8);
    if (d.length <= 2) return d;
    if (d.length <= 4) return `${d.slice(0, 2)}/${d.slice(2)}`;
    return `${d.slice(0, 2)}/${d.slice(2, 4)}/${d.slice(4, 8)}`;
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const input = e.target.value;
    const digits = input.replace(/\D/g, '').slice(0, 8);
    setRawValue(digits);
  };

  const displayValue = formatDate(rawValue);
  const isComplete = rawValue.length === 8;

  const getISODate = (): string | null => {
    if (!isComplete) return null;
    const mm = rawValue.slice(0, 2);
    const dd = rawValue.slice(2, 4);
    const yyyy = rawValue.slice(4, 8);
    return `${yyyy}-${mm}-${dd}`;
  };

  const calculateAge = (isoDate: string) => {
    const today = new Date();
    const birth = new Date(isoDate);
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    return age;
  };

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (!isComplete) return;

    const isoDate = getISODate();
    if (!isoDate) return;

    const parsed = new Date(isoDate);
    if (isNaN(parsed.getTime())) {
      showError('Please enter a valid date');
      return;
    }

    const age = calculateAge(isoDate);
    if (age < minAge) {
      showError(`You must be at least ${minAge} years old to use this app in ${country.countryName}`);
      return;
    }

    localStorage.setItem('pendingUserBirthday', isoDate);
    navigate('/location-permission');
  };

  return (
    <div className="min-h-screen bg-white flex flex-col px-6 py-8">
      <div className="text-sm text-gray-600 mb-8">
        9:27
      </div>

      <div className="flex-1 flex flex-col justify-between max-w-md mx-auto w-full">
        <div className="space-y-8 pt-8">
          <div className="text-center space-y-2">
            <h1 className="text-3xl font-bold text-gray-900">
              When's your birthday?
            </h1>
            <p className="text-gray-600 text-sm pt-4">
              Enter your date of birth to verify your age
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="relative">
              <input
                ref={inputRef}
                type="text"
                inputMode="numeric"
                value={displayValue}
                onChange={handleChange}
                placeholder="MM/DD/YYYY"
                maxLength={10}
                className="w-full px-6 py-4 rounded-full border-2 border-gray-200 focus:border-[#E91E63] focus:outline-none bg-white text-gray-900 text-lg font-medium text-center tracking-widest"
              />
            </div>
          </form>

          <div className="text-center text-sm text-gray-500">
            <p>
              <span className="text-2xl mr-2">{country.flag}</span>
              {country.countryName}
            </p>
            <p className="text-xs mt-2">
              Minimum age requirement: <span className="font-semibold text-[#E91E63]">{minAge}+</span>
            </p>
          </div>
        </div>

        <div className="space-y-6 pb-8">
          <button
            onClick={handleSubmit}
            disabled={!isComplete}
            className="w-full bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg flex items-center justify-center gap-2 hover:bg-[#C2185B] transition-colors shadow-lg disabled:opacity-50 disabled:bg-gray-300 disabled:text-gray-500"
          >
            Continue
            <ArrowRight size={24} />
          </button>

          <div className="h-1 w-32 bg-gray-900 rounded-full mx-auto" />
        </div>
      </div>
    </div>
  );
}
