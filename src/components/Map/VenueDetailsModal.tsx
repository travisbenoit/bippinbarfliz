import { useState, useEffect } from 'react';
import { X, MapPin, Star, Users, User, MessageCircle, ExternalLink, CheckCircle, Radio, Phone, Globe, Clock } from 'lucide-react';
import type { RealTimeVenue } from '../../services/locationService';
import type { MapUserProfile } from '../../hooks/useMapData';
import { VenueRatingWidget } from '../Venues/VenueRatingWidget';
import { CheersButton } from '../Social/CheersButton';
import { VenueBuzzChat } from '../Community/VenueBuzzChat';
import { VibePulseWidget } from '../Community/VibePulseWidget';
import { TheRoom } from '../Room/TheRoom';
import { VenueEntryAnimation } from '../Room/VenueEntryAnimation';
import { roomService, RoomStats } from '../../services/roomService';
import { supabase } from '../../lib/supabase';
import { useGeofenceContext } from '../../geolocation/GeofenceProvider';

interface VenueDetailsModalProps {
  isOpen: boolean;
  onClose: () => void;
  venue: RealTimeVenue | null;
  usersAtVenue: MapUserProfile[];
  onViewProfile: (user: MapUserProfile) => void;
  onMessageUser: (userId: string) => void;
}

