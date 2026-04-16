import { useEffect, useState } from 'react';
import { MapPin, MessageCircle, Wallet, Sparkles, Users2, History } from 'lucide-react';
import { useLocation, useNavigate } from 'react-router-dom';
import { messagesService } from '../../services/messagesService';
import { friendsService } from '../../services/friendsService';
import { supabase } from '../../lib/supabase';

export default function BottomNav() {
  const location = useLocation();
  const navigate = useNavigate();
  const [unreadMessages, setUnreadMessages] = useState(0);
  const [pendingFriends, setPendingFriends] = useState(0);

  useEffect(() => {
    let mounted = true;

    const fetchUnread = async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user || !mounted) return;
        const [msgCount, friendReqs] = await Promise.all([
          messagesService.getUnreadCount(),
          friendsService.getPendingRequests(),
        ]);
        if (mounted) {
          setUnreadMessages(msgCount);
          setPendingFriends(friendReqs.length);
        }
      } catch {
        // silent
      }
    };

    fetchUnread();

    const sub = messagesService.subscribeToAllMessages(() => {
      fetchUnread();
    });

    return () => {
      mounted = false;
      sub.unsubscribe();
    };
  }, []);

  const tabs = [
    { path: '/map', icon: MapPin, label: 'Explore' },
    { path: '/swarms', icon: Sparkles, label: 'Swarms' },
    { path: '/messages', icon: MessageCircle, label: 'Chat', badge: unreadMessages > 0 ? Math.min(unreadMessages, 99) : 0 },
    { path: '/friends', icon: Users2, label: 'Friends', badge: pendingFriends > 0 ? pendingFriends : 0 },
    { path: '/history', icon: History, label: 'History' },
    { path: '/payments', icon: Wallet, label: 'Pay' },
  ];

  return (
    <div className="fixed bottom-0 left-0 right-0 z-50 pointer-events-none">
      <div className="absolute inset-0 bg-gradient-to-t from-[#FFF5F0] via-[#FFF5F0]/80 to-transparent" />
      <div className="relative mx-3 mb-3 pointer-events-auto" style={{ paddingBottom: 'env(safe-area-inset-bottom, 0px)' }}>
        <div className="bg-white/95 backdrop-blur-xl border border-gray-200/80 rounded-2xl shadow-lg">
          <div className="flex items-center justify-around px-2 py-2">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              const isActive = location.pathname === tab.path;
              const badge = 'badge' in tab ? tab.badge : 0;

              return (
                <button
                  key={tab.path}
                  onClick={() => navigate(tab.path)}
                  className={`press-scale relative flex flex-col items-center gap-1 px-4 py-2 rounded-xl transition-all duration-200 min-w-[56px] ${
                    isActive ? 'bg-[#E91E63]/10' : 'hover:bg-gray-50'
                  }`}
                >
                  <div className="relative">
                    <Icon
                      size={22}
                      className={`transition-all duration-200 ${
                        isActive ? 'text-[#E91E63] scale-110' : 'text-gray-400'
                      }`}
                      style={isActive ? { transform: 'scale(1.1)' } : undefined}
                      strokeWidth={isActive ? 2.5 : 2}
                    />
                    {badge > 0 && (
                      <span className="absolute -top-1.5 -right-2 min-w-[16px] h-4 bg-[#E91E63] rounded-full text-[9px] font-bold text-white flex items-center justify-center px-1 leading-none animate-badge-pop">
                        {badge > 99 ? '99+' : badge}
                      </span>
                    )}
                  </div>
                  <span
                    className={`text-[10px] font-medium transition-all duration-200 ${
                      isActive ? 'text-[#E91E63]' : 'text-gray-400'
                    }`}
                  >
                    {tab.label}
                  </span>
                  {isActive && (
                    <div className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 bg-[#E91E63] rounded-full" />
                  )}
                </button>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
