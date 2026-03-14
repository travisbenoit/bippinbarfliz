import { useState, useEffect } from 'react';
import { MapPin, Plus, Trash2, Send, Navigation, Users, X, Loader2 } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

interface RouteStop {
  venue_id: string;
  venue_name: string;
  order: number;
}

interface NightRoute {
  id: string;
  name: string;
  stops: RouteStop[];
  planned_date: string | null;
  status: string;
  creator_id: string;
  creator_name?: string;
}

interface Venue {
  id: string;
  name: string;
  category: string;
  address: string | null;
}

interface Props {
  isOpen: boolean;
  onClose: () => void;
}

export function NightRoutePlanner({ isOpen, onClose }: Props) {
  const { user } = useAuth();
  const [routes, setRoutes] = useState<NightRoute[]>([]);
  const [routeName, setRouteName] = useState('');
  const [stops, setStops] = useState<RouteStop[]>([]);
  const [venueResults, setVenueResults] = useState<Venue[]>([]);
  const [venueSearch, setVenueSearch] = useState('');
  const [friends, setFriends] = useState<Array<{ id: string; name: string }>>([]);
  const [selectedFriends, setSelectedFriends] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [step, setStep] = useState<'list' | 'create'>('list');

  useEffect(() => {
    if (!isOpen || !user) return;
    setLoading(true);
    setError(null);
    Promise.all([loadRoutes(), loadFriends()])
      .catch(() => setError('Failed to load data'))
      .finally(() => setLoading(false));
  }, [isOpen, user]);

  // Server-side venue search with debounce
  useEffect(() => {
    if (!venueSearch.trim()) {
      setVenueResults([]);
      return;
    }
    const timer = setTimeout(async () => {
      const { data } = await supabase
        .from('venues')
        .select('id, name, category, address')
        .ilike('name', `%${venueSearch.trim()}%`)
        .limit(8);
      if (data) setVenueResults(data);
    }, 300);
    return () => clearTimeout(timer);
  }, [venueSearch]);

  const loadRoutes = async () => {
    // Simple query without FK join to avoid PostgREST resolution issues
    const { data, error: err } = await supabase
      .from('night_routes')
      .select('id, name, stops, planned_date, status, creator_id')
      .order('created_at', { ascending: false })
      .limit(10);
    if (err) throw err;
    if (data) {
      setRoutes(data.map((r: any) => ({
        ...r,
        stops: r.stops || [],
      })));
    }
  };

  const loadFriends = async () => {
    if (!user) return;
    const { data: friendships } = await supabase
      .from('friendships')
      .select('user_id, friend_id')
      .eq('status', 'accepted')
      .or(`user_id.eq.${user.id},friend_id.eq.${user.id}`);
    const friendIds = (friendships || []).map(f => f.user_id === user.id ? f.friend_id : f.user_id);
    if (friendIds.length > 0) {
      const { data } = await supabase.from('users').select('id, name').in('id', friendIds);
      if (data) setFriends(data);
    }
  };

  const addStop = (venue: Venue) => {
    if (stops.find(s => s.venue_id === venue.id)) return;
    setStops(prev => [...prev, { venue_id: venue.id, venue_name: venue.name, order: prev.length + 1 }]);
    setVenueSearch('');
    setVenueResults([]);
  };

  const removeStop = (venueId: string) => {
    setStops(prev => prev.filter(s => s.venue_id !== venueId).map((s, i) => ({ ...s, order: i + 1 })));
  };

  const saveRoute = async () => {
    if (!user || stops.length < 2) return;
    setSaving(true);
    setError(null);
    try {
      const { data: route, error: insertErr } = await supabase
        .from('night_routes')
        .insert({
          creator_id: user.id,
          name: routeName || 'My Night Out',
          stops,
          status: 'active',
        })
        .select()
        .maybeSingle();

      if (insertErr) throw insertErr;

      if (route && selectedFriends.length > 0) {
        await supabase.from('night_route_invites').insert(
          selectedFriends.map(friendId => ({ route_id: route.id, user_id: friendId }))
        );
        for (const friendId of selectedFriends) {
          await supabase.from('notifications').insert({
            recipient_user_id: friendId,
            actor_user_id: user.id,
            notification_type: 'route_invite',
            title: `${routeName || 'A friend'} invited you on a bar crawl`,
            body: `${stops.length} stops planned`,
          });
        }
      }

      await loadRoutes();
      setStep('list');
      setStops([]);
      setRouteName('');
      setSelectedFriends([]);
    } catch (err: any) {
      setError(err?.message || 'Failed to save route');
    } finally {
      setSaving(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[2000] flex flex-col" onClick={onClose}>
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" />
      <div
        className="relative mt-auto bg-white rounded-t-3xl shadow-2xl max-h-[90vh] flex flex-col"
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <div className="flex items-center gap-2">
            <Navigation className="w-5 h-5 text-[#E91E63]" />
            <h2 className="font-bold text-gray-900 text-lg">Night Planner</h2>
          </div>
          <div className="flex items-center gap-2">
            {step === 'list' && (
              <button
                onClick={() => setStep('create')}
                className="flex items-center gap-1.5 bg-[#E91E63] text-white px-3 py-1.5 rounded-full text-sm font-semibold"
              >
                <Plus className="w-4 h-4" /> New Route
              </button>
            )}
            <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100">
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto overscroll-contain px-5 py-4 space-y-4">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
              {error}
            </div>
          )}

          {step === 'list' && (
            <>
              {loading ? (
                <div className="flex items-center justify-center py-12">
                  <Loader2 className="w-6 h-6 text-[#E91E63] animate-spin" />
                </div>
              ) : routes.length === 0 ? (
                <div className="text-center py-12">
                  <Navigation className="w-10 h-10 text-gray-200 mx-auto mb-3" />
                  <p className="text-gray-400 font-medium">No routes yet</p>
                  <p className="text-gray-300 text-sm mt-1">Plan your perfect bar crawl</p>
                </div>
              ) : (
                routes.map(route => (
                  <div key={route.id} className="border border-gray-100 rounded-2xl p-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="font-semibold text-gray-900">{route.name}</p>
                        <p className="text-xs text-gray-500 mt-0.5">{route.stops.length} stops</p>
                      </div>
                      <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                        route.status === 'active' ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-500'
                      }`}>{route.status}</span>
                    </div>
                    <div className="mt-3 space-y-1">
                      {route.stops.slice(0, 4).map((stop, i) => (
                        <div key={i} className="flex items-center gap-2 text-xs text-gray-600">
                          <div className="w-5 h-5 bg-[#E91E63]/10 rounded-full flex items-center justify-center flex-shrink-0">
                            <span className="text-[10px] font-bold text-[#E91E63]">{i + 1}</span>
                          </div>
                          {stop.venue_name}
                        </div>
                      ))}
                      {route.stops.length > 4 && (
                        <p className="text-xs text-gray-400 pl-7">+{route.stops.length - 4} more</p>
                      )}
                    </div>
                  </div>
                ))
              )}
            </>
          )}

          {step === 'create' && (
            <>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">Route name</label>
                <input
                  type="text"
                  value={routeName}
                  onChange={e => setRouteName(e.target.value)}
                  placeholder="Friday night run"
                  className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-[#E91E63]"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">Add stops</label>
                <input
                  type="text"
                  value={venueSearch}
                  onChange={e => setVenueSearch(e.target.value)}
                  placeholder="Search venues..."
                  className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-[#E91E63]"
                />
                {venueResults.length > 0 && (
                  <div className="mt-2 border border-gray-100 rounded-xl overflow-hidden shadow-sm">
                    {venueResults.map(v => (
                      <button
                        key={v.id}
                        onClick={() => addStop(v)}
                        className="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-50 text-left border-b border-gray-50 last:border-0"
                      >
                        <MapPin className="w-4 h-4 text-gray-400 flex-shrink-0" />
                        <div>
                          <p className="text-sm font-medium text-gray-900">{v.name}</p>
                          {v.address && <p className="text-xs text-gray-400 truncate">{v.address}</p>}
                        </div>
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {stops.length > 0 && (
                <div>
                  <p className="text-sm font-semibold text-gray-700 mb-2">Your route ({stops.length} stops)</p>
                  <div className="space-y-2">
                    {stops.map((stop, i) => (
                      <div key={stop.venue_id} className="flex items-center gap-3 bg-gray-50 rounded-xl p-3">
                        <div className="w-7 h-7 bg-[#E91E63] rounded-full flex items-center justify-center text-white text-xs font-bold flex-shrink-0">
                          {i + 1}
                        </div>
                        <p className="flex-1 text-sm font-medium text-gray-800">{stop.venue_name}</p>
                        <button onClick={() => removeStop(stop.venue_id)}>
                          <Trash2 className="w-4 h-4 text-gray-400 hover:text-red-500 transition-colors" />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {friends.length > 0 && (
                <div>
                  <p className="text-sm font-semibold text-gray-700 mb-2">Invite friends</p>
                  <div className="flex flex-wrap gap-2">
                    {friends.map(f => (
                      <button
                        key={f.id}
                        onClick={() => setSelectedFriends(prev =>
                          prev.includes(f.id) ? prev.filter(id => id !== f.id) : [...prev, f.id]
                        )}
                        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm transition-all ${
                          selectedFriends.includes(f.id)
                            ? 'bg-[#E91E63] text-white'
                            : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        }`}
                      >
                        <Users className="w-3.5 h-3.5" />
                        {f.name.split(' ')[0]}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              <div className="flex gap-3 pt-2">
                <button
                  onClick={() => { setStep('list'); setError(null); }}
                  className="flex-1 py-3 border border-gray-200 rounded-xl text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  onClick={saveRoute}
                  disabled={stops.length < 2 || saving}
                  className="flex-1 py-3 bg-[#E91E63] text-white rounded-xl text-sm font-semibold hover:bg-[#C2185B] disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  {saving ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : (
                    <Send className="w-4 h-4" />
                  )}
                  {saving ? 'Saving...' : 'Save & Invite'}
                </button>
              </div>
            </>
          )}
        </div>
        <div className="h-6 flex-shrink-0" />
      </div>
    </div>
  );
}
