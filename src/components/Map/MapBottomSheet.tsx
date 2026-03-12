import { useRef, useCallback, useState, useEffect } from 'react';
import { MapPin as MapPinIcon, Users, Sparkles, Flame, User, ChevronUp } from 'lucide-react';
import SwarmDateFilter, { DateFilterOption } from '../Swarms/SwarmDateFilter';
import { useRegionalSettings } from '../../contexts/RegionalSettingsContext';
import type { MapSwarm, MapUserProfile } from '../../hooks/useMapData';
import type { RealTimeVenue } from '../../services/locationService';
import { getCategoryIcon } from './MapCanvas';
import type { TabType } from './MapCanvas';

interface Props {
  activeTab: TabType;
  onTabChange: (tab: TabType) => void;
  sheetHeight: number;
  onSheetHeightChange: (h: number) => void;
  swarmDateFilter: DateFilterOption;
  onSwarmDateFilterChange: (f: DateFilterOption) => void;
  filteredSwarms: MapSwarm[];
  filteredUsers: MapUserProfile[];
  filteredVenues: RealTimeVenue[];
  hotspotsWithUsers: RealTimeVenue[];
  venueUserCounts: Record<string, number>;
  getUsersAtVenue: (venueId: string) => MapUserProfile[];
  onSwarmClick: (s: MapSwarm) => void;
  onUserClick: (u: MapUserProfile) => void;
  onVenueClick: (v: RealTimeVenue) => void;
  tonightStatus?: { color: string; label: string; glow: string };
  onTonightStatusClick?: () => void;
}

const COLLAPSED_HEIGHT = 12;
const HALF_HEIGHT = 45;
const FULL_HEIGHT = 80;
const SNAP_POINTS = [COLLAPSED_HEIGHT, HALF_HEIGHT, FULL_HEIGHT];

