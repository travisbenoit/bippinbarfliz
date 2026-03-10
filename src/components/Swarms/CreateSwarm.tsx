import { useState, useEffect, FormEvent } from 'react';
import { ArrowLeft, MapPin, Clock, Search, ChevronRight, X, UserPlus } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { xpService } from '../../services/xpService';
import { VIBE_TAGS, type VibeTag } from '../../data/dummyData';
import TimePicker from './TimePicker';

interface Venue { id: string; name: string; address: string; category: string; rating: number | null; }
interface Friend { id: string; name: string; username: string | null; avatar_url: string | null; }

export default function CreateSwarm() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [step, setStep] = useState<'venue' | 'details' | 'vibes' | 'invite'>('venue');

  const [allVenues, setAllVenues] = useState<Venue[]>([]);
  const [venuesLoading, setVenuesLoading] = useState(true);
  const [venuesError, setVenuesError] = useState(false);
  const [allFriends, setAllFriends] = useState<Friend[]>([]);
  const [selectedVenue, setSelectedVenue] = useState<Venue | null>(null);
  const [venueSearch, setVenueSearch] = useState('');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [startTime, setStartTime] = useState('');
  const [startDate, setStartDate] = useState<'today' | 'tomorrow'>('today');
  const [joinMode, setJoinMode] = useState<'open' | 'friends' | 'invite_only' | 'request_approval'>('open');
  const [showCustomTime, setShowCustomTime] = useState(false);
  const [vibeTags, setVibeTags] = useState<VibeTag[]>([]);
  const [invitedUsers, setInvitedUsers] = useState<Friend[]>([]);
  const [friendSearch, setFriendSearch] = useState('');

  useEffect(() => {
    setVenuesLoading(true);
    setVenuesError(false);
    const countryCode = localStorage.getItem('userCountryCode') || 'AU';

    const loadVenues = (userLat: number, userLng: number) => {
      const RADIUS_KM = 100;
      const degreeOffset = RADIUS_KM / 111;
      let query = supabase
        .from('venues')
        .select('id, name, address, category, rating, lat, lng')
        .eq('is_active', true)
        .eq('country', countryCode);

      if (userLat && userLng) {
        query = query
          .gte('lat', userLat - degreeOffset)
          .lte('lat', userLat + degreeOffset)
          .gte('lng', userLng - degreeOffset)
          .lte('lng', userLng + degreeOffset);
      }

      query.limit(200).then(({ data, error }) => {
          if (error) {
            setVenuesError(true);
          } else if (data) {
            let sorted = data as (Venue & { lat: number; lng: number })[];
            if (userLat && userLng) {
              const calcDist = (lat: number, lng: number) => {
                const R = 6371;
                const dLat = (lat - userLat) * Math.PI / 180;
                const dLng = (lng - userLng) * Math.PI / 180;
                const a = Math.sin(dLat / 2) ** 2 + Math.cos(userLat * Math.PI / 180) * Math.cos(lat * Math.PI / 180) * Math.sin(dLng / 2) ** 2;
                return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
              };
              sorted = [...sorted].sort((a, b) => calcDist(a.lat, a.lng) - calcDist(b.lat, b.lng));
            } else {
              sorted = [...sorted].sort((a, b) => a.name.localeCompare(b.name));
            }
            setAllVenues(sorted);
          }
          setVenuesLoading(false);
        });
    };

    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => loadVenues(pos.coords.latitude, pos.coords.longitude),
        () => loadVenues(0, 0),
        { timeout: 5000, maximumAge: 60000 }
      );
    } else {
      loadVenues(0, 0);
    }

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
  }, [user?.id]);

  const filteredVenues = allVenues.filter(v =>
    v.name.toLowerCase().includes(venueSearch.toLowerCase()) ||
    v.address.toLowerCase().includes(venueSearch.toLowerCase())
  );

  const filteredFriends = allFriends.filter(u =>
    (u.name.toLowerCase().includes(friendSearch.toLowerCase()) ||
    (u.username || '').toLowerCase().includes(friendSearch.toLowerCase())) &&
    !invitedUsers.some(inv => inv.id === u.id)
  );

  const toggleInvite = (friend: Friend) => {
    if (invitedUsers.some(u => u.id === friend.id)) {
      setInvitedUsers(invitedUsers.filter(u => u.id !== friend.id));
    } else {
      setInvitedUsers([...invitedUsers, friend]);
    }
  };

  const toggleVibeTag = (tag: VibeTag) => {
    if (vibeTags.includes(tag)) {
      setVibeTags(vibeTags.filter(t => t !== tag));
    } else if (vibeTags.length < 5) {
      setVibeTags([...vibeTags, tag]);
    }
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');

    if (!selectedVenue) {
      setError('Please select a venue');
      setStep('venue');
      return;
    }

    if (!title.trim()) {
      setError('Please enter a title');
      setStep('details');
      return;
    }

    if (!startTime) {
      setError('Please select a start time');
      setStep('details');
      return;
    }

    if (vibeTags.length === 0) {
      setError('Please select at least one vibe');
      setStep('vibes');
      return;
    }

    setLoading(true);

    try {
      const now = new Date();
      const baseDate = new Date(now);
      if (startDate === 'tomorrow') baseDate.setDate(baseDate.getDate() + 1);
      const baseDateStr = baseDate.toISOString().split('T')[0];
      const startDateTime = new Date(`${baseDateStr}T${startTime}:00`);
      const endDateTime = new Date(startDateTime.getTime() + 4 * 60 * 60 * 1000);

      const fullDescription = description
        ? `${description}\n\nVenue: ${selectedVenue.name}`
        : `Venue: ${selectedVenue.name}`;

      const { data: swarm, error: insertError } = await supabase
        .from('swarms')
        .insert({
          host_user_id: user!.id,
          venue_id: selectedVenue.id,
          venue_name: selectedVenue.name,
          title,
          description: fullDescription,
          vibe_tags: vibeTags,
          start_time: startDateTime.toISOString(),
          end_time: endDateTime.toISOString(),
          join_mode: joinMode,
          status: 'active',
        })
        .select()
        .single();

      if (insertError) throw insertError;

      await supabase.from('swarm_members').insert({
        swarm_id: swarm.id,
        user_id: user!.id,
        role: 'host',
        rsvp: 'going',
      });

      if (invitedUsers.length > 0) {
        await supabase.from('swarm_members').insert(
          invitedUsers.map(friend => ({
            swarm_id: swarm.id,
            user_id: friend.id,
            role: 'member',
            rsvp: 'invited',
          }))
        );
      }

      // Award XP/coins for creating swarm; auto-assign challenges if needed
      xpService.onSwarmCreated(user!.id, invitedUsers.length + 1).catch(() => null);
      xpService.autoAssignChallenges(user!.id).catch(() => null);

      navigate('/swarms');
    } catch (err: any) {
      setError(err.message);
      setLoading(false);
    }
  };

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'club': return '🎵';
      case 'brewery': return '🍺';
      case 'rooftop': return '🌆';
      case 'lounge': return '🍸';
      case 'sports_bar': return '🏈';
      default: return '🍻';
    }
  };

  const quickTimes = [
    { label: '7:00 PM', value: '19:00' },
    { label: '8:00 PM', value: '20:00' },
    { label: '9:00 PM', value: '21:00' },
    { label: '10:00 PM', value: '22:00' },
    { label: '11:00 PM', value: '23:00' },
  ];

  const formatTimeDisplay = (time: string) => {
    if (!time) return '';
    const [hours, minutes] = time.split(':').map(Number);
    const period = hours >= 12 ? 'PM' : 'AM';
    const displayHours = hours % 12 || 12;
    return `${displayHours}:${minutes.toString().padStart(2, '0')} ${period}`;
  };

  const joinModes = [
    { value: 'open', label: 'Anyone', description: 'Public - anyone can see & join' },
    { value: 'friends', label: 'Friends', description: 'Only friends can see it' },
    { value: 'invite_only', label: 'Invite Only', description: 'Only invited can see it' },
    { value: 'request_approval', label: 'Approval', description: 'Public - admin approves joins' },
  ] as const;

  const stepNumber = step === 'venue' ? 1 : step === 'details' ? 2 : step === 'vibes' ? 3 : 4;
  const steps = ['venue', 'details', 'vibes', 'invite'] as const;

  const isStepComplete = (s: typeof steps[number]) => {
    const currentIndex = steps.indexOf(step);
    const sIndex = steps.indexOf(s);
    return sIndex < currentIndex;
  };

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      <div className="bg-white shadow-sm p-4 flex items-center gap-4 sticky top-0 z-10">
        <button onClick={() => navigate(-1)} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
          <ArrowLeft size={24} className="text-gray-700" />
        </button>
        <div className="flex-1">
          <h1 className="text-xl font-bold text-gray-900">Create Swarm</h1>
          <p className="text-sm text-gray-500">
            Step {stepNumber} of 4
          </p>
        </div>
      </div>

      <div className="flex gap-1 px-4 py-3 bg-white border-b border-gray-100">
        {steps.map((s) => (
          <div
            key={s}
            className={`flex-1 h-1 rounded-full transition-colors ${
              step === s ? 'bg-pink-500' : isStepComplete(s) ? 'bg-pink-300' : 'bg-gray-200'
            }`}
          />
        ))}
      </div>

      {error && (
        <div className="mx-4 mt-4 bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-xl text-sm flex items-center gap-2">
          <X className="w-4 h-4" />
          {error}
        </div>
      )}

      {step === 'venue' && (
        <div className="flex flex-col h-[calc(100vh-120px)]">
          <div className="p-4 pb-0 space-y-4">
            <div className="relative">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                value={venueSearch}
                onChange={(e) => setVenueSearch(e.target.value)}
                placeholder="Search venues..."
                className="w-full pl-12 pr-4 py-3.5 bg-white rounded-xl border-2 border-gray-200 focus:border-pink-500 focus:outline-none"
              />
            </div>

            <p className="text-sm text-gray-500">
              Tap a venue to select it
            </p>
          </div>

          <div className="flex-1 overflow-y-auto p-4 pt-2 space-y-2">
            {filteredVenues.map((venue) => (
              <button
                key={venue.id}
                onClick={() => {
                  setSelectedVenue(venue);
                  setStep('details');
                }}
                className="w-full flex items-center gap-3 p-4 rounded-xl transition-all bg-white border-2 border-transparent hover:border-pink-300 hover:bg-pink-50 active:bg-pink-100"
              >
                <div className="w-12 h-12 rounded-xl bg-gray-100 flex items-center justify-center text-2xl">
                  {getCategoryIcon(venue.category)}
                </div>
                <div className="flex-1 text-left">
                  <p className="font-semibold text-gray-900">{venue.name}</p>
                  <p className="text-sm text-gray-500">{venue.address.split(',')[0]}</p>
                  {venue.rating && (
                    <div className="flex items-center gap-1 mt-1">
                      <span className="text-yellow-500 text-xs">{'★'.repeat(Math.round(venue.rating))}</span>
                      <span className="text-xs text-gray-400">{venue.rating}</span>
                    </div>
                  )}
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400" />
              </button>
            ))}

            {venuesLoading && (
              <div className="text-center py-12">
                <div className="w-10 h-10 border-4 border-pink-500/30 border-t-pink-500 rounded-full animate-spin mx-auto mb-3" />
                <p className="text-gray-500">Loading venues...</p>
              </div>
            )}

            {!venuesLoading && venuesError && (
              <div className="text-center py-8 text-gray-500">
                <MapPin className="w-12 h-12 mx-auto mb-3 text-red-300" />
                <p className="text-red-600 font-medium">Failed to load venues</p>
                <p className="text-sm mt-1">Check your connection and try again</p>
              </div>
            )}

            {!venuesLoading && !venuesError && filteredVenues.length === 0 && (
              <div className="text-center py-8 text-gray-500">
                <MapPin className="w-12 h-12 mx-auto mb-3 text-gray-300" />
                <p>No venues found</p>
                <p className="text-sm mt-1">Try a different search term</p>
              </div>
            )}
          </div>
        </div>
      )}

      {step === 'details' && (
        <div className="p-4 space-y-6">
          {selectedVenue && (
            <div className="flex items-center gap-3 p-3 bg-gray-100 rounded-xl">
              <MapPin className="w-5 h-5 text-pink-500" />
              <span className="font-medium text-gray-900">{selectedVenue.name}</span>
              <button
                onClick={() => setStep('venue')}
                className="ml-auto text-sm text-pink-600"
              >
                Change
              </button>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Swarm Name
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g., Friday Night Drinks"
              className="w-full px-4 py-3.5 rounded-xl border-2 border-gray-200 focus:border-pink-500 focus:outline-none"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Description (optional)
            </label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="What's the plan?"
              rows={3}
              className="w-full px-4 py-3.5 rounded-xl border-2 border-gray-200 focus:border-pink-500 focus:outline-none resize-none"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Date
            </label>
            <div className="flex gap-2">
              {(['today', 'tomorrow'] as const).map((d) => (
                <button
                  key={d}
                  type="button"
                  onClick={() => setStartDate(d)}
                  className={`flex-1 py-2.5 rounded-xl font-medium transition-colors capitalize ${
                    startDate === d ? 'bg-pink-500 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {d}
                </button>
              ))}
            </div>
          </div>

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
                      ? 'bg-pink-500 text-white'
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
                showCustomTime ? 'bg-pink-500 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Custom Time
            </button>
            {showCustomTime && (
              <div className="mt-3">
                <TimePicker
                  value={startTime}
                  onChange={(time) => setStartTime(time)}
                />
              </div>
            )}
            {startTime && (
              <p className="text-sm text-pink-600 mt-2 font-medium">
                Selected: {formatTimeDisplay(startTime)}
              </p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Who can join?
            </label>
            <div className="grid grid-cols-2 gap-2">
              {joinModes.map((mode) => (
                <button
                  key={mode.value}
                  type="button"
                  onClick={() => setJoinMode(mode.value)}
                  className={`py-3 px-4 rounded-xl font-medium transition-colors text-left ${
                    joinMode === mode.value
                      ? 'bg-pink-500 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  <span className="block text-sm font-semibold">{mode.label}</span>
                  <span className={`block text-xs mt-0.5 ${joinMode === mode.value ? 'text-pink-100' : 'text-gray-500'}`}>
                    {mode.description}
                  </span>
                </button>
              ))}
            </div>
            {(joinMode === 'friends' || joinMode === 'invite_only') && (
              <p className="text-xs text-pink-600 mt-2">
                You'll be able to invite friends in the next step
              </p>
            )}
          </div>

          <div className="flex gap-3">
            <button
              onClick={() => setStep('venue')}
              className="flex-1 py-4 bg-gray-100 text-gray-700 rounded-xl font-semibold hover:bg-gray-200 transition-colors"
            >
              Back
            </button>
            <button
              onClick={() => title && startTime && setStep('vibes')}
              disabled={!title || !startTime}
              className="flex-1 py-4 bg-pink-500 text-white rounded-xl font-semibold hover:bg-pink-600 transition-colors shadow-lg disabled:opacity-50"
            >
              Continue
            </button>
          </div>
        </div>
      )}

      {step === 'vibes' && (
        <div className="p-4 space-y-6">
          <div>
            <h3 className="font-semibold text-gray-900 mb-2">What's the vibe?</h3>
            <p className="text-sm text-gray-500 mb-4">Select up to 5 tags to help others find your swarm</p>
            <div className="flex flex-wrap gap-2">
              {VIBE_TAGS.map((vibe) => (
                <button
                  key={vibe}
                  type="button"
                  onClick={() => toggleVibeTag(vibe)}
                  disabled={!vibeTags.includes(vibe) && vibeTags.length >= 5}
                  className={`px-4 py-2.5 rounded-full font-medium transition-all ${
                    vibeTags.includes(vibe)
                      ? 'bg-pink-500 text-white shadow-md'
                      : 'bg-gray-100 text-gray-700 disabled:opacity-50 hover:bg-gray-200'
                  }`}
                >
                  {vibe}
                </button>
              ))}
            </div>
            <p className="text-xs text-gray-500 mt-3">{vibeTags.length}/5 selected</p>
          </div>

          <div className="flex gap-3">
            <button
              type="button"
              onClick={() => setStep('details')}
              className="flex-1 py-4 bg-gray-100 text-gray-700 rounded-xl font-semibold hover:bg-gray-200 transition-colors"
            >
              Back
            </button>
            <button
              onClick={() => vibeTags.length > 0 && setStep('invite')}
              disabled={vibeTags.length === 0}
              className="flex-1 py-4 bg-pink-500 text-white rounded-xl font-semibold hover:bg-pink-600 transition-colors shadow-lg disabled:opacity-50"
            >
              Continue
            </button>
          </div>
        </div>
      )}

      {step === 'invite' && (
        <form onSubmit={handleSubmit} className="p-4 space-y-6">
          <div>
            <h3 className="font-semibold text-gray-900 mb-2">Invite Friends</h3>
            <p className="text-sm text-gray-500 mb-4">
              {joinMode === 'invite_only'
                ? 'Add friends who can join your swarm (at least one required)'
                : joinMode === 'friends'
                ? 'Invite friends to your swarm'
                : 'Add friends to your swarm (optional)'}
            </p>

            {invitedUsers.length > 0 && (
              <div className="mb-4">
                <p className="text-xs text-gray-500 mb-2">{invitedUsers.length} invited</p>
                <div className="flex flex-wrap gap-2">
                  {invitedUsers.map(friend => (
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
              </div>
            )}

            <div className="relative mb-4">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                value={friendSearch}
                onChange={(e) => setFriendSearch(e.target.value)}
                placeholder="Search friends..."
                className="w-full pl-12 pr-4 py-3.5 bg-white rounded-xl border-2 border-gray-200 focus:border-pink-500 focus:outline-none"
              />
            </div>

            <div className="space-y-2 max-h-64 overflow-y-auto">
              {filteredFriends.slice(0, 8).map((friend) => (
                <button
                  key={friend.id}
                  type="button"
                  onClick={() => toggleInvite(friend)}
                  className="w-full flex items-center gap-3 p-3 rounded-xl bg-white border-2 border-transparent hover:border-gray-200 transition-all"
                >
                  <img
                    src={friend.avatar_url || 'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=50'}
                    alt={friend.name}
                    className="w-12 h-12 rounded-full object-cover"
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
            </div>
          </div>

          <div className="bg-gray-100 rounded-xl p-4">
            <h4 className="font-semibold text-gray-900 mb-2">Preview</h4>
            <div className="bg-white rounded-xl p-4 shadow-sm">
              <h3 className="font-bold text-gray-900">{title || 'Swarm Name'}</h3>
              <p className="text-sm text-gray-600 mt-1">{selectedVenue?.name}</p>
              <div className="flex items-center gap-4 mt-2 text-sm text-gray-500">
                <span className="capitalize">{startDate}</span>
                <span>{formatTimeDisplay(startTime) || 'Time'}</span>
                <span className="text-pink-600">{joinModes.find(m => m.value === joinMode)?.label}</span>
              </div>
              {vibeTags.length > 0 && (
                <div className="flex flex-wrap gap-1 mt-3">
                  {vibeTags.map(tag => (
                    <span key={tag} className="px-2 py-1 bg-pink-100 text-pink-700 text-xs rounded-full">
                      {tag}
                    </span>
                  ))}
                </div>
              )}
              {invitedUsers.length > 0 && (
                <div className="flex items-center gap-2 mt-3 pt-3 border-t border-gray-100">
                  <div className="flex -space-x-2">
                    {invitedUsers.slice(0, 4).map(friend => (
                      <img
                        key={friend.id}
                        src={friend.avatar_url || 'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=50'}
                        alt={friend.name}
                        className="w-8 h-8 rounded-full border-2 border-white object-cover"
                      />
                    ))}
                  </div>
                  <span className="text-sm text-gray-500">
                    {invitedUsers.length} friend{invitedUsers.length !== 1 ? 's' : ''} invited
                  </span>
                </div>
              )}
            </div>
          </div>

          <div className="flex gap-3">
            <button
              type="button"
              onClick={() => setStep('vibes')}
              className="flex-1 py-4 bg-gray-100 text-gray-700 rounded-xl font-semibold hover:bg-gray-200 transition-colors"
            >
              Back
            </button>
            <button
              type="submit"
              disabled={loading || (joinMode === 'invite_only' && invitedUsers.length === 0)}
              className="flex-1 py-4 bg-pink-500 text-white rounded-xl font-semibold hover:bg-pink-600 transition-colors shadow-lg disabled:opacity-50"
            >
              {loading ? 'Creating...' : 'Create Swarm'}
            </button>
          </div>
        </form>
      )}
    </div>
  );
}
