import { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { ArrowLeft, Menu, X, Home, MapPin, MessageCircle, User, Settings, Gift, Users, DollarSign, Music, Shield, Bell, LogOut } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';

interface MenuItem {
  icon: any;
  label: string;
  path: string;
  color: string;
}

const menuItems: MenuItem[] = [
  { icon: Home, label: 'Home', path: '/home', color: 'text-[#E91E63]' },
  { icon: MapPin, label: 'Map', path: '/map', color: 'text-blue-600' },
  { icon: Users, label: 'Swarms', path: '/swarms', color: 'text-purple-600' },
  { icon: MessageCircle, label: 'Messages', path: '/messages', color: 'text-green-600' },
  { icon: Gift, label: 'Gifts', path: '/gifts', color: 'text-pink-600' },
  { icon: Music, label: 'Music Sharing', path: '/home', color: 'text-orange-600' },
  { icon: DollarSign, label: 'Payments', path: '/payments', color: 'text-emerald-600' },
  { icon: User, label: 'Profile', path: '/profile', color: 'text-indigo-600' },
  { icon: Settings, label: 'Settings', path: '/settings', color: 'text-gray-600' },
  { icon: Bell, label: 'Notifications', path: '/settings/notifications', color: 'text-yellow-600' },
  { icon: Shield, label: 'Safety & Security', path: '/settings/safety', color: 'text-red-600' },
];

interface PageHeaderProps {
  title: string;
  onBack?: () => void;
  showBackButton?: boolean;
}

export default function PageHeader({ title, onBack, showBackButton = true }: PageHeaderProps) {
  const [menuOpen, setMenuOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const { signOut } = useAuth();

  const handleBack = () => {
    if (onBack) {
      onBack();
    } else {
      navigate(-1);
    }
  };

  const handleNavigation = (path: string) => {
    navigate(path);
    setMenuOpen(false);
  };

  const handleLogout = async () => {
    await signOut();
    setMenuOpen(false);
  };

  return (
    <>
      <div className="bg-white shadow-sm p-4 flex items-center justify-between">
        <div className="flex items-center gap-4">
          {showBackButton && (
            <button onClick={handleBack} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
              <ArrowLeft size={24} className="text-gray-700" />
            </button>
          )}
          <h1 className="text-2xl font-bold text-gray-900">{title}</h1>
        </div>
        <button
          onClick={() => setMenuOpen(true)}
          className="w-10 h-10 flex items-center justify-center rounded-lg hover:bg-gray-100 transition-colors"
        >
          <Menu size={24} className="text-gray-900" />
        </button>
      </div>

      {menuOpen && (
        <>
          <div
            className="fixed inset-0 bg-black/50 z-40"
            onClick={() => setMenuOpen(false)}
          />
          <div className="fixed inset-y-0 right-0 w-80 bg-white z-50 shadow-2xl flex flex-col">
            <div className="bg-gradient-to-r from-[#E91E63] to-[#C2185B] p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-white">Menu</h2>
                <button
                  onClick={() => setMenuOpen(false)}
                  className="w-10 h-10 flex items-center justify-center rounded-lg hover:bg-white/20 transition-colors"
                >
                  <X size={24} className="text-white" />
                </button>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center">
                  <User size={28} className="text-white" />
                </div>
                <div>
                  <p className="text-white font-bold text-lg">Welcome!</p>
                  <p className="text-white/80 text-sm">Explore all features</p>
                </div>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-4">
              <div className="space-y-2">
                {menuItems.map((item) => {
                  const Icon = item.icon;
                  const isActive = location.pathname === item.path;
                  return (
                    <button
                      key={item.path}
                      onClick={() => handleNavigation(item.path)}
                      className={`w-full flex items-center gap-4 px-4 py-3 rounded-xl transition-all ${
                        isActive
                          ? 'bg-[#E91E63]/10 border-2 border-[#E91E63]'
                          : 'hover:bg-gray-50 border-2 border-transparent'
                      }`}
                    >
                      <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                        isActive ? 'bg-[#E91E63]' : 'bg-gray-100'
                      }`}>
                        <Icon size={20} className={isActive ? 'text-white' : item.color} />
                      </div>
                      <span className={`font-medium ${
                        isActive ? 'text-[#E91E63]' : 'text-gray-900'
                      }`}>
                        {item.label}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="p-4 border-t border-gray-200">
              <button
                onClick={handleLogout}
                className="w-full flex items-center justify-center gap-3 px-4 py-3 bg-red-50 text-red-600 rounded-xl font-medium hover:bg-red-100 transition-colors"
              >
                <LogOut size={20} />
                <span>Log Out</span>
              </button>
            </div>
          </div>
        </>
      )}
    </>
  );
}