export default function MapBottomSheet({
  activeTab, onTabChange,
  sheetHeight, onSheetHeightChange,
  swarmDateFilter, onSwarmDateFilterChange,
  filteredSwarms, filteredUsers, filteredVenues,
  hotspotsWithUsers, venueUserCounts,
  getUsersAtVenue,
  onSwarmClick, onUserClick, onVenueClick,
  tonightStatus, onTonightStatusClick,
}: Props) {
  const { formatDistance: formatDistanceRegional } = useRegionalSettings();
  const sheetRef = useRef<HTMLDivElement>(null);
  const isDraggingRef = useRef(false);
  const dragStartY = useRef(0);
  const dragStartHeight = useRef(0);
  const [isCollapsed, setIsCollapsed] = useState(false);

  useEffect(() => {
    setIsCollapsed(sheetHeight <= COLLAPSED_HEIGHT + 2);
  }, [sheetHeight]);

  const snapToNearest = useCallback((height: number) => {
    const closest = SNAP_POINTS.reduce((prev, curr) =>
      Math.abs(curr - height) < Math.abs(prev - height) ? curr : prev
    );
    onSheetHeightChange(closest);
  }, [onSheetHeightChange]);

  const onDragStart = (clientY: number) => {
    isDraggingRef.current = true;
    dragStartY.current = clientY;
    dragStartHeight.current = sheetHeight;
  };

  const onDragMove = (clientY: number) => {
    if (!isDraggingRef.current) return;
    const deltaY = dragStartY.current - clientY;
    const deltaPercent = (deltaY / window.innerHeight) * 100;
    const newHeight = Math.max(COLLAPSED_HEIGHT, Math.min(85, dragStartHeight.current + deltaPercent));
    onSheetHeightChange(newHeight);
  };

  const onDragEnd = () => {
    if (isDraggingRef.current) {
      snapToNearest(sheetHeight);
      isDraggingRef.current = false;
    }
  };

  const handleTapHandle = () => {
    if (sheetHeight <= COLLAPSED_HEIGHT + 2) {
      onSheetHeightChange(HALF_HEIGHT);
    } else if (sheetHeight >= FULL_HEIGHT - 2) {
      onSheetHeightChange(HALF_HEIGHT);
    } else {
      onSheetHeightChange(COLLAPSED_HEIGHT);
    }
  };

  const tabs = [
    { key: 'swarms' as TabType, label: 'Swarms', icon: Sparkles },
    { key: 'people' as TabType, label: 'People', icon: Users },
    { key: 'places' as TabType, label: 'Places', icon: MapPinIcon },
    { key: 'hotspots' as TabType, label: 'Live', icon: Flame },
  ];

  const activeCount = activeTab === 'swarms' ? filteredSwarms.length
    : activeTab === 'people' ? filteredUsers.filter(u => u.tonightStatus === 'going_out').length
    : activeTab === 'places' ? filteredVenues.length
    : hotspotsWithUsers.length;

  return (
    <div
      ref={sheetRef}
      className="relative z-10"
      onMouseMove={(e) => isDraggingRef.current && onDragMove(e.clientY)}
      onMouseUp={onDragEnd}
      onMouseLeave={onDragEnd}
      onTouchMove={(e) => onDragMove(e.touches[0].clientY)}
      onTouchEnd={onDragEnd}
    >
      <div className="absolute inset-x-0 -top-8 h-8 bg-gradient-to-t from-white to-transparent pointer-events-none" />
      <div
        className="bg-white rounded-t-3xl flex flex-col border-t border-gray-200 shadow-[0_-4px_20px_rgba(0,0,0,0.12)]"
        style={{
          height: `${sheetHeight}vh`,
          transition: isDraggingRef.current ? 'none' : 'height 0.3s ease-out'
        }}
      >
        <div
          className="sticky top-0 bg-white rounded-t-3xl px-5 pt-2 pb-3 cursor-grab active:cursor-grabbing select-none"
          onMouseDown={(e) => { e.preventDefault(); onDragStart(e.clientY); }}
          onTouchStart={(e) => onDragStart(e.touches[0].clientY)}
        >
          <button
            onClick={handleTapHandle}
            className="w-full flex flex-col items-center py-1 mb-2"
            type="button"
          >
            <div className="w-14 h-1.5 bg-gray-300 rounded-full hover:bg-gray-400 transition-colors" />
            <ChevronUp className={`w-4 h-4 text-gray-400 mt-1 transition-transform ${isCollapsed ? '' : 'rotate-180'}`} />
          </button>

          <div className="flex items-center gap-2 overflow-x-auto scrollbar-hide">
            {tonightStatus && onTonightStatusClick && (
              <button
                onClick={onTonightStatusClick}
                className="flex items-center gap-1.5 px-3 py-2.5 rounded-xl text-sm font-semibold bg-gray-100 text-gray-700 hover:bg-gray-200 transition-all whitespace-nowrap shrink-0"
              >
                <div className={`w-2.5 h-2.5 rounded-full ${tonightStatus.color}`} />
                {tonightStatus.label}
              </button>
            )}
            {tabs.map(tab => (
              <button
                key={tab.key}
                onClick={() => { onTabChange(tab.key); if (sheetHeight <= COLLAPSED_HEIGHT + 2) onSheetHeightChange(HALF_HEIGHT); }}
                className={`flex items-center gap-1.5 px-4 py-2.5 rounded-xl text-sm font-semibold transition-all duration-300 whitespace-nowrap ${
                  activeTab === tab.key
                    ? tab.key === 'hotspots'
                      ? 'bg-gradient-to-r from-orange-500 to-red-500 text-white shadow-md'
                      : 'bg-[#E91E63] text-white shadow-md'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                <tab.icon className="w-4 h-4" />
                {tab.label}
                {tab.key === 'hotspots' && hotspotsWithUsers.length > 0 && (
                  <span className={`ml-1 px-1.5 py-0.5 rounded-full text-xs font-bold ${
                    activeTab === 'hotspots' ? 'bg-white/20' : 'bg-orange-500 text-white'
                  }`}>
                    {hotspotsWithUsers.length}
                  </span>
                )}
              </button>
            ))}
          </div>

          {isCollapsed && activeCount > 0 && (
            <p className="text-xs text-gray-500 mt-2 text-center font-medium">
              {activeCount} {activeTab === 'people' ? 'people going out' : activeTab} nearby -- swipe up
            </p>
          )}
        </div>

        <div className="flex-1 overflow-y-auto px-5 pb-24 scrollbar-hide min-h-0">
          {activeTab === 'swarms' && (
            <div className="space-y-3 pt-2">
              <div className="pt-2 pb-2">
                <SwarmDateFilter selectedFilter={swarmDateFilter} onFilterChange={onSwarmDateFilterChange} />
              </div>
              {filteredSwarms.length === 0 ? (
                <div className="text-center py-12">
                  <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mx-auto mb-4">
                    <Sparkles className="w-8 h-8 text-gray-400" />
                  </div>
                  <p className="text-gray-600 font-medium">No swarms nearby</p>
                  <p className="text-gray-400 text-sm mt-1">Be the first to start one!</p>
                </div>
              ) : (
                filteredSwarms.map((swarm) => (
                  <button
                    key={swarm.id}
                    onClick={() => onSwarmClick(swarm)}
                    className="w-full bg-gray-50 border border-gray-100 rounded-2xl p-4 hover:bg-gray-100 transition-all text-left"
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1 min-w-0">
                        <h3 className="font-bold text-gray-900 truncate">{swarm.name}</h3>
                        <p className="text-sm text-[#E91E63] mt-0.5">{swarm.venueName}</p>
                        <p className="text-sm text-gray-500 mt-1 line-clamp-1">{swarm.description}</p>
                      </div>
                      <div className="text-right ml-4 flex-shrink-0">
                        <div className="flex items-center gap-1.5 text-gray-600">
                          <Users className="w-4 h-4" />
                          <span className="text-sm font-semibold">{swarm.memberCount}/{swarm.maxSize}</span>
                        </div>
                        <p className="text-xs text-gray-400 mt-1">{swarm.startTime}</p>
                      </div>
                    </div>
                    <div className="flex flex-wrap gap-1.5 mt-3">
                      {swarm.vibes.slice(0, 3).map(vibe => (
                        <span key={vibe} className="px-3 py-1 bg-[#E91E63]/10 text-[#E91E63] rounded-full text-xs font-semibold">{vibe}</span>
                      ))}
                    </div>
                  </button>
                ))
              )}
            </div>
          )}

          {activeTab === 'people' && (
            <div className="space-y-2 pt-2">
              {filteredUsers.filter(u => u.tonightStatus === 'going_out').length === 0 ? (
                <div className="text-center py-12">
                  <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mx-auto mb-4">
                    <Users className="w-8 h-8 text-gray-400" />
                  </div>
                  <p className="text-gray-600 font-medium">No one going out nearby</p>
                </div>
              ) : (
                filteredUsers.filter(u => u.tonightStatus === 'going_out').map((person) => (
                  <button
                    key={person.id}
                    onClick={() => onUserClick(person)}
                    className="w-full flex items-center gap-3 p-3 rounded-2xl hover:bg-gray-50 transition-all"
                  >
                    <div className="relative">
                      <div className="w-12 h-12 rounded-full overflow-hidden border-2 border-gray-100">
                        {person.avatar_url ? (
                          <img src={person.avatar_url} alt={person.name} className="w-full h-full object-cover" />
                        ) : (
                          <div className="w-full h-full bg-gradient-to-br from-[#E91E63] to-[#C2185B] flex items-center justify-center">
                            <User className="w-5 h-5 text-white" />
                          </div>
                        )}
                      </div>
                      <div className={`absolute -bottom-0.5 -right-0.5 w-4 h-4 ${person.tonightStatus === 'going_out' ? 'bg-emerald-500' : person.tonightStatus === 'maybe' ? 'bg-amber-500' : 'bg-gray-500'} rounded-full border-2 border-white`} />
                    </div>
                    <div className="flex-1 text-left min-w-0">
                      <p className="font-semibold text-gray-900 truncate">{person.name}</p>
                      {person.tonightVenue && (
                        <p className="text-xs text-[#E91E63] mt-0.5 truncate">Going to {person.tonightVenue}</p>
                      )}
                    </div>
                    <div className="text-right">
                      <p className="text-xs text-gray-400">{formatDistanceRegional(((person as any).distance || 0) * 1000)}</p>
                    </div>
                  </button>
                ))
              )}
            </div>
          )}

          {activeTab === 'places' && (
            <div className="space-y-2 pt-2">
              {filteredVenues.length === 0 ? (
                <div className="text-center py-12">
                  <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mx-auto mb-4">
                    <MapPinIcon className="w-8 h-8 text-gray-400" />
                  </div>
                  <p className="text-gray-600 font-medium">No venues nearby</p>
                </div>
              ) : (
                filteredVenues.map((venue) => {
                  const userCount = venueUserCounts[venue.id] || 0;
                  return (
                    <button
                      key={venue.id}
                      onClick={() => onVenueClick(venue)}
                      className="w-full flex items-start gap-3 p-3 rounded-2xl hover:bg-white hover:shadow-md transition-all border border-transparent hover:border-gray-200"
                    >
                      <div className="w-16 h-16 rounded-xl bg-gradient-to-br from-gray-100 to-gray-50 flex items-center justify-center text-2xl shrink-0 border border-gray-200">
                        {getCategoryIcon(venue.category)}
                      </div>
                      <div className="flex-1 text-left min-w-0">
                        <p className="font-bold text-gray-900 truncate text-base">{venue.name}</p>
                        {venue.rating && (
                          <div className="flex items-center gap-2 mt-0.5">
                            <div className="flex items-center gap-1">
                              <span className="text-amber-500 text-sm">★</span>
                              <span className="text-sm font-semibold text-gray-900">{venue.rating.toFixed(1)}</span>
                            </div>
                            {venue.user_ratings_total && (
                              <span className="text-xs text-gray-400">({venue.user_ratings_total})</span>
                            )}
                            {userCount > 0 && (
                              <span className="ml-auto px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-semibold rounded-full flex items-center gap-1">
                                <Flame className="w-3 h-3" />
                                {userCount} here
                              </span>
                            )}
                          </div>
                        )}
                        <p className="text-sm text-gray-500 truncate mt-0.5">{venue.address?.split(',').slice(0, 2).join(',') || 'No address'}</p>
                        <div className="flex items-center gap-2 mt-1">
                          <span className="text-xs text-gray-400 capitalize">{venue.category}</span>
                          {(venue as any).distance !== undefined && (
                            <>
                              <span className="text-gray-300">•</span>
                              <span className="text-xs text-gray-400">{formatDistanceRegional(((venue as any).distance || 0) * 1000)}</span>
                            </>
                          )}
                        </div>
                      </div>
                    </button>
                  );
                })
              )}
            </div>
          )}

          {activeTab === 'hotspots' && (
            <div className="space-y-2 pt-2">
              {hotspotsWithUsers.length === 0 ? (
                <div className="text-center py-12">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-br from-orange-100 to-red-100 flex items-center justify-center mx-auto mb-4">
                    <Flame className="w-8 h-8 text-orange-400" />
                  </div>
                  <p className="text-gray-600 font-medium">No hotspots yet</p>
                  <p className="text-gray-400 text-sm mt-1">Visit a venue to appear here</p>
                </div>
              ) : (
                <>
                  <p className="text-xs text-gray-500 uppercase tracking-wider font-semibold px-1 mb-2">Where people are tonight</p>
                  {hotspotsWithUsers.map((venue) => {
                    const userCount = venueUserCounts[venue.id] || 0;
                    const usersHere = getUsersAtVenue(venue.id).filter(u => u.visibilityMode === 'public');
                    return (
                      <button
                        key={venue.id}
                        onClick={() => onVenueClick(venue)}
                        className="w-full bg-gradient-to-r from-orange-50 to-red-50 border border-orange-100 rounded-2xl p-4 hover:from-orange-100 hover:to-red-100 transition-all text-left"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-orange-500 to-red-500 flex items-center justify-center shadow-lg">
                            <Flame className="w-7 h-7 text-white" />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <h3 className="font-bold text-gray-900 truncate">{venue.name}</h3>
                              <span className="flex-shrink-0 px-2 py-0.5 bg-orange-500 text-white rounded-full text-xs font-bold">
                                {userCount} here
                              </span>
                            </div>
                            <p className="text-sm text-gray-500 truncate">{venue.address?.split(',')[0]}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-1 mt-3 -ml-1">
                          {usersHere.slice(0, 5).map((user, idx) => (
                            <div
                              key={user.id}
                              className="w-8 h-8 rounded-full border-2 border-white shadow-sm overflow-hidden"
                              style={{ marginLeft: idx > 0 ? '-8px' : '0', zIndex: 5 - idx }}
                            >
                              {user.avatar_url ? (
                                <img src={user.avatar_url} alt={user.name} className="w-full h-full object-cover" />
                              ) : (
                                <div className="w-full h-full bg-gradient-to-br from-[#E91E63] to-[#C2185B] flex items-center justify-center">
                                  <User className="w-3 h-3 text-white" />
                                </div>
                              )}
                            </div>
                          ))}
                          {usersHere.length > 5 && (
                            <span className="text-xs text-gray-500 ml-2">+{usersHere.length - 5} more</span>
                          )}
                        </div>
                      </button>
                    );
                  })}
                </>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
