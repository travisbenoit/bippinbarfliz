import { useState, useEffect } from 'react';
import { Settings, Edit3, MapPin, Heart, LogOut, DollarSign, Trophy, Flame } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';
import { xpService, UserStats } from '../../services/xpService';
import TonightStatusModal from '../TonightStatus/TonightStatusModal';
import { XPProfile } from '../Community/XPProfile';
import type { Database } from '../../lib/database.types';

type UserProfile = Database['public']['Tables']['users']['Row'];
type TonightStatus = 'going_out' | 'maybe' | 'staying_in' | null;

export default function ProfileView() {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const { showSuccess, showError } = useToast();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [savingStatus, setSavingStatus] = useState(false);
  const [showStatusModal, setShowStatusModal] = useState(false);
  const [currentStatus, setCurrentStatus] = useState<TonightStatus>(null);
  const [currentVenue, setCurrentVenue] = useState<string | null>(null);
  const [showXPProfile, setShowXPProfile] = useState(false);
  const [userStats, setUserStats] = useState<UserStats | null>(null);
  const [coinBalance, setCoinBalance] = useState(0);

  useEffect(() => {
    loadProfile();
    if (user) {
      xpService.getUserStats(user.id).then(setUserStats).catch(() => null);
      xpService.getCoinBalance(user.id).then(setCoinBalance).catch(() => null);
      xpService.autoAssignChallenges(user.id).catch(() => null);
    }
  }, [user]);

  const loadProfile = async () => {
    if (!user) {
      setLoading(false);
      return;
    }

    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

      if (error) {
        console.error('Error loading profile:', error);
      }

      if (data) {
        setProfile(data);
        const dbStatus = data.tonight_status;
        if (dbStatus === 'out_now') setCurrentStatus('going_out');
        else if (dbStatus === 'going_out_soon') setCurrentStatus('maybe');
        else if (dbStatus === 'staying_in') setCurrentStatus('staying_in');
        else setCurrentStatus(null);
      }
    } catch (err) {
      console.error('Unexpected error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleStatusSave = async (status: TonightStatus, venue: string | null) => {
    if (!user) return;
    setSavingStatus(true);
    let dbStatus: string | null = null;
    if (status === 'going_out') dbStatus = 'out_now';
    else if (status === 'maybe') dbStatus = 'going_out_soon';
    else if (status === 'staying_in') dbStatus = 'staying_in';

    const { error } = await supabase
      .from('users')
      .update({ tonight_status: dbStatus })
      .eq('id', user.id);

    if (!error) {
      setCurrentStatus(status);
      setCurrentVenue(venue);
      showSuccess('Status updated');
      loadProfile();
    } else {
      showError('Could not update status. Try again.');
    }
    setSavingStatus(false);
  };

  const handleSignOut = async () => {
    await signOut();
    navigate('/');
  };

  const calculateAge = (dob: string) => {
    const today = new Date();
    const birthDate = new Date(dob);
    let age = today.getFullYear() - birthDate.getFullYear();
    const m = today.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    return age;
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

  if (!profile) {
    return (
      <div className="h-full flex items-center justify-center bg-[#FFF5F0] p-6">
        <div className="text-center max-w-md">
          <div className="w-20 h-20 bg-[#E91E63] bg-opacity-10 rounded-full flex items-center justify-center mx-auto mb-4">
            <Settings size={40} className="text-[#E91E63]" />
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Profile Not Found</h2>
          <p className="text-gray-600 mb-6">
            It looks like your profile hasn't been set up yet. Please complete your profile to continue.
          </p>
          <button
            onClick={() => navigate('/settings/edit-profile')}
            className="bg-[#E91E63] text-white px-6 py-3 rounded-full font-semibold hover:bg-[#C2185B] transition-colors"
          >
            Complete Profile Setup
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-20">
      <div className="bg-gradient-to-br from-pink-200 to-orange-200 p-6 pb-20">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold text-gray-900">Profile</h1>
          <button
            onClick={() => navigate('/settings')}
            className="p-2 bg-white rounded-full shadow-md hover:shadow-lg transition-shadow"
          >
            <Settings size={24} className="text-gray-700" />
          </button>
        </div>

        <div className="flex flex-col items-center">
          <div className="w-32 h-32 bg-white rounded-full flex items-center justify-center shadow-lg mb-4 overflow-hidden">
            {profile.avatar_url ? (
              <img src={profile.avatar_url} alt={profile.name} className="w-full h-full object-cover" />
            ) : (
              <span className="text-5xl font-bold text-[#E91E63]">
                {profile.name.charAt(0)}
              </span>
            )}
          </div>
          <h2 className="text-2xl font-bold text-gray-900">
            {profile.name}, {calculateAge(profile.dob)}
          </h2>

          <div className="mt-3 flex items-center justify-center gap-2">
            {(profile.registration_country === 'US' || (!profile.registration_country && profile.phone_country_code === '+1')) ? (
              <div className="flex items-center gap-2 px-4 py-2 bg-white rounded-full shadow-sm">
                <div className="w-6 h-6 bg-[#008CFF] rounded-full flex items-center justify-center">
                  <DollarSign size={14} className="text-white" />
                </div>
                {profile.venmo_linked && profile.venmo_username ? (
                  <span className="text-sm font-medium text-gray-900">
                    @{profile.venmo_username}
                  </span>
                ) : (
                  <span className="text-xs text-gray-400">Venmo</span>
                )}
              </div>
            ) : (
              <div className="flex items-center gap-2 px-4 py-2 bg-white rounded-full shadow-sm">
                <div className="w-6 h-6 bg-gradient-to-br from-[#FF6B6B] to-[#FFB347] rounded-full flex items-center justify-center">
                  <DollarSign size={14} className="text-white" />
                </div>
                {profile.payment_provider_linked && profile.payment_provider_username ? (
                  <span className="text-sm font-medium text-gray-900">
                    @{profile.payment_provider_username}
                  </span>
                ) : (
                  <span className="text-xs text-gray-400">Beem It</span>
                )}
              </div>
            )}
          </div>

          <p className="text-gray-700 flex items-center gap-1 mt-3">
            <MapPin size={16} />
            {profile.home_city}
          </p>
          {profile.occupation && (
            <p className="text-gray-600 text-sm mt-1">{profile.occupation}</p>
          )}
          {profile.looking_for && (
            <span className="mt-2 px-3 py-1 bg-white/50 backdrop-blur-sm rounded-full text-sm font-medium text-gray-700">
              {profile.looking_for}
            </span>
          )}
        </div>
      </div>

      <div className="px-6 -mt-12 space-y-4">
        <button
          onClick={() => setShowStatusModal(true)}
          className="w-full bg-white rounded-2xl p-6 shadow-md space-y-4 text-left hover:shadow-lg transition-shadow"
        >
          <div className="flex items-center justify-between">
            <h3 className="font-semibold text-gray-900">Tonight's Status</h3>
            <span className="text-[#E91E63] text-sm font-medium">
              Change
            </span>
          </div>
          <div className="flex items-center gap-2 p-3 bg-gray-50 rounded-xl">
            <div className={`w-4 h-4 rounded-full ${
              profile.tonight_status === 'out_now' ? 'bg-emerald-500' :
              profile.tonight_status === 'going_out_soon' ? 'bg-amber-500' :
              'bg-gray-400'
            }`} />
            <div>
              <p className="font-medium text-gray-900">
                {profile.tonight_status === 'out_now' && 'Going Out'}
                {profile.tonight_status === 'going_out_soon' && 'Maybe'}
                {profile.tonight_status === 'staying_in' && 'Staying In'}
                {!profile.tonight_status && 'Not Set'}
              </p>
              <p className="text-xs text-gray-500">
                Let others know your plans
              </p>
            </div>
          </div>
        </button>

        <div className="bg-white rounded-2xl p-6 shadow-md space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-semibold text-gray-900">About Me</h3>
            <button
              onClick={() => navigate('/settings/edit-profile')}
              className="text-[#E91E63]"
            >
              <Edit3 size={18} />
            </button>
          </div>
          <p className="text-gray-700">{profile.bio}</p>
        </div>

        <div className="bg-white rounded-2xl p-6 shadow-md space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-semibold text-gray-900">My Vibes</h3>
            <button
              onClick={() => navigate('/settings/edit-profile')}
              className="text-[#E91E63]"
            >
              <Edit3 size={18} />
            </button>
          </div>
          <div className="flex flex-wrap gap-2">
            {profile.vibe_tags.map((tag, i) => (
              <span
                key={i}
                className="px-3 py-2 bg-[#E91E63] bg-opacity-10 text-[#E91E63] rounded-full text-sm font-medium"
              >
                {tag}
              </span>
            ))}
          </div>
        </div>

        {profile.favorite_drinks.length > 0 && (
          <div className="bg-white rounded-2xl p-6 shadow-md space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-semibold text-gray-900 flex items-center gap-2">
                <Heart size={18} className="text-[#E91E63]" />
                Favorite Drinks
              </h3>
              <button
                onClick={() => navigate('/settings/edit-profile')}
                className="text-[#E91E63]"
              >
                <Edit3 size={18} />
              </button>
            </div>
            <div className="flex flex-wrap gap-2">
              {profile.favorite_drinks.map((drink, i) => (
                <span
                  key={i}
                  className="px-3 py-2 bg-gray-100 text-gray-700 rounded-full text-sm"
                >
                  {drink}
                </span>
              ))}
            </div>
          </div>
        )}

        {(profile.interests?.length > 0) && (
          <div className="bg-white rounded-2xl p-6 shadow-md space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-semibold text-gray-900">Interests</h3>
              <button
                onClick={() => navigate('/settings/edit-profile')}
                className="text-[#E91E63]"
              >
                <Edit3 size={18} />
              </button>
            </div>
            <div className="flex flex-wrap gap-2">
              {profile.interests.map((interest, i) => (
                <span
                  key={i}
                  className="px-3 py-2 bg-blue-50 text-blue-700 rounded-full text-sm"
                >
                  {interest}
                </span>
              ))}
            </div>
          </div>
        )}

        {(profile.fun_fact || profile.go_to_karaoke_song || profile.ideal_night_out) && (
          <div className="bg-white rounded-2xl p-6 shadow-md space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-semibold text-gray-900">More About Me</h3>
              <button
                onClick={() => navigate('/settings/edit-profile')}
                className="text-[#E91E63]"
              >
                <Edit3 size={18} />
              </button>
            </div>

            {profile.fun_fact && (
              <div>
                <p className="text-xs text-gray-500 uppercase font-medium mb-1">Fun Fact</p>
                <p className="text-gray-700">{profile.fun_fact}</p>
              </div>
            )}

            {profile.go_to_karaoke_song && (
              <div>
                <p className="text-xs text-gray-500 uppercase font-medium mb-1">Karaoke Song</p>
                <p className="text-gray-700">{profile.go_to_karaoke_song}</p>
              </div>
            )}

            {profile.ideal_night_out && (
              <div>
                <p className="text-xs text-gray-500 uppercase font-medium mb-1">Ideal Night Out</p>
                <p className="text-gray-700">{profile.ideal_night_out}</p>
              </div>
            )}

            {profile.first_drink_on_me && (
              <div className="flex items-center gap-2 p-3 bg-green-50 rounded-xl">
                <DollarSign size={18} className="text-green-600" />
                <span className="text-sm font-medium text-green-700">First drink on me!</span>
              </div>
            )}
          </div>
        )}

        {(profile.instagram_username || profile.spotify_username) && (
          <div className="bg-white rounded-2xl p-6 shadow-md space-y-3">
            <h3 className="font-semibold text-gray-900">Connect With Me</h3>
            {profile.instagram_username && (
              <a
                href={`https://instagram.com/${profile.instagram_username}`}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-3 p-3 bg-gradient-to-r from-pink-50 to-purple-50 rounded-xl hover:from-pink-100 hover:to-purple-100 transition-colors"
              >
                <div className="w-10 h-10 bg-gradient-to-br from-pink-500 to-purple-500 rounded-full flex items-center justify-center">
                  <span className="text-white text-xl">📷</span>
                </div>
                <div>
                  <p className="font-medium text-gray-900">Instagram</p>
                  <p className="text-sm text-gray-600">@{profile.instagram_username}</p>
                </div>
              </a>
            )}
            {profile.spotify_username && (
              <a
                href={`https://open.spotify.com/user/${profile.spotify_username}`}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-3 p-3 bg-green-50 rounded-xl hover:bg-green-100 transition-colors"
              >
                <div className="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center">
                  <span className="text-white text-xl">🎵</span>
                </div>
                <div>
                  <p className="font-medium text-gray-900">Spotify</p>
                  <p className="text-sm text-gray-600">{profile.spotify_username}</p>
                </div>
              </a>
            )}
          </div>
        )}

        {/* XP & Lush Coin card */}
        <button
          onClick={() => setShowXPProfile(true)}
          className="w-full bg-gradient-to-br from-purple-600 to-blue-600 rounded-2xl p-6 shadow-md text-left hover:shadow-lg transition-shadow"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Trophy size={20} className="text-yellow-300" />
              <span className="font-bold text-white text-lg">Nightlife XP</span>
            </div>
            <span className="text-purple-200 text-sm">View all →</span>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div className="bg-white/10 rounded-xl p-3 text-center">
              <p className="text-2xl font-black text-white">{userStats?.total_xp ?? 0}</p>
              <p className="text-xs text-purple-200 mt-0.5">Total XP</p>
            </div>
            <div className="bg-white/10 rounded-xl p-3 text-center">
              <div className="flex items-center justify-center gap-1">
                <Flame size={14} className="text-orange-300" />
                <p className="text-2xl font-black text-white">{userStats?.current_streak ?? 0}</p>
              </div>
              <p className="text-xs text-purple-200 mt-0.5">Streak</p>
            </div>
            <div className="bg-white/10 rounded-xl p-3 text-center">
              <p className="text-2xl font-black text-yellow-300">{coinBalance}</p>
              <p className="text-xs text-purple-200 mt-0.5">🪙 Coins</p>
            </div>
          </div>
        </button>

        {showXPProfile && (
          <div className="fixed inset-0 z-50 bg-gray-50 overflow-y-auto">
            <div className="p-4">
              <button
                onClick={() => setShowXPProfile(false)}
                className="mb-4 flex items-center gap-2 text-gray-600 font-medium hover:text-gray-900"
              >
                ← Back to Profile
              </button>
              <XPProfile userId={user?.id} />
            </div>
          </div>
        )}

        <div className="bg-white rounded-2xl p-6 shadow-md space-y-3">
          <h3 className="font-semibold text-gray-900">Account</h3>
          <button
            onClick={() => navigate('/settings')}
            className="w-full text-left p-3 flex items-center justify-between hover:bg-gray-50 rounded-xl transition-colors"
          >
            <span className="text-gray-700">Settings</span>
            <Settings size={20} className="text-gray-400" />
          </button>
          <button
            onClick={handleSignOut}
            className="w-full text-left p-3 flex items-center justify-between hover:bg-gray-50 rounded-xl transition-colors"
          >
            <span className="text-red-600">Sign Out</span>
            <LogOut size={20} className="text-red-400" />
          </button>
        </div>
      </div>

      <TonightStatusModal
        isOpen={showStatusModal}
        onClose={() => setShowStatusModal(false)}
        currentStatus={currentStatus}
        currentVenue={currentVenue}
        onSave={handleStatusSave}
      />
    </div>
  );
}