export default function VenueDetailsModal({
  isOpen,
  onClose,
  venue,
  usersAtVenue,
  onViewProfile,
  onMessageUser,
}: VenueDetailsModalProps) {
  const { state: geofenceState } = useGeofenceContext();
  const [checkedIn, setCheckedIn] = useState(false);
  const [loadingPresence, setLoadingPresence] = useState(false);
  const [activeTab, setActiveTab] = useState<'overview' | 'buzz' | 'vibe'>('overview');
  const [showRoom, setShowRoom] = useState(false);
  const [showEntryAnimation, setShowEntryAnimation] = useState(false);
  const [roomStats, setRoomStats] = useState<RoomStats>({ message_count: 0, active_users: 0, top_drink: null, top_music: null });

  const isAutoCheckedIn = geofenceState.currentVenue?.id === venue?.id;

  useEffect(() => {
    if (isOpen && venue) {
      loadCurrentPresence();
      roomService.getStats(venue.id).then(setRoomStats).catch(() => {});
    } else {
      setCheckedIn(false);
      setShowRoom(false);
      setShowEntryAnimation(false);
    }
  }, [isOpen, venue?.id, isAutoCheckedIn]);

  const loadCurrentPresence = async () => {
    if (!venue) return;
    setLoadingPresence(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoadingPresence(false); return; }

      const { data } = await supabase
        .from('user_venue_presence')
        .select('id, status')
        .eq('user_id', user.id)
        .eq('venue_id', venue.id)
        .eq('status', 'IN_VENUE')
        .is('left_at', null)
        .maybeSingle();

      setCheckedIn(!!data || isAutoCheckedIn);
    } catch {
      setCheckedIn(isAutoCheckedIn);
    }
    setLoadingPresence(false);
  };

  if (!isOpen || !venue) return null;

  const getCategoryLabel = (category: string) => {
    const labels: Record<string, string> = {
      bar: 'Bar',
      club: 'Nightclub',
      lounge: 'Lounge',
      brewery: 'Brewery',
      sports_bar: 'Sports Bar',
      rooftop: 'Rooftop Bar',
      restaurant: 'Restaurant',
    };
    return labels[category] || 'Venue';
  };

  const getCategoryIcon = (category: string) => {
    const icons: Record<string, string> = {
      club: '🎵',
      brewery: '🍺',
      rooftop: '🌆',
      lounge: '🍸',
      sports_bar: '🏈',
      bar: '🍻',
      restaurant: '🍽️',
    };
    return icons[category] || '🍻';
  };

  const publicUsers = usersAtVenue.filter(u => u.visibilityMode !== 'private');

  if (showRoom && venue) {
    return (
      <TheRoom
        venueId={venue.id}
        venueName={venue.name}
        venuePhoto={venue.photo_url}
        isInsideVenue={!!(isAutoCheckedIn || checkedIn)}
        onClose={() => setShowRoom(false)}
        onMessageUser={onMessageUser}
      />
    );
  }

  return (
    <>
    {showEntryAnimation && venue && (
      <VenueEntryAnimation
        venueName={venue.name}
        stats={{
          messageCount: roomStats.message_count,
          activeUsers: roomStats.active_users,
          topDrink: roomStats.top_drink,
          topMusic: roomStats.top_music,
        }}
        onEnter={() => { setShowEntryAnimation(false); setShowRoom(true); }}
        onDismiss={() => setShowEntryAnimation(false)}
      />
    )}
    <div className="fixed inset-0 z-[2000] flex items-end justify-center">
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={onClose}
      />
      <div className="relative bg-white rounded-t-3xl w-full max-w-lg max-h-[95vh] overflow-hidden animate-slide-up flex flex-col">
        <div className="relative h-48 flex-shrink-0 overflow-hidden">
          {venue.photo_url ? (
            <img
              src={venue.photo_url}
              alt={venue.name}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="w-full h-full bg-gradient-to-br from-[#E91E63] to-[#C2185B] flex items-center justify-center">
              <span className="text-8xl">{getCategoryIcon(venue.category)}</span>
            </div>
          )}
          <button
            onClick={onClose}
            className="absolute top-4 right-4 w-10 h-10 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center hover:bg-white/30 transition-colors z-10"
          >
            <X className="w-5 h-5 text-white" />
          </button>
          <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-6">
            <div className="flex items-center gap-2 mb-2">
              <span className="px-3 py-1 bg-white/20 backdrop-blur-sm rounded-full text-xs font-medium text-white">
                {getCategoryLabel(venue.category)}
              </span>
              {venue.user_count > 0 && (
                <span className="px-3 py-1 bg-emerald-500/80 backdrop-blur-sm rounded-full text-xs font-bold text-white flex items-center gap-1">
                  <Users className="w-3 h-3" />
                  {venue.user_count} here now
                </span>
              )}
            </div>
            <h2 className="text-2xl font-bold text-white">{venue.name}</h2>
          </div>
        </div>

        <div className="overflow-y-auto flex-1 flex flex-col">
          {/* Tab Navigation */}
          <div className="sticky top-0 bg-white border-b border-gray-100 px-6 py-3 flex gap-2 z-10">
            <button
              onClick={() => setActiveTab('overview')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                activeTab === 'overview'
                  ? 'bg-[#E91E63]/10 text-[#E91E63]'
                  : 'text-gray-600 hover:bg-gray-50'
              }`}
            >
              Overview
            </button>
            <button
              onClick={() => setActiveTab('vibe')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                activeTab === 'vibe'
                  ? 'bg-purple-500/10 text-purple-600'
                  : 'text-gray-600 hover:bg-gray-50'
              }`}
            >
              Vibe
            </button>
            <button
              onClick={() => setActiveTab('buzz')}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                activeTab === 'buzz'
                  ? 'bg-blue-500/10 text-blue-600'
                  : 'text-gray-600 hover:bg-gray-50'
              }`}
            >
              💬 Buzz
            </button>
          </div>

          {activeTab === 'overview' && (
            <div className="p-6 space-y-6 flex-1">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                {venue.rating != null && (
                  <div className="flex items-center gap-1">
                    <Star className="w-5 h-5 text-amber-500 fill-amber-500" />
                    <span className="font-bold text-gray-900">{typeof venue.rating === 'number' ? venue.rating.toFixed(1) : venue.rating}</span>
                  </div>
                )}
              </div>
              <button
                onClick={() => {
                  if (venue.address) {
                    window.open(`https://maps.google.com/?q=${encodeURIComponent(venue.address)}`, '_blank');
                  }
                }}
                className="flex items-center gap-2 px-4 py-2 bg-[#E91E63]/10 text-[#E91E63] rounded-xl text-sm font-semibold hover:bg-[#E91E63]/20 transition-colors"
              >
                <ExternalLink className="w-4 h-4" />
                Directions
              </button>
            </div>

            <div className="space-y-3">
              {venue.address && (
                <div className="flex items-start gap-3 text-gray-600">
                  <MapPin className="w-5 h-5 flex-shrink-0 mt-0.5" />
                  <p className="text-sm">{venue.address}</p>
                </div>
              )}

              {(venue as any).phone && (
                <div className="flex items-center gap-3 text-gray-600">
                  <Phone className="w-5 h-5 flex-shrink-0" />
                  <a
                    href={`tel:${(venue as any).phone}`}
                    className="text-sm hover:text-[#E91E63] transition-colors"
                  >
                    {(venue as any).phone}
                  </a>
                </div>
              )}

              {(venue as any).website && (
                <div className="flex items-center gap-3 text-gray-600">
                  <Globe className="w-5 h-5 flex-shrink-0" />
                  <a
                    href={(venue as any).website}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-sm hover:text-[#E91E63] transition-colors truncate"
                  >
                    Visit Website
                  </a>
                </div>
              )}

              {(venue as any).hours?.weekday_text && (
                <div className="flex items-start gap-3 text-gray-600">
                  <Clock className="w-5 h-5 flex-shrink-0 mt-0.5" />
                  <div className="text-sm space-y-0.5">
                    {(venue as any).hours.weekday_text.slice(0, 3).map((day: string, idx: number) => (
                      <p key={idx}>{day}</p>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {(checkedIn || isAutoCheckedIn) && (
              <div className="bg-emerald-50 border border-emerald-200 rounded-2xl p-4 flex items-center gap-3">
                <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center flex-shrink-0">
                  <CheckCircle className="w-5 h-5 text-emerald-600" />
                </div>
                <div className="flex-1">
                  <p className="font-semibold text-emerald-900 text-sm">You're checked in here</p>
                  <p className="text-emerald-600 text-xs mt-0.5">Your friends can see you at this venue</p>
                </div>
              </div>
            )}

            <div
              className="relative overflow-hidden rounded-2xl cursor-pointer group"
              style={{ background: 'linear-gradient(135deg, #0a0a0f 0%, #1a1205 100%)', border: '1px solid rgba(245,124,0,0.3)' }}
              onClick={() => {
                if (isAutoCheckedIn || checkedIn) {
                  setShowEntryAnimation(true);
                } else {
                  setShowRoom(true);
                }
              }}
            >
              <div className="absolute inset-0 bg-gradient-to-r from-amber-500/5 to-orange-500/5 group-hover:from-amber-500/10 group-hover:to-orange-500/10 transition-all" />
              <div className="relative p-4">
                <div className="flex items-center gap-2 mb-3">
                  <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
                  <span className="text-green-400 text-xs font-bold uppercase tracking-wider">The Room</span>
                  <span className="ml-auto text-xs text-amber-500 font-semibold group-hover:translate-x-0.5 transition-transform">
                    Enter →
                  </span>
                </div>
                <div className="grid grid-cols-2 gap-3 mb-3">
                  <div className="text-center">
                    <p className="text-2xl font-black text-white">{roomStats.active_users}</p>
                    <p className="text-xs text-gray-400">🔥 here now</p>
                  </div>
                  <div className="text-center">
                    <p className="text-2xl font-black text-white">{roomStats.message_count}</p>
                    <p className="text-xs text-gray-400">💬 tonight</p>
                  </div>
                </div>
                {(roomStats.top_drink || roomStats.top_music) && (
                  <div className="flex gap-3 text-xs border-t border-gray-800 pt-2">
                    {roomStats.top_drink && (
                      <span className="text-gray-400">🍸 <span className="text-white capitalize">{roomStats.top_drink.replace(/_/g, ' ')}</span></span>
                    )}
                    {roomStats.top_music && (
                      <span className="text-gray-400">🎵 <span className="text-white capitalize">{roomStats.top_music.replace(/_/g, ' ')}</span></span>
                    )}
                  </div>
                )}
                {!isAutoCheckedIn && !checkedIn && (
                  <p className="text-xs text-gray-500 mt-2 border-t border-gray-800 pt-2">
                    Viewing remotely — check in to post
                  </p>
                )}
              </div>
            </div>

            {venue.vibes && venue.vibes.length > 0 && (
              <div className="flex flex-wrap gap-2">
                {venue.vibes.map((vibe: string) => (
                  <span
                    key={vibe}
                    className="px-3 py-1.5 bg-gray-100 text-gray-700 rounded-full text-sm font-medium"
                  >
                    {vibe}
                  </span>
                ))}
              </div>
            )}

            {publicUsers.length > 0 && (
              <div>
                <div className="flex items-center justify-between mb-4">
                  <h3 className="font-bold text-gray-900 flex items-center gap-2">
                    <Users className="w-5 h-5 text-[#E91E63]" />
                    People Here Now
                  </h3>
                  <span className="text-sm text-gray-500">{publicUsers.length} visible</span>
                </div>
                <div className="space-y-2">
                  {publicUsers.map((u) => (
                    <div
                      key={u.id}
                      className="flex items-center gap-3 p-3 bg-gray-50 rounded-2xl"
                    >
                      <div className="relative">
                        <div className="w-12 h-12 rounded-full overflow-hidden border-2 border-white shadow-md">
                          {u.avatar_url ? (
                            <img
                              src={u.avatar_url}
                              alt={u.name}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <div className="w-full h-full bg-gradient-to-br from-[#E91E63] to-[#C2185B] flex items-center justify-center">
                              <User className="w-5 h-5 text-white" />
                            </div>
                          )}
                        </div>
                        <div className="absolute -bottom-0.5 -right-0.5 w-4 h-4 bg-emerald-500 rounded-full border-2 border-white" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <button
                          onClick={() => onViewProfile(u)}
                          className="font-semibold text-gray-900 hover:text-[#E91E63] transition-colors text-left"
                        >
                          {u.name}
                        </button>
                      </div>
                      <div className="flex items-center gap-2">
                        <CheersButton
                          recipientId={u.id}
                          recipientName={u.name}
                          venueId={venue.id}
                          venueName={venue.name}
                          compact
                        />
                        <button
                          onClick={() => onMessageUser(u.id)}
                          className="p-2.5 bg-[#E91E63]/10 text-[#E91E63] rounded-xl hover:bg-[#E91E63]/20 transition-colors"
                        >
                          <MessageCircle className="w-5 h-5" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {publicUsers.length === 0 && (
              <div className="text-center py-8">
                <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mx-auto mb-4">
                  <Users className="w-8 h-8 text-gray-400" />
                </div>
                <p className="text-gray-600 font-medium">No one here yet</p>
                <p className="text-gray-400 text-sm mt-1">Visit this venue to check in automatically</p>
              </div>
            )}

            {venue.id && (
              <div>
                <h3 className="font-bold text-gray-900 mb-3">Vibe Ratings</h3>
                <VenueRatingWidget venueId={venue.id} venueName={venue.name} />
              </div>
            )}
            </div>
          )}

          {activeTab === 'vibe' && venue.id && (
            <div className="p-6 flex-1">
              <VibePulseWidget venueId={venue.id} />
            </div>
          )}

          {activeTab === 'buzz' && venue.id && (
            <div className="flex-1 flex flex-col">
              <VenueBuzzChat venueId={venue.id} venueTitle={venue.name} />
            </div>
          )}

          <div className="sticky bottom-0 bg-white border-t border-gray-100 p-4 flex-shrink-0">
            {loadingPresence ? (
              <div className="w-full py-3.5 bg-gray-100 rounded-xl flex items-center justify-center">
                <div className="w-5 h-5 border-2 border-gray-400 border-t-transparent rounded-full animate-spin" />
              </div>
            ) : checkedIn || isAutoCheckedIn ? (
              <div className="w-full py-3.5 bg-emerald-50 text-emerald-700 rounded-xl font-semibold flex items-center justify-center gap-2 border border-emerald-200">
                <CheckCircle className="w-5 h-5" />
                You're checked in here
              </div>
            ) : (
              <div className="w-full py-3.5 bg-gray-50 text-gray-500 rounded-xl font-medium flex items-center justify-center gap-2 border border-gray-200">
                <Radio className="w-5 h-5" />
                Auto check-in when you arrive
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
    </>
  );
}
