import { useState, useEffect } from 'react';
import { ArrowLeft, MapPin, Clock, Search, X, UserPlus, Trash2 } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';
import { VIBE_TAGS, type VibeTag } from '../../data/dummyData';
import TimePicker from './TimePicker';
import type { Database } from '../../lib/database.types';

type Swarm = Database['public']['Tables']['swarms']['Row'];

interface Venue { id: string; name: string; address: string; category: string; rating: number | null; }
interface Friend { id: string; name: string; username: string | null; avatar_url: string | null; }
interface Member { id: string; memberId: string; name: string; username: string | null; avatar_url: string | null; }

interface EditSwarmProps {
  swarm: Swarm;
  onClose: () => void;
  onSaved: () => void;
}

const DURATION_OPTIONS = [
  { label: '1 hr', hours: 1 },
  { label: '2 hrs', hours: 2 },
  { label: '3 hrs', hours: 3 },
  { label: '4 hrs', hours: 4 },
  { label: '5 hrs', hours: 5 },
  { label: '6 hrs', hours: 6 },
];

const joinModes = [
  { value: 'open', label: 'Anyone', description: 'Public - anyone can see & join' },
  { value: 'friends', label: 'Friends', description: 'Only friends can see it' },
  { value: 'invite_only', label: 'Invite Only', description: 'Only invited can see it' },
  { value: 'request_approval', label: 'Approval', description: 'Public - admin approves joins' },
] as const;

const quickTimes = [
  { label: '7:00 PM', value: '19:00' },
  { label: '8:00 PM', value: '20:00' },
  { label: '9:00 PM', value: '21:00' },
  { label: '10:00 PM', value: '22:00' },
  { label: '11:00 PM', value: '23:00' },
];

