import { useState, useEffect, useCallback } from 'react';
import { MapPin, Users, Clock, ChevronDown, ChevronUp, UserPlus, UserCheck, History, Building2 } from 'lucide-react';
import { friendsService, VenueHistory, CrossingPath, FriendshipStatus } from '../../services/friendsService';
import { useToast } from '../../contexts/ToastContext';
import { useAuth } from '../../contexts/AuthContext';
import UserProfileModal from '../Profile/UserProfileModal';
import { supabase } from '../../lib/supabase';
import type { Database } from '../../lib/database.types';

type UserProfile = Database['public']['Tables']['users']['Row'];

function formatRelativeTime(dateStr: string) {
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays === 1) return 'Yesterday';
  return `${diffDays} days ago`;
}

function formatDuration(enteredAt: string, leftAt: string | null) {
  if (!leftAt) return 'Still here';
  const diffMs = new Date(leftAt).getTime() - new Date(enteredAt).getTime();
  const mins = Math.floor(diffMs / 60000);
  if (mins < 60) return `${mins}m`;
  const hours = Math.floor(mins / 60);
  const remainMins = mins % 60;
  return remainMins > 0 ? `${hours}h ${remainMins}m` : `${hours}h`;
}

function isWithin24Hours(enteredAt: string) {
  const diffMs = Date.now() - new Date(enteredAt).getTime();
  return diffMs < 24 * 60 * 60 * 1000;
}

function groupByDay(entries: VenueHistory[]) {
  const groups: Record<string, VenueHistory[]> = {};
  entries.forEach((entry) => {
    const day = new Date(entry.entered_at).toLocaleDateString('en-US', {
      weekday: 'long', month: 'long', day: 'numeric'
    });
    if (!groups[day]) groups[day] = [];
    groups[day].push(entry);
  });
  return groups;
}

interface CrossingPersonProps {
  path: CrossingPath;
  onViewProfile: (profile: UserProfile) => void;
}

function CrossingPerson({ path, onViewProfile }: CrossingPersonProps) {
  const { showSuccess, showError } = useToast();
  const [friendStatus, setFriendStatus] = useState<FriendshipStatus | null>(null);
  const [friendshipId, setFriendshipId] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    friendsService.getFriendshipRow(path.other_user_id).then((row) => {
      setFriendStatus(row ? row.status : null);
      setFriendshipId(row ? row.id : null);
    });
  }, [path.other_user_id]);

  const handleFriendAction = async (e: React.MouseEvent) => {
    e.stopPropagation();
    setLoading(true);
    try {
      if (!friendStatus) {
        await friendsService.sendFriendRequest(path.other_user_id);
        setFriendStatus('pending');
        showSuccess('Friend request sent!');
      } else if (friendStatus === 'pending') {
        if (friendshipId) {
          await friendsService.cancelFriendRequest(friendshipId);
          setFriendStatus(null);
          showSuccess('Request cancelled.');
        }
      }
    } catch (e: any) {
      showError(e?.message || 'Could not send request.');
    } finally {
      setLoading(false);
    }
  };

  const other = path.other_user;
  const displayName = other?.name || 'Unknown User';
  const showWindow = isWithin24Hours(path.other_entered_at);

  if (!showWindow) return null;

  const handleViewProfile = () => {
    if (!other) return;
    // Build a minimal UserProfile shape for the modal
    const profile = {
      id: path.other_user_id,
      name: other.name,
      avatar_url: other.avatar_url,
      tonight_status: other.tonight_status,
      home_city: other.home_city,
      occupation: other.occupation,
      vibe_tags: other.vibe_tags || [],
      dob: (other as any).dob || '2000-01-01',
      bio: (other as any).bio || null,
    } as UserProfile;
    onViewProfile(profile);
  };

  return (
    <div
      className="flex items-center gap-3 py-2 px-3 rounded-xl hover:bg-gray-50 active:bg-gray-100 transition-colors cursor-pointer"
      onClick={handleViewProfile}
    >
      <div className="w-9 h-9 rounded-full overflow-hidden flex-shrink-0 bg-gradient-to-br from-pink-200 to-orange-200 flex items-center justify-center">
        {other?.avatar_url ? (
          <img src={other.avatar_url} alt={displayName} className="w-full h-full object-cover" />
        ) : (
          <span className="font-bold text-[#E91E63] text-sm">{displayName.charAt(0)}</span>
        )}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-semibold text-gray-900 truncate">{displayName}</p>
        {other?.occupation && (
          <p className="text-xs text-gray-500 truncate">{other.occupation}</p>
        )}
      </div>
      {friendStatus === 'accepted' ? (
        <span className="flex items-center gap-1 text-xs text-emerald-600 font-medium flex-shrink-0">
          <UserCheck size={14} />
          Friends
        </span>
      ) : (
        <button
          onClick={handleFriendAction}
          disabled={loading}
          className={`flex items-center gap-1 text-xs font-medium px-2.5 py-1.5 rounded-full transition-colors flex-shrink-0 disabled:opacity-50 ${
            friendStatus === 'pending'
              ? 'bg-amber-100 text-amber-700'
              : 'bg-[#E91E63]/10 text-[#E91E63] hover:bg-[#E91E63]/20'
          }`}
        >
          <UserPlus size={12} />
          {friendStatus === 'pending' ? 'Pending' : 'Add'}
        </button>
      )}
    </div>
  );
}

