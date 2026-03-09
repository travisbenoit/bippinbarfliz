import { useState, useEffect } from 'react';
import { MapPin, Sparkles, UserCheck, Users, Clock, Activity } from 'lucide-react';
import { activityService, type ActivityEvent } from '../../services/activityService';

function timeAgo(dateStr: string): string {
  const now = Date.now();
  const then = new Date(dateStr).getTime();
  const diff = Math.floor((now - then) / 1000);
  if (diff < 60) return 'just now';
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

function ActivityIcon({ type }: { type: ActivityEvent['activity_type'] }) {
  const base = 'w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0';
  switch (type) {
    case 'venue_enter':
      return <div className={`${base} bg-emerald-100`}><MapPin className="w-4 h-4 text-emerald-600" /></div>;
    case 'venue_leave':
      return <div className={`${base} bg-gray-100`}><MapPin className="w-4 h-4 text-gray-500" /></div>;
    case 'swarm_join':
      return <div className={`${base} bg-blue-100`}><Users className="w-4 h-4 text-blue-600" /></div>;
    case 'swarm_create':
      return <div className={`${base} bg-[#E91E63]/10`}><Sparkles className="w-4 h-4 text-[#E91E63]" /></div>;
    case 'friend_request_accepted':
      return <div className={`${base} bg-amber-100`}><UserCheck className="w-4 h-4 text-amber-600" /></div>;
    default:
      return <div className={`${base} bg-gray-100`}><Activity className="w-4 h-4 text-gray-500" /></div>;
  }
}

function activityText(event: ActivityEvent): string {
  switch (event.activity_type) {
    case 'venue_enter':
      return `arrived at ${event.venue_name || 'a bar'}`;
    case 'venue_leave':
      return `left ${event.venue_name || 'a bar'}`;
    case 'swarm_join':
      return `joined the swarm "${event.swarm_name || 'a swarm'}"`;
    case 'swarm_create':
      return `started a swarm at ${event.venue_name || 'nearby'}`;
    case 'friend_request_accepted':
      return 'is now your friend';
    case 'status_update':
      return (event.metadata?.status as string) || 'updated their status';
    default:
      return 'did something';
  }
}

interface Props {
  maxItems?: number;
  compact?: boolean;
}

export function ActivityFeed({ maxItems = 20, compact = false }: Props) {
  const [events, setEvents] = useState<ActivityEvent[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      const data = await activityService.getFriendActivity(maxItems);
      setEvents(data);
      setLoading(false);
    };
    load();

    const unsub = activityService.subscribeToActivityFeed((data) => {
      setEvents(data.slice(0, maxItems));
    });
    return unsub;
  }, [maxItems]);

  if (loading) {
    return (
      <div className="space-y-3">
        {[1, 2, 3].map(i => (
          <div key={i} className="flex items-center gap-3 animate-pulse">
            <div className="w-9 h-9 bg-gray-200 rounded-full flex-shrink-0" />
            <div className="flex-1 space-y-2">
              <div className="h-3 bg-gray-200 rounded w-3/4" />
              <div className="h-2 bg-gray-100 rounded w-1/3" />
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (events.length === 0) {
    return (
      <div className={`text-center ${compact ? 'py-4' : 'py-10'}`}>
        <Activity className="w-8 h-8 text-gray-300 mx-auto mb-2" />
        <p className="text-sm text-gray-400">No activity from friends yet</p>
        {!compact && <p className="text-xs text-gray-300 mt-1">Their moves will show up here</p>}
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {events.map(event => (
        <div key={event.id} className="flex items-start gap-3">
          <ActivityIcon type={event.activity_type} />
          <div className="flex-1 min-w-0">
            <p className={`${compact ? 'text-sm' : 'text-base'} text-gray-900`}>
              <span className="font-semibold">{event.actor_name}</span>
              {' '}
              <span className="text-gray-600">{activityText(event)}</span>
            </p>
            <div className="flex items-center gap-1 mt-0.5">
              <Clock className="w-3 h-3 text-gray-400" />
              <span className="text-xs text-gray-400">{timeAgo(event.created_at)}</span>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
