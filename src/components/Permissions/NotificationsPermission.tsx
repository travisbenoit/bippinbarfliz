import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Bell, ArrowRight } from 'lucide-react';

export default function NotificationsPermission() {
  const navigate = useNavigate();
  const [requesting, setRequesting] = useState(false);

  const requestNotificationPermission = async () => {
    setRequesting(true);
    try {
      if ('Notification' in window && typeof Notification.requestPermission === 'function') {
        const permission = await Notification.requestPermission();
        if (permission === 'granted') {
          localStorage.setItem('notification_permission', 'granted');
        } else {
          localStorage.setItem('notification_permission', 'skipped');
        }
      } else {
        localStorage.setItem('notification_permission', 'skipped');
      }
    } catch {
      localStorage.setItem('notification_permission', 'skipped');
    } finally {
      setRequesting(false);
      navigate('/profile-setup');
    }
  };

  const handleSkip = () => {
    localStorage.setItem('notification_permission', 'skipped');
    navigate('/profile-setup');
  };

  return (
    <div className="min-h-screen bg-white flex flex-col px-6 py-8">
      <div className="text-sm text-gray-600 mb-8">
        9:27
      </div>

      <div className="flex-1 flex flex-col justify-between max-w-md mx-auto w-full">
        <div className="flex-1 flex flex-col items-center justify-center space-y-8">
          <div className="relative w-64 h-64 flex items-center justify-center">
            <div className="relative">
              <div className="w-40 h-48 bg-white border-4 border-gray-800 rounded-3xl shadow-xl relative overflow-hidden">
                <div className="absolute top-2 left-1/2 -translate-x-1/2 w-16 h-1 bg-gray-800 rounded-full"></div>
                <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-16 h-1 bg-gray-800 rounded-full"></div>
              </div>

              <div className="absolute -top-6 -right-6 w-20 h-20 bg-white border-4 border-gray-800 rounded-full flex items-center justify-center shadow-xl animate-pulse">
                <Bell size={32} className="text-yellow-500 fill-yellow-500" />
              </div>

              <div className="absolute -bottom-4 -left-4 w-16 h-16 border-4 border-gray-800 rounded-full bg-white"></div>
              <div className="absolute -bottom-2 -left-2 w-16 h-16 border-4 border-gray-800 rounded-full bg-white"></div>
            </div>
          </div>

          <div className="text-center space-y-4">
            <h1 className="text-3xl font-bold text-gray-900">
              Barfliz would like to send<br />you Notifications
            </h1>
            <p className="text-gray-600 text-base max-w-sm mx-auto">
              Notification may includes alerts, sounds and icon badge
            </p>
          </div>
        </div>

        <div className="space-y-4 pb-8">
          <button
            onClick={requestNotificationPermission}
            disabled={requesting}
            className="w-full bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg flex items-center justify-center gap-2 hover:bg-[#C2185B] transition-colors shadow-lg disabled:opacity-50"
          >
            {requesting ? 'Requesting...' : 'Allow access'}
            <ArrowRight size={24} />
          </button>

          <button
            onClick={handleSkip}
            className="w-full text-gray-600 py-2 font-medium"
          >
            Skip for now
          </button>

          <div className="h-1 w-32 bg-gray-900 rounded-full mx-auto" />
        </div>
      </div>
    </div>
  );
}
