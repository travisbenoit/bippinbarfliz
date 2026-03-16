import { useState, useEffect, useRef } from 'react';
import { ArrowLeft, Camera, X, Upload, Sparkles, Music as MusicIcon, MessageCircle, Briefcase, GraduationCap, Instagram, DollarSign, Wallet, CircleCheck as CheckCircle, ExternalLink } from 'lucide-react';
import { useNavigate } from 'react-router';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';
import type { Database } from '../../lib/database.types';
import DrinkSelector from '../DrinkSelector';
import { usePaymentProvider } from '../../hooks/usePaymentProvider';
import { logger } from '../../lib/logger';

type UserProfile = Database['public']['Tables']['users']['Row'];

const VIBE_OPTIONS = [
  'Chill Vibes', 'Party Mode', 'Live Music', 'Craft Cocktails',
  'Sports Fan', 'Dancing', 'Rooftop Scene', 'Dive Bars',
  'Wine Lover', 'Beer Enthusiast', 'Karaoke', 'Late Night',
  'Happy Hour', 'Brunch Crowd', 'Networking', 'Date Night'
];

const INTEREST_OPTIONS = [
  'Music', 'Sports', 'Travel', 'Food & Cooking', 'Movies', 'Gaming',
  'Fitness', 'Art', 'Tech', 'Fashion', 'Photography', 'Books',
  'Outdoor Activities', 'Comedy', 'Dancing', 'Entrepreneurship'
];

const LOOKING_FOR_OPTIONS = [
  'New Friends', 'Dating', 'Networking', 'Activity Partners', 'Just Vibing'
];