interface VenueEntryCardProps {
  entry: VenueHistory;
  onViewProfile: (profile: UserProfile) => void;
}

function VenueEntryCard({ entry, onViewProfile }: VenueEntryCardProps) {
  const [expanded, setExpanded] = useState(false);
  const [crossingPaths, setCrossingPaths] = useState<CrossingPath[]>([]);
  const [loadingPaths, setLoadingPaths] = useState(false);

  const withinWindow = isWithin24Hours(entry.entered_at);
  const venueName = entry.venue?.name || 'Unknown Venue';

  const loadCrossingPaths = useCallback(async () => {
    if (crossingPaths.length > 0 || !withinWindow) return;
    setLoadingPaths(true);
    try {
      const paths = await friendsService.getCrossingPathsForVenue(entry.venue_id, entry.entered_at);
      setCrossingPaths(paths);
    } catch {
      // silent
    } finally {
      setLoadingPaths(false);
    }
  }, [entry.venue_id, entry.entered_at, withinWindow]);

  const handleExpand = () => {
    setExpanded(!expanded);
    if (!expanded) loadCrossingPaths();
  };

  const placeType = entry.venue?.place_type;
  const typeLabel = placeType
    ? placeType.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
    : 'Venue';

  return (
    <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
      <div
        className="flex items-center gap-3 p-4 cursor-pointer"
        onClick={handleExpand}
      >
        <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-[#E91E63]/10 to-orange-100 flex items-center justify-center flex-shrink-0">
          <Building2 size={20} className="text-[#E91E63]" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-semibold text-gray-900 truncate">{venueName}</p>
          <div className="flex items-center gap-2 mt-0.5 flex-wrap">
            <span className="text-xs text-gray-500">{typeLabel}</span>
            <span className="text-gray-300 text-xs">•</span>
            <div className="flex items-center gap-1 text-xs text-gray-500">
              <Clock size={11} />
              {formatRelativeTime(entry.entered_at)}
            </div>
            <span className="text-gray-300 text-xs">•</span>
            <span className="text-xs text-gray-500">
              {formatDuration(entry.entered_at, entry.left_at)}
            </span>
          </div>
        </div>
        <div className="flex items-center gap-2 flex-shrink-0">
          {withinWindow && (
            <span className="text-xs text-[#E91E63] font-medium bg-[#E91E63]/10 px-2 py-0.5 rounded-full">
              People
            </span>
          )}
          {expanded ? (
            <ChevronUp size={18} className="text-gray-400" />
          ) : (
            <ChevronDown size={18} className="text-gray-400" />
          )}
        </div>
      </div>

      {expanded && (
        <div className="border-t border-gray-100 px-4 pb-4">
          {!withinWindow ? (
            <p className="text-sm text-gray-400 py-3 text-center">
              The 24-hour window to see who you crossed paths with has passed.
            </p>
          ) : loadingPaths ? (
            <div className="flex items-center justify-center py-4">
              <div className="w-6 h-6 border-2 border-[#E91E63]/30 border-t-[#E91E63] rounded-full animate-spin" />
            </div>
          ) : crossingPaths.length === 0 ? (
            <p className="text-sm text-gray-400 py-3 text-center">
              No one visible crossed paths with you here.
            </p>
          ) : (
            <div className="pt-2 space-y-1">
              <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
                {crossingPaths.length} person{crossingPaths.length !== 1 ? 's' : ''} crossed paths with you
              </p>
              {crossingPaths.map((path) => (
                <CrossingPerson
                  key={path.other_user_id}
                  path={path}
                  onViewProfile={onViewProfile}
                />
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default function HistoryView() {
  const { user } = useAuth();
  const [history, setHistory] = useState<VenueHistory[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedProfile, setSelectedProfile] = useState<UserProfile | null>(null);

  useEffect(() => {
    loadHistory();
  }, []);

  const loadHistory = async () => {
    setLoading(true);
    try {
      const data = await friendsService.getVenueHistory(7);
      setHistory(data);
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  };

  const grouped = groupByDay(history);
  const days = Object.keys(grouped);

  return (
    <div className="h-full flex flex-col bg-[#FFF5F0]">
      <div className="bg-white shadow-sm p-5">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-[#E91E63]/10 flex items-center justify-center">
            <History size={20} className="text-[#E91E63]" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">History</h1>
            <p className="text-sm text-gray-500">Your venues over the last 7 days</p>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto">
        {loading ? (
          <div className="flex items-center justify-center h-full">
            <div className="w-10 h-10 border-4 border-[#E91E63]/30 border-t-[#E91E63] rounded-full animate-spin" />
          </div>
        ) : history.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full p-8 text-center">
            <div className="w-24 h-24 rounded-full bg-[#E91E63]/10 flex items-center justify-center mb-5">
              <MapPin size={40} className="text-[#E91E63]/40" />
            </div>
            <p className="text-xl font-bold text-gray-900 mb-2">No history yet</p>
            <p className="text-gray-500 text-sm max-w-xs">
              When you check in to venues or places, they'll appear here for 7 days. You'll also see who you crossed paths with for 24 hours after each visit.
            </p>
          </div>
        ) : (
          <div className="p-4 space-y-6">
            <div className="bg-gradient-to-r from-[#E91E63]/10 to-orange-50 border border-[#E91E63]/20 rounded-2xl p-4 flex items-start gap-3">
              <Users size={18} className="text-[#E91E63] mt-0.5 flex-shrink-0" />
              <div>
                <p className="text-sm font-semibold text-gray-900">Crossing Paths</p>
                <p className="text-xs text-gray-600 mt-0.5">
                  Tap a venue to see who you crossed paths with. Profiles are visible for 24 hours after your visit.
                </p>
              </div>
            </div>

            {days.map((day) => (
              <div key={day}>
                <div className="flex items-center gap-3 mb-3">
                  <div className="h-px flex-1 bg-gray-200" />
                  <span className="text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap">{day}</span>
                  <div className="h-px flex-1 bg-gray-200" />
                </div>
                <div className="space-y-3">
                  {grouped[day].map((entry, idx) => (
                    <VenueEntryCard
                      key={`${entry.venue_id}-${entry.entered_at}-${idx}`}
                      entry={entry}
                      onViewProfile={setSelectedProfile}
                    />
                  ))}
                </div>
              </div>
            ))}

            <p className="text-center text-xs text-gray-400 pb-4">
              Showing the last 7 days. All visit history is kept privately and securely.
            </p>
          </div>
        )}
      </div>

      <UserProfileModal
        isOpen={!!selectedProfile}
        onClose={() => setSelectedProfile(null)}
        user={selectedProfile}
      />
    </div>
  );
}
