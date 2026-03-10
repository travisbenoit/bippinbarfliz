import { MapPin, Users, Building2, Sparkles, User as UserIcon, Clock, Flame, Trophy } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import type { Database } from '../../lib/database.types';
import WeatherCard from '../Weather/WeatherCard';
import RadiusControl from '../Map/RadiusControl';
import UberPlaceholder from '../Transportation/UberPlaceholder';
import SwarmDateFilter, { DateFilterOption, filterSwarmsByDate } from '../Swarms/SwarmDateFilter';
import { NightSummary } from '../Social/NightSummary';
import { CheckInStreakBadge, TonightFeed, DDModeToggle } from '../Social/TonightFeed';
import { SafeArrivalButton, FriendSafeArrivals } from '../Safety/SafeArrival';
import { SwarmSuggestion } from '../Social/SwarmSuggestion';
import { TrendingVenues } from '../Venues/TrendingVenues';
import { NightRoutePlanner } from '../Social/NightRoutePlanner';
import { xpService, UserStats } from '../../services/xpService';

type UserProfile = Database['public']['Tables']['users']['Row'];
type Venue = Database['public']['Tables']['venues']['Row'];
type Swarm = Database['public']['Tables']['swarms']['Row'];

interface Props {
  userProfile: UserProfile | null;
  nearbyUsers: UserProfile[];
  venues: Venue[];
  swarms: Swarm[];
  searchRadius: number;
  userLocation: { lat: number; lng: number } | null;
  swarmDateFilter: DateFilterOption;
  onSwarmDateFilterChange: (f: DateFilterOption) => void;
  onRadiusChange: (radius: number) => void;
  onFindVenues: () => void;
  onShowStatusModal: () => void;
  onShowActivityHistory: () => void;
  onSelectUser: (userId: string) => void;
  onSelectUserProfile: (user: UserProfile) => void;
}

