import { useState, FormEvent, useRef, ChangeEvent } from 'react';
import { Camera, MapPin, ArrowRight } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import DrinkSelector from './DrinkSelector';
import { getMinDrinkingAge, getCountryByCode } from '../services/geoLocationService';

interface ProfileSetupProps {
  onComplete: () => void;
}

const VIBE_OPTIONS = [
  'Happy Hour',
  'Big Game',
  'Casual Beer',
  'Cocktails',
  'Late Night',
  'Wine Tasting',
  'Craft Beer',
  'Sports Bar',
  'Live Music',
  'Karaoke',
];

const formatDate = (digits: string): string => {
  const d = digits.replace(/\D/g, '').slice(0, 8);
  if (d.length <= 2) return d;
  if (d.length <= 4) return `${d.slice(0, 2)}/${d.slice(2)}`;
  return `${d.slice(0, 2)}/${d.slice(2, 4)}/${d.slice(4, 8)}`;
};

const dobToISO = (digits: string): string | null => {
  if (digits.length !== 8) return null;
  const mm = digits.slice(0, 2);
  const dd = digits.slice(2, 4);
  const yyyy = digits.slice(4, 8);
  return `${yyyy}-${mm}-${dd}`;
};

export default function ProfileSetup({ onComplete }: ProfileSetupProps) {
  const { user } = useAuth();
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const countryCode = localStorage.getItem('userCountryCode') || 'US';
  const minAge = getMinDrinkingAge(countryCode);
  const country = getCountryByCode(countryCode);

  const [name, setName] = useState(localStorage.getItem('pendingUserName') || '');

  const existingDob = localStorage.getItem('pendingUserBirthday') || '';
  const existingDobDigits = existingDob
    ? existingDob.replace(/-/g, '').replace(/^(\d{4})(\d{2})(\d{2})$/, '$2$3$1')
    : '';
  const [dobRaw, setDobRaw] = useState(existingDobDigits);

  const [bio, setBio] = useState('');
  const [homeCity, setHomeCity] = useState('');
  const [vibeTags, setVibeTags] = useState<string[]>(
    JSON.parse(localStorage.getItem('pendingDrinkingVibes') || '[]')
  );
  const [favoriteDrinks, setFavoriteDrinks] = useState<string[]>(
    JSON.parse(localStorage.getItem('pendingFavoriteDrinks') || '[]')
  );
  const [venuePreferences] = useState<string[]>(
    JSON.parse(localStorage.getItem('pendingVenuePreferences') || '[]')
  );

  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [uploadingPhoto, setUploadingPhoto] = useState(false);

  const dobDisplay = formatDate(dobRaw);
  const isDobComplete = dobRaw.replace(/\D/g, '').length === 8;

  const handleDobChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const digits = e.target.value.replace(/\D/g, '').slice(0, 8);
    setDobRaw(digits);
  };

  const handlePhotoSelect = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.type)) {
      setError('Please select a valid image file (JPG, PNG, WEBP, or GIF)');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setError('Image must be smaller than 5MB');
      return;
    }

    setAvatarFile(file);
    setError('');

    const reader = new FileReader();
    reader.onload = (ev) => setAvatarPreview(ev.target?.result as string);
    reader.readAsDataURL(file);
  };

  const uploadAvatar = async (): Promise<string | null> => {
    if (!avatarFile || !user) return null;

    setUploadingPhoto(true);
    try {
      const ext = avatarFile.name.split('.').pop() || 'jpg';
      const path = `avatars/${user.id}/${Date.now()}.${ext}`;

      const { error: uploadError } = await supabase.storage
        .from('profiles')
        .upload(path, avatarFile, { upsert: true });

      if (uploadError) throw uploadError;

      const { data } = supabase.storage.from('profiles').getPublicUrl(path);
      return data.publicUrl;
    } catch (err: any) {
      setError(`Photo upload failed: ${err.message}`);
      return null;
    } finally {
      setUploadingPhoto(false);
    }
  };

  const calculateAge = (birthDate: string) => {
    const today = new Date();
    const birth = new Date(birthDate);
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    return age;
  };

  const toggleVibeTag = (tag: string) => {
    setVibeTags((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]
    );
  };

  const handleNext = () => {
    if (step === 1) {
      if (!name.trim()) {
        setError('Please enter your name');
        return;
      }
      if (!isDobComplete) {
        setError('Please enter your date of birth');
        return;
      }
      const isoDate = dobToISO(dobRaw.replace(/\D/g, ''));
      if (!isoDate) {
        setError('Please enter a valid date');
        return;
      }
      const parsed = new Date(isoDate);
      if (isNaN(parsed.getTime())) {
        setError('Please enter a valid date');
        return;
      }
      const age = calculateAge(isoDate);
      if (age < minAge) {
        setError(`You must be at least ${minAge} years old to use this app in ${country.countryName}`);
        return;
      }
      localStorage.setItem('pendingUserBirthday', isoDate);
      setError('');
      setStep(2);
    } else if (step === 2) {
      if (!homeCity.trim()) {
        setError('Please enter your city');
        return;
      }
      setError('');
      setStep(3);
    } else if (step === 3) {
      if (vibeTags.length === 0) {
        setError('Please select at least one vibe');
        return;
      }
      setError('');
      setStep(4);
    }
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    if (favoriteDrinks.length === 0) {
      setError('Please select at least one favorite drink');
      return;
    }

    setLoading(true);
    setError('');

    try {
      let avatarUrl: string | null = null;
      if (avatarFile) {
        avatarUrl = await uploadAvatar();
        if (!avatarUrl) {
          setLoading(false);
          return;
        }
      }

      const dob = localStorage.getItem('pendingUserBirthday') || '';
      const age = dob ? calculateAge(dob) : null;

      const profileData: Record<string, unknown> = {
        name,
        dob,
        is_21_plus_confirmed: true,
        bio,
        home_city: homeCity,
        vibe_tags: vibeTags,
        favorite_drinks: favoriteDrinks,
        venue_preferences: venuePreferences,
        ...(age !== null ? { age } : {}),
        ...(avatarUrl ? { avatar_url: avatarUrl } : {}),
      };

      const { error: upsertError } = await supabase
        .from('users')
        .upsert({ id: user!.id, ...profileData });

      if (upsertError) throw upsertError;

      localStorage.removeItem('pendingUserName');
      localStorage.removeItem('pendingUserBirthday');
      localStorage.removeItem('pendingFavoriteDrinks');
      localStorage.removeItem('pendingVenuePreferences');
      localStorage.removeItem('pendingDrinkingVibes');
      localStorage.setItem('onboarding_complete', 'true');
      onComplete();
    } catch (err: any) {
      setError(err.message);
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#FFF5F0] px-6 py-8">
      <div className="max-w-md mx-auto space-y-6">
        <div className="flex justify-center gap-2 mb-8">
          {[1, 2, 3, 4].map((i) => (
            <div
              key={i}
              className={`h-1 rounded-full transition-all ${
                i === step ? 'w-8 bg-[#E91E63]' : i < step ? 'w-4 bg-[#E91E63]/50' : 'w-1 bg-gray-300'
              }`}
            />
          ))}
        </div>

        {step === 1 && (
          <div className="space-y-6">
            <div className="text-center space-y-2">
              <h1 className="text-3xl font-bold text-gray-900">Tell us about yourself</h1>
              <p className="text-gray-600">Let's set up your profile</p>
            </div>

            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}

            <div className="space-y-4">
              <div className="flex justify-center mb-6">
                <div className="relative">
                  <div
                    className="w-32 h-32 bg-gray-200 rounded-full flex items-center justify-center overflow-hidden cursor-pointer"
                    onClick={() => fileInputRef.current?.click()}
                  >
                    {avatarPreview ? (
                      <img
                        src={avatarPreview}
                        alt="Profile preview"
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <Camera size={40} className="text-gray-400" />
                    )}
                  </div>
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    className="absolute bottom-0 right-0 bg-[#E91E63] text-white p-3 rounded-full shadow-lg hover:bg-[#C2185B] transition-colors"
                  >
                    <Camera size={20} />
                  </button>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/jpeg,image/png,image/webp,image/gif"
                    className="hidden"
                    onChange={handlePhotoSelect}
                  />
                </div>
              </div>

              {avatarPreview && (
                <p className="text-center text-sm text-green-600 font-medium -mt-2">
                  Photo selected — will upload when you complete the profile
                </p>
              )}

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Full Name</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                  placeholder="Your name"
                  className="w-full px-4 py-3 rounded-2xl border-2 border-gray-200 focus:border-[#E91E63] focus:outline-none bg-white"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Date of Birth</label>
                <input
                  type="text"
                  inputMode="numeric"
                  value={dobDisplay}
                  onChange={handleDobChange}
                  placeholder="MM/DD/YYYY"
                  maxLength={10}
                  className="w-full px-4 py-3 rounded-2xl border-2 border-gray-200 focus:border-[#E91E63] focus:outline-none bg-white text-center tracking-widest font-medium"
                />
                <p className="text-xs text-gray-400 mt-1 text-center">
                  {country.flag} Minimum age requirement: <span className="font-semibold text-[#E91E63]">{minAge}+</span>
                </p>
              </div>
            </div>

            <button
              onClick={handleNext}
              className="w-full bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg flex items-center justify-center gap-2 hover:bg-[#C2185B] transition-colors shadow-lg"
            >
              Next
              <ArrowRight size={20} />
            </button>
          </div>
        )}

        {step === 2 && (
          <div className="space-y-6">
            <div className="text-center space-y-2">
              <h1 className="text-3xl font-bold text-gray-900">About You</h1>
              <p className="text-gray-600">Tell others what you're about</p>
            </div>

            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Bio <span className="text-gray-400 font-normal">(optional)</span></label>
                <textarea
                  value={bio}
                  onChange={(e) => setBio(e.target.value)}
                  placeholder="Tell people a bit about yourself..."
                  rows={4}
                  className="w-full px-4 py-3 rounded-2xl border-2 border-gray-200 focus:border-[#E91E63] focus:outline-none bg-white resize-none"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Home City</label>
                <div className="relative">
                  <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
                  <input
                    type="text"
                    value={homeCity}
                    onChange={(e) => setHomeCity(e.target.value)}
                    placeholder="e.g., San Francisco, CA"
                    className="w-full pl-12 pr-4 py-3 rounded-2xl border-2 border-gray-200 focus:border-[#E91E63] focus:outline-none bg-white"
                  />
                </div>
              </div>
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setStep(1)}
                className="flex-1 bg-gray-200 text-gray-700 py-4 rounded-full font-semibold text-lg hover:bg-gray-300 transition-colors"
              >
                Back
              </button>
              <button
                onClick={handleNext}
                className="flex-1 bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg hover:bg-[#C2185B] transition-colors shadow-lg"
              >
                Next
              </button>
            </div>
          </div>
        )}

        {step === 3 && (
          <div className="space-y-6">
            <div className="text-center space-y-2">
              <h1 className="text-3xl font-bold text-gray-900">Your Vibes</h1>
              <p className="text-gray-600">What kind of nights do you enjoy?</p>
            </div>

            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-3">Select your vibes</label>
              <div className="flex flex-wrap gap-2">
                {VIBE_OPTIONS.map((vibe) => (
                  <button
                    key={vibe}
                    type="button"
                    onClick={() => toggleVibeTag(vibe)}
                    className={`px-4 py-2 rounded-full font-medium transition-colors ${
                      vibeTags.includes(vibe)
                        ? 'bg-[#E91E63] text-white'
                        : 'bg-white text-gray-700 border-2 border-gray-200'
                    }`}
                  >
                    {vibe}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setStep(2)}
                className="flex-1 bg-gray-200 text-gray-700 py-4 rounded-full font-semibold text-lg hover:bg-gray-300 transition-colors"
              >
                Back
              </button>
              <button
                onClick={handleNext}
                className="flex-1 bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg hover:bg-[#C2185B] transition-colors shadow-lg"
              >
                Next
              </button>
            </div>
          </div>
        )}

        {step === 4 && (
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="text-center space-y-2">
              <h1 className="text-3xl font-bold text-gray-900">Favorite Drinks</h1>
              <p className="text-gray-600">What do you usually order?</p>
            </div>

            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-3">
                Select your favorite drinks (up to 5)
              </label>
              <DrinkSelector
                selectedDrinks={favoriteDrinks}
                onDrinksChange={setFavoriteDrinks}
                maxSelections={5}
              />
            </div>

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setStep(3)}
                className="flex-1 bg-gray-200 text-gray-700 py-4 rounded-full font-semibold text-lg hover:bg-gray-300 transition-colors"
              >
                Back
              </button>
              <button
                type="submit"
                disabled={loading || uploadingPhoto}
                className="flex-1 bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg hover:bg-[#C2185B] transition-colors shadow-lg disabled:opacity-50"
              >
                {uploadingPhoto ? 'Uploading photo...' : loading ? 'Creating profile...' : 'Complete'}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
