import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, MapPin, Users, Wine } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import locationService from '../../services/locationService';
import type { RealTimeUser } from '../../services/locationService';
import UserProfileModal from '../Profile/UserProfileModal';
import { supabase } from '../../lib/supabase';
import type { Database } from '../../lib/database.types';

type UserProfileDB = Database['public']['Tables']['users']['Row'];

interface UserProfile extends RealTimeUser {
  avatar_url?: string;
}

export default function PeopleNearbyView() {
  const navigate = useNavigate();
  const { userProfile } = useAuth();
  const [nearbyPeople, setNearbyPeople] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<UserProfileDB | null>(null);
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [searchRadius, setSearchRadius] = useState(5);

  useEffect(() => {
    loadNearbyPeople();
  }, [searchRadius]);

  const loadNearbyPeople = async () => {
    try {
      setLoading(true);
      const location = await locationService.fetchCurrentUserLocation();
      setUserLocation(location);

      if (!location) {
        setLoading(false);
        return;
      }

      const users = await locationService.fetchNearbyUsers(
        location.lat,
        location.lng,
        searchRadius
      );

      const { data: profiles } = await import('../../lib/supabase').then(m =>
        m.supabase
          .from('users')
          .select('id, avatar_url')
          .in('id', users.map(u => u.id))
      );

      const profileMap = new Map((profiles || []).map(p => [p.id, p]));
      const enriched = users.map(user => ({
        ...user,
        avatar_url: profileMap.get(user.id)?.avatar_url,
      }));

      setNearbyPeople(enriched);
    } catch (error) {
      console.error('Error loading nearby people:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'going_out':
        return 'bg-green-500';
      case 'staying_in':
        return 'bg-gray-400';
      default:
        return 'bg-yellow-500';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'going_out':
        return 'Out Now';
      default:
        return 'Going Out Soon';
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-[#E91E63] via-[#9C27B0] to-[#673AB7] flex items-center justify-center">
        <div className="text-white text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-white mx-auto mb-4"></div>
          <p>Finding people nearby...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-gradient-to-br from-[#E91E63] via-[#9C27B0] to-[#673AB7] text-white p-6 pb-8">
        <div className="flex items-center gap-4 mb-6">
          <button
            onClick={() => navigate(-1)}
            className="p-2 hover:bg-white/10 rounded-full transition-colors"
          >
            <ArrowLeft size={24} />
          </button>
          <div>
            <h1 className="text-2xl font-bold">People Nearby</h1>
            <p className="text-white/80 text-sm">
              {nearbyPeople.length} {nearbyPeople.length === 1 ? 'person' : 'people'} within {searchRadius}km
            </p>
          </div>
        </div>

        <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4">
          <label className="text-sm text-white/90 mb-2 block">Search Radius</label>
          <div className="flex items-center gap-4">
            <input
              type="range"
              min="1"
              max="50"
              value={searchRadius}
              onChange={(e) => setSearchRadius(Number(e.target.value))}
              className="flex-1"
            />
            <span className="text-lg font-bold min-w-[60px]">{searchRadius}km</span>
          </div>
        </div>
      </div>

      <div className="p-4 space-y-3">
        {nearbyPeople.length === 0 ? (
          <div className="bg-white rounded-xl p-8 text-center">
            <Users size={48} className="mx-auto text-gray-300 mb-4" />
            <h3 className="font-bold text-gray-900 mb-2">No One Nearby</h3>
            <p className="text-gray-600 text-sm">
              Try increasing your search radius or check back later when more people are out!
            </p>
          </div>
        ) : (
          nearbyPeople.map((person) => {
            const distance = userLocation
              ? locationService.calculateDistance(
                  userLocation.lat,
                  userLocation.lng,
                  person.lat,
                  person.lng
                )
              : 0;

            const handleUserClick = async (userId: string) => {
              const { data } = await supabase
                .from('users')
                .select('*')
                .eq('id', userId)
                .maybeSingle();
              if (data) setSelectedUser(data);
            };

            return (
              <button
                key={person.id}
                onClick={() => handleUserClick(person.id)}
                className="w-full bg-white rounded-xl p-4 shadow-sm hover:shadow-md transition-all text-left"
              >
                <div className="flex items-start gap-4">
                  <div className="relative">
                    {person.avatar_url ? (
                      <img
                        src={person.avatar_url}
                        alt={person.name}
                        className="w-16 h-16 rounded-full object-cover"
                      />
                    ) : (
                      <div className="w-16 h-16 rounded-full bg-gradient-to-br from-[#E91E63] to-[#9C27B0] flex items-center justify-center text-white text-xl font-bold">
                        {person.name.charAt(0).toUpperCase()}
                      </div>
                    )}
                    <div
                      className={`absolute -bottom-1 -right-1 w-5 h-5 ${getStatusColor(
                        person.tonightStatus
                      )} rounded-full border-2 border-white`}
                    ></div>
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <h3 className="font-bold text-gray-900">{person.name}</h3>
                        <p className="text-sm text-gray-600">
                          {getStatusLabel(person.tonightStatus)}
                        </p>
                      </div>
                      <div className="flex items-center gap-1 text-gray-600 text-sm">
                        <MapPin size={14} />
                        <span>{distance.toFixed(1)}km</span>
                      </div>
                    </div>

                    {person.vibes.length > 0 && (
                      <div className="flex flex-wrap gap-1 mt-2">
                        {person.vibes.slice(0, 3).map((vibe, idx) => (
                          <span
                            key={idx}
                            className="px-2 py-1 bg-gray-100 rounded-full text-xs text-gray-700"
                          >
                            {vibe}
                          </span>
                        ))}
                        {person.vibes.length > 3 && (
                          <span className="px-2 py-1 bg-gray-100 rounded-full text-xs text-gray-700">
                            +{person.vibes.length - 3}
                          </span>
                        )}
                      </div>
                    )}

                    {person.favoriteDrinks.length > 0 && (
                      <div className="flex items-center gap-2 mt-2 text-xs text-gray-600">
                        <Wine size={14} />
                        <span>{person.favoriteDrinks.slice(0, 2).join(', ')}</span>
                      </div>
                    )}
                  </div>
                </div>
              </button>
            );
          })
        )}
      </div>

      <UserProfileModal
        isOpen={!!selectedUser}
        onClose={() => setSelectedUser(null)}
        user={selectedUser}
      />
    </div>
  );
}
