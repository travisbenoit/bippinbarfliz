import { useState } from 'react';
import { MapPin, Bell, Shield } from 'lucide-react';

interface PermissionsRequestProps {
  onComplete: () => void;
}

export default function PermissionsRequest({ onComplete }: PermissionsRequestProps) {
  const [locationGranted, setLocationGranted] = useState(false);
  const [notificationsGranted, setNotificationsGranted] = useState(false);
  const [error, setError] = useState('');

  const requestLocationPermission = async () => {
    try {
      const result = await navigator.permissions.query({ name: 'geolocation' });

      if (result.state === 'granted' || result.state === 'prompt') {
        navigator.geolocation.getCurrentPosition(
          () => {
            setLocationGranted(true);
            setError('');
          },
          () => {
            setError('Location access denied. You can enable it later in settings.');
            setTimeout(() => setLocationGranted(true), 2000);
          }
        );
      }
    } catch {
      navigator.geolocation.getCurrentPosition(
        () => {
          setLocationGranted(true);
          setError('');
        },
        () => {
          setError('Location access denied. You can enable it later in settings.');
          setTimeout(() => setLocationGranted(true), 2000);
        }
      );
    }
  };

  const requestNotificationPermission = async () => {
    try {
      if ('Notification' in window) {
        const permission = await Notification.requestPermission();
        if (permission === 'granted' || permission === 'denied') {
          setNotificationsGranted(true);
          setError('');
        }
      } else {
        setNotificationsGranted(true);
      }
    } catch {
      setNotificationsGranted(true);
    }
  };

  const handleContinue = () => {
    if (locationGranted && notificationsGranted) {
      onComplete();
    } else if (!locationGranted) {
      requestLocationPermission();
    } else if (!notificationsGranted) {
      requestNotificationPermission();
    }
  };

  return (
    <div className="min-h-screen bg-[#FFF5F0] px-6 py-8 flex flex-col justify-between">
      <div className="flex-1 flex items-center justify-center">
        <div className="max-w-md w-full space-y-8">
          <div className="text-center space-y-4">
            <div className="flex justify-center">
              <div className="w-24 h-24 bg-[#E91E63] bg-opacity-10 rounded-full flex items-center justify-center">
                <Shield size={48} className="text-[#E91E63]" />
              </div>
            </div>
            <h1 className="text-3xl font-bold text-gray-900">
              Let's Get You Connected
            </h1>
            <p className="text-gray-600">
              We need a few permissions to help you find drinking buddies nearby and stay updated
            </p>
          </div>

          {error && (
            <div className="bg-yellow-100 border border-yellow-400 text-yellow-800 px-4 py-3 rounded-lg text-sm">
              {error}
            </div>
          )}

          <div className="space-y-4">
            <div className={`p-6 rounded-2xl border-2 transition-colors ${
              locationGranted ? 'bg-green-50 border-green-300' : 'bg-white border-gray-200'
            }`}>
              <div className="flex items-start gap-4">
                <div className={`p-3 rounded-xl ${
                  locationGranted ? 'bg-green-100' : 'bg-[#E91E63] bg-opacity-10'
                }`}>
                  <MapPin size={24} className={locationGranted ? 'text-green-600' : 'text-[#E91E63]'} />
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold text-gray-900 mb-1">Location Access</h3>
                  <p className="text-sm text-gray-600">
                    Find people and venues near you
                  </p>
                </div>
                {locationGranted && (
                  <div className="text-green-600 font-semibold">✓</div>
                )}
              </div>
            </div>

            <div className={`p-6 rounded-2xl border-2 transition-colors ${
              notificationsGranted ? 'bg-green-50 border-green-300' : 'bg-white border-gray-200'
            }`}>
              <div className="flex items-start gap-4">
                <div className={`p-3 rounded-xl ${
                  notificationsGranted ? 'bg-green-100' : 'bg-[#E91E63] bg-opacity-10'
                }`}>
                  <Bell size={24} className={notificationsGranted ? 'text-green-600' : 'text-[#E91E63]'} />
                </div>
                <div className="flex-1">
                  <h3 className="font-semibold text-gray-900 mb-1">Notifications</h3>
                  <p className="text-sm text-gray-600">
                    Get notified about messages and invites
                  </p>
                </div>
                {notificationsGranted && (
                  <div className="text-green-600 font-semibold">✓</div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="space-y-4">
        <button
          onClick={handleContinue}
          className="w-full bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg hover:bg-[#C2185B] transition-colors shadow-lg"
        >
          {locationGranted && notificationsGranted ? 'Continue' : 'Grant Permissions'}
        </button>

        {!locationGranted || !notificationsGranted ? (
          <button
            onClick={onComplete}
            className="w-full text-gray-600 py-2 font-medium"
          >
            Skip for now
          </button>
        ) : null}
      </div>
    </div>
  );
}
