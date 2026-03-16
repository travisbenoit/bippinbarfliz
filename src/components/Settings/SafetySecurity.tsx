import { useState, useEffect } from 'react';
import { Phone, UserPlus, Users, MapPin, Trash2, TriangleAlert as AlertTriangle, MessageCircle, X } from 'lucide-react';
import { useNavigate } from 'react-router';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';
import PageHeader from '../Layout/PageHeader';
import { logger } from '../../lib/logger';

interface SafetyFriend {
  id: string;
  name: string;
  phone: string;
}

const PREVIEW_MODE = false;

export default function SafetySecurity() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { showError, showSuccess } = useToast();
  const userCountryCode = localStorage.getItem('userCountryCode') || 'US';
  const [safetyFriends, setSafetyFriends] = useState<SafetyFriend[]>([]);
  const [showAddFriend, setShowAddFriend] = useState(false);
  const [newFriendName, setNewFriendName] = useState('');
  const [newFriendPhone, setNewFriendPhone] = useState('');
  const [loading, setLoading] = useState(true);
  const [showEmergencyConfirm, setShowEmergencyConfirm] = useState(false);
  const [sharingLocation, setSharingLocation] = useState(false);
  const [showMessageOptions, setShowMessageOptions] = useState(false);
  const [sendingMessage, setSendingMessage] = useState(false);
  const [emergencyNumber, setEmergencyNumber] = useState('000');
  const [emergencyCountry, setEmergencyCountry] = useState('AU');

  useEffect(() => {
    if (user) {
      loadSafetyFriends();
      determineEmergencyNumber();
    } else {
      setLoading(false);
    }
  }, [user]);

  const determineEmergencyNumber = async () => {
    try {
      if (!user?.id) return;

      const { data: userData } = await supabase
        .from('users')
        .select('registration_country, phone_country_code, last_known_lat, last_known_lng')
        .eq('id', user.id)
        .maybeSingle();

      let countryCode = userCountryCode;

      if (userData?.last_known_lat && userData?.last_known_lng) {
        try {
          const response = await fetch(
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${userData.last_known_lat}&lon=${userData.last_known_lng}`
          );
          const data = await response.json();
          if (data.address?.country_code) {
            countryCode = data.address.country_code.toUpperCase();
          }
        } catch {
          countryCode = userData?.registration_country || userData?.phone_country_code || userCountryCode;
        }
      } else {
        countryCode = userData?.registration_country || userData?.phone_country_code || userCountryCode;
      }

      const { data: emergencyData } = await supabase
        .from('emergency_numbers')
        .select('country, emergency_number')
        .eq('country', countryCode)
        .maybeSingle();

      if (emergencyData) {
        setEmergencyNumber(emergencyData.emergency_number);
        setEmergencyCountry(emergencyData.country);
      } else {
        setEmergencyNumber('911');
        setEmergencyCountry('US');
      }
    } catch (error) {
      logger.error('Error determining emergency number:', error);
      setEmergencyNumber('911');
      setEmergencyCountry('US');
    }
  };

  const loadSafetyFriends = async () => {
    if (PREVIEW_MODE) {
      setSafetyFriends([
        { id: '1', name: 'Sarah Mitchell', phone: '+61412345678' },
        { id: '2', name: 'James Cooper', phone: '+61498765432' }
      ]);
      setLoading(false);
      return;
    }

    try {
      if (!user?.id) {
        setLoading(false);
        return;
      }

      const { data, error } = await supabase
        .from('safety_friends')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: true });

      if (error) {
        logger.error('Error loading safety friends:', error);
      } else if (data) {
        setSafetyFriends(data.map(f => ({
          id: f.id,
          name: f.friend_name,
          phone: f.friend_phone,
        })));
      }
    } catch (error) {
      logger.error('Error loading safety friends:', error);
    } finally {
      setLoading(false);
    }
  };

  const addSafetyFriend = async () => {
    if (!newFriendName.trim() || !newFriendPhone.trim()) {
      showError('Please enter both name and phone number');
      return;
    }

    if (!user?.id) {
      showError('You must be logged in to add safety friends');
      return;
    }

    if (!validatePhone(newFriendPhone)) {
      showError('Please enter a valid mobile number');
      return;
    }

    try {
      let phoneToSave = newFriendPhone.trim();

      if (phoneToSave.startsWith('04')) {
        const digitsOnly = phoneToSave.replace(/\D/g, '');
        phoneToSave = `+61${digitsOnly.substring(1)}`;
      } else if (!phoneToSave.startsWith('+61')) {
        const digitsOnly = phoneToSave.replace(/\D/g, '');
        if (digitsOnly.startsWith('4')) {
          phoneToSave = `+61${digitsOnly}`;
        }
      }

      const { data, error } = await supabase
        .from('safety_friends')
        .insert({
          user_id: user.id,
          friend_name: newFriendName.trim(),
          friend_phone: phoneToSave,
        })
        .select()
        .single();

      if (error) {
        logger.error('Error adding safety friend:', error);
        showError(`Failed to add safety friend: ${error.message}`);
        return;
      }

      if (data) {
        setSafetyFriends([...safetyFriends, {
          id: data.id,
          name: data.friend_name,
          phone: data.friend_phone,
        }]);
        setNewFriendName('');
        setNewFriendPhone('');
        setShowAddFriend(false);
      }
    } catch (error) {
      logger.error('Error adding safety friend:', error);
      showError(`Failed to add safety friend: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  };

  const removeSafetyFriend = async (id: string) => {
    try {
      const { error } = await supabase
        .from('safety_friends')
        .delete()
        .eq('id', id);

      if (error) {
        logger.error('Error removing safety friend:', error);
        showError('Failed to remove safety friend. Please try again.');
        return;
      }

      setSafetyFriends(safetyFriends.filter(f => f.id !== id));
    } catch (error) {
      logger.error('Error removing safety friend:', error);
      showError('Failed to remove safety friend. Please try again.');
    }
  };

  const handleEmergencyCall = () => {
    window.location.href = `tel:${emergencyNumber}`;
  };

  const shareLocationWithFriends = async () => {
    if (safetyFriends.length === 0) return;

    setSharingLocation(true);

    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords;
          const locationUrl = `https://maps.google.com/?q=${latitude},${longitude}`;

          if (!PREVIEW_MODE) {
            await supabase.from('safety_alerts').insert({
              user_id: user!.id,
              latitude,
              longitude,
              location_url: locationUrl,
              alert_type: 'location_share',
            });
          }

          setSharingLocation(false);
          showSuccess('Your location has been shared with your safety friends!');
        },
        () => {
          setSharingLocation(false);
          showError('Could not get your location. Please enable location services.');
        }
      );
    }
  };

  const sendEmergencyMessage = async () => {
    if (safetyFriends.length === 0) return;

    setSendingMessage(true);

    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords;
          const locationUrl = `https://maps.google.com/?q=${latitude},${longitude}`;

          const message = `\uD83D\uDEA8 EMERGENCY ALERT \uD83D\uDEA8\n\nI need immediate help! My current location:\n${locationUrl}\n\nPlease respond or call me ASAP.`;

          safetyFriends.forEach(friend => {
            const smsUrl = `sms:${friend.phone}?body=${encodeURIComponent(message)}`;
            window.open(smsUrl, '_blank');
          });

          if (!PREVIEW_MODE) {
            await supabase.from('safety_alerts').insert({
              user_id: user!.id,
              latitude,
              longitude,
              location_url: locationUrl,
              alert_type: 'emergency_message',
            });
          }

          setSendingMessage(false);
          setShowMessageOptions(false);
          showSuccess('Emergency messages sent to all safety friends!');
        },
        () => {
          setSendingMessage(false);
          showError('Could not get your location. Please enable location services.');
        }
      );
    } else {
      const message = `EMERGENCY ALERT\n\nI need immediate help! Please call me ASAP.`;

      safetyFriends.forEach(friend => {
        const smsUrl = `sms:${friend.phone}?body=${encodeURIComponent(message)}`;
        window.open(smsUrl, '_blank');
      });

      setSendingMessage(false);
      setShowMessageOptions(false);
      showSuccess('Emergency messages sent to all safety friends!');
    }
  };

  const sendFriendMessage = async () => {
    if (safetyFriends.length === 0) return;

    setSendingMessage(true);

    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords;
          const locationUrl = `https://maps.google.com/?q=${latitude},${longitude}`;

          const message = `Hey! I'm out tonight. Here's my location if you need it:\n${locationUrl}\n\nLet me know if you want to meet up!`;

          safetyFriends.forEach(friend => {
            const smsUrl = `sms:${friend.phone}?body=${encodeURIComponent(message)}`;
            window.open(smsUrl, '_blank');
          });

          if (!PREVIEW_MODE) {
            await supabase.from('safety_alerts').insert({
              user_id: user!.id,
              latitude,
              longitude,
              location_url: locationUrl,
              alert_type: 'friend_message',
            });
          }

          setSendingMessage(false);
          setShowMessageOptions(false);
          showSuccess('Messages sent to all safety friends!');
        },
        () => {
          setSendingMessage(false);
          showError('Could not get your location. Please enable location services.');
        }
      );
    } else {
      const message = `Hey! I'm out tonight. Let me know if you want to meet up!`;

      safetyFriends.forEach(friend => {
        const smsUrl = `sms:${friend.phone}?body=${encodeURIComponent(message)}`;
        window.open(smsUrl, '_blank');
      });

      setSendingMessage(false);
      setShowMessageOptions(false);
      showSuccess('Messages sent to all safety friends!');
    }
  };

  const formatPhone = (phone: string) => {
    if (phone.startsWith('+61')) {
      const number = phone.substring(3);
      if (number.length === 9) {
        return `+61 ${number.slice(0, 3)} ${number.slice(3, 6)} ${number.slice(6)}`;
      }
    }
    const cleaned = phone.replace(/\D/g, '');
    if (cleaned.length === 10) {
      return `${cleaned.slice(0, 4)} ${cleaned.slice(4, 7)} ${cleaned.slice(7)}`;
    }
    return phone;
  };

  const handlePhoneChange = (value: string) => {
    const digitsOnly = value.replace(/\D/g, '');

    if (value.startsWith('+61')) {
      const afterCode = digitsOnly.substring(2);
      if (afterCode.length <= 9) {
        if (afterCode.length === 0) {
          setNewFriendPhone('+61 ');
        } else if (afterCode.length <= 3) {
          setNewFriendPhone(`+61 ${afterCode}`);
        } else if (afterCode.length <= 6) {
          setNewFriendPhone(`+61 ${afterCode.slice(0, 3)} ${afterCode.slice(3)}`);
        } else {
          setNewFriendPhone(`+61 ${afterCode.slice(0, 3)} ${afterCode.slice(3, 6)} ${afterCode.slice(6, 9)}`);
        }
      }
    } else if (value.startsWith('04') || value.startsWith('4')) {
      if (digitsOnly.length <= 10) {
        if (digitsOnly.length <= 4) {
          setNewFriendPhone(digitsOnly);
        } else if (digitsOnly.length <= 7) {
          setNewFriendPhone(`${digitsOnly.slice(0, 4)} ${digitsOnly.slice(4)}`);
        } else {
          setNewFriendPhone(`${digitsOnly.slice(0, 4)} ${digitsOnly.slice(4, 7)} ${digitsOnly.slice(7, 10)}`);
        }
      }
    } else {
      setNewFriendPhone(value);
    }
  };

  const validatePhone = (phone: string): boolean => {
    const digitsOnly = phone.replace(/\D/g, '');

    if (phone.startsWith('+61')) {
      return digitsOnly.length === 11 && digitsOnly.substring(2, 3) === '4';
    }

    if (phone.startsWith('+1') || userCountryCode === 'US') {
      return digitsOnly.length === 10 || digitsOnly.length === 11;
    }

    if (phone.startsWith('+')) {
      return digitsOnly.length >= 7 && digitsOnly.length <= 15;
    }

    return digitsOnly.length === 10 && (digitsOnly.startsWith('04') || !digitsOnly.startsWith('0'));
  };

  const isPhoneValid = validatePhone(newFriendPhone);

  if (loading) {
    return (
      <div className="h-full flex items-center justify-center bg-[#FFF5F0]">
        <div className="w-12 h-12 border-4 border-[#E91E63] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-8">
      <div className="sticky top-0 z-10">
        <PageHeader title="Safety & Security" onBack={() => navigate('/settings')} />
      </div>

      <div className="p-4 space-y-4">
        <div className="bg-gradient-to-r from-red-500 to-red-600 rounded-2xl p-5 shadow-lg">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center">
              <Phone size={24} className="text-white" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-white">Emergency Call</h2>
              <p className="text-white/80 text-sm">Call {emergencyNumber} immediately</p>
            </div>
          </div>
          <button
            onClick={() => setShowEmergencyConfirm(true)}
            className="w-full py-4 bg-white text-red-600 rounded-xl font-bold text-lg shadow-md hover:bg-red-50 transition-colors"
          >
            Call {emergencyNumber}
          </button>
        </div>

        <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
          <div className="p-5 border-b border-gray-100">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-[#E91E63]/10 rounded-full flex items-center justify-center">
                  <Users size={20} className="text-[#E91E63]" />
                </div>
                <div>
                  <h2 className="font-semibold text-gray-900">Safety Friends</h2>
                  <p className="text-sm text-gray-500">Contacts who can receive your location</p>
                </div>
              </div>
              <button
                onClick={() => setShowAddFriend(true)}
                className="p-2 bg-[#E91E63] rounded-full text-white hover:bg-[#C2185B] transition-colors"
              >
                <UserPlus size={18} />
              </button>
            </div>
          </div>

          {safetyFriends.length === 0 ? (
            <div className="p-8 text-center">
              <Users size={40} className="mx-auto text-gray-300 mb-3" />
              <p className="text-gray-500 mb-1">No safety friends added</p>
              <p className="text-sm text-gray-400">Add trusted contacts who can help in emergencies</p>
            </div>
          ) : (
            <div className="divide-y divide-gray-100">
              {safetyFriends.map((friend) => (
                <div key={friend.id} className="px-5 py-4 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                      <span className="text-lg font-semibold text-gray-600">
                        {friend.name.charAt(0).toUpperCase()}
                      </span>
                    </div>
                    <div>
                      <p className="font-medium text-gray-900">{friend.name}</p>
                      <p className="text-sm text-gray-500">{formatPhone(friend.phone)}</p>
                    </div>
                  </div>
                  <button
                    onClick={() => removeSafetyFriend(friend.id)}
                    className="p-2 text-red-500 hover:bg-red-50 rounded-full transition-colors"
                  >
                    <Trash2 size={18} />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        {safetyFriends.length > 0 && (
          <>
            <button
              onClick={shareLocationWithFriends}
              disabled={sharingLocation}
              className="w-full bg-white rounded-2xl p-5 shadow-sm flex items-center justify-between hover:bg-gray-50 transition-colors disabled:opacity-50"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                  <MapPin size={20} className="text-blue-600" />
                </div>
                <div className="text-left">
                  <p className="font-medium text-gray-900">Share My Location</p>
                  <p className="text-sm text-gray-500">Send current location to all safety friends</p>
                </div>
              </div>
              {sharingLocation ? (
                <div className="w-5 h-5 border-2 border-[#E91E63] border-t-transparent rounded-full animate-spin" />
              ) : (
                <span className="text-[#E91E63] font-medium">Share</span>
              )}
            </button>

            <button
              onClick={() => setShowMessageOptions(true)}
              disabled={sendingMessage}
              className="w-full bg-gradient-to-r from-[#E91E63] to-[#C2185B] rounded-2xl p-5 shadow-lg hover:shadow-xl transition-all disabled:opacity-50"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
                    <MessageCircle size={20} className="text-white" />
                  </div>
                  <div className="text-left">
                    <p className="font-bold text-white">Send Message to Friends</p>
                    <p className="text-sm text-white/80">Emergency or casual check-in</p>
                  </div>
                </div>
                {sendingMessage ? (
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                ) : (
                  <span className="text-white font-medium">Send</span>
                )}
              </div>
            </button>
          </>
        )}

        <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4">
          <div className="flex gap-3">
            <AlertTriangle size={20} className="text-amber-600 flex-shrink-0 mt-0.5" />
            <div>
              <p className="font-medium text-amber-800">Stay Safe</p>
              <p className="text-sm text-amber-700 mt-1">
                Always let someone know where you're going. Your safety friends will receive your
                location when you use the share feature.
              </p>
            </div>
          </div>
        </div>
      </div>

      {showAddFriend && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end">
          <div className="w-full bg-white rounded-t-3xl p-6 animate-slide-up">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-gray-900">Add Safety Friend</h2>
              <button
                onClick={() => {
                  setShowAddFriend(false);
                  setNewFriendName('');
                  setNewFriendPhone('');
                }}
                className="p-2 hover:bg-gray-100 rounded-full transition-colors"
              >
                <X size={20} className="text-gray-500" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
                <input
                  type="text"
                  value={newFriendName}
                  onChange={(e) => setNewFriendName(e.target.value)}
                  placeholder="Friend's name"
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
                <input
                  type="tel"
                  value={newFriendPhone}
                  onChange={(e) => handlePhoneChange(e.target.value)}
                  placeholder="+61 412 345 678 or 0412 345 678"
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none"
                />
                {newFriendPhone && !isPhoneValid && (
                  <p className="text-xs text-red-500 mt-1">
                    Must be 10 digits starting with 04 (e.g., 0412 345 678) or +61 format
                  </p>
                )}
              </div>
              <div className="flex gap-3">
                <button
                  onClick={() => {
                    setShowAddFriend(false);
                    setNewFriendName('');
                    setNewFriendPhone('');
                  }}
                  className="flex-1 py-3 bg-gray-100 text-gray-700 rounded-xl font-medium hover:bg-gray-200 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={addSafetyFriend}
                  disabled={!newFriendName.trim() || !newFriendPhone.trim() || !isPhoneValid}
                  className="flex-1 py-3 bg-[#E91E63] text-white rounded-xl font-semibold disabled:opacity-50 hover:bg-[#C2185B] transition-colors"
                >
                  Add Friend
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {showEmergencyConfirm && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-6 max-w-sm w-full">
            <div className="text-center mb-6">
              <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Phone size={32} className="text-red-600" />
              </div>
              <h2 className="text-xl font-bold text-gray-900 mb-2">Call {emergencyNumber}?</h2>
              <p className="text-gray-600">
                This will immediately dial emergency services. Only use in real emergencies.
              </p>
            </div>
            <div className="space-y-3">
              <button
                onClick={handleEmergencyCall}
                className="w-full py-3 bg-red-600 text-white rounded-xl font-bold"
              >
                Yes, Call {emergencyNumber}
              </button>
              <button
                onClick={() => setShowEmergencyConfirm(false)}
                className="w-full py-3 bg-gray-100 text-gray-700 rounded-xl font-medium"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {showMessageOptions && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-6 max-w-sm w-full">
            <div className="text-center mb-6">
              <div className="w-16 h-16 bg-[#E91E63]/10 rounded-full flex items-center justify-center mx-auto mb-4">
                <MessageCircle size={32} className="text-[#E91E63]" />
              </div>
              <h2 className="text-xl font-bold text-gray-900 mb-2">Send Message</h2>
              <p className="text-gray-600">
                Choose the type of message to send to your safety friends
              </p>
            </div>
            <div className="space-y-3">
              <button
                onClick={sendEmergencyMessage}
                disabled={sendingMessage}
                className="w-full py-4 bg-red-600 text-white rounded-xl font-bold hover:bg-red-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
              >
                <AlertTriangle size={20} />
                <span>Emergency Alert</span>
              </button>
              <button
                onClick={sendFriendMessage}
                disabled={sendingMessage}
                className="w-full py-4 bg-[#E91E63] text-white rounded-xl font-bold hover:bg-[#C2185B] transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
              >
                <MessageCircle size={20} />
                <span>Casual Check-in</span>
              </button>
              <button
                onClick={() => setShowMessageOptions(false)}
                className="w-full py-3 bg-gray-100 text-gray-700 rounded-xl font-medium hover:bg-gray-200 transition-colors"
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
