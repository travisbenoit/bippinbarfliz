import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { BarChart2, MapPin, MessageSquare, Zap, TrendingUp } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import PageHeader from '../Layout/PageHeader';

interface VenueRow {
  id: string;
  name: string;
  city: string | null;
  checkin_count: number;
  buzz_count: number;
  vibe_count: number;
}

type SortKey = 'checkin_count' | 'buzz_count' | 'vibe_count';

export default function AdminVenueAnalytics() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [venues, setVenues] = useState<VenueRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [denied, setDenied] = useState(false);
  const [sortBy, setSortBy] = useState<SortKey>('checkin_count');
  const [search, setSearch] = useState('');

  useEffect(() => {
    checkAdmin();
  }, [user]);

  const checkAdmin = async () => {
    if (!user) return;
    const { data } = await supabase
      .from('users')
      .select('is_admin')
      .eq('id', user.id)
      .maybeSingle();
    if (!data?.is_admin) { setDenied(true); setLoading(false); return; }
    loadAnalytics();
  };

  const loadAnalytics = async () => {
    setLoading(true);
    try {
      // Get all venues
      const { data: venueList } = await supabase
        .from('venues')
        .select('id, name, city')
        .order('name')
        .limit(300);

      if (!venueList || venueList.length === 0) { setLoading(false); return; }
      const venueIds = venueList.map(v => v.id);

      // Count presence rows per venue (check-ins)
      const { data: presenceRows } = await supabase
        .from('user_venue_presence')
        .select('venue_id')
        .in('venue_id', venueIds);

      // Count buzz messages per venue
      const { data: buzzRows } = await supabase
        .from('venue_buzz')
        .select('venue_id')
        .in('venue_id', venueIds);

      // Count vibe votes per venue
      const { data: vibeRows } = await supabase
        .from('vibe_votes')
        .select('venue_id')
        .in('venue_id', venueIds);

      // Aggregate counts
      const checkinCounts: Record<string, number> = {};
      (presenceRows || []).forEach(r => { checkinCounts[r.venue_id] = (checkinCounts[r.venue_id] || 0) + 1; });

      const buzzCounts: Record<string, number> = {};
      (buzzRows || []).forEach(r => { buzzCounts[r.venue_id] = (buzzCounts[r.venue_id] || 0) + 1; });

      const vibeCounts: Record<string, number> = {};
      (vibeRows || []).forEach(r => { vibeCounts[r.venue_id] = (vibeCounts[r.venue_id] || 0) + 1; });

      const merged: VenueRow[] = venueList.map(v => ({
        id: v.id,
        name: v.name,
        city: v.city,
        checkin_count: checkinCounts[v.id] || 0,
        buzz_count: buzzCounts[v.id] || 0,
        vibe_count: vibeCounts[v.id] || 0,
      })).filter(v => v.checkin_count + v.buzz_count + v.vibe_count > 0);

      setVenues(merged);
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  };

  const filtered = venues
    .filter(v => !search || v.name.toLowerCase().includes(search.toLowerCase()) || (v.city || '').toLowerCase().includes(search.toLowerCase()))
    .sort((a, b) => b[sortBy] - a[sortBy]);

  const totals = venues.reduce((acc, v) => ({
    checkins: acc.checkins + v.checkin_count,
    buzz: acc.buzz + v.buzz_count,
    vibes: acc.vibes + v.vibe_count,
  }), { checkins: 0, buzz: 0, vibes: 0 });

  if (denied) {
    return (
      <div className="h-full flex items-center justify-center bg-[#FFF5F0]">
        <p className="text-gray-500">Admin access required.</p>
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-8">
      <div className="sticky top-0 z-10">
        <PageHeader title="Venue Analytics" onBack={() => navigate('/settings')} />
      </div>

      <div className="p-4 space-y-4">
        {/* Summary stats */}
        <div className="grid grid-cols-3 gap-3">
          {[
            { label: 'Check-ins', value: totals.checkins, icon: MapPin, color: 'text-pink-500', bg: 'bg-pink-50' },
            { label: 'Buzz msgs', value: totals.buzz, icon: MessageSquare, color: 'text-blue-500', bg: 'bg-blue-50' },
            { label: 'Vibe votes', value: totals.vibes, icon: Zap, color: 'text-amber-500', bg: 'bg-amber-50' },
          ].map(({ label, value, icon: Icon, color, bg }) => (
            <div key={label} className={`${bg} rounded-2xl p-3 text-center`}>
              <Icon className={`w-5 h-5 ${color} mx-auto mb-1`} />
              <p className="text-lg font-bold text-gray-900">{value.toLocaleString()}</p>
              <p className="text-xs text-gray-500">{label}</p>
            </div>
          ))}
        </div>

        {/* Sort tabs */}
        <div className="bg-white rounded-2xl p-1 shadow-sm flex gap-1">
          {([
            { key: 'checkin_count', label: 'Check-ins', icon: MapPin },
            { key: 'buzz_count', label: 'Buzz', icon: MessageSquare },
            { key: 'vibe_count', label: 'Vibes', icon: Zap },
          ] as { key: SortKey; label: string; icon: any }[]).map(({ key, label, icon: Icon }) => (
            <button
              key={key}
              onClick={() => setSortBy(key)}
              className={`flex-1 py-2 rounded-xl text-sm font-semibold flex items-center justify-center gap-1.5 transition-colors ${
                sortBy === key ? 'bg-[#E91E63] text-white' : 'text-gray-600'
              }`}
            >
              <Icon className="w-3.5 h-3.5" />
              {label}
            </button>
          ))}
        </div>

        {/* Search */}
        <input
          type="text"
          placeholder="Search venues..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full bg-white border border-gray-200 rounded-2xl px-4 py-3 text-sm focus:outline-none focus:border-[#E91E63]"
        />

        {loading ? (
          <div className="flex items-center justify-center py-16">
            <div className="w-10 h-10 border-4 border-[#E91E63]/30 border-t-[#E91E63] rounded-full animate-spin" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-16 text-gray-400">
            <BarChart2 className="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p>No activity data yet</p>
          </div>
        ) : (
          <div className="space-y-2">
            <p className="text-xs text-gray-400 font-medium uppercase tracking-wide px-1">
              {filtered.length} venues with activity
            </p>
            {filtered.map((v, i) => (
              <div key={v.id} className="bg-white rounded-2xl p-4 shadow-sm">
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-3 min-w-0">
                    <span className="text-sm font-bold text-gray-400 w-6 flex-shrink-0">#{i + 1}</span>
                    <div className="min-w-0">
                      <p className="font-semibold text-gray-900 truncate">{v.name}</p>
                      {v.city && <p className="text-xs text-gray-400">{v.city}</p>}
                    </div>
                  </div>
                  <div className="flex gap-3 flex-shrink-0 text-right">
                    <div className="text-center">
                      <p className="text-sm font-bold text-pink-500">{v.checkin_count}</p>
                      <p className="text-xs text-gray-400">check-ins</p>
                    </div>
                    <div className="text-center">
                      <p className="text-sm font-bold text-blue-500">{v.buzz_count}</p>
                      <p className="text-xs text-gray-400">buzz</p>
                    </div>
                    <div className="text-center">
                      <p className="text-sm font-bold text-amber-500">{v.vibe_count}</p>
                      <p className="text-xs text-gray-400">vibes</p>
                    </div>
                  </div>
                </div>
                {/* Activity bar */}
                <div className="mt-3 flex gap-0.5 h-1.5 rounded-full overflow-hidden">
                  {[
                    { val: v.checkin_count, color: 'bg-pink-400' },
                    { val: v.buzz_count, color: 'bg-blue-400' },
                    { val: v.vibe_count, color: 'bg-amber-400' },
                  ].map(({ val, color }) => {
                    const total = v.checkin_count + v.buzz_count + v.vibe_count || 1;
                    return <div key={color} className={`${color} rounded-full`} style={{ width: `${(val / total) * 100}%` }} />;
                  })}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
