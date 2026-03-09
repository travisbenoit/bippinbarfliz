import { useState, useEffect } from 'react';
import { Bell, MessageCircle, Users, MapPin, Gift, Megaphone } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import PageHeader from '../Layout/PageHeader';

interface NotificationSetting {
  id: string;
  icon: React.ElementType;
  label: string;
  description: string;
  enabled: boolean;
}

export default function NotificationsSettings() {
  const navigate = useNavigate();
  const [settings, setSettings] = useState<NotificationSetting[]>([
    {
      id: 'push_all',
      icon: Bell,
      label: 'Push Notifications',
      description: 'Enable all push notifications',
      enabled: true,
    },
    {
      id: 'messages',
      icon: MessageCircle,
      label: 'Messages',
      description: 'New messages and chat activity',
      enabled: true,
    },
    {
      id: 'swarms',
      icon: Users,
      label: 'Swarm Updates',
      description: 'Invites, joins, and swarm activity',
      enabled: true,
    },
    {
      id: 'nearby',
      icon: MapPin,
      label: 'Friends Nearby',
      description: 'When friends are at nearby venues',
      enabled: false,
    },
    {
      id: 'gifts',
      icon: Gift,
      label: 'Gifts & Payments',
      description: 'When you receive drinks or payments',
      enabled: true,
    },
    {
      id: 'promotions',
      icon: Megaphone,
      label: 'Promotions',
      description: 'Deals and special offers from venues',
      enabled: false,
    },
  ]);

  useEffect(() => {
    const saved = localStorage.getItem('notification_settings');
    if (saved) {
      const savedSettings = JSON.parse(saved);
      setSettings(prev => prev.map(s => ({
        ...s,
        enabled: savedSettings[s.id] ?? s.enabled
      })));
    }
  }, []);

  const toggleSetting = (id: string) => {
    const updated = settings.map(s =>
      s.id === id ? { ...s, enabled: !s.enabled } : s
    );
    setSettings(updated);

    const toSave = updated.reduce((acc, s) => ({ ...acc, [s.id]: s.enabled }), {});
    localStorage.setItem('notification_settings', JSON.stringify(toSave));
  };

  const masterToggle = settings.find(s => s.id === 'push_all');
  const otherSettings = settings.filter(s => s.id !== 'push_all');

  return (
    <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-8">
      <div className="sticky top-0 z-10">
        <PageHeader title="Notifications" onBack={() => navigate('/settings')} />
      </div>

      <div className="p-4 space-y-4">
        {masterToggle && (
          <div className="bg-white rounded-2xl p-5 shadow-sm">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-[#E91E63]/10 rounded-full flex items-center justify-center">
                  <masterToggle.icon size={20} className="text-[#E91E63]" />
                </div>
                <div>
                  <p className="font-medium text-gray-900">{masterToggle.label}</p>
                  <p className="text-sm text-gray-500">{masterToggle.description}</p>
                </div>
              </div>
              <button
                onClick={() => toggleSetting(masterToggle.id)}
                className={`w-12 h-7 rounded-full transition-all duration-300 ${
                  masterToggle.enabled ? 'bg-[#E91E63]' : 'bg-gray-300'
                }`}
              >
                <div className={`w-5 h-5 bg-white rounded-full shadow-sm transition-all duration-300 ${
                  masterToggle.enabled ? 'translate-x-6' : 'translate-x-1'
                }`} />
              </button>
            </div>
          </div>
        )}

        <div className={`bg-white rounded-2xl shadow-sm overflow-hidden transition-opacity ${
          masterToggle?.enabled ? 'opacity-100' : 'opacity-50 pointer-events-none'
        }`}>
          <h2 className="text-sm font-semibold text-gray-500 uppercase tracking-wide px-5 py-3 bg-gray-50">
            Notification Types
          </h2>
          <div className="divide-y divide-gray-100">
            {otherSettings.map((setting) => {
              const Icon = setting.icon;
              return (
                <div key={setting.id} className="px-5 py-4 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                      <Icon size={18} className="text-gray-600" />
                    </div>
                    <div>
                      <p className="font-medium text-gray-900">{setting.label}</p>
                      <p className="text-sm text-gray-500">{setting.description}</p>
                    </div>
                  </div>
                  <button
                    onClick={() => toggleSetting(setting.id)}
                    className={`w-12 h-7 rounded-full transition-all duration-300 ${
                      setting.enabled ? 'bg-[#E91E63]' : 'bg-gray-300'
                    }`}
                  >
                    <div className={`w-5 h-5 bg-white rounded-full shadow-sm transition-all duration-300 ${
                      setting.enabled ? 'translate-x-6' : 'translate-x-1'
                    }`} />
                  </button>
                </div>
              );
            })}
          </div>
        </div>

        <p className="text-sm text-gray-500 text-center px-4">
          You can change these settings at any time. Some notifications are required for app functionality.
        </p>
      </div>
    </div>
  );
}
