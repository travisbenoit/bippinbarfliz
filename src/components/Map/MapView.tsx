import { useState, useCallback, useEffect, useMemo, useRef } from 'react';
import { useRealTimeLocation } from '../../hooks/useRealTimeLocation';
import { Search, X, SlidersHorizontal, Settings, MapPin } from 'lucide-react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { VIBE_TAGS, GROUP_SIZE_OPTIONS, type VibeTag } from '../../data/dummyData';
import MapFilters from './MapFilters';
import TonightStatusModal from '../TonightStatus/TonightStatusModal';
import SwarmDetailsModal from '../Swarms/SwarmDetailsModal';
import UserProfileModal from '../Profile/UserProfileModal';
import VenueDetailsModal from './VenueDetailsModal';
import ChatView from '../Messages/ChatView';
import { ErrorBoundary } from '../ErrorBoundary';
import { useRegionalSettings } from '../../contexts/RegionalSettingsContext';
import { filterSwarmsByDate, type DateFilterOption } from '../Swarms/SwarmDateFilter';
import locationService from '../../services/locationService';
import { useMapData, type MapSwarm, type MapUserProfile } from '../../hooks/useMapData';
import MapCanvas from './MapCanvas';
import MapBottomSheet from './MapBottomSheet';
import type { TabType, TonightStatus } from './MapCanvas';
import type { RealTimeVenue } from '../../services/locationService';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../contexts/ToastContext';

type GroupSizeValue = 'small' | 'medium' | 'large' | null;

