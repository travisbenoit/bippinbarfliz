import { useState, useEffect } from 'react';
import { Radio, MapPin, Save, AlertCircle, CheckCircle, RefreshCw, ChevronDown, ChevronUp } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';
import PageHeader from '../Layout/PageHeader';

interface VenueGeofence {
  id: string;
  name: string;
  lat: number;
  lng: number;
  geofence_radius_meters: number | null;
  address: string | null;
}

const PRESET_RADII = [
  { label: 'Small bar (30m)', value: 30 },
  { label: 'Standard bar (50m)', value: 50 },
  { label: 'Large venue (100m)', value: 100 },
  { label: 'Club / complex (150m)', value: 150 },
  { label: 'Festival / stadium (250m)', value: 250 },
];

export default function AdminGeofences() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [venues, setVenues] = useState<VenueGeofence[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState<Record<string, boolean>>({});
  const [saved, setSaved] = useState<Record<string, boolean>>({});
  const [error, setError] = useState<string | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [checkingAdmin, setCheckingAdmin] = useState(true);
  const [expanded, setExpanded] = useState<string | null>(null);
  const [radiiEdits, setRadiiEdits] = useState<Record<string, number>>({});
  const [filter, setFilter] = useState<'all' | 'set' | 'unset'>('all');

  useEffect(() => {
    checkAdminAndLoad();
  }, []);

  const checkAdminAndLoad = async () => {
    if (!user) { setCheckingAdmin(false); return; }
    try {
      const { data: profile } = await supabase
        .from('user_profiles')
        .select('is_admin')
        .eq('id', user.id)
        .maybeSingle();
      setIsAdmin(profile?.is_admin || false);
      if (profile?.is_admin) loadVenues();
    } catch {
      setIsAdmin(false);
    } finally {
      setCheckingAdmin(false);
    }
  };

  const loadVenues = async () => {
    setLoading(true);
    setError(null);
    try {
      const { data, error: err } = await supabase
        .from('venues')
        .select('id, name, lat, lng, geofence_radius_meters, address')
        .order('name');

      if (err) throw err;
      setVenues(data || []);

      const initialEdits: Record<string, number> = {};
      (data || []).forEach(v => {
        initialEdits[v.id] = v.geofence_radius_meters ?? 50;
      });
      setRadiiEdits(initialEdits);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load venues');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (venueId: string) => {
    setSaving(prev => ({ ...prev, [venueId]: true }));
    setError(null);
    try {
      const radius = radiiEdits[venueId];
      const { error: err } = await supabase
        .from('venues')
        .update({ geofence_radius_meters: radius })
        .eq('id', venueId);
      if (err) throw err;
      setVenues(prev => prev.map(v => v.id === venueId ? { ...v, geofence_radius_meters: radius } : v));
      setSaved(prev => ({ ...prev, [venueId]: true }));
      setTimeout(() => setSaved(prev => ({ ...prev, [venueId]: false })), 2000);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save');
    } finally {
      setSaving(prev => ({ ...prev, [venueId]: false }));
    }
  };

  const handleBulkSet = async (radius: number) => {
    const unset = venues.filter(v => !v.geofence_radius_meters);
    if (unset.length === 0) return;
    const newEdits = { ...radiiEdits };
    unset.forEach(v => { newEdits[v.id] = radius; });
    setRadiiEdits(newEdits);
  };

  const filteredVenues = venues.filter(v => {
    if (filter === 'set') return v.geofence_radius_meters != null;
    if (filter === 'unset') return v.geofence_radius_meters == null;
    return true;
  });

  const setCount = venues.filter(v => v.geofence_radius_meters != null).length;

  if (!user || checkingAdmin) {
    return (
      <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-20">
        <PageHeader title="Geofence Settings" onBack={() => navigate('/settings')} />
        <div className="p-4 flex justify-center py-8">
          <div className="w-8 h-8 border-4 border-[#E91E63] border-t-transparent rounded-full animate-spin" />
        </div>
      </div>
    );
  }

  if (!isAdmin) {
    return (
      <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-20">
        <PageHeader title="Geofence Settings" onBack={() => navigate('/settings')} />
        <div className="p-4">
          <div className="bg-red-50 border border-red-200 rounded-2xl p-4">
            <p className="text-red-800 font-semibold">Access Denied</p>
            <p className="text-red-700 text-sm mt-1">Admin privileges required.</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-20">
      <PageHeader title="Geofence Radii" onBack={() => navigate('/settings')} />

      <div className="p-4 space-y-4">
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-2xl p-4 flex items-start gap-3">
            <AlertCircle size={18} className="text-red-600 flex-shrink-0 mt-0.5" />
            <p className="text-red-800 text-sm">{error}</p>
          </div>
        )}

        <div className="bg-white rounded-2xl shadow-sm p-4">
          <div className="flex items-center gap-2 mb-3">
            <Radio size={20} className="text-[#E91E63]" />
            <h2 className="font-semibold text-gray-900">Venue Geofence Radii</h2>
          </div>
          <div className="grid grid-cols-3 gap-2 text-center mb-3">
            <div className="bg-gray-50 rounded-xl p-2">
              <p className="text-xl font-bold text-gray-900">{venues.length}</p>
              <p className="text-xs text-gray-500">Total</p>
            </div>
            <div className="bg-emerald-50 rounded-xl p-2">
              <p className="text-xl font-bold text-emerald-700">{setCount}</p>
              <p className="text-xs text-gray-500">Configured</p>
            </div>
            <div className="bg-amber-50 rounded-xl p-2">
              <p className="text-xl font-bold text-amber-600">{venues.length - setCount}</p>
              <p className="text-xs text-gray-500">Unset</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-2xl shadow-sm p-4">
          <h3 className="font-semibold text-gray-900 mb-3 text-sm">Bulk set unset venues</h3>
          <div className="flex flex-wrap gap-2">
            {PRESET_RADII.map(preset => (
              <button
                key={preset.value}
                onClick={() => handleBulkSet(preset.value)}
                className="px-3 py-1.5 bg-gray-100 hover:bg-[#E91E63] hover:text-white text-gray-700 rounded-full text-xs font-medium transition-colors"
              >
                {preset.label}
              </button>
            ))}
          </div>
        </div>

        <div className="flex gap-2">
          {(['all', 'set', 'unset'] as const).map(f => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`flex-1 py-2 rounded-xl text-sm font-medium capitalize transition-colors ${
                filter === f ? 'bg-[#E91E63] text-white' : 'bg-white text-gray-600 border border-gray-200'
              }`}
            >
              {f}
            </button>
          ))}
        </div>

        {loading ? (
          <div className="flex justify-center py-8">
            <div className="w-8 h-8 border-4 border-[#E91E63] border-t-transparent rounded-full animate-spin" />
          </div>
        ) : (
          <div className="space-y-2">
            {filteredVenues.map(venue => {
              const isExpanded = expanded === venue.id;
              const radius = radiiEdits[venue.id] ?? 50;
              const isDirty = radius !== (venue.geofence_radius_meters ?? null);
              return (
                <div key={venue.id} className="bg-white rounded-2xl shadow-sm overflow-hidden">
                  <button
                    className="w-full flex items-center gap-3 p-4 text-left hover:bg-gray-50 transition-colors"
                    onClick={() => setExpanded(isExpanded ? null : venue.id)}
                  >
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${
                      venue.geofence_radius_meters ? 'bg-emerald-100' : 'bg-gray-100'
                    }`}>
                      <Radio className={`w-5 h-5 ${venue.geofence_radius_meters ? 'text-emerald-600' : 'text-gray-400'}`} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-gray-900 truncate">{venue.name}</p>
                      <p className="text-xs text-gray-500">
                        {venue.geofence_radius_meters ? `${venue.geofence_radius_meters}m radius` : 'No radius set'}
                      </p>
                    </div>
                    {isDirty && <span className="text-xs text-amber-600 font-medium">Unsaved</span>}
                    {isExpanded ? <ChevronUp size={16} className="text-gray-400" /> : <ChevronDown size={16} className="text-gray-400" />}
                  </button>

                  {isExpanded && (
                    <div className="px-4 pb-4 border-t border-gray-50">
                      <div className="pt-3 space-y-3">
                        {venue.address && (
                          <div className="flex items-start gap-2">
                            <MapPin size={14} className="text-gray-400 mt-0.5 flex-shrink-0" />
                            <p className="text-xs text-gray-500">{venue.address}</p>
                          </div>
                        )}
                        <p className="text-xs text-gray-500">{venue.lat.toFixed(5)}, {venue.lng.toFixed(5)}</p>

                        <div>
                          <div className="flex items-center justify-between mb-2">
                            <label className="text-sm font-medium text-gray-700">Geofence Radius</label>
                            <span className="text-sm font-bold text-[#E91E63]">{radius}m</span>
                          </div>
                          <input
                            type="range"
                            min={20}
                            max={500}
                            step={5}
                            value={radius}
                            onChange={e => setRadiiEdits(prev => ({ ...prev, [venue.id]: Number(e.target.value) }))}
                            className="w-full accent-[#E91E63]"
                          />
                          <div className="flex justify-between text-xs text-gray-400 mt-1">
                            <span>20m</span>
                            <span>500m</span>
                          </div>
                        </div>

                        <div className="flex flex-wrap gap-2">
                          {PRESET_RADII.map(preset => (
                            <button
                              key={preset.value}
                              onClick={() => setRadiiEdits(prev => ({ ...prev, [venue.id]: preset.value }))}
                              className={`px-2.5 py-1 rounded-full text-xs font-medium transition-colors ${
                                radius === preset.value
                                  ? 'bg-[#E91E63] text-white'
                                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                              }`}
                            >
                              {preset.value}m
                            </button>
                          ))}
                        </div>

                        <button
                          onClick={() => handleSave(venue.id)}
                          disabled={saving[venue.id] || saved[venue.id]}
                          className={`w-full py-2.5 rounded-xl font-medium text-sm flex items-center justify-center gap-2 transition-all ${
                            saved[venue.id]
                              ? 'bg-emerald-100 text-emerald-700'
                              : 'bg-[#E91E63] text-white hover:bg-[#C2185B] disabled:opacity-50'
                          }`}
                        >
                          {saving[venue.id] ? (
                            <RefreshCw size={14} className="animate-spin" />
                          ) : saved[venue.id] ? (
                            <CheckCircle size={14} />
                          ) : (
                            <Save size={14} />
                          )}
                          {saved[venue.id] ? 'Saved' : 'Save Radius'}
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        <button
          onClick={loadVenues}
          disabled={loading}
          className="w-full py-3 bg-white border border-gray-200 rounded-2xl font-medium text-gray-700 hover:bg-gray-50 transition-colors flex items-center justify-center gap-2"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          Refresh
        </button>
      </div>
    </div>
  );
}
