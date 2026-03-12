import { useState, FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, ChevronDown } from 'lucide-react';
import { getMinDrinkingAge, getCountryByCode } from '../../services/geoLocationService';
import { useToast } from '../../contexts/ToastContext';

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

function getDaysInMonth(month: number, year: number): number {
  if (!month) return 31;
  return new Date(year || 2000, month, 0).getDate();
}

function SelectField({
  label,
  value,
  onChange,
  children,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  children: React.ReactNode;
  placeholder: string;
}) {
  return (
    <div className="flex-1">
      <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2 text-center">
        {label}
      </label>
      <div className="relative">
        <select
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className={`w-full appearance-none px-3 py-4 rounded-2xl border-2 text-center text-base font-semibold focus:outline-none focus:border-[#E91E63] transition-colors bg-white cursor-pointer ${
            value ? 'border-gray-200 text-gray-900' : 'border-gray-200 text-gray-400'
          }`}
        >
          <option value="" disabled>{placeholder}</option>
          {children}
        </select>
        <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
      </div>
    </div>
  );
}

export default function BirthdaySetup() {
  const navigate = useNavigate();
  const { showError } = useToast();
  const [day, setDay] = useState('');
  const [month, setMonth] = useState('');
  const [year, setYear] = useState('');

  const countryCode = localStorage.getItem('userCountryCode') || 'US';
  const minAge = getMinDrinkingAge(countryCode);
  const country = getCountryByCode(countryCode);

  const currentYear = new Date().getFullYear();
  const years = Array.from({ length: 100 }, (_, i) => currentYear - 18 - i);
  const daysInMonth = getDaysInMonth(parseInt(month), parseInt(year));
  const days = Array.from({ length: daysInMonth }, (_, i) => i + 1);

  const isComplete = !!(day && month && year);

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

  const handleSubmit = (e?: FormEvent) => {
    e?.preventDefault();
    if (!isComplete) return;

    const paddedMonth = month.padStart(2, '0');
    const paddedDay = day.padStart(2, '0');
    const isoDate = `${year}-${paddedMonth}-${paddedDay}`;

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

  const handleDayChange = (v: string) => {
    setDay(v);
  };

  const handleMonthChange = (v: string) => {
    setMonth(v);
    const newDays = getDaysInMonth(parseInt(v), parseInt(year));
    if (parseInt(day) > newDays) setDay('');
  };

  const handleYearChange = (v: string) => {
    setYear(v);
    const newDays = getDaysInMonth(parseInt(month), parseInt(v));
    if (parseInt(day) > newDays) setDay('');
  };

  const formattedPreview = isComplete
    ? new Date(parseInt(year), parseInt(month) - 1, parseInt(day))
        .toLocaleDateString('en-US', { day: 'numeric', month: 'long', year: 'numeric' })
    : null;

  return (
    <div className="min-h-screen bg-white flex flex-col px-6 py-8">
      <div className="flex-1 flex flex-col justify-between max-w-md mx-auto w-full">
        <div className="space-y-8 pt-12">
          <div className="text-center space-y-3">
            <div className="text-5xl mb-4">🎂</div>
            <h1 className="text-3xl font-bold text-gray-900">
              When's your birthday?
            </h1>
            <p className="text-gray-500 text-sm">
              You must be {minAge}+ to use Barfliz in {country.countryName}
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            <div className="flex gap-3">
              <SelectField
                label="Month"
                value={month}
                onChange={handleMonthChange}
                placeholder="Month"
              >
                {MONTHS.map((m, i) => (
                  <option key={m} value={String(i + 1)}>{m}</option>
                ))}
              </SelectField>

              <SelectField
                label="Day"
                value={day}
                onChange={handleDayChange}
                placeholder="Day"
              >
                {days.map((d) => (
                  <option key={d} value={String(d)}>{d}</option>
                ))}
              </SelectField>
            </div>

            <SelectField
              label="Year"
              value={year}
              onChange={handleYearChange}
              placeholder="Year"
            >
              {years.map((y) => (
                <option key={y} value={String(y)}>{y}</option>
              ))}
            </SelectField>
          </form>

          {formattedPreview && (
            <div className="text-center">
              <div className="inline-flex items-center gap-2 bg-pink-50 border border-pink-200 text-[#E91E63] px-5 py-3 rounded-full text-sm font-semibold">
                <span>{country.flag}</span>
                <span>{formattedPreview}</span>
              </div>
            </div>
          )}

          {!formattedPreview && (
            <div className="text-center text-sm text-gray-400">
              <span className="text-xl mr-2">{country.flag}</span>
              {country.countryName} &nbsp;&middot;&nbsp; {minAge}+ required
            </div>
          )}
        </div>

        <div className="space-y-6 pb-8">
          <button
            onClick={() => handleSubmit()}
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
