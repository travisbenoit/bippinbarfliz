import { useState, useEffect, FormEvent } from 'react';
import { useNavigate } from 'react-router';
import { ArrowLeft, ArrowRight, ChevronDown, Shield, X } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import {
  detectUserCountry,
  formatPhoneNumber,
  getFullPhoneNumber,
  validatePhoneLength,
  ALL_COUNTRIES,
  type CountryInfo
} from '../../services/geoLocationService';

export default function SignIn() {
  const navigate = useNavigate();
  const [phoneNumber, setPhoneNumber] = useState('');
  const [selectedCountry, setSelectedCountry] = useState<CountryInfo | null>(null);
  const [showCountryPicker, setShowCountryPicker] = useState(false);
  const [loading, setLoading] = useState(false);
  const [detecting, setDetecting] = useState(true);
  const [error, setError] = useState('');
  const { twilioSendOtp } = useAuth();

  useEffect(() => {
    const detectCountry = async () => {
      setDetecting(true);
      const country = await detectUserCountry();
      setSelectedCountry(country);
      localStorage.setItem('userCountryCode', country.countryCode);
      localStorage.setItem('minDrinkingAge', String(country.minDrinkingAge));
      setDetecting(false);
    };
    detectCountry();
  }, []);

  const handlePhoneChange = (value: string) => {
    if (!selectedCountry) return;
    const formatted = formatPhoneNumber(value, selectedCountry.countryCode);
    setPhoneNumber(formatted);
  };

  const handleCountrySelect = (country: CountryInfo) => {
    setSelectedCountry(country);
    localStorage.setItem('userCountryCode', country.countryCode);
    localStorage.setItem('minDrinkingAge', String(country.minDrinkingAge));
    setPhoneNumber('');
    setShowCountryPicker(false);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');

    if (!selectedCountry) {
      setError('Please wait for country detection');
      return;
    }

    if (!validatePhoneLength(phoneNumber, selectedCountry.countryCode)) {
      setError('Please enter a valid phone number');
      return;
    }

    setLoading(true);

    const fullPhoneNumber = getFullPhoneNumber(phoneNumber, selectedCountry.countryCode);

    const { error, devOtp } = await twilioSendOtp(fullPhoneNumber);

    if (error) {
      setError(error.message);
      setLoading(false);
    } else {
      navigate('/verify-phone', {
        state: {
          phone: fullPhoneNumber,
          countryCode: selectedCountry.countryCode,
          isSignIn: true,
          devOtp,
        }
      });
    }
  };

  if (detecting) {
    return (
      <div className="min-h-screen bg-white flex flex-col items-center justify-center px-6">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-[#E91E63] border-t-transparent mb-4" />
        <p className="text-gray-600">Detecting your location...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white flex flex-col px-6 py-8">
      <div className="flex items-center mb-8">
        <button onClick={() => navigate('/')}>
          <ArrowLeft size={24} className="text-gray-700" />
        </button>
      </div>

      <div className="flex-1 flex flex-col justify-between max-w-md mx-auto w-full">
        <div className="space-y-8 pt-8">
          <div className="text-center space-y-2">
            <h1 className="text-3xl font-bold text-gray-900">
              Welcome Back!
            </h1>
            <h2 className="text-3xl font-bold text-gray-900">
              What's your number?
            </h2>
            <p className="text-gray-600 text-sm pt-4">
              Enter your phone number to sign in
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setShowCountryPicker(true)}
                className="flex items-center gap-2 px-4 py-4 rounded-2xl border-2 border-gray-200 bg-white hover:border-gray-300 transition-colors"
              >
                <span className="text-2xl">{selectedCountry?.flag}</span>
                <span className="text-sm font-medium text-gray-700">{selectedCountry?.dialCode}</span>
                <ChevronDown size={20} className="text-gray-400" />
              </button>
              <input
                type="tel"
                placeholder={selectedCountry?.phonePlaceholder || 'Enter number'}
                value={phoneNumber}
                onChange={(e) => handlePhoneChange(e.target.value)}
                required
                className="flex-1 px-4 py-4 rounded-2xl border-2 border-gray-200 focus:border-[#E91E63] focus:outline-none bg-white"
              />
            </div>
          </form>

          {selectedCountry && (
            <div className="text-center text-sm text-gray-500">
              <p>Detected location: {selectedCountry.countryName}</p>
            </div>
          )}
        </div>

        <div className="space-y-6 pb-8">
          <div className="flex items-center justify-center gap-2 text-[#00BFA5] text-sm">
            <Shield size={18} />
            <span>Your Information is safe with us</span>
          </div>

          <button
            onClick={handleSubmit}
            disabled={loading}
            className="w-full bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg flex items-center justify-center gap-2 hover:bg-[#C2185B] transition-colors shadow-lg disabled:opacity-50"
          >
            {loading ? 'Sending OTP...' : 'Get OTP'}
            <ArrowRight size={24} />
          </button>

          <p className="text-center text-gray-600">
            Don't have an account?{' '}
            <button
              onClick={() => navigate('/signup')}
              className="text-[#E91E63] font-semibold"
            >
              Sign up
            </button>
          </p>

          <div className="h-1 w-32 bg-gray-900 rounded-full mx-auto" />
        </div>
      </div>

      {showCountryPicker && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end justify-center">
          <div className="bg-white w-full max-w-md rounded-t-3xl max-h-[80vh] flex flex-col">
            <div className="flex items-center justify-between p-4 border-b">
              <h3 className="text-lg font-semibold">Select Country</h3>
              <button onClick={() => setShowCountryPicker(false)}>
                <X size={24} className="text-gray-500" />
              </button>
            </div>
            <div className="overflow-y-auto flex-1">
              {ALL_COUNTRIES.map((country) => (
                <button
                  key={country.countryCode}
                  onClick={() => handleCountrySelect(country)}
                  className={`w-full flex items-center gap-4 px-4 py-3 hover:bg-gray-50 transition-colors ${
                    selectedCountry?.countryCode === country.countryCode ? 'bg-pink-50' : ''
                  }`}
                >
                  <span className="text-2xl">{country.flag}</span>
                  <div className="flex-1 text-left">
                    <p className="font-medium text-gray-900">{country.countryName}</p>
                    <p className="text-sm text-gray-500">{country.dialCode}</p>
                  </div>
                  {selectedCountry?.countryCode === country.countryCode && (
                    <div className="w-5 h-5 rounded-full bg-[#E91E63] flex items-center justify-center">
                      <div className="w-2 h-2 rounded-full bg-white" />
                    </div>
                  )}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