export default function MapView() {
  const gpsLocation = useRealTimeLocation();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { distanceUnit } = useRegionalSettings();
  const { showSuccess, showError, showInfo } = useToast();

  const getDefaultMapCenter = (): [number, number] => {
    const countryCode = localStorage.getItem('userCountryCode') || 'US';
    const countryDefaults: Record<string, [number, number]> = {
      AU: [-12.4634, 130.8456],
      GB: [51.5074, -0.1278],
      CA: [43.6532, -79.3832],
      DE: [52.5200, 13.4050],
      NZ: [-36.8485, 174.7633],
      US: [39.8283, -98.5795],
    };
    return countryDefaults[countryCode] || countryDefaults.US;
  };

  const getZoomForRadius = (radiusKm: number) => {
    if (radiusKm <= 1) return 15;
    if (radiusKm <= 2) return 14;
    if (radiusKm <= 5) return 13;
    if (radiusKm <= 10) return 12;
    if (radiusKm <= 15) return 11;
    if (radiusKm <= 25) return 10;
    return 9;
  };

  const [mapCenter, setMapCenter] = useState<[number, number]>(getDefaultMapCenter);
  const [mapZoom, setMapZoom] = useState(() => {
    const defaultDist = distanceUnit === 'miles' ? 8.0 : 10.0;
    return getZoomForRadius(defaultDist);
  });
  const currentZoomRef = useRef(mapZoom);
  const [showSearch, setShowSearch] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const initialTab = (searchParams.get('tab') as TabType) || 'places';
  const [activeTab, setActiveTab] = useState<TabType>(initialTab);
  const [showFilters, setShowFilters] = useState(false);
  const [sheetHeight, setSheetHeight] = useState(45);
  const [swarmDateFilter, setSwarmDateFilter] = useState<DateFilterOption>('today');
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [hasCentered, setHasCentered] = useState(false);

  const defaultDistance = distanceUnit === 'miles' ? 8.0 : 10.0;
  const [distanceFilter, setDistanceFilter] = useState(defaultDistance);
  const hasLoadedUserRadius = useRef(false);

  useEffect(() => {
    if (hasLoadedUserRadius.current) return;
    const loadUserRadius = async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (user) {
          const { data } = await supabase
            .from('users')
            .select('preferred_radius_meters')
            .eq('id', user.id)
            .maybeSingle();
          if (data?.preferred_radius_meters) {
            const radiusKm = data.preferred_radius_meters / 1000;
            setDistanceFilter(radiusKm);
            setMapZoom(getZoomForRadius(radiusKm));
            hasLoadedUserRadius.current = true;
          }
        }
      } catch (err) {
        console.error('Error loading user radius:', err);
      }
    };
    loadUserRadius();
  }, []);
  const [groupSizeFilter, setGroupSizeFilter] = useState<GroupSizeValue>(null);

  const handleDistanceFilterChange = useCallback(async (newDistance: number) => {
    setDistanceFilter(newDistance);
    setMapZoom(getZoomForRadius(newDistance));
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const radiusMeters = Math.round(newDistance * 1000);
        await supabase
          .from('users')
          .update({ preferred_radius_meters: radiusMeters })
          .eq('id', user.id);
      }
    } catch (err) {
      console.error('Error saving radius preference:', err);
    }
  }, []);
  const [vibeFilters, setVibeFilters] = useState<VibeTag[]>([]);
  const [drinkFilters, setDrinkFilters] = useState<string[]>([]);

  const [showTonightStatus, setShowTonightStatus] = useState(false);
  const [myTonightStatus, setMyTonightStatus] = useState<TonightStatus>('going_out');
  const [myTonightVenue, setMyTonightVenue] = useState<string | null>(null);

  const [selectedSwarm, setSelectedSwarm] = useState<MapSwarm | null>(null);
  const [selectedUser, setSelectedUser] = useState<MapUserProfile | null>(null);
  const [selectedVenue, setSelectedVenue] = useState<RealTimeVenue | null>(null);
  const [showChat, setShowChat] = useState(false);
  const [chatRecipient, setChatRecipient] = useState<MapUserProfile | null>(null);
  const [chatSwarm, setChatSwarm] = useState<MapSwarm | null>(null);

  useEffect(() => {
    if (gpsLocation) {
      setUserLocation(gpsLocation);
      if (!hasCentered) {
        setMapCenter([gpsLocation.lat, gpsLocation.lng]);
        setHasCentered(true);
      }
    }
  }, [gpsLocation, hasCentered]);

  useEffect(() => {
    if (!gpsLocation) {
      locationService.fetchCurrentUserLocation().then((loc) => {
        if (loc) {
          setUserLocation(loc);
          if (!hasCentered) {
            setMapCenter([loc.lat, loc.lng]);
            setHasCentered(true);
          }
        }
      });
    }
  }, []);

  const { swarms: dbSwarms, users: realTimeUsers, venues: realTimeVenues } = useMapData(userLocation, distanceFilter);

  const dynamicDistanceOptions = useMemo(() => {
    if (distanceUnit === 'miles') {
      return [
        { label: '0.3 mi', value: 0.5 }, { label: '0.6 mi', value: 1 },
        { label: '1 mi', value: 1.6 }, { label: '3 mi', value: 5 },
        { label: '6 mi', value: 10 }, { label: '15 mi', value: 25 },
      ];
    }
    return [
      { label: '0.5 km', value: 0.5 }, { label: '1 km', value: 1 },
      { label: '2 km', value: 2 }, { label: '5 km', value: 5 },
      { label: '10 km', value: 10 }, { label: '25 km', value: 25 },
    ];
  }, [distanceUnit]);

  const calculateDistance = (lat1: number, lng1: number, lat2: number, lng2: number) => {
    const R = 6371;
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLng = (lng2 - lng1) * (Math.PI / 180);
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  };

  const [searchCenter, setSearchCenter] = useState<{ lat: number; lng: number } | null>(null);
  const [showSearchThisArea, setShowSearchThisArea] = useState(false);
  const [currentMapCenter, setCurrentMapCenter] = useState<[number, number]>(mapCenter);
  const [mapBounds, setMapBounds] = useState<{ ne: [number, number]; sw: [number, number] } | null>(null);

  const filterByDistance = <T extends { lat: number; lng: number }>(items: T[]) => {
    const center = searchCenter || userLocation || { lat: mapCenter[0], lng: mapCenter[1] };
    return items
      .map(item => ({ ...item, distance: calculateDistance(center.lat, center.lng, item.lat, item.lng) }))
      .sort((a, b) => a.distance - b.distance);
  };

  const filterByMapBounds = <T extends { lat: number; lng: number }>(items: T[]) => {
    if (!mapBounds) return items;
    return items.filter(item =>
      item.lat >= mapBounds.sw[0] &&
      item.lat <= mapBounds.ne[0] &&
      item.lng >= mapBounds.sw[1] &&
      item.lng <= mapBounds.ne[1]
    );
  };

  const filterByVibes = <T extends { vibes: string[] | VibeTag[] }>(items: T[]) =>
    vibeFilters.length === 0 ? items : items.filter(item => vibeFilters.some(v => item.vibes.includes(v)));

  const filterByDrinks = <T extends { favoriteDrinks?: string[] }>(items: T[]) =>
    drinkFilters.length === 0 ? items : items.filter(item =>
      item.favoriteDrinks?.some(d => drinkFilters.includes(d)) ?? false
    );

  const filterByGroupSize = (items: MapSwarm[]) => {
    if (!groupSizeFilter) return items;
    const opt = GROUP_SIZE_OPTIONS.find(o => o.value === groupSizeFilter);
    if (!opt || !('min' in opt)) return items;
    return items.filter(s => s.memberCount >= opt.min && s.memberCount <= opt.max);
  };

  const filteredUsers = filterByDrinks(filterByVibes(filterByDistance(realTimeUsers))).filter(u => u.visibilityMode === 'public');
  const filteredVenues = filterByVibes(filterByMapBounds(filterByDistance(realTimeVenues)));
  const filteredSwarms = filterSwarmsByDate(filterByGroupSize(filterByVibes(filterByMapBounds(filterByDistance(dbSwarms)))), swarmDateFilter);

  const getUsersAtVenue = (venueId: string) =>
    realTimeUsers.filter(u => u.currentVenueId === venueId && u.tonightStatus === 'going_out');

  const venueUserCounts: Record<string, number> = {};
  filteredVenues.forEach(v => {
    venueUserCounts[v.id] = getUsersAtVenue(v.id).filter(u => u.visibilityMode === 'public').length;
  });

  const hotspotsWithUsers = filteredVenues
    .filter(v => venueUserCounts[v.id] > 0)
    .sort((a, b) => venueUserCounts[b.id] - venueUserCounts[a.id]);

  const activeFilterCount = (vibeFilters.length > 0 ? 1 : 0) + (groupSizeFilter ? 1 : 0) +
    (distanceFilter !== defaultDistance ? 1 : 0) + (drinkFilters.length > 0 ? 1 : 0);

  const handleMapMove = useCallback((center: [number, number], zoom: number, bounds?: { ne: [number, number]; sw: [number, number] }) => {
    setCurrentMapCenter(center);
    currentZoomRef.current = zoom;
    if (bounds) {
      setMapBounds(bounds);
    }
    if (center[0] !== mapCenter[0] || center[1] !== mapCenter[1]) {
      const distance = calculateDistance(mapCenter[0], mapCenter[1], center[0], center[1]);
      if (distance > 0.1) {
        setShowSearchThisArea(true);
      }
    }
  }, [mapCenter, calculateDistance]);

  const handleRecenter = useCallback(() => {
    if (userLocation) {
      setMapCenter([userLocation.lat, userLocation.lng]);
      setMapZoom(currentZoomRef.current);
      setSearchCenter(null);
      setShowSearchThisArea(false);
    }
  }, [userLocation]);

  const handleSearchThisArea = useCallback(() => {
    setSearchCenter({ lat: currentMapCenter[0], lng: currentMapCenter[1] });
    setShowSearchThisArea(false);
  }, [currentMapCenter]);

  const handleJoinSwarm = async (swarmId: string) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { showError('You must be signed in to join a swarm'); return; }
      const { error } = await supabase.from('swarm_members').insert({
        swarm_id: swarmId, user_id: user.id, role: 'member', rsvp: 'going',
      });
      if (error) {
        if (error.code === '23505') showInfo('You have already joined this swarm');
        else throw error;
      } else {
        showSuccess('Joined swarm!');
        setSelectedSwarm(null);
      }
    } catch { showError('Could not join swarm. Please try again.'); }
  };

  const handleMessageSwarm = (swarmId: string) => {
    const swarm = dbSwarms.find(s => s.id === swarmId);
    if (swarm) { setChatSwarm(swarm); setChatRecipient(null); setSelectedSwarm(null); setShowChat(true); }
  };

  const handleMessageUser = (userId: string) => {
    const user = realTimeUsers.find(u => u.id === userId);
    if (user) { setChatRecipient(user); setChatSwarm(null); setSelectedUser(null); setShowChat(true); }
  };

  const handleFollowUser = async (userId: string) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { showError('You must be signed in to follow someone'); return; }
      if (user.id === userId) { showInfo('You cannot follow yourself'); return; }
      const { error } = await supabase.from('friendships').insert({
        user_id: user.id, friend_id: userId, status: 'pending',
      });
      if (error) {
        if (error.code === '23505') showInfo('Friend request already sent');
        else throw error;
      } else showSuccess('Friend request sent!');
    } catch { showError('Could not send friend request. Please try again.'); }
  };

  const handleViewProfile = (userId: string) => {
    const user = realTimeUsers.find(u => u.id === userId);
    if (user) { setSelectedSwarm(null); setSelectedUser(user); }
  };

  const handleStatusSave = (status: TonightStatus, venue: string | null) => {
    setMyTonightStatus(status);
    setMyTonightVenue(venue);
  };

  const statusInfo = myTonightStatus === 'going_out'
    ? { color: 'bg-emerald-500', label: 'Going Out', glow: 'shadow-[0_0_12px_rgba(16,185,129,0.5)]' }
    : myTonightStatus === 'maybe'
    ? { color: 'bg-amber-500', label: 'Maybe', glow: 'shadow-[0_0_12px_rgba(245,158,11,0.5)]' }
    : { color: 'bg-gray-500', label: 'Staying In', glow: '' };

  return (
    <div className="h-full flex flex-col relative bg-[#FFF5F0]">
      <div className="absolute top-0 left-0 right-0 z-[1000] p-4 pt-6">
        <div className="flex items-center gap-3">
          {!showSearch ? (
            <>
              <button
                onClick={() => setShowSearch(true)}
                className="flex-1 bg-white/90 backdrop-blur-xl border border-gray-200 shadow-md rounded-2xl px-5 py-3.5 flex items-center gap-3 text-left hover:bg-white transition-all"
              >
                <Search className="w-5 h-5 text-gray-400" />
                <span className="text-gray-400 font-medium">Find bars, swarms...</span>
              </button>
              <button
                onClick={() => setShowFilters(true)}
                className="relative bg-white/90 backdrop-blur-xl border border-gray-200 shadow-md rounded-2xl p-3.5 hover:bg-white transition-all"
              >
                <SlidersHorizontal className="w-5 h-5 text-gray-600" />
                {activeFilterCount > 0 && (
                  <span className="absolute -top-1 -right-1 w-5 h-5 bg-[#E91E63] text-white text-xs rounded-full flex items-center justify-center font-bold">
                    {activeFilterCount}
                  </span>
                )}
              </button>
              <button
                onClick={() => navigate('/settings')}
                className="bg-white/90 backdrop-blur-xl border border-gray-200 shadow-md rounded-2xl p-3.5 hover:bg-white transition-all"
              >
                <Settings className="w-5 h-5 text-gray-600" />
              </button>
            </>
          ) : (
            <div className="flex-1 bg-white/95 backdrop-blur-xl border border-gray-200 shadow-lg rounded-2xl p-4 animate-scale-in">
              <div className="flex items-center gap-3 mb-4">
                <Search className="w-5 h-5 text-gray-400" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Find bars, swarms..."
                  className="flex-1 bg-transparent outline-none text-gray-900 placeholder:text-gray-400"
                  autoFocus
                />
                <button onClick={() => { setShowSearch(false); setSearchQuery(''); }} className="p-1">
                  <X className="w-5 h-5 text-gray-400 hover:text-gray-600 transition-colors" />
                </button>
              </div>
              {searchQuery && (
                <div className="space-y-1 max-h-64 overflow-y-auto">
                  {filteredVenues.filter(v => v.name.toLowerCase().includes(searchQuery.toLowerCase())).slice(0, 5).map(venue => (
                    <button
                      key={venue.id}
                      className="w-full text-left p-3 hover:bg-gray-100 rounded-xl flex items-center gap-3 transition-colors"
                      onClick={() => {
                        setMapCenter([venue.lat, venue.lng]);
                        setMapZoom(15);
                        setShowSearch(false);
                        setSearchQuery('');
                      }}
                    >
                      <div className="w-10 h-10 rounded-xl bg-gray-100 flex items-center justify-center text-lg">
                        {venue.category}
                      </div>
                      <div>
                        <p className="font-medium text-gray-900">{venue.name}</p>
                        <p className="text-sm text-gray-500">{venue.address?.split(',')[0]}</p>
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        {(showSearchThisArea || searchCenter) && (
          <div className="absolute top-24 left-1/2 -translate-x-1/2 z-[999] animate-fade-in">
            {searchCenter ? (
              <button
                onClick={() => { setSearchCenter(null); setShowSearchThisArea(false); }}
                className="bg-white border border-gray-200 text-gray-900 px-5 py-2.5 rounded-full shadow-lg font-medium flex items-center gap-2 transition-all hover:bg-gray-50 active:scale-95"
              >
                <MapPin className="w-4 h-4 text-[#E91E63]" />
                Searching this area
                <span className="w-5 h-5 rounded-full bg-gray-100 flex items-center justify-center ml-1">
                  <X className="w-3 h-3 text-gray-500" />
                </span>
              </button>
            ) : (
              <button
                onClick={handleSearchThisArea}
                className="bg-gray-900 hover:bg-black text-white px-6 py-3 rounded-full shadow-lg font-medium flex items-center gap-2 transition-all hover:scale-105 active:scale-95"
              >
                <MapPin className="w-4 h-4" />
                Search this area
              </button>
            )}
          </div>
        )}
      </div>

      <MapFilters
        isOpen={showFilters}
        onClose={() => setShowFilters(false)}
        distanceFilter={distanceFilter}
        setDistanceFilter={handleDistanceFilterChange}
        groupSizeFilter={groupSizeFilter}
        setGroupSizeFilter={setGroupSizeFilter}
        vibeFilters={vibeFilters}
        setVibeFilters={setVibeFilters}
        drinkFilters={drinkFilters}
        setDrinkFilters={setDrinkFilters}
        distanceOptions={dynamicDistanceOptions}
        groupSizeOptions={GROUP_SIZE_OPTIONS}
        vibeOptions={VIBE_TAGS}
        defaultDistance={defaultDistance}
      />

      <div className="flex-1 relative overflow-hidden">
        <MapCanvas
          activeTab={activeTab}
          mapCenter={mapCenter}
          zoom={mapZoom}
          userLocation={userLocation}
          searchCenter={searchCenter}
          filteredSwarms={filteredSwarms}
          filteredUsers={filteredUsers}
          filteredVenues={filteredVenues}
          venueUserCounts={venueUserCounts}
          onSwarmClick={(s) => setSelectedSwarm(s)}
          onUserClick={(u) => setSelectedUser(u)}
          onVenueClick={(v) => setSelectedVenue(v)}
          onMapMove={handleMapMove}
          onRecenter={handleRecenter}
          onSearchThisArea={handleSearchThisArea}
        />
      </div>

      <MapBottomSheet
        activeTab={activeTab}
        onTabChange={setActiveTab}
        sheetHeight={sheetHeight}
        onSheetHeightChange={setSheetHeight}
        swarmDateFilter={swarmDateFilter}
        onSwarmDateFilterChange={setSwarmDateFilter}
        filteredSwarms={filteredSwarms}
        filteredUsers={filteredUsers}
        filteredVenues={filteredVenues}
        hotspotsWithUsers={hotspotsWithUsers}
        venueUserCounts={venueUserCounts}
        getUsersAtVenue={getUsersAtVenue}
        onSwarmClick={(s) => setSelectedSwarm(s)}
        onUserClick={(u) => setSelectedUser(u)}
        onVenueClick={(v) => setSelectedVenue(v)}
        tonightStatus={statusInfo}
        onTonightStatusClick={() => setShowTonightStatus(true)}
      />


      <TonightStatusModal
        isOpen={showTonightStatus}
        onClose={() => setShowTonightStatus(false)}
        currentStatus={myTonightStatus}
        currentVenue={myTonightVenue}
        onSave={handleStatusSave}
      />

      <SwarmDetailsModal
        isOpen={!!selectedSwarm}
        onClose={() => setSelectedSwarm(null)}
        swarm={selectedSwarm}
        onJoin={handleJoinSwarm}
        onMessage={handleMessageSwarm}
        onViewProfile={handleViewProfile}
      />

      <UserProfileModal
        isOpen={!!selectedUser}
        onClose={() => setSelectedUser(null)}
        user={selectedUser}
        onMessage={handleMessageUser}
        onFollow={handleFollowUser}
      />

      <VenueDetailsModal
        isOpen={!!selectedVenue}
        onClose={() => setSelectedVenue(null)}
        venue={selectedVenue}
        usersAtVenue={selectedVenue ? getUsersAtVenue(selectedVenue.id) : []}
        onViewProfile={(user) => { setSelectedVenue(null); setSelectedUser(user); }}
        onMessageUser={handleMessageUser}
      />

      <ErrorBoundary fallbackLabel="Chat failed to load">
        <ChatView
          isOpen={showChat}
          onClose={() => { setShowChat(false); setChatRecipient(null); setChatSwarm(null); }}
          chatType={chatSwarm ? 'swarm' : 'direct'}
          recipient={chatRecipient ? { id: chatRecipient.id, name: chatRecipient.name, avatar_url: chatRecipient.avatar_url || null, tonightStatus: chatRecipient.tonightStatus } : undefined}
          swarm={chatSwarm || undefined}
          members={chatSwarm ? realTimeUsers.filter(u => u.currentVenueId === chatSwarm.venueId).slice(0, chatSwarm.memberCount).map(u => ({ id: u.id, name: u.name, avatar_url: u.avatar_url })) : []}
        />
      </ErrorBoundary>
    </div>
  );
}