function parseStartTime(isoString: string | null): { date: 'today' | 'tomorrow' | 'custom'; customDate: string; time: string } {
  if (!isoString) return { date: 'today', customDate: '', time: '20:00' };
  const d = new Date(isoString);
  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(today.getDate() + 1);
  const hhmm = `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
  if (d.toDateString() === today.toDateString()) return { date: 'today', customDate: '', time: hhmm };
  if (d.toDateString() === tomorrow.toDateString()) return { date: 'tomorrow', customDate: '', time: hhmm };
  return { date: 'custom', customDate: d.toISOString().split('T')[0], time: hhmm };
}

function parseDuration(startIso: string | null, endIso: string | null): number {
  if (!startIso || !endIso) return 4;
  const diff = (new Date(endIso).getTime() - new Date(startIso).getTime()) / (1000 * 60 * 60);
  const rounded = Math.round(diff);
  return rounded >= 1 && rounded <= 6 ? rounded : 4;
}

function stripVenueSuffix(description: string | null, venueName: string | null): string {
  if (!description) return '';
  const suffix = `\n\nVenue: ${venueName}`;
  if (venueName && description.endsWith(suffix)) {
    return description.slice(0, -suffix.length);
  }
  if (description === `Venue: ${venueName}`) return '';
  return description;
}

function formatTimeDisplay(time: string) {
  if (!time) return '';
  const [hours, minutes] = time.split(':').map(Number);
  const period = hours >= 12 ? 'PM' : 'AM';
  const displayHours = hours % 12 || 12;
  return `${displayHours}:${minutes.toString().padStart(2, '0')} ${period}`;
}

function getCategoryIcon(category: string) {
  switch (category) {
    case 'club': return '🎵';
    case 'brewery': return '🍺';
    case 'rooftop': return '🌆';
    case 'lounge': return '🍸';
    case 'sports_bar': return '🏈';
    default: return '🍻';
  }
}

export default function EditSwarm({ swarm, onClose, onSaved }: EditSwarmProps) {
  const { user } = useAuth();
  const { showSuccess, showError } = useToast();
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  // Venue
  const [selectedVenue, setSelectedVenue] = useState<Venue | null>(null);
  const [allVenues, setAllVenues] = useState<Venue[]>([]);
  const [venueSearch, setVenueSearch] = useState('');
  const [showVenuePicker, setShowVenuePicker] = useState(false);
  const [venuesLoading, setVenuesLoading] = useState(false);

  // Details
  const [title, setTitle] = useState(swarm.title);
  const [description, setDescription] = useState(stripVenueSuffix(swarm.description, swarm.venue_name));
  const [joinMode, setJoinMode] = useState<'open' | 'friends' | 'invite_only' | 'request_approval'>(
    (swarm.join_mode as any) || 'open'
  );

  // Time
  const parsed = parseStartTime(swarm.start_time);
  const [startDate, setStartDate] = useState<'today' | 'tomorrow' | 'custom'>(parsed.date);
  const [customDate, setCustomDate] = useState(parsed.customDate);
  const [startTime, setStartTime] = useState(parsed.time);
  const [duration, setDuration] = useState(parseDuration(swarm.start_time, swarm.end_time));
  const [showCustomTime, setShowCustomTime] = useState(!quickTimes.some(t => t.value === parsed.time));

  // Vibes
  const [vibeTags, setVibeTags] = useState<VibeTag[]>((swarm.vibe_tags as VibeTag[]) || []);

  // Members
  const [currentMembers, setCurrentMembers] = useState<Member[]>([]);
  const [membersToRemove, setMembersToRemove] = useState<Set<string>>(new Set());
  const [allFriends, setAllFriends] = useState<Friend[]>([]);
  const [newInvites, setNewInvites] = useState<Friend[]>([]);
  const [friendSearch, setFriendSearch] = useState('');

  useEffect(() => {
    // Load current venue info
    if (swarm.venue_id) {
      supabase
        .from('venues')
        .select('id, name, address, category, rating')
        .eq('id', swarm.venue_id)
        .maybeSingle()
        .then(({ data }) => { if (data) setSelectedVenue(data); });
    }

    // Load current members (excluding host)
    supabase
      .from('swarm_members')
      .select('id, user:users!swarm_members_user_id_fkey(id, name, username, avatar_url)')
      .eq('swarm_id', swarm.id)
      .neq('role', 'host')
      .then(({ data }) => {
        if (data) {
          setCurrentMembers(
            data.map((r: any) => ({ memberId: r.id, ...r.user })).filter((m: any) => m.id)
          );
        }
      });

    // Load friends
    if (user) {
      supabase
        .from('friendships')
        .select('friend:users!friendships_friend_id_fkey(id, name, username, avatar_url)')
        .eq('user_id', user.id)
        .eq('status', 'accepted')
        .then(({ data }) => {
          if (data) setAllFriends(data.map((r: any) => r.friend).filter(Boolean));
        });
    }
  }, [swarm.id, swarm.venue_id, user?.id]);

  const loadVenues = () => {
    if (allVenues.length > 0) { setShowVenuePicker(true); return; }
    setVenuesLoading(true);
    const countryCode = localStorage.getItem('userCountryCode') || 'AU';
    const loadWithCoords = (lat: number, lng: number) => {
      const RADIUS_KM = 100;
      const deg = RADIUS_KM / 111;
      let query = supabase
        .from('venues')
        .select('id, name, address, category, rating, lat, lng')
        .eq('is_active', true)
        .eq('country', countryCode);
      if (lat && lng) {
        query = query.gte('lat', lat - deg).lte('lat', lat + deg).gte('lng', lng - deg).lte('lng', lng + deg);
      }
      query.limit(200).then(({ data }) => {
        if (data) {
          const sorted = lat && lng
            ? [...data].sort((a: any, b: any) => {
                const dist = (v: any) => Math.hypot(v.lat - lat, v.lng - lng);
                return dist(a) - dist(b);
              })
            : [...data].sort((a: any, b: any) => a.name.localeCompare(b.name));
          setAllVenues(sorted);
        }
        setVenuesLoading(false);
        setShowVenuePicker(true);
      });
    };
    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        (p) => loadWithCoords(p.coords.latitude, p.coords.longitude),
        () => loadWithCoords(0, 0),
        { timeout: 5000, maximumAge: 60000 }
      );
    } else {
      loadWithCoords(0, 0);
    }
  };

  const toggleVibeTag = (tag: VibeTag) => {
    if (vibeTags.includes(tag)) {
      setVibeTags(vibeTags.filter(t => t !== tag));
    } else if (vibeTags.length < 5) {
      setVibeTags([...vibeTags, tag]);
    }
  };

  const toggleRemoveMember = (memberId: string) => {
    setMembersToRemove(prev => {
      const next = new Set(prev);
      next.has(memberId) ? next.delete(memberId) : next.add(memberId);
      return next;
    });
  };

  const toggleInvite = (friend: Friend) => {
    if (newInvites.some(u => u.id === friend.id)) {
      setNewInvites(newInvites.filter(u => u.id !== friend.id));
    } else {
      setNewInvites([...newInvites, friend]);
    }
  };

  const handleSave = async () => {
    setError('');
    if (!title.trim()) { setError('Please enter a title'); return; }
    if (!startTime) { setError('Please select a start time'); return; }
    if (vibeTags.length === 0) { setError('Please select at least one vibe'); return; }

    setSaving(true);
    try {
      // Build start/end datetime
      const now = new Date();
      let baseDate = new Date(now);
      if (startDate === 'tomorrow') baseDate.setDate(baseDate.getDate() + 1);
      else if (startDate === 'custom' && customDate) baseDate = new Date(customDate);
      const baseDateStr = baseDate.toISOString().split('T')[0];
      const startDateTime = new Date(`${baseDateStr}T${startTime}:00`);
      const endDateTime = new Date(startDateTime.getTime() + duration * 60 * 60 * 1000);

      const fullDescription = description.trim()
        ? `${description.trim()}\n\nVenue: ${selectedVenue?.name || swarm.venue_name}`
        : `Venue: ${selectedVenue?.name || swarm.venue_name}`;

      const { error: updateError } = await supabase
        .from('swarms')
        .update({
          title: title.trim(),
          description: fullDescription,
          venue_id: selectedVenue?.id || swarm.venue_id,
          venue_name: selectedVenue?.name || swarm.venue_name,
          vibe_tags: vibeTags,
          start_time: startDateTime.toISOString(),
          end_time: endDateTime.toISOString(),
          join_mode: joinMode,
        })
        .eq('id', swarm.id);

      if (updateError) throw updateError;

      // Remove members marked for removal
      if (membersToRemove.size > 0) {
        const idsToRemove = currentMembers
          .filter(m => membersToRemove.has(m.id))
          .map(m => m.memberId);
        if (idsToRemove.length > 0) {
          await supabase.from('swarm_members').delete().in('id', idsToRemove);
        }
      }

      // Add new invites (skip duplicates via upsert-style — ignore conflict)
      if (newInvites.length > 0) {
        const existingIds = new Set(currentMembers.map(m => m.id));
        const toInsert = newInvites
          .filter(f => !existingIds.has(f.id))
          .map(f => ({ swarm_id: swarm.id, user_id: f.id, role: 'member', rsvp: 'invited' }));
        if (toInsert.length > 0) {
          await supabase.from('swarm_members').insert(toInsert);
        }
      }

      showSuccess('Swarm updated!');
      onSaved();
    } catch (err: any) {
      setError(err.message);
      setSaving(false);
    }
  };

  // Friends not already in the swarm and not already invited
  const existingMemberIds = new Set(currentMembers.map(m => m.id));
  const filteredFriends = allFriends.filter(f =>
    !existingMemberIds.has(f.id) &&
    !newInvites.some(inv => inv.id === f.id) &&
    (f.name.toLowerCase().includes(friendSearch.toLowerCase()) ||
     (f.username || '').toLowerCase().includes(friendSearch.toLowerCase()))
  );

  const filteredVenues = allVenues.filter(v =>
    v.name.toLowerCase().includes(venueSearch.toLowerCase()) ||
    v.address.toLowerCase().includes(venueSearch.toLowerCase())
  );

  return (
    <div className="fixed inset-0 z-50 bg-gray-50 overflow-y-auto">
      {/* Header */}
      <div className="bg-white shadow-sm p-4 flex items-center gap-4 sticky top-0 z-10">
        <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
          <ArrowLeft size={24} className="text-gray-700" />
        </button>
        <div className="flex-1">
          <h1 className="text-xl font-bold text-gray-900">Edit Swarm</h1>
          <p className="text-sm text-gray-500">Changes save immediately</p>
        </div>
        <button
          onClick={handleSave}
          disabled={saving}
          className="px-5 py-2.5 bg-[#E91E63] text-white rounded-xl font-semibold hover:bg-[#C2185B] transition-colors disabled:opacity-50"
        >
          {saving ? 'Saving...' : 'Save'}
        </button>
      </div>

      <div className="p-4 space-y-6 pb-20">
        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-xl text-sm flex items-center gap-2">
            <X className="w-4 h-4 flex-shrink-0" />
            {error}
          </div>
        )}

        {/* Venue */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Venue</label>
          <button
            type="button"
            onClick={loadVenues}
            className="w-full flex items-center gap-3 p-4 bg-white rounded-xl border-2 border-gray-200 hover:border-pink-400 transition-colors text-left"
          >
            <MapPin className="w-5 h-5 text-[#E91E63] flex-shrink-0" />
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-gray-900 truncate">
                {selectedVenue?.name || swarm.venue_name || 'Select venue'}
              </p>
              {selectedVenue?.address && (
                <p className="text-sm text-gray-500 truncate">{selectedVenue.address.split(',')[0]}</p>
              )}
            </div>
            <span className="text-sm text-[#E91E63] font-medium flex-shrink-0">Change</span>
          </button>
        </div>

        {/* Title */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Swarm Name</label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g., Friday Night Drinks"
            className="w-full px-4 py-3.5 rounded-xl border-2 border-gray-200 focus:border-pink-500 focus:outline-none"
          />
        </div>

        {/* Description */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Description (optional)</label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="What's the plan?"
            rows={3}
            className="w-full px-4 py-3.5 rounded-xl border-2 border-gray-200 focus:border-pink-500 focus:outline-none resize-none"
          />
        </div>

        {/* Date */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Date</label>
          <div className="flex gap-2 flex-wrap">
            {(['today', 'tomorrow'] as const).map(d => (
              <button
                key={d}
                type="button"
                onClick={() => setStartDate(d)}
                className={`flex-1 py-2.5 rounded-xl font-medium transition-colors capitalize ${
                  startDate === d ? 'bg-[#E91E63] text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {d}
              </button>
            ))}
            <button
              type="button"
              onClick={() => setStartDate('custom')}
              className={`flex-1 py-2.5 rounded-xl font-medium transition-colors ${
                startDate === 'custom' ? 'bg-[#E91E63] text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Pick Date
            </button>
          </div>
          {startDate === 'custom' && (
            <input
              type="date"
              value={customDate}
              onChange={(e) => setCustomDate(e.target.value)}
              min={new Date().toISOString().split('T')[0]}
              className="mt-2 w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-pink-500 focus:outline-none"
            />
          )}
        </div>

        {/* Start Time */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            <Clock className="w-4 h-4 inline mr-1" />
            Start Time
          </label>
          <div className="flex flex-wrap gap-2 mb-3">
            {quickTimes.map((time) => (
              <button
                key={time.value}
                type="button"
                onClick={() => { setStartTime(time.value); setShowCustomTime(false); }}
                className={`px-4 py-2.5 rounded-xl font-medium transition-colors ${
                  startTime === time.value && !showCustomTime
                    ? 'bg-[#E91E63] text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {time.label}
              </button>
            ))}
          </div>
          <button
            type="button"
            onClick={() => setShowCustomTime(!showCustomTime)}
            className={`px-4 py-2.5 rounded-xl font-medium transition-colors ${
              showCustomTime ? 'bg-[#E91E63] text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            Custom Time
          </button>
          {showCustomTime && (
            <div className="mt-3">
              <TimePicker value={startTime} onChange={setStartTime} />
            </div>
          )}
          {startTime && (
            <p className="text-sm text-pink-600 mt-2 font-medium">
              Selected: {formatTimeDisplay(startTime)}
            </p>
          )}
        </div>

        {/* Duration */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Duration</label>
          <div className="flex gap-2 flex-wrap">
            {DURATION_OPTIONS.map(opt => (
              <button
                key={opt.hours}
                type="button"
                onClick={() => setDuration(opt.hours)}
                className={`px-4 py-2.5 rounded-xl font-medium transition-colors ${
                  duration === opt.hours ? 'bg-[#E91E63] text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
          {startTime && (
            <p className="text-xs text-gray-500 mt-2">
              Ends at {formatTimeDisplay(
                (() => {
                  const [h, m] = startTime.split(':').map(Number);
                  const endH = (h + duration) % 24;
                  return `${endH.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
                })()
              )}
            </p>
          )}
        </div>

        {/* Who can join */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Who can join?</label>
          <div className="grid grid-cols-2 gap-2">
            {joinModes.map((mode) => (
              <button
                key={mode.value}
                type="button"
                onClick={() => setJoinMode(mode.value)}
                className={`py-3 px-4 rounded-xl font-medium transition-colors text-left ${
                  joinMode === mode.value ? 'bg-[#E91E63] text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                <span className="block text-sm font-semibold">{mode.label}</span>
                <span className={`block text-xs mt-0.5 ${joinMode === mode.value ? 'text-pink-100' : 'text-gray-500'}`}>
                  {mode.description}
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Vibe Tags */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Vibes <span className="text-gray-400 font-normal">({vibeTags.length}/5)</span>
          </label>
          <div className="flex flex-wrap gap-2">
            {VIBE_TAGS.map((vibe) => (
              <button
                key={vibe}
                type="button"
                onClick={() => toggleVibeTag(vibe)}
                disabled={!vibeTags.includes(vibe) && vibeTags.length >= 5}
                className={`px-4 py-2.5 rounded-full font-medium transition-all ${
                  vibeTags.includes(vibe)
                    ? 'bg-[#E91E63] text-white shadow-md'
                    : 'bg-gray-100 text-gray-700 disabled:opacity-50 hover:bg-gray-200'
                }`}
              >
                {vibe}
              </button>
            ))}
          </div>
        </div>

        {/* Current Members */}
        {currentMembers.length > 0 && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Current Members
              <span className="text-gray-400 font-normal ml-1">(tap to remove)</span>
            </label>
            <div className="space-y-2">
              {currentMembers.map(member => (
                <div
                  key={member.id}
                  className={`flex items-center gap-3 p-3 rounded-xl border-2 transition-colors ${
                    membersToRemove.has(member.id)
                      ? 'bg-red-50 border-red-300'
                      : 'bg-white border-gray-200'
                  }`}
                >
                  <div className="w-10 h-10 rounded-full overflow-hidden flex-shrink-0 bg-gray-200">
                    {member.avatar_url ? (
                      <img src={member.avatar_url} alt={member.name} className="w-full h-full object-cover" />
                    ) : (
                      <div className="w-full h-full bg-gradient-to-br from-pink-400 to-pink-600 flex items-center justify-center text-white font-bold text-sm">
                        {member.name[0]}
                      </div>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-gray-900 truncate">{member.name}</p>
                    {member.username && <p className="text-xs text-gray-500">{member.username}</p>}
                  </div>
                  <button
                    type="button"
                    onClick={() => toggleRemoveMember(member.id)}
                    className={`p-2 rounded-full transition-colors flex-shrink-0 ${
                      membersToRemove.has(member.id)
                        ? 'bg-red-500 text-white'
                        : 'bg-gray-100 text-gray-500 hover:bg-red-100 hover:text-red-500'
                    }`}
                    title={membersToRemove.has(member.id) ? 'Undo remove' : 'Remove member'}
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              ))}
            </div>
            {membersToRemove.size > 0 && (
              <p className="text-xs text-red-500 mt-1">{membersToRemove.size} member{membersToRemove.size !== 1 ? 's' : ''} will be removed on save</p>
            )}
          </div>
        )}

        {/* Invite new friends */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Invite More Friends</label>

          {newInvites.length > 0 && (
            <div className="flex flex-wrap gap-2 mb-3">
              {newInvites.map(friend => (
                <div
                  key={friend.id}
                  className="flex items-center gap-2 bg-pink-100 text-pink-700 pl-2 pr-1 py-1 rounded-full"
                >
                  <img
                    src={friend.avatar_url || 'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=50'}
                    alt={friend.name}
                    className="w-6 h-6 rounded-full object-cover"
                  />
                  <span className="text-sm font-medium">{friend.name.split(' ')[0]}</span>
                  <button
                    type="button"
                    onClick={() => toggleInvite(friend)}
                    className="p-1 hover:bg-pink-200 rounded-full"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>
              ))}
            </div>
          )}

          <div className="relative mb-3">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={friendSearch}
              onChange={(e) => setFriendSearch(e.target.value)}
              placeholder="Search friends..."
              className="w-full pl-12 pr-4 py-3.5 bg-white rounded-xl border-2 border-gray-200 focus:border-pink-500 focus:outline-none"
            />
          </div>

          <div className="space-y-2 max-h-48 overflow-y-auto">
            {filteredFriends.slice(0, 10).map(friend => (
              <button
                key={friend.id}
                type="button"
                onClick={() => toggleInvite(friend)}
                className="w-full flex items-center gap-3 p-3 rounded-xl bg-white border-2 border-transparent hover:border-gray-200 transition-all"
              >
                <img
                  src={friend.avatar_url || 'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=50'}
                  alt={friend.name}
                  className="w-10 h-10 rounded-full object-cover"
                />
                <div className="flex-1 text-left">
                  <p className="font-semibold text-gray-900">{friend.name}</p>
                  <p className="text-sm text-gray-500">{friend.username}</p>
                </div>
                <div className="w-8 h-8 rounded-full border-2 border-gray-200 flex items-center justify-center">
                  <UserPlus className="w-4 h-4 text-gray-400" />
                </div>
              </button>
            ))}
            {filteredFriends.length === 0 && (
              <p className="text-sm text-gray-400 text-center py-4">No friends to add</p>
            )}
          </div>
        </div>

        {/* Save button at bottom */}
        <button
          onClick={handleSave}
          disabled={saving}
          className="w-full py-4 bg-[#E91E63] text-white rounded-xl font-semibold hover:bg-[#C2185B] transition-colors shadow-lg disabled:opacity-50"
        >
          {saving ? 'Saving Changes...' : 'Save Changes'}
        </button>
      </div>

      {/* Venue Picker Overlay */}
      {showVenuePicker && (
        <div className="fixed inset-0 z-[60] bg-gray-50 flex flex-col">
          <div className="bg-white shadow-sm p-4 flex items-center gap-4 sticky top-0">
            <button onClick={() => setShowVenuePicker(false)} className="p-2 hover:bg-gray-100 rounded-full">
              <ArrowLeft size={24} className="text-gray-700" />
            </button>
            <h2 className="text-lg font-bold text-gray-900">Change Venue</h2>
          </div>
          <div className="p-4 pb-2">
            <div className="relative">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                value={venueSearch}
                onChange={(e) => setVenueSearch(e.target.value)}
                placeholder="Search venues..."
                className="w-full pl-12 pr-4 py-3.5 bg-white rounded-xl border-2 border-gray-200 focus:border-pink-500 focus:outline-none"
                autoFocus
              />
            </div>
          </div>
          <div className="flex-1 overflow-y-auto p-4 pt-2 space-y-2">
            {venuesLoading ? (
              <div className="text-center py-12">
                <div className="w-10 h-10 border-4 border-pink-500/30 border-t-pink-500 rounded-full animate-spin mx-auto mb-3" />
                <p className="text-gray-500">Loading venues...</p>
              </div>
            ) : filteredVenues.map(venue => (
              <button
                key={venue.id}
                onClick={() => {
                  setSelectedVenue(venue);
                  setShowVenuePicker(false);
                  setVenueSearch('');
                }}
                className={`w-full flex items-center gap-3 p-4 rounded-xl transition-all border-2 ${
                  selectedVenue?.id === venue.id
                    ? 'bg-pink-50 border-pink-400'
                    : 'bg-white border-transparent hover:border-pink-300 hover:bg-pink-50'
                }`}
              >
                <div className="w-12 h-12 rounded-xl bg-gray-100 flex items-center justify-center text-2xl">
                  {getCategoryIcon(venue.category)}
                </div>
                <div className="flex-1 text-left">
                  <p className="font-semibold text-gray-900">{venue.name}</p>
                  <p className="text-sm text-gray-500">{venue.address.split(',')[0]}</p>
                  {venue.rating && (
                    <span className="text-yellow-500 text-xs">{'★'.repeat(Math.round(venue.rating))} {venue.rating}</span>
                  )}
                </div>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
