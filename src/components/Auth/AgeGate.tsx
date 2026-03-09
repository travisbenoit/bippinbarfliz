import { useState, FormEvent } from 'react';
import { Shield, AlertTriangle } from 'lucide-react';
import { getMinDrinkingAge, getCountryByCode } from '../../services/geoLocationService';

interface AgeGateProps {
  onPass: () => void;
}

const calculateAge = (birthDate: string): number => {
  const today = new Date();
  const birth = new Date(birthDate);
  let age = today.getFullYear() - birth.getFullYear();
  const m = today.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--;
  return age;
};

export default function AgeGate({ onPass }: AgeGateProps) {
  const countryCode = localStorage.getItem('userCountryCode') || 'US';
  const minAge = getMinDrinkingAge(countryCode);
  const country = getCountryByCode(countryCode);

  const [dob, setDob] = useState('');
  const [blocked, setBlocked] = useState(false);

  const maxDate = (() => {
    const d = new Date();
    d.setFullYear(d.getFullYear() - minAge);
    return d.toISOString().split('T')[0];
  })();

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (!dob) return;
    const age = calculateAge(dob);
    if (age >= minAge) {
      localStorage.setItem('age_verified', 'true');
      onPass();
    } else {
      setBlocked(true);
    }
  };

  if (blocked) {
    return (
      <div className="min-h-screen bg-gray-950 flex flex-col items-center justify-center px-6 text-center">
        <div className="w-20 h-20 bg-red-900/30 rounded-full flex items-center justify-center mb-6">
          <AlertTriangle className="w-10 h-10 text-red-400" />
        </div>
        <h1 className="text-2xl font-bold text-white mb-3">Access Restricted</h1>
        <p className="text-gray-400 text-base max-w-xs leading-relaxed">
          You must be at least <span className="text-white font-semibold">{minAge} years old</span> to use Barfliz in {country.countryName}.
        </p>
        <p className="text-gray-600 text-sm mt-6">
          This app is an alcohol-related service subject to local legal requirements.
        </p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-950 flex flex-col items-center justify-center px-6">
      <div className="w-full max-w-sm">
        <div className="flex flex-col items-center mb-10">
          <div className="w-16 h-16 bg-gradient-to-br from-[#E91E63] to-[#FF6B6B] rounded-2xl flex items-center justify-center mb-5 shadow-lg">
            <Shield className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white mb-2">Age Verification</h1>
          <p className="text-gray-400 text-center text-sm leading-relaxed">
            Barfliz is an alcohol-related app. You must be{' '}
            <span className="text-white font-semibold">{minAge}+ years old</span> to continue in{' '}
            <span className="text-white">{country.flag} {country.countryName}</span>.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <label className="block text-sm font-medium text-gray-400 mb-2">
              Date of Birth
            </label>
            <input
              type="date"
              value={dob}
              onChange={(e) => setDob(e.target.value)}
              max={new Date().toISOString().split('T')[0]}
              required
              className="w-full px-4 py-3.5 bg-gray-900 border border-gray-700 rounded-xl text-white focus:border-[#E91E63] focus:outline-none focus:ring-1 focus:ring-[#E91E63] transition-colors"
              style={{ colorScheme: 'dark' }}
            />
          </div>

          <button
            type="submit"
            disabled={!dob}
            className="w-full py-4 bg-gradient-to-r from-[#E91E63] to-[#FF6B6B] text-white rounded-xl font-semibold text-base hover:shadow-lg hover:shadow-pink-500/25 transition-all disabled:opacity-40 disabled:cursor-not-allowed"
          >
            Verify My Age
          </button>
        </form>

        <p className="text-center text-xs text-gray-600 mt-6 leading-relaxed">
          Your date of birth is used only for age verification and is not stored.
        </p>

        <div className="mt-8 pt-6 border-t border-gray-800 flex justify-center gap-6">
          <a href="/terms-of-service.html" target="_blank" rel="noopener noreferrer" className="text-xs text-gray-500 hover:text-gray-300 transition-colors">
            Terms of Service
          </a>
          <a href="/privacy-policy.html" target="_blank" rel="noopener noreferrer" className="text-xs text-gray-500 hover:text-gray-300 transition-colors">
            Privacy Policy
          </a>
        </div>
      </div>
    </div>
  );
}
