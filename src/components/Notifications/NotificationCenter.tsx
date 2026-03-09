import { useState, useEffect, useCallback } from 'react';
import { Bell, MapPin, Users, UserCheck, Sparkles, X, CheckCheck } from 'lucide-react';
import { activityService, type AppNotification } from '../../services/activityService';

function timeAgo(dateStr: string): string {
  const now = Date.now();
  const then = new Date(dateStr).getTime();
  const diff = Math.floor((now - then) / 1000);
  if (diff < 60) return 'just now';
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

function NotifIcon({ type }: { type: string }) {
  const base = 'w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0';
  if (type.includes('venue')) return <div className={`${base} bg-emerald-100`}><MapPin className="w-5 h-5 text-emerald-600" /></div>;
  if (type.includes('swarm')) return <div className={`${base} bg-blue-100`}><Sparkles className="w-5 h-5 text-blue-600" /></div>;
  if (type.includes('friend')) return <div className={`${base} bg-amber-100`}><UserCheck className="w-5 h-5 text-amber-600" /></div>;
  return <div className={`${base} bg-gray-100`}><Bell className="w-5 h-5 text-gray-500" /></div>;
}

interface Props {
  isOpen: boolean;
  onClose: () => void;
}

export function NotificationCenter({ isOpen, onClose }: Props) {
  const [notifications, setNotifications] = useState<AppNotification[]>([]);
  const [loading, setLoading] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    const data = await activityService.getNotifications();
    setNotifications(data);
    setLoading(false);
  }, []);

  useEffect(() => {
    if (!isOpen) return;
    load();
    const unsub = activityService.subscribeToNotifications((data) => {
      setNotifications(data);
    });
    return unsub;
  }, [isOpen, load]);

  const handleMarkRead = async (id: string) => {
    await activityService.markAsRead(id);
    setNotifications(prev => prev.map(n => n.id === id ? { ...n, is_read: true } : n));
  };

  const handleMarkAllRead = async () => {
    await activityService.markAllAsRead();
    setNotifications(prev => prev.map(n => ({ ...n, is_read: true })));
  };

  const unreadCount = notifications.filter(n => !n.is_read).length;

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[2000] flex flex-col" onClick={onClose}>
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" />
      <div
        className="relative mt-auto bg-white rounded-t-3xl shadow-2xl max-h-[85vh] flex flex-col"
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <div className="flex items-center gap-2">
            <Bell className="w-5 h-5 text-[#E91E63]" />
            <h2 className="font-bold text-gray-900 text-lg">Notifications</h2>
            {unreadCount > 0 && (
              <span className="bg-[#E91E63] text-white text-xs font-bold px-2 py-0.5 rounded-full">
                {unreadCount}
              </span>
            )}
          </div>
          <div className="flex items-center gap-2">
            {unreadCount > 0 && (
              <button
                onClick={handleMarkAllRead}
                className="flex items-center gap-1.5 text-sm text-[#E91E63] font-medium px-3 py-1.5 rounded-full hover:bg-[#E91E63]/10 transition-colors"
              >
                <CheckCheck className="w-4 h-4" />
                Mark all read
              </button>
            )}
            <button
              onClick={onClose}
              className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100 transition-colors"
            >
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto overscroll-contain">
          {loading ? (
            <div className="space-y-0">
              {[1, 2, 3, 4, 5].map(i => (
                <div key={i} className="flex items-start gap-3 px-5 py-4 animate-pulse border-b border-gray-50">
                  <div className="w-10 h-10 bg-gray-200 rounded-full flex-shrink-0" />
                  <div className="flex-1 space-y-2">
                    <div className="h-3.5 bg-gray-200 rounded w-3/4" />
                    <div className="h-2.5 bg-gray-100 rounded w-1/2" />
                  </div>
                </div>
              ))}
            </div>
          ) : notifications.length === 0 ? (
            <div className="text-center py-16">
              <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Bell className="w-8 h-8 text-gray-300" />
              </div>
              <p className="font-medium text-gray-700">No notifications yet</p>
              <p className="text-sm text-gray-400 mt-1">We'll let you know when friends are out</p>
            </div>
          ) : (
            <div>
              {notifications.map(notif => (
                <button
                  key={notif.id}
                  onClick={() => handleMarkRead(notif.id)}
                  className={`w-full flex items-start gap-3 px-5 py-4 border-b border-gray-50 text-left transition-colors hover:bg-gray-50 ${
                    !notif.is_read ? 'bg-[#E91E63]/5' : ''
                  }`}
                >
                  <NotifIcon type={notif.notification_type} />
                  <div className="flex-1 min-w-0">
                    <p className={`text-sm leading-snug ${!notif.is_read ? 'font-semibold text-gray-900' : 'text-gray-700'}`}>
                      {notif.title}
                    </p>
                    {notif.body && (
                      <p className="text-xs text-gray-500 mt-0.5 leading-relaxed">{notif.body}</p>
                    )}
                    <p className="text-xs text-gray-400 mt-1">{timeAgo(notif.created_at)}</p>
                  </div>
                  {!notif.is_read && (
                    <div className="w-2 h-2 bg-[#E91E63] rounded-full flex-shrink-0 mt-2" />
                  )}
                </button>
              ))}
            </div>
          )}
        </div>

        <div className="h-6 flex-shrink-0" />
      </div>
    </div>
  );
}

export function NotificationBell({ onClick }: { onClick: () => void }) {
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    const loadCount = async () => {
      const count = await activityService.getUnreadCount();
      setUnreadCount(count);
    };
    loadCount();

    const unsub = activityService.subscribeToNotifications((notifs) => {
      setUnreadCount(notifs.filter(n => !n.is_read).length);
    });
    return unsub;
  }, []);

  return (
    <button
      onClick={onClick}
      className="relative w-10 h-10 flex items-center justify-center rounded-2xl hover:bg-gray-100 transition-colors"
    >
      <Bell className="w-5 h-5 text-gray-600" />
      {unreadCount > 0 && (
        <span className="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] bg-[#E91E63] text-white text-[10px] font-bold rounded-full flex items-center justify-center px-1">
          {unreadCount > 9 ? '9+' : unreadCount}
        </span>
      )}
    </button>
  );
}