export default function HomeDashboardTab({
  userProfile,
  nearbyUsers,
  venues,
  swarms,
  searchRadius,
  userLocation,
  swarmDateFilter,
  onSwarmDateFilterChange,
  onRadiusChange,
  onFindVenues,
  onShowStatusModal,
  onShowActivityHistory,
  onSelectUser,
  onSelectUserProfile,
}: Props) {
  const navigate = useNavigate();
  const [showPlanner, setShowPlanner] = useState(false);
  const [xpStats, setXpStats] = useState<UserStats | null>(null);

  useEffect(() => {
    if (!userProfile?.id) return;
    xpService.getUserStats(userProfile.id).then(setXpStats).catch(() => null);
  }, [userProfile?.id]);

  return (
    <div className="p-4 space-y-4 pb-24">
      <NightSummary />

      <SwarmSuggestion />
      <FriendSafeArrivals />

      {userProfile && (
        <div className="bg-gradient-to-br from-[#E91E63] to-[#C2185B] rounded-2xl p-5 text-white shadow-lg">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="w-16 h-16 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center">
                <UserIcon size={32} className="text-white" />
              </div>
              <div>
                <h3 className="font-bold text-xl">{userProfile.name}</h3>
                <div className="mt-1">
                  <CheckInStreakBadge userId={userProfile.id} />
                </div>
                <p className="text-white/80 text-sm">
                  {userProfile.tonight_status === 'out_now' && '🟢 Out now'}
                  {userProfile.tonight_status === 'going_out_soon' && '🟡 Going out soon'}
                  {userProfile.tonight_status === 'staying_in' && '⚪ Staying in'}
                </p>
              </div>
            </div>
            <button
              onClick={onShowStatusModal}
              className="bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full text-sm font-medium hover:bg-white/30 transition-colors"
            >
              Edit Status
            </button>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
              <p className="text-2xl font-bold">{userProfile.vibe_tags.length}</p>
              <p className="text-xs text-white/80 mt-1">Vibe Tags</p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
              <p className="text-2xl font-bold">{userProfile.favorite_drinks.length}</p>
              <p className="text-xs text-white/80 mt-1">Fav Drinks</p>
            </div>
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 text-center">
              <p className="text-2xl font-bold">{userProfile.venmo_linked ? '✓' : '○'}</p>
              <p className="text-xs text-white/80 mt-1">Venmo</p>
            </div>
          </div>
        </div>
      )}

      {xpStats && (
        <button
          onClick={() => navigate('/leaderboard')}
          className="w-full bg-gradient-to-r from-purple-600 to-blue-600 rounded-2xl p-4 text-white shadow-lg text-left hover:opacity-90 transition-opacity"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Trophy size={24} className="text-yellow-300" />
              <div>
                <p className="font-bold text-base">{xpStats.total_xp} XP</p>
                <p className="text-white/80 text-xs">
                  {xpStats.current_streak > 0 ? `🔥 ${xpStats.current_streak}-night streak · ` : ''}
                  {xpStats.total_checkins} check-ins
                </p>
              </div>
            </div>
            <div className="text-white/70 text-sm font-medium">Leaderboard →</div>
          </div>
        </button>
      )}

      <SafeArrivalButton />

      <div className="bg-white rounded-2xl p-5 shadow-sm">
        <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
          <MapPin size={20} className="text-[#E91E63]" />
          Location & Travel
        </h3>
        <div className="space-y-3">
          <WeatherCard
            latitude={userLocation?.lat || userProfile?.last_known_lat as number}
            longitude={userLocation?.lng || userProfile?.last_known_lng as number}
            location={userProfile?.weather_location || userProfile?.home_city || 'Current Location'}
          />
          <RadiusControl
            currentRadius={searchRadius}
            onRadiusChange={(radius) => {
              onRadiusChange(radius);
              onFindVenues();
            }}
          />
          <UberPlaceholder
            currentLocation={userProfile?.home_city || 'Your location'}
            currentLatitude={userLocation?.lat || userProfile?.last_known_lat || 0}
            currentLongitude={userLocation?.lng || userProfile?.last_known_lng || 0}
            venues={(venues || []).map(v => ({
              id: v.id,
              name: v.name,
              latitude: v.latitude,
              longitude: v.longitude,
              address: v.address || ''
            }))}
          />
        </div>
      </div>

      <div className="bg-white rounded-2xl p-5 shadow-sm">
        <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
          <Users size={20} className="text-[#E91E63]" />
          Social Activity
        </h3>
        <div className="grid grid-cols-2 gap-3 mb-4">
          <button
            onClick={() => navigate('/people-nearby')}
            className="bg-gradient-to-br from-[#E91E63]/10 to-[#C2185B]/10 rounded-xl p-4 text-center border border-[#E91E63]/20 hover:shadow-md transition-all"
          >
            <p className="text-3xl font-bold text-[#E91E63]">{(nearbyUsers || []).length}</p>
            <p className="text-xs text-gray-600 mt-1">People Nearby</p>
          </button>
          <button
            onClick={() => navigate('/people-nearby')}
            className="bg-gradient-to-br from-blue-500/10 to-blue-600/10 rounded-xl p-4 text-center border border-blue-500/20 hover:shadow-md transition-all"
          >
            <p className="text-3xl font-bold text-blue-600">
              {(nearbyUsers || []).filter(u => u.tonight_status === 'out_now').length}
            </p>
            <p className="text-xs text-gray-600 mt-1">Out Now</p>
          </button>
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
            <div className="flex items-center gap-2">
              <Building2 size={18} className="text-gray-500" />
              <span className="text-sm font-medium text-gray-700">Venues Found</span>
            </div>
            <span className="text-lg font-bold text-gray-900">{(venues || []).length}</span>
          </div>
          <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
            <div className="flex items-center gap-2">
              <Sparkles size={18} className="text-gray-500" />
              <span className="text-sm font-medium text-gray-700">Active Swarms</span>
            </div>
            <span className="text-lg font-bold text-gray-900">{(swarms || []).length}</span>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-2xl p-5 shadow-sm">
        <h3 className="font-bold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-2 gap-3">
          <button
            onClick={() => navigate('/create-swarm')}
            className="bg-gradient-to-br from-[#E91E63] to-[#C2185B] text-white p-4 rounded-xl font-medium shadow-md hover:shadow-lg transition-all flex flex-col items-center gap-2"
          >
            <Sparkles size={24} />
            <span className="text-sm">Create Swarm</span>
          </button>
          <button
            onClick={() => navigate('/messages')}
            className="bg-gradient-to-br from-cyan-500 to-cyan-600 text-white p-4 rounded-xl font-medium shadow-md hover:shadow-lg transition-all flex flex-col items-center gap-2"
          >
            <Users size={24} />
            <span className="text-sm">Send Message</span>
          </button>
          <button
            onClick={onFindVenues}
            className="bg-gradient-to-br from-blue-500 to-blue-600 text-white p-4 rounded-xl font-medium shadow-md hover:shadow-lg transition-all flex flex-col items-center gap-2"
          >
            <Building2 size={24} />
            <span className="text-sm">Find Venues</span>
          </button>
          <button
            onClick={() => navigate('/map?tab=people')}
            className="bg-gradient-to-br from-emerald-500 to-emerald-600 text-white p-4 rounded-xl font-medium shadow-md hover:shadow-lg transition-all flex flex-col items-center gap-2"
          >
            <Users size={24} />
            <span className="text-sm">Find People</span>
          </button>
          <button
            onClick={onShowActivityHistory}
            className="bg-gradient-to-br from-orange-500 to-orange-600 text-white p-4 rounded-xl font-medium shadow-md hover:shadow-lg transition-all flex flex-col items-center gap-2"
          >
            <Clock size={24} />
            <span className="text-sm">View History</span>
          </button>
        </div>
      </div>

      <div className="bg-white rounded-2xl p-5 shadow-sm">
        <h3 className="font-bold text-gray-900 mb-4">Tonight's Scene</h3>
        <div className="space-y-3">
          {(nearbyUsers || []).filter(u => u.tonight_status === 'out_now').slice(0, 3).map((person) => (
            <button
              key={person.id}
              onClick={() => onSelectUserProfile(person)}
              className="w-full flex items-center gap-3 p-3 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors cursor-pointer text-left"
            >
              <div className="w-12 h-12 bg-gray-200 rounded-full flex items-center justify-center flex-shrink-0">
                <UserIcon size={20} className="text-gray-400" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-gray-900 text-sm truncate">{person.name}</p>
                <p className="text-xs text-gray-500 truncate">
                  {person.vibe_tags[0] || 'Just vibing'}
                </p>
              </div>
              <div className="flex items-center gap-1 text-xs text-gray-500">
                <MapPin size={14} />
                <span>Nearby</span>
              </div>
            </button>
          ))}
          {(nearbyUsers || []).filter(u => u.tonight_status === 'out_now').length === 0 && (
            <p className="text-sm text-gray-500 text-center py-4">No one is out yet. Be the first!</p>
          )}
        </div>
      </div>

      <div className="bg-white rounded-2xl p-5 shadow-sm">
        <h3 className="font-bold text-gray-900 mb-4">Popular Venues Nearby</h3>
        <div className="space-y-3">
          {(venues || []).slice(0, 3).map((venue) => (
            <div
              key={venue.id}
              className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors cursor-pointer"
            >
              <div className="w-12 h-12 bg-gray-200 rounded-xl flex items-center justify-center flex-shrink-0">
                <Building2 size={20} className="text-gray-400" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-gray-900 text-sm truncate">{venue.name}</p>
                <p className="text-xs text-gray-500 truncate capitalize">{venue.category}</p>
              </div>
              {venue.verified && (
                <span className="text-blue-500 flex-shrink-0">✓</span>
              )}
            </div>
          ))}
          {(venues || []).length === 0 && (
            <div className="text-center py-4">
              <p className="text-sm text-gray-500 mb-3">No venues found yet</p>
              <button
                onClick={onFindVenues}
                className="bg-[#E91E63] text-white px-4 py-2 rounded-full text-sm font-medium hover:bg-[#C2185B] transition-colors"
              >
                Find Nearby Bars
              </button>
            </div>
          )}
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm p-5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Users size={20} className="text-[#E91E63]" />
            <h3 className="font-bold text-gray-900">Who's Going Out Tonight</h3>
          </div>
        </div>
        <DDModeToggle />
        <div className="mt-4">
          <TonightFeed onSelectUser={onSelectUser} />
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm p-5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Flame size={20} className="text-orange-500" />
            <h3 className="font-bold text-gray-900">Trending Venues</h3>
          </div>
        </div>
        <TrendingVenues />
      </div>

      <button
        onClick={() => setShowPlanner(true)}
        className="w-full bg-gradient-to-r from-[#E91E63] to-[#C2185B] text-white rounded-2xl p-4 flex items-center gap-3 hover:shadow-lg transition-all"
      >
        <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
          <MapPin className="w-5 h-5 text-white" />
        </div>
        <div className="text-left">
          <p className="font-bold">Plan Tonight's Route</p>
          <p className="text-xs text-white/80">Build a bar crawl and invite friends</p>
        </div>
      </button>

      <NightRoutePlanner isOpen={showPlanner} onClose={() => setShowPlanner(false)} />

      <div className="bg-white rounded-2xl p-5 shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-bold text-gray-900">Active Swarms</h3>
          <SwarmDateFilter selectedFilter={swarmDateFilter} onFilterChange={onSwarmDateFilterChange} />
        </div>
        <div className="space-y-3">
          {filterSwarmsByDate(swarms, swarmDateFilter).slice(0, 3).map((swarm) => (
            <div
              key={swarm.id}
              className="p-4 bg-gradient-to-br from-[#E91E63]/10 to-[#C2185B]/10 rounded-xl border border-[#E91E63]/20 hover:border-[#E91E63]/40 transition-colors cursor-pointer"
            >
              <div className="flex items-start justify-between mb-2">
                <h4 className="font-semibold text-gray-900 flex-1">{swarm.title}</h4>
                <span className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded-full flex-shrink-0">
                  Active
                </span>
              </div>
              {swarm.description && (
                <p className="text-sm text-gray-600 mb-2 line-clamp-1">{swarm.description}</p>
              )}
              <div className="flex items-center gap-2 text-xs text-gray-500">
                <MapPin size={14} />
                <span>
                  {new Date(swarm.start_time).toLocaleTimeString([], {
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                </span>
                <span className="mx-1">•</span>
                <span>Max {swarm.max_attendees}</span>
              </div>
            </div>
          ))}
          {(swarms || []).length === 0 && (
            <p className="text-sm text-gray-500 text-center py-4">No active swarms. Create one!</p>
          )}
        </div>
      </div>
    </div>
  );
}
