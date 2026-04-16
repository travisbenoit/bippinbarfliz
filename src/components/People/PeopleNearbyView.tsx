import { useEffect, useState, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, MapPin, Users, Wine, UserPlus, UserCheck, RefreshCw, X, Heart, Sparkles, ChevronDown } from 'lucide-react';
import { WingmanPanel } from '../AI/WingmanPanel';
import { useAuth } from '../../contexts/AuthContext';
import locationService from '../../services/locationService';
import type { RealTimeUser } from '../../services/locationService';
import UserProfileModal from '../Profile/UserProfileModal';
import { supabase } from '../../lib/supabase';
import { friendsService } from '../../services/friendsService';
import { useToast } from '../../contexts/ToastContext';
import type { Database } from '../../lib/database.types';
import { CardSkeleton } from '../UI/Skeleton';

type UserProfileDB = Database['public']['Tables']['users']['Row'];

interface UserProfile extends RealTimeUser {
  avatar_url?: string;
}

export default function PeopleNearbyView() {
  const navigate = useNavigate();
  const { userProfile } = useAuth();
  const { showSuccess, showError } = useToast();
  const [nearbyPeople, setNearbyPeople] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<UserProfileDB | null>(null);
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [searchRadius, setSearchRadius] = useState(5);
  const [friendStatuses, setFriendStatuses] = useState<Record<string, 'none' | 'pending' | 'accepted'>>({});
  const [addingFriend, setAddingFriend] = useState<string | null>(null);

  // Swipe card state
  const [currentIndex, setCurrentIndex] = useState(0);
  const [swipeDirection, setSwipeDirection] = useState<'left' | 'right' | null>(null);
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const [expandedCard, setExpandedCard] = useState(false);
  const dragStart = useRef<{ x: number; y: number } | null>(null);
  const cardRef = useRef<HTMLDivElement>(null);

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
      setCurrentIndex(0);

      const statuses: Record<string, 'none' | 'pending' | 'accepted'> = {};
      await Promise.all(
        enriched.map(async (person) => {
          const status = await friendsService.getFriendshipStatus(person.id).catch(() => null);
          statuses[person.id] = (status as any) || 'none';
        })
      );
      setFriendStatuses(statuses);
    } catch (error) {
      console.error('Error loading nearby people:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAddFriend = useCallback(async (userId: string) => {
    setAddingFriend(userId);
    try {
      await friendsService.sendFriendRequest(userId);
      setFriendStatuses(prev => ({ ...prev, [userId]: 'pending' }));
      showSuccess('Friend request sent!');
    } catch {
      showError('Could not send friend request.');
    } finally {
      setAddingFriend(null);
    }
  }, []);

  const handleSwipe = useCallback((direction: 'left' | 'right') => {
    const person = nearbyPeople[currentIndex];
    if (!person) return;

    setSwipeDirection(direction);

    if (direction === 'right' && friendStatuses[person.id] === 'none') {
      handleAddFriend(person.id);
    }

    setTimeout(() => {
      setSwipeDirection(null);
      setCurrentIndex(prev => prev + 1);
      setExpandedCard(false);
    }, 400);
  }, [currentIndex, nearbyPeople, friendStatuses, handleAddFriend]);

  // Touch/mouse drag handlers
  const handleDragStart = useCallback((clientX: number, clientY: number) => {
    dragStart.current = { x: clientX, y: clientY };
    setIsDragging(true);
  }, []);

  const handleDragMove = useCallback((clientX: number, clientY: number) => {
    if (!dragStart.current || !isDragging) return;
    const dx = clientX - dragStart.current.x;
    const dy = clientY - dragStart.current.y;
    setDragOffset({ x: dx, y: dy * 0.3 });
  }, [isDragging]);

  const handleDragEnd = useCallback(() => {
    if (!isDragging) return;
    setIsDragging(false);
    dragStart.current = null;

    const threshold = 100;
    if (dragOffset.x > threshold) {
      handleSwipe('right');
    } else if (dragOffset.x < -threshold) {
      handleSwipe('left');
    }
    setDragOffset({ x: 0, y: 0 });
  }, [isDragging, dragOffset, handleSwipe]);

  const handleUserClick = async (userId: string) => {
    const { data } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .maybeSingle();
    if (data) setSelectedUser(data);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'going_out': return 'bg-green-500';
      case 'staying_in': return 'bg-gray-400';
      default: return 'bg-yellow-500';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'going_out': return 'Out Now';
      default: return 'Going Out Soon';
    }
  };

  const currentPerson = nearbyPeople[currentIndex];
  const nextPerson = nearbyPeople[currentIndex + 1];
  const isDone = currentIndex >= nearbyPeople.length;

  const distance = currentPerson && userLocation
    ? locationService.calculateDistance(userLocation.lat, userLocation.lng, currentPerson.lat, currentPerson.lng)
    : 0;

  // Card tilt based on drag
  const rotation = isDragging ? dragOffset.x * 0.08 : 0;
  const likeOpacity = Math.min(Math.max(dragOffset.x / 100, 0), 1);
  const nopeOpacity = Math.min(Math.max(-dragOffset.x / 100, 0), 1);

  if (loading) {
    return (
      <div className="min-h-screen bg-[#FFF5F0]">
        <div className="bg-gradient-to-br from-[#E91E63] via-[#9C27B0] to-[#673AB7] text-white p-6 pb-8">
          <div className="flex items-center gap-4 mb-4">
            <button onClick={() => navigate(-1)} className="p-2 hover:bg-white/10 rounded-full transition-colors">
              <ArrowLeft size={24} />
            </button>
            <div>
              <h1 className="text-2xl font-bold">People Nearby</h1>
              <div className="skeleton-shimmer h-3 w-32 rounded-full mt-2" style={{ background: 'rgba(255,255,255,0.2)' }} />
            </div>
          </div>
        </div>
        <div className="p-4 space-y-4">
          <CardSkeleton />
          <CardSkeleton />
          <CardSkeleton />
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#FFF5F0] flex flex-col">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#E91E63] via-[#9C27B0] to-[#673AB7] text-white px-6 pt-6 pb-4 flex-shrink-0">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-4">
            <button onClick={() => navigate(-1)} className="p-2 hover:bg-white/10 rounded-full transition-colors press-scale">
              <ArrowLeft size={24} />
            </button>
            <div>
              <h1 className="text-2xl font-bold">People Nearby</h1>
              <p className="text-white/70 text-sm">
                {nearbyPeople.length} {nearbyPeople.length === 1 ? 'person' : 'people'} within {searchRadius}km
              </p>
            </div>
          </div>
          <button
            onClick={() => { setCurrentIndex(0); loadNearbyPeople(); }}
            className="p-2.5 bg-white/15 rounded-full hover:bg-white/25 transition-colors press-scale"
          >
            <RefreshCw size={18} />
          </button>
        </div>

        {/* Radius slider */}
        <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3">
          <div className="flex items-center gap-4">
            <input
              type="range" min="1" max="50" value={searchRadius}
              onChange={(e) => setSearchRadius(Number(e.target.value))}
              className="flex-1 accent-white"
            />
            <span className="text-sm font-bold min-w-[48px]">{searchRadius}km</span>
          </div>
        </div>
      </div>

      {/* Card Stack Area */}
      <div className="flex-1 flex items-center justify-center p-4 relative overflow-hidden">
        {isDone ? (
          /* Empty / done state */
          <div className="text-center animate-scale-in px-8">
            <div className="w-24 h-24 mx-auto mb-6 bg-gradient-to-br from-pink-100 to-purple-100 rounded-full flex items-center justify-center">
              <Users size={40} className="text-[#E91E63]" />
            </div>
            <h3 className="text-xl font-bold text-gray-900 mb-2">
              {nearbyPeople.length === 0 ? 'No One Nearby' : "You've Seen Everyone"}
            </h3>
            <p className="text-gray-500 text-sm mb-6 leading-relaxed">
              {nearbyPeople.length === 0
                ? 'Try increasing your search radius or check back later!'
                : 'Come back later to discover new people in your area.'}
            </p>
            <button
              onClick={() => { setCurrentIndex(0); loadNearbyPeople(); }}
              className="px-8 py-3 bg-gradient-to-r from-[#E91E63] to-[#9C27B0] text-white rounded-full font-semibold shadow-lg press-scale"
            >
              <RefreshCw size={16} className="inline mr-2" />
              Refresh
            </button>
          </div>
        ) : (
          <div className="relative w-full max-w-sm" style={{ height: expandedCard ? '85vh' : '70vh' }}>
            {/* Next card (peek behind) */}
            {nextPerson && !swipeDirection && (
              <div className="absolute inset-0 rounded-3xl overflow-hidden bg-white shadow-lg scale-[0.95] opacity-60 transition-all duration-300">
                <div className="absolute inset-0 bg-gradient-to-br from-[#E91E63] to-[#9C27B0]">
                  {nextPerson.avatar_url && (
                    <img src={nextPerson.avatar_url} alt="" className="w-full h-full object-cover" />
                  )}
                </div>
              </div>
            )}

            {/* Current card */}
            {currentPerson && (
              <div
                ref={cardRef}
                className={`absolute inset-0 rounded-3xl overflow-hidden shadow-2xl cursor-grab active:cursor-grabbing select-none transition-shadow ${
                  swipeDirection === 'right' ? 'animate-card-exit-right' :
                  swipeDirection === 'left' ? 'animate-card-exit-left' : ''
                }`}
                style={{
                  transform: isDragging
                    ? `translateX(${dragOffset.x}px) translateY(${dragOffset.y}px) rotate(${rotation}deg)`
                    : swipeDirection ? undefined : 'translateX(0) rotate(0deg)',
                  transition: isDragging ? 'none' : 'transform 0.3s cubic-bezier(0.16, 1, 0.3, 1)',
                  willChange: 'transform',
                }}
                onPointerDown={(e) => {
                  if (expandedCard) return;
                  e.preventDefault();
                  (e.target as HTMLElement).setPointerCapture(e.pointerId);
                  handleDragStart(e.clientX, e.clientY);
                }}
                onPointerMove={(e) => handleDragMove(e.clientX, e.clientY)}
                onPointerUp={handleDragEnd}
                onPointerCancel={handleDragEnd}
              >
                {/* Photo / avatar background */}
                <div className="absolute inset-0 bg-gradient-to-br from-[#E91E63] via-[#9C27B0] to-[#673AB7]">
                  {currentPerson.avatar_url && (
                    <img
                      src={currentPerson.avatar_url}
                      alt={currentPerson.name}
                      className="w-full h-full object-cover"
                      draggable={false}
                    />
                  )}
                  {/* Gradient overlay for text readability */}
                  <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
                </div>

                {/* LIKE / NOPE overlays */}
                <div className="swipe-overlay-like" style={{ opacity: likeOpacity }}>ADD</div>
                <div className="swipe-overlay-nope" style={{ opacity: nopeOpacity }}>SKIP</div>

                {/* Status badge */}
                <div className="absolute top-5 left-5 z-10">
                  <span className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-white text-xs font-bold backdrop-blur-md bg-black/30`}>
                    <span className={`w-2 h-2 rounded-full ${getStatusColor(currentPerson.tonightStatus)}`} />
                    {getStatusLabel(currentPerson.tonightStatus)}
                  </span>
                </div>

                {/* Distance badge */}
                <div className="absolute top-5 right-5 z-10">
                  <span className="flex items-center gap-1 px-3 py-1.5 rounded-full text-white text-xs font-bold backdrop-blur-md bg-black/30">
                    <MapPin size={12} />
                    {distance.toFixed(1)}km
                  </span>
                </div>

                {/* Friend status badge */}
                {friendStatuses[currentPerson.id] === 'accepted' && (
                  <div className="absolute top-14 right-5 z-10">
                    <span className="flex items-center gap-1 px-3 py-1.5 rounded-full text-white text-xs font-bold bg-green-500/80 backdrop-blur-md">
                      <UserCheck size={12} /> Friends
                    </span>
                  </div>
                )}

                {/* Bottom info section */}
                <div className="absolute bottom-0 left-0 right-0 p-6 z-10">
                  <div className="mb-4" onClick={() => handleUserClick(currentPerson.id)}>
                    <h2 className="text-3xl font-extrabold text-white drop-shadow-lg">
                      {currentPerson.name}
                    </h2>

                    {currentPerson.vibes.length > 0 && (
                      <div className="flex flex-wrap gap-1.5 mt-3">
                        {currentPerson.vibes.slice(0, 4).map((vibe, idx) => (
                          <span key={idx} className="px-3 py-1 bg-white/20 backdrop-blur-sm rounded-full text-xs text-white font-medium">
                            {vibe}
                          </span>
                        ))}
                        {currentPerson.vibes.length > 4 && (
                          <span className="px-3 py-1 bg-white/20 backdrop-blur-sm rounded-full text-xs text-white font-medium">
                            +{currentPerson.vibes.length - 4}
                          </span>
                        )}
                      </div>
                    )}

                    {currentPerson.favoriteDrinks.length > 0 && (
                      <div className="flex items-center gap-2 mt-2 text-white/80 text-sm">
                        <Wine size={14} />
                        <span>{currentPerson.favoriteDrinks.slice(0, 2).join(', ')}</span>
                      </div>
                    )}
                  </div>

                  {/* Expand button */}
                  <button
                    onClick={(e) => { e.stopPropagation(); setExpandedCard(!expandedCard); }}
                    className="w-full flex items-center justify-center gap-1 py-2 text-white/60 text-xs"
                  >
                    <ChevronDown size={16} className={`transition-transform ${expandedCard ? 'rotate-180' : ''}`} />
                    {expandedCard ? 'Less' : 'Tap for more'}
                  </button>

                  {/* Expanded Wingman section */}
                  {expandedCard && currentPerson.id !== userProfile?.id && (
                    <div className="mt-2 animate-slide-up" onClick={e => e.stopPropagation()}>
                      <WingmanPanel targetUserId={currentPerson.id} targetName={currentPerson.name} />
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Action buttons */}
      {!isDone && currentPerson && (
        <div className="flex-shrink-0 pb-24 pt-2 flex items-center justify-center gap-6">
          <button
            onClick={() => handleSwipe('left')}
            className="w-16 h-16 bg-white rounded-full shadow-lg flex items-center justify-center border-2 border-gray-200 hover:border-red-300 hover:shadow-xl transition-all press-scale group"
          >
            <X size={28} className="text-gray-400 group-hover:text-red-500 transition-colors" />
          </button>

          <button
            onClick={() => handleUserClick(currentPerson.id)}
            className="w-12 h-12 bg-white rounded-full shadow-md flex items-center justify-center border-2 border-gray-200 hover:border-blue-300 transition-all press-scale group"
          >
            <Sparkles size={20} className="text-gray-400 group-hover:text-blue-500 transition-colors" />
          </button>

          <button
            onClick={() => handleSwipe('right')}
            disabled={addingFriend === currentPerson.id}
            className="w-16 h-16 bg-gradient-to-br from-[#E91E63] to-[#FF6B6B] rounded-full shadow-lg flex items-center justify-center hover:shadow-xl hover:scale-105 transition-all press-scale disabled:opacity-50"
          >
            {addingFriend === currentPerson.id ? (
              <RefreshCw size={28} className="text-white animate-spin" />
            ) : friendStatuses[currentPerson.id] === 'accepted' ? (
              <UserCheck size={28} className="text-white" />
            ) : (
              <Heart size={28} className="text-white" fill="white" />
            )}
          </button>
        </div>
      )}

      <UserProfileModal
        isOpen={!!selectedUser}
        onClose={() => setSelectedUser(null)}
        user={selectedUser}
      />
    </div>
  );
}
