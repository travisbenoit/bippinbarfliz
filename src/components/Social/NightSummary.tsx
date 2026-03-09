import { useState, useEffect } from 'react';
import { Moon, MapPin, Users, Sparkles, Calendar, ChevronRight } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

interface WeeklySummary {
  week_start: string;
  venues_visited: number;
  swarms_joined: number;
  people_met: number;
  venue_names: string[];
  nights_out: number;
}

function getWeekStart(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  d.setDate(d.getDate() - ((day + 1) % 7));
  d.setHours(0, 0, 0, 0);
  return d;
}

function formatDate(d: Date) {
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

export function NightSummary() {
  const { user } = useAuth();
  const [summary, setSummary] = useState<WeeklySummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState(false);

  useEffect(() => {
    if (!user) { setLoading(false); return; }
    buildSummary();
  }, [user]);

  const buildSummary = async () => {
    if (!user) return;
    const weekStart = getWeekStart(new Date());
    const weekEnd = new Date();

    const { data: events } = await supabase
      .from('activity_feed')
      .select('activity_type, venue_id, swarm_id, created_at, metadata')
      .eq('actor_user_id', user.id)
      .gte('created_at', weekStart.toISOString())
      .lte('created_at', weekEnd.toISOString());

    if (!events?.length) { setLoading(false); return; }

    const venueEnters = events.filter(e => e.activity_type === 'venue_enter');
    const swarmJoins = events.filter(e => e.activity_type === 'swarm_join' || e.activity_type === 'swarm_create');
    const venueNames = [...new Set(venueEnters.map(e => (e.metadata as any)?.venue_name).filter(Boolean))] as string[];
    const nightsOut = new Set(venueEnters.map(e => new Date(e.created_at).toDateString())).size;

    const { count: peopleCount } = await supabase
      .from('friendships')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'accepted')
      .gte('created_at', weekStart.toISOString());

    setSummary({
      week_start: weekStart.toISOString(),
      venues_visited: venueNames.length,
      swarms_joined: swarmJoins.length,
      people_met: peopleCount || 0,
      venue_names: venueNames,
      nights_out: nightsOut,
    });
    setLoading(false);
  };

  if (loading || !summary || summary.nights_out === 0) return null;

  const weekStart = new Date(summary.week_start);
  const weekEnd = new Date();
  const isMonday = new Date().getDay() === 1;

  return (
    <div className="bg-gradient-to-br from-[#E91E63] to-[#C2185B] rounded-2xl p-5 text-white shadow-lg">
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-2 mb-3">
          <Moon className="w-5 h-5 text-white/80" />
          <p className="font-semibold text-white/90 text-sm">
            {isMonday ? 'Last weekend recap' : 'This week so far'}
          </p>
        </div>
        <div className="flex items-center gap-1 text-white/60 text-xs">
          <Calendar className="w-3 h-3" />
          {formatDate(weekStart)} – {formatDate(weekEnd)}
        </div>
      </div>

      <div className="grid grid-cols-3 gap-3 mb-4">
        <div className="bg-white/15 rounded-xl p-3 text-center">
          <p className="text-2xl font-black">{summary.nights_out}</p>
          <p className="text-xs text-white/80 mt-0.5">Nights out</p>
        </div>
        <div className="bg-white/15 rounded-xl p-3 text-center">
          <p className="text-2xl font-black">{summary.venues_visited}</p>
          <p className="text-xs text-white/80 mt-0.5">Venues</p>
        </div>
        <div className="bg-white/15 rounded-xl p-3 text-center">
          <p className="text-2xl font-black">{summary.swarms_joined}</p>
          <p className="text-xs text-white/80 mt-0.5">Swarms</p>
        </div>
      </div>

      {summary.venue_names.length > 0 && (
        <button
          onClick={() => setExpanded(!expanded)}
          className="w-full flex items-center justify-between bg-white/10 rounded-xl px-4 py-2.5"
        >
          <div className="flex items-center gap-2">
            <MapPin className="w-4 h-4 text-white/70" />
            <p className="text-sm text-white/90">
              {expanded ? 'Venues this week' : summary.venue_names[0]}
              {!expanded && summary.venue_names.length > 1 && (
                <span className="text-white/60"> +{summary.venue_names.length - 1} more</span>
              )}
            </p>
          </div>
          <ChevronRight className={`w-4 h-4 text-white/50 transition-transform ${expanded ? 'rotate-90' : ''}`} />
        </button>
      )}

      {expanded && summary.venue_names.length > 0 && (
        <div className="mt-2 bg-white/10 rounded-xl p-3 space-y-1.5">
          {summary.venue_names.map((name, i) => (
            <div key={i} className="flex items-center gap-2 text-sm text-white/90">
              <div className="w-5 h-5 bg-white/20 rounded-full flex items-center justify-center text-[10px] font-bold">{i + 1}</div>
              {name}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
