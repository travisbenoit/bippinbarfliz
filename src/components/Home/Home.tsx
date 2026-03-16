import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router';
import { Settings, MessageCircle, User as UserIcon } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';
import type { Database } from '../../lib/database.types';
import ActivityHistoryModal from '../Activity/ActivityHistoryModal';
import StatusModal from './StatusModal';
import HomeDashboardTab from './HomeDashboardTab';
import UserProfileModal from '../Profile/UserProfileModal';
import { NotificationBell, NotificationCenter } from '../Notifications/NotificationCenter';
import type { DateFilterOption } from '../Swarms/SwarmDateFilter';
import { messagesService } from '../../services/messagesService';

type UserProfile = Database['public']['Tables']['users']['Row'];
type Venue = Database['public']['Tables']['venues']['Row'];
type Swarm = Database['public']['Tables']['swarms']['Row'];

export default function Home() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { showError, showSuccess } = useToast();
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [nearbyUsers, setNearbyUsers] = useState<UserProfile[]>([]);
  const [venues, setVenues] = useState<Venue[]>([]);
  const [swarms, setSwarms] = useState<Swarm[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchRadius, setSearchRadius] = useState(5000);
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [showActivityHistory, setShowActivityHistory] = useState(false);
  const [showStatusModal, setShowStatusModal] = useState(false);
  const [swarmDateFilter, setSwarmDateFilter] = useState<DateFilterOption>('today');
  const [showNotifications, setShowNotifications] = useState(false);
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null);
  const [showProfileModal, setShowProfileModal] = useState(false);
  const [unreadMessageCount, setUnreadMessageCount] = useState(0);

  useEffect(() => {
    loadProfile();
    updateLocation();
    loadUnreadCount();
  }, []);

  useEffect(() => {
    const interval = setInterval(updateLocation, 60000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const subscription = messagesService.subscribeToAllMessages(() => {
      loadUnreadCount();
    });
    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const loadProfile = async () => {
    if (!user) return;
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', user!.id)
        .maybeSingle();

      if (error) throw error;

      if (data) {
        setUserProfile(data);
        if (data.preferred_radius_meters) {
          setSearchRadius(data.preferred_radius_meters);
        }
      }
    } catch {
      showError('Failed to load your profile. Please refresh.');
    }
  };

  const loadData = async (lat?: number, lng?: number) => {
    setLoading(true);
    try {
      const RADIUS_KM = 50;
      let usersQuery = supabase
        .from('users')
        .select('*')
        .neq('ghost_mode', true)
        .in('tonight_status', ['out_now', 'going_out_soon'])
        .not('last_known_lat', 'is', null)
        .not('last_known_lng', 'is', null)
        .limit(50);

      const [usersRes, venuesRes, swarmsRes] = await Promise.all([
        usersQuery,
        supabase.from('venues').select('*').eq('is_active', true).limit(50),
        supabase.from('swarms').select('*').eq('status', 'active').limit(20),
      ]);

      if (usersRes.data) {
        let filtered = usersRes.data.filter(u => u.id !== user!.id);
        if (lat !== undefined && lng !== undefined) {
          filtered = filtered.filter(u => {
            if (!u.last_known_lat || !u.last_known_lng) return false;
            const dLat = (u.last_known_lat - lat) * (Math.PI / 180);
            const dLng = (u.last_known_lng - lng) * (Math.PI / 180);
            const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat * Math.PI / 180) * Math.cos(u.last_known_lat * Math.PI / 180) * Math.sin(dLng / 2) ** 2;
            const dist = 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            return dist <= RADIUS_KM;
          });
        }
        setNearbyUsers(filtered);
      }
      if (venuesRes.data) {
        let filteredVenues = venuesRes.data;
        if (lat !== undefined && lng !== undefined) {
          filteredVenues = filteredVenues.filter(v => {
            if (!v.lat || !v.lng) return false;
            const dLat = (v.lat - lat) * (Math.PI / 180);
            const dLng = (v.lng - lng) * (Math.PI / 180);
            const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat * Math.PI / 180) * Math.cos(v.lat * Math.PI / 180) * Math.sin(dLng / 2) ** 2;
            const dist = 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            return dist <= RADIUS_KM;
          });
        }
        setVenues(filteredVenues);
      }
      if (swarmsRes.data) setSwarms(swarmsRes.data);
    } catch {
      showError('Could not load nearby data. Check your connection.');
    } finally {
      setLoading(false);
    }
  };


  const updateLocation = async () => {
    if (!('geolocation' in navigator)) {
      loadData();
      return;
    }

    navigator.geolocation.getCurrentPosition(
      async (position) => {
        const lat = position.coords.latitude;
        const lng = position.coords.longitude;
        setUserLocation({ lat, lng });
        loadData(lat, lng);
        if (!user) return;
        try {
          await supabase
            .from('users')
            .update({
              last_known_lat: lat,
              last_known_lng: lng,
              last_active_at: new Date().toISOString(),
            })
            .eq('id', user!.id);
        } catch (err) {
          console.debug('Background location update failed:', err);
        }
      },
      () => {
        loadData();
      },
      { timeout: 8000, maximumAge: 60000 }
    );
  };

  const handleSelectUser = async (userId: string) => {
    const found = nearbyUsers.find(u => u.id === userId);
    if (found) {
      setSelectedUser(found);
      setShowProfileModal(true);
      return;
    }
    try {
      const { data } = await supabase.from('users').select('*').eq('id', userId).maybeSingle();
      if (data) {
        setSelectedUser(data);
        setShowProfileModal(true);
      }
    } catch {
      showError('Could not load profile.');
    }
  };

  const handleSelectUserProfile = (person: UserProfile) => {
    setSelectedUser(person);
    setShowProfileModal(true);
  };

  const loadUnreadCount = async () => {
    if (!user) return;
    try {
      const count = await messagesService.getUnreadCount();
      setUnreadMessageCount(count);
    } catch (error) {
      console.error('Error loading unread count:', error);
    }
  };

  return (
    <div className="min-h-screen bg-[#FFF5F0] flex flex-col">
      <div className="bg-white shadow-sm sticky top-0 z-10">
        <div className="px-6 py-4 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Barfliz</h1>
            <p className="text-sm text-gray-600">Going out made easy</p>
          </div>
          <div className="flex items-center gap-1">
            <button
              onClick={() => navigate('/messages')}
              className="w-10 h-10 flex items-center justify-center hover:bg-gray-100 rounded-2xl transition-colors relative">
              <MessageCircle size={22} className="text-gray-700" />
              {unreadMessageCount > 0 && (
                <span className="absolute -top-1 -right-1 bg-[#E91E63] text-white text-xs font-bold rounded-full min-w-[18px] h-[18px] flex items-center justify-center px-1">
                  {unreadMessageCount > 99 ? '99+' : unreadMessageCount}
                </span>
              )}
            </button>
            <NotificationBell onClick={() => setShowNotifications(true)} />
            <button
              onClick={() => navigate('/settings')}
              className="w-10 h-10 flex items-center justify-center hover:bg-gray-100 rounded-2xl transition-colors">
              <Settings size={22} className="text-gray-700" />
            </button>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-auto">
        <HomeDashboardTab
          userProfile={userProfile}
          nearbyUsers={nearbyUsers}
          venues={venues}
          swarms={swarms}
          searchRadius={searchRadius}
          userLocation={userLocation}
          swarmDateFilter={swarmDateFilter}
          onSwarmDateFilterChange={setSwarmDateFilter}
          onRadiusChange={setSearchRadius}
          onFindVenues={() => navigate('/map?tab=places')}
          onShowStatusModal={() => setShowStatusModal(true)}
          onShowActivityHistory={() => setShowActivityHistory(true)}
          onSelectUser={handleSelectUser}
          onSelectUserProfile={handleSelectUserProfile}
        />

        <UserProfileModal
          isOpen={showProfileModal}
          onClose={() => { setShowProfileModal(false); setSelectedUser(null); }}
          user={selectedUser}
        />

        <ActivityHistoryModal
          isOpen={showActivityHistory}
          onClose={() => setShowActivityHistory(false)}
        />

        {userProfile && (
          <StatusModal
            isOpen={showStatusModal}
            onClose={() => setShowStatusModal(false)}
            currentStatus={userProfile.tonight_status as 'out_now' | 'going_out_soon' | 'staying_in'}
            onStatusUpdate={(status) => setUserProfile({ ...userProfile, tonight_status: status })}
          />
        )}
      </div>

      <NotificationCenter isOpen={showNotifications} onClose={() => setShowNotifications(false)} />
    </div>
  );
}
