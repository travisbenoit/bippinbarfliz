import { useState, useEffect } from 'react';
import { User, Bell, Shield, MapPin, HelpCircle, ChevronRight, LogOut, Moon, Ruler, Trash2, AlertTriangle, X } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { useRegionalSettings } from '../../contexts/RegionalSettingsContext';
import { supabase } from '../../lib/supabase';
import type { Database } from '../../lib/database.types';
import PageHeader from '../Layout/PageHeader';

type UserProfile = Database['public']['Tables']['users']['Row'];

export default function SettingsView() {
  const navigate = useNavigate();
  const { user, signOut } = useAuth();
  const { distanceUnit, setDistanceUnit, setTemperatureUnit } = useRegionalSettings();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [darkMode, setDarkMode] = useState(() => localStorage.getItem('darkMode') === 'true');
  const [useMetric, setUseMetric] = useState(() => distanceUnit === 'kilometers');
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteConfirmText, setDeleteConfirmText] = useState('');
  const [deleting, setDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  useEffect(() => {
    loadProfile();
  }, []);

  useEffect(() => {
    localStorage.setItem('darkMode', darkMode.toString());
  }, [darkMode]);

  useEffect(() => {
    setDistanceUnit(useMetric ? 'kilometers' : 'miles');
    setTemperatureUnit(useMetric ? 'C' : 'F');
  }, [useMetric, setDistanceUnit, setTemperatureUnit]);

  const loadProfile = async () => {
    const { data } = await supabase
      .from('users')
      .select('*')
      .eq('id', user!.id)
      .maybeSingle();

    if (data) {
      setProfile(data);
    }
  };

  const handleSignOut = async () => {
    await signOut();
    navigate('/');
  };

  const handleDeleteAccount = async () => {
    if (deleteConfirmText !== 'DELETE') return;
    setDeleting(true);
    setDeleteError(null);
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const res = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/delete-account`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${session?.access_token}`,
            'Content-Type': 'application/json',
          },
        }
      );
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(body.error || 'Deletion failed');
      }
      localStorage.clear();
      sessionStorage.clear();
      await signOut();
      navigate('/');
    } catch (err) {
      setDeleteError(err instanceof Error ? err.message : 'Something went wrong. Please try again.');
      setDeleting(false);
    }
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

  const settingsSections = [
    {
      title: 'Account',
      items: [
        {
          icon: User,
          label: 'Profile',
          subtitle: profile ? `${profile.name}, ${calculateAge(profile.dob)}` : 'View and edit your profile',
          action: () => navigate('/settings/edit-profile'),
          showProfile: true,
        },
        {
          icon: Bell,
          label: 'Notifications',
          subtitle: 'Manage notification preferences',
          action: () => navigate('/settings/notifications'),
        },
        {
          icon: MapPin,
          label: 'Privacy & Location',
          subtitle: 'Location sharing is enabled',
          action: () => {},
          badge: 'On',
        },
      ],
    },
    {
      title: 'Support',
      items: [
        {
          icon: HelpCircle,
          label: 'Help Center',
          subtitle: 'FAQs and contact support',
          action: () => navigate('/settings/help'),
        },
        {
          icon: Shield,
          label: 'Safety & Security',
          subtitle: 'Emergency contacts and safety tools',
          action: () => navigate('/settings/safety'),
        },
      ],
    },
  ];

  return (
    <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-20">
      <PageHeader title="Settings" onBack={() => navigate('/map')} />

      <div className="p-4 space-y-4">
        {settingsSections.map((section) => (
          <div key={section.title} className="bg-white rounded-2xl shadow-sm overflow-hidden">
            <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide px-5 py-3 bg-gray-50">
              {section.title}
            </h2>
            <div className="divide-y divide-gray-100">
              {section.items.map((item) => {
                const Icon = item.icon;
                return (
                  <button
                    key={item.label}
                    onClick={item.action}
                    className="w-full px-5 py-4 flex items-center gap-3 hover:bg-gray-50 transition-colors"
                  >
                    {item.showProfile && profile ? (
                      <div className="w-12 h-12 bg-gradient-to-br from-pink-200 to-orange-200 rounded-full flex items-center justify-center">
                        <span className="text-xl font-bold text-[#E91E63]">
                          {profile.name.charAt(0)}
                        </span>
                      </div>
                    ) : (
                      <div className="w-10 h-10 bg-[#E91E63]/10 rounded-full flex items-center justify-center">
                        <Icon size={20} className="text-[#E91E63]" />
                      </div>
                    )}
                    <div className="flex-1 text-left">
                      <p className="font-medium text-gray-900">{item.label}</p>
                      <p className="text-sm text-gray-500">{item.subtitle}</p>
                    </div>
                    {item.badge ? (
                      <span className="px-2 py-1 bg-emerald-100 text-emerald-700 rounded-full text-xs font-medium">
                        {item.badge}
                      </span>
                    ) : (
                      <ChevronRight size={20} className="text-gray-400" />
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        ))}

        <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
          <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide px-5 py-3 bg-gray-50">
            Preferences
          </h2>
          <div className="divide-y divide-gray-100">
            <div className="px-5 py-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-[#E91E63]/10 rounded-full flex items-center justify-center">
                  <Moon size={20} className="text-[#E91E63]" />
                </div>
                <div>
                  <p className="font-medium text-gray-900">Dark Mode</p>
                  <p className="text-sm text-gray-500">Use dark theme throughout the app</p>
                </div>
              </div>
              <button
                onClick={() => setDarkMode(!darkMode)}
                className={`w-12 h-7 rounded-full transition-all duration-300 ${
                  darkMode ? 'bg-[#E91E63]' : 'bg-gray-300'
                }`}
              >
                <div className={`w-5 h-5 bg-white rounded-full shadow-sm transition-all duration-300 ${
                  darkMode ? 'translate-x-6' : 'translate-x-1'
                }`} />
              </button>
            </div>

            <div className="px-5 py-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-[#E91E63]/10 rounded-full flex items-center justify-center">
                  <Ruler size={20} className="text-[#E91E63]" />
                </div>
                <div>
                  <p className="font-medium text-gray-900">Metric Units</p>
                  <p className="text-sm text-gray-500">{useMetric ? 'Using kilometers' : 'Using miles'}</p>
                </div>
              </div>
              <button
                onClick={() => setUseMetric(!useMetric)}
                className={`w-12 h-7 rounded-full transition-all duration-300 ${
                  useMetric ? 'bg-[#E91E63]' : 'bg-gray-300'
                }`}
              >
                <div className={`w-5 h-5 bg-white rounded-full shadow-sm transition-all duration-300 ${
                  useMetric ? 'translate-x-6' : 'translate-x-1'
                }`} />
              </button>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
          <button
            onClick={handleSignOut}
            className="w-full px-5 py-4 flex items-center gap-3 hover:bg-red-50 transition-colors"
          >
            <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
              <LogOut size={20} className="text-red-600" />
            </div>
            <span className="flex-1 text-left font-medium text-red-600">Sign Out</span>
          </button>
          <div className="border-t border-gray-100">
            <button
              onClick={() => setShowDeleteModal(true)}
              className="w-full px-5 py-4 flex items-center gap-3 hover:bg-red-50 transition-colors"
            >
              <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
                <Trash2 size={20} className="text-red-600" />
              </div>
              <div className="flex-1 text-left">
                <p className="font-medium text-red-600">Delete Account</p>
                <p className="text-xs text-gray-400">Permanently remove your data</p>
              </div>
            </button>
          </div>
        </div>

        <div className="text-center space-y-2 pt-4">
          <p className="text-sm text-gray-500">Barfliz v1.0.0</p>
          <p className="text-xs text-gray-400">Made with care for your nightlife</p>
        </div>
      </div>

      {showDeleteModal && (
        <div className="fixed inset-0 z-[9000] bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-sm shadow-2xl">
            <div className="p-6">
              <div className="flex items-start justify-between mb-4">
                <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
                  <AlertTriangle size={24} className="text-red-600" />
                </div>
                <button
                  onClick={() => { setShowDeleteModal(false); setDeleteConfirmText(''); setDeleteError(null); }}
                  className="p-1 hover:bg-gray-100 rounded-full transition-colors"
                >
                  <X size={20} className="text-gray-500" />
                </button>
              </div>

              <h2 className="text-xl font-bold text-gray-900 mb-2">Delete Account</h2>
              <p className="text-sm text-gray-600 mb-4 leading-relaxed">
                This will permanently delete your account, profile, messages, gifts, and all associated data. <span className="font-semibold text-gray-900">This cannot be undone.</span>
              </p>

              <div className="bg-gray-50 rounded-xl p-3 mb-4">
                <p className="text-xs text-gray-500 mb-2">Type <span className="font-bold text-gray-900">DELETE</span> to confirm</p>
                <input
                  type="text"
                  value={deleteConfirmText}
                  onChange={(e) => setDeleteConfirmText(e.target.value.toUpperCase())}
                  placeholder="DELETE"
                  className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm font-mono focus:border-red-400 focus:outline-none focus:ring-1 focus:ring-red-400"
                />
              </div>

              {deleteError && (
                <p className="text-sm text-red-600 mb-4">{deleteError}</p>
              )}

              <button
                onClick={handleDeleteAccount}
                disabled={deleteConfirmText !== 'DELETE' || deleting}
                className="w-full py-3 bg-red-600 text-white rounded-xl font-semibold text-sm hover:bg-red-700 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
              >
                {deleting ? 'Deleting...' : 'Permanently Delete My Account'}
              </button>
              <button
                onClick={() => { setShowDeleteModal(false); setDeleteConfirmText(''); setDeleteError(null); }}
                className="w-full py-3 mt-2 text-gray-600 text-sm font-medium hover:text-gray-900 transition-colors"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