export default function EditProfile() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { showError, showSuccess } = useToast();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [activeTab, setActiveTab] = useState<'basic' | 'personality' | 'social'>('basic');

  const [name, setName] = useState('');
  const [dob, setDob] = useState('');
  const [bio, setBio] = useState('');
  const [homeCity, setHomeCity] = useState('');
  const [occupation, setOccupation] = useState('');
  const [education, setEducation] = useState('');

  const [selectedVibes, setSelectedVibes] = useState<string[]>([]);
  const [selectedDrinks, setSelectedDrinks] = useState<string[]>([]);
  const [selectedInterests, setSelectedInterests] = useState<string[]>([]);
  const [lookingFor, setLookingFor] = useState('');

  const [funFact, setFunFact] = useState('');
  const [goToKaraokeSong, setGoToKaraokeSong] = useState('');
  const [idealNightOut, setIdealNightOut] = useState('');
  const [firstDrinkOnMe, setFirstDrinkOnMe] = useState(false);

  const [spotifyUsername, setSpotifyUsername] = useState('');
  const [instagramUsername, setInstagramUsername] = useState('');

  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);
  const [paymentLinked, setPaymentLinked] = useState(false);
  const [paymentUsername, setPaymentUsername] = useState('');
  const paymentProvider = usePaymentProvider();

  useEffect(() => {
    loadProfile();
  }, []);

  const loadProfile = async () => {
    const { data } = await supabase
      .from('users')
      .select('*')
      .eq('id', user!.id)
      .maybeSingle();

    if (data) {
      setProfile(data);
      setName(data.name || '');
      setDob(data.dob || '');
      setBio(data.bio || '');
      setHomeCity(data.home_city || '');
      setOccupation(data.occupation || '');
      setEducation(data.education || '');

      setSelectedVibes(data.vibe_tags || []);
      setSelectedDrinks(data.favorite_drinks || []);
      setSelectedInterests(data.interests || []);
      setLookingFor(data.looking_for || '');

      setFunFact(data.fun_fact || '');
      setGoToKaraokeSong(data.go_to_karaoke_song || '');
      setIdealNightOut(data.ideal_night_out || '');
      setFirstDrinkOnMe(data.first_drink_on_me || false);

      setSpotifyUsername(data.spotify_username || '');
      setInstagramUsername(data.instagram_username || '');

      setAvatarUrl(data.avatar_url || null);
      setPaymentLinked(data.payment_provider_linked || data.venmo_linked || false);
      setPaymentUsername(data.payment_provider_username || data.venmo_username || '');
    }
    setLoading(false);
  };

  const compressImage = (file: File): Promise<File> =>
    new Promise((resolve) => {
      const img = new Image();
      const objectUrl = URL.createObjectURL(file);
      img.onload = () => {
        const MAX_PX = 800;
        const scale = Math.min(1, MAX_PX / Math.max(img.width, img.height));
        const canvas = document.createElement('canvas');
        canvas.width = Math.round(img.width * scale);
        canvas.height = Math.round(img.height * scale);
        canvas.getContext('2d')!.drawImage(img, 0, 0, canvas.width, canvas.height);
        URL.revokeObjectURL(objectUrl);
        canvas.toBlob(
          (blob) => resolve(new File([blob!], 'avatar.jpg', { type: 'image/jpeg' })),
          'image/jpeg',
          0.85
        );
      };
      img.onerror = () => { URL.revokeObjectURL(objectUrl); resolve(file); };
      img.src = objectUrl;
    });

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const raw = e.target.files?.[0];
    if (!raw) return;

    if (!raw.type.startsWith('image/')) {
      showError('Please select an image file');
      return;
    }

    if (raw.size > 10 * 1024 * 1024) {
      showError('Image must be less than 10MB');
      return;
    }

    setUploadingImage(true);

    try {
      const file = await compressImage(raw);
      const fileName = `${Date.now()}.jpg`;
      const filePath = `avatars/${user!.id}/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('profiles')
        .upload(filePath, file, { upsert: true });

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabase.storage
        .from('profiles')
        .getPublicUrl(filePath);

      setAvatarUrl(publicUrl);

      await supabase
        .from('users')
        .update({ avatar_url: publicUrl })
        .eq('id', user!.id);

    } catch (error: any) {
      logger.error('Error uploading image:', error);
      showError('Failed to upload image. Please try again.');
    } finally {
      setUploadingImage(false);
    }
  };

  const handleSave = async () => {
    if (!name.trim()) {
      showError('Please enter your name');
      return;
    }

    setSaving(true);

    const { error } = await supabase
      .from('users')
      .update({
        name,
        dob,
        bio,
        home_city: homeCity,
        occupation,
        education,
        vibe_tags: selectedVibes,
        favorite_drinks: selectedDrinks,
        interests: selectedInterests,
        looking_for: lookingFor,
        fun_fact: funFact,
        go_to_karaoke_song: goToKaraokeSong,
        ideal_night_out: idealNightOut,
        first_drink_on_me: firstDrinkOnMe,
        spotify_username: spotifyUsername,
        instagram_username: instagramUsername,
        avatar_url: avatarUrl,
      })
      .eq('id', user!.id);

    setSaving(false);

    if (!error) {
      showSuccess('Profile saved!');
      navigate('/profile');
    } else {
      showError('Failed to save profile. Please try again.');
    }
  };

  const toggleVibe = (vibe: string) => {
    if (selectedVibes.includes(vibe)) {
      setSelectedVibes(selectedVibes.filter(v => v !== vibe));
    } else if (selectedVibes.length < 5) {
      setSelectedVibes([...selectedVibes, vibe]);
    }
  };

  const toggleInterest = (interest: string) => {
    if (selectedInterests.includes(interest)) {
      setSelectedInterests(selectedInterests.filter(i => i !== interest));
    } else if (selectedInterests.length < 8) {
      setSelectedInterests([...selectedInterests, interest]);
    }
  };

  if (loading) {
    return (
      <div className="h-full flex items-center justify-center bg-[#FFF5F0]">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-[#E91E63] border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Loading profile...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto bg-[#FFF5F0]">
      <div className="bg-white shadow-sm p-4 flex items-center justify-between sticky top-0 z-10">
        <div className="flex items-center gap-2">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
          >
            <ArrowLeft size={24} className="text-gray-700" />
          </button>
          <h1 className="text-xl font-bold text-gray-900">Edit Profile</h1>
        </div>
        <button
          onClick={handleSave}
          disabled={saving || !name.trim()}
          className="px-6 py-2 bg-[#E91E63] text-white rounded-full font-medium disabled:opacity-50 hover:bg-[#C2185B] transition-colors"
        >
          {saving ? 'Saving...' : 'Save'}
        </button>
      </div>

      <div className="flex border-b border-gray-200 bg-white sticky top-[72px] z-10">
        <button
          onClick={() => setActiveTab('basic')}
          className={`flex-1 py-3 px-4 font-semibold transition-colors ${
            activeTab === 'basic'
              ? 'text-[#E91E63] border-b-2 border-[#E91E63]'
              : 'text-gray-500'
          }`}
        >
          Basic Info
        </button>
        <button
          onClick={() => setActiveTab('personality')}
          className={`flex-1 py-3 px-4 font-semibold transition-colors ${
            activeTab === 'personality'
              ? 'text-[#E91E63] border-b-2 border-[#E91E63]'
              : 'text-gray-500'
          }`}
        >
          Personality
        </button>
        <button
          onClick={() => setActiveTab('social')}
          className={`flex-1 py-3 px-4 font-semibold transition-colors ${
            activeTab === 'social'
              ? 'text-[#E91E63] border-b-2 border-[#E91E63]'
              : 'text-gray-500'
          }`}
        >
          Social
        </button>
      </div>

      <div className="p-4 space-y-4 pb-24">
        {activeTab === 'basic' && (
          <>
            <div className="bg-white rounded-2xl p-5 shadow-sm">
              <h2 className="font-semibold text-gray-900 mb-4 flex items-center gap-2">
                <Camera size={20} className="text-[#E91E63]" />
                Profile Photo
              </h2>
              <div className="flex items-center gap-4">
                <div className="w-24 h-24 bg-gradient-to-br from-pink-200 to-orange-200 rounded-full flex items-center justify-center overflow-hidden">
                  {avatarUrl ? (
                    <img src={avatarUrl} alt={name} className="w-full h-full object-cover" />
                  ) : (
                    <span className="text-4xl font-bold text-[#E91E63]">
                      {name.charAt(0) || 'U'}
                    </span>
                  )}
                </div>
                <div className="flex flex-col gap-2">
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleImageUpload}
                    className="hidden"
                  />
                  <button
                    onClick={() => fileInputRef.current?.click()}
                    disabled={uploadingImage}
                    className="flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-full text-gray-700 hover:bg-gray-50 transition-colors disabled:opacity-50"
                  >
                    <Upload size={18} />
                    <span>{uploadingImage ? 'Uploading...' : 'Upload Photo'}</span>
                  </button>
                  <p className="text-xs text-gray-500">Max 5MB, JPG or PNG</p>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-2xl p-5 shadow-sm space-y-4">
              <h2 className="font-semibold text-gray-900">Basic Information</h2>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Name *</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all"
                  placeholder="Your name"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Date of Birth</label>
                <input
                  type="date"
                  value={dob}
                  onChange={(e) => setDob(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Bio</label>
                <textarea
                  value={bio}
                  onChange={(e) => setBio(e.target.value)}
                  rows={3}
                  maxLength={200}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all resize-none"
                  placeholder="Tell others about yourself..."
                />
                <p className="text-xs text-gray-500 text-right mt-1">{bio.length}/200</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Home City</label>
                <input
                  type="text"
                  value={homeCity}
                  onChange={(e) => setHomeCity(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all"
                  placeholder="e.g., Los Angeles, CA"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1 flex items-center gap-2">
                  <Briefcase size={16} />
                  Occupation
                </label>
                <input
                  type="text"
                  value={occupation}
                  onChange={(e) => setOccupation(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all"
                  placeholder="What do you do?"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1 flex items-center gap-2">
                  <GraduationCap size={16} />
                  Education
                </label>
                <input
                  type="text"
                  value={education}
                  onChange={(e) => setEducation(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all"
                  placeholder="Your school or degree"
                />
              </div>
            </div>

            <div className="bg-white rounded-2xl p-5 shadow-sm space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="font-semibold text-gray-900 flex items-center gap-2">
                  <Sparkles size={20} className="text-[#E91E63]" />
                  My Vibes
                </h2>
                <span className="text-sm text-gray-500">{selectedVibes.length}/5</span>
              </div>
              <p className="text-sm text-gray-600">Select up to 5 vibes that match your style</p>
              <div className="flex flex-wrap gap-2">
                {VIBE_OPTIONS.map((vibe) => (
                  <button
                    key={vibe}
                    onClick={() => toggleVibe(vibe)}
                    disabled={!selectedVibes.includes(vibe) && selectedVibes.length >= 5}
                    className={`px-3 py-2 rounded-full text-sm font-medium transition-all ${
                      selectedVibes.includes(vibe)
                        ? 'bg-[#E91E63] text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200 disabled:opacity-50'
                    }`}
                  >
                    {vibe}
                  </button>
                ))}
              </div>
            </div>

            <div className="bg-white rounded-2xl p-5 shadow-sm space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="font-semibold text-gray-900">Favorite Drinks</h2>
                <span className="text-sm text-gray-500">{selectedDrinks.length}/5</span>
              </div>
              <p className="text-sm text-gray-600">What do you usually order?</p>
              <DrinkSelector
                selectedDrinks={selectedDrinks}
                onDrinksChange={setSelectedDrinks}
                maxSelections={5}
              />
            </div>
          </>
        )}

        {activeTab === 'personality' && (
          <>
            <div className="bg-white rounded-2xl p-5 shadow-sm space-y-4">
              <h2 className="font-semibold text-gray-900 flex items-center gap-2">
                <MessageCircle size={20} className="text-[#E91E63]" />
                Looking For
              </h2>
              <p className="text-sm text-gray-600">What brings you out tonight?</p>
              <div className="flex flex-wrap gap-2">
                {LOOKING_FOR_OPTIONS.map((option) => (
                  <button
                    key={option}
                    onClick={() => setLookingFor(option)}
                    className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                      lookingFor === option
                        ? 'bg-[#E91E63] text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    }`}
                  >
                    {option}
                  </button>
                ))}
              </div>
            </div>

            <div className="bg-white rounded-2xl p-5 shadow-sm space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="font-semibold text-gray-900">Interests</h2>
                <span className="text-sm text-gray-500">{selectedInterests.length}/8</span>
              </div>
              <p className="text-sm text-gray-600">What are you passionate about?</p>
              <div className="flex flex-wrap gap-2">
                {INTEREST_OPTIONS.map((interest) => (
                  <button
                    key={interest}
                    onClick={() => toggleInterest(interest)}
                    disabled={!selectedInterests.includes(interest) && selectedInterests.length >= 8}
                    className={`px-3 py-2 rounded-full text-sm font-medium transition-all ${
                      selectedInterests.includes(interest)
                        ? 'bg-[#E91E63] text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200 disabled:opacity-50'
                    }`}
                  >
                    {interest}
                  </button>
                ))}
              </div>
            </div>

            <div className="bg-white rounded-2xl p-5 shadow-sm space-y-4">
              <h2 className="font-semibold text-gray-900">Conversation Starters</h2>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Fun Fact</label>
                <textarea
                  value={funFact}
                  onChange={(e) => setFunFact(e.target.value)}
                  rows={2}
                  maxLength={150}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all resize-none"
                  placeholder="Something interesting about you..."
                />
                <p className="text-xs text-gray-500 text-right mt-1">{funFact.length}/150</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1 flex items-center gap-2">
                  <MusicIcon size={16} />
                  Go-To Karaoke Song
                </label>
                <input
                  type="text"
                  value={goToKaraokeSong}
                  onChange={(e) => setGoToKaraokeSong(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all"
                  placeholder="Your karaoke jam"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Ideal Night Out</label>
                <textarea
                  value={idealNightOut}
                  onChange={(e) => setIdealNightOut(e.target.value)}
                  rows={2}
                  maxLength={150}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all resize-none"
                  placeholder="Describe your perfect night..."
                />
                <p className="text-xs text-gray-500 text-right mt-1">{idealNightOut.length}/150</p>
              </div>

              <div className="flex items-center justify-between p-4 bg-gradient-to-r from-green-50 to-emerald-50 rounded-xl border border-green-200">
                <div className="flex items-center gap-3">
                  <DollarSign size={24} className="text-green-600" />
                  <div>
                    <p className="font-medium text-gray-900">First drink on me</p>
                    <p className="text-xs text-gray-600">Show you're generous</p>
                  </div>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={firstDrinkOnMe}
                    onChange={(e) => setFirstDrinkOnMe(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-[#E91E63]/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#E91E63]"></div>
                </label>
              </div>
            </div>
          </>
        )}

        {activeTab === 'social' && (
          <>
            <div className="bg-white rounded-2xl p-5 shadow-sm space-y-4">
              <h2 className="font-semibold text-gray-900">Connect Your Socials</h2>
              <p className="text-sm text-gray-600">Let others find and connect with you</p>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1 flex items-center gap-2">
                  <Instagram size={16} className="text-pink-600" />
                  Instagram
                </label>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">@</span>
                  <input
                    type="text"
                    value={instagramUsername}
                    onChange={(e) => setInstagramUsername(e.target.value)}
                    className="w-full pl-8 pr-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all"
                    placeholder="username"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1 flex items-center gap-2">
                  <MusicIcon size={16} className="text-green-600" />
                  Spotify
                </label>
                <input
                  type="text"
                  value={spotifyUsername}
                  onChange={(e) => setSpotifyUsername(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all"
                  placeholder="Your Spotify username"
                />
              </div>
            </div>

            <div className="bg-white rounded-2xl p-5 shadow-sm space-y-4">
              <h2 className="font-semibold text-gray-900 flex items-center gap-2">
                <Wallet size={20} className="text-[#008CFF]" />
                Payment Account
              </h2>
              <p className="text-sm text-gray-600">
                Connect your {paymentProvider.displayName} account to send and receive drinks
              </p>
              {paymentLinked && paymentUsername ? (
                <div className="flex items-center gap-3 p-4 bg-emerald-50 rounded-xl border border-emerald-200">
                  <CheckCircle size={20} className="text-emerald-600 flex-shrink-0" />
                  <div className="flex-1">
                    <p className="font-medium text-gray-900">{paymentProvider.displayName} Connected</p>
                    <p className="text-sm text-gray-600">@{paymentUsername}</p>
                  </div>
                  <button
                    onClick={() => navigate('/payments/setup')}
                    className="text-sm text-[#008CFF] font-medium"
                  >
                    Manage
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => navigate('/payments/setup')}
                  className="w-full flex items-center justify-between p-4 bg-[#008CFF]/5 rounded-xl border border-[#008CFF]/20 hover:bg-[#008CFF]/10 transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-[#008CFF] flex items-center justify-center">
                      {paymentProvider.isVenmo ? (
                        <span className="text-white font-black text-lg">V</span>
                      ) : (
                        <Wallet size={20} className="text-white" />
                      )}
                    </div>
                    <div className="text-left">
                      <p className="font-medium text-gray-900">Connect {paymentProvider.displayName}</p>
                      <p className="text-xs text-gray-500">Send and receive drinks</p>
                    </div>
                  </div>
                  <ExternalLink size={18} className="text-[#008CFF]" />
                </button>
              )}
            </div>

            <div className="bg-gradient-to-br from-pink-50 to-orange-50 rounded-2xl p-5 border border-pink-200">
              <div className="flex items-start gap-3">
                <Sparkles size={24} className="text-[#E91E63] flex-shrink-0 mt-1" />
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">Profile Tips</h3>
                  <ul className="space-y-2 text-sm text-gray-700">
                    <li>• Add a clear profile photo to get 3x more connections</li>
                    <li>• Share your interests to find like-minded people</li>
                    <li>• Be authentic - the best connections start with honesty</li>
                    <li>• Update your status regularly to stay visible</li>
                  </ul>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
