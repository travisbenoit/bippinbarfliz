import { useState, useEffect } from 'react';
import { Sparkles, Users, MapPin, X } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';

interface VenueCluster {
  venue_id: string;
  venue_name: string;
  friends: Array<{ id: string; name: string }>;
}

export function SwarmSuggestion() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [clusters, setClusters] = useState<VenueCluster[]>([]);
  const [dismissed, setDismissed] = useState<string[]>([]);

  useEffect(() => {
    if (!user) return;
    detectClusters();
    const interval = setInterval(detectClusters, 120000);
    return () => clearInterval(interval);
  }, [user]);

  const detectClusters = async () => {
    if (!user) return;
    const { data: friends } = await supabase
      .from('friendships')
      .select('user_id, friend_id')
      .eq('status', 'accepted')
      .or(`user_id.eq.${user.id},friend_id.eq.${user.id}`);

    if (!friends?.length) return;
    const friendIds = friends.map(f => f.user_id === user.id ? f.friend_id : f.user_id);

    const { data: presences } = await supabase
      .from('user_venue_presence')
      .select('user_id, venue_id, venues(name), users(id, name)')
      .in('user_id', [...friendIds, user.id])
      .eq('status', 'IN_VENUE');

    if (!presences?.length) return;

    const byVenue: Record<string, VenueCluster> = {};
    presences.forEach((p: any) => {
      const vId = p.venue_id;
      if (!vId || p.user_id === user.id) return;
      if (!byVenue[vId]) {
        byVenue[vId] = { venue_id: vId, venue_name: p.venues?.name || 'Unknown', friends: [] };
      }
      if (p.users?.id && !byVenue[vId].friends.find(f => f.id === p.users.id)) {
        byVenue[vId].friends.push({ id: p.users.id, name: p.users.name });
      }
    });

    const significant = Object.values(byVenue).filter(c => c.friends.length >= 2);
    setClusters(significant);
  };

  const visible = clusters.filter(c => !dismissed.includes(c.venue_id));
  if (visible.length === 0) return null;

  return (
    <div className="space-y-2">
      {visible.map(cluster => (
        <div
          key={cluster.venue_id}
          className="relative bg-gradient-to-r from-[#E91E63]/10 to-[#C2185B]/10 border border-[#E91E63]/25 rounded-2xl p-4"
        >
          <button
            onClick={() => setDismissed(prev => [...prev, cluster.venue_id])}
            className="absolute top-3 right-3 w-6 h-6 flex items-center justify-center rounded-full hover:bg-black/10"
          >
            <X className="w-3.5 h-3.5 text-gray-500" />
          </button>
          <div className="flex items-start gap-3">
            <div className="w-10 h-10 bg-[#E91E63]/20 rounded-xl flex items-center justify-center flex-shrink-0">
              <Sparkles className="w-5 h-5 text-[#E91E63]" />
            </div>
            <div className="flex-1 min-w-0 pr-6">
              <p className="font-semibold text-gray-900 text-sm">Start a swarm?</p>
              <div className="flex items-center gap-1.5 mt-0.5">
                <Users className="w-3.5 h-3.5 text-gray-400" />
                <p className="text-xs text-gray-600">
                  {cluster.friends.slice(0, 2).map(f => f.name.split(' ')[0]).join(', ')}
                  {cluster.friends.length > 2 && ` +${cluster.friends.length - 2} more`} at
                </p>
              </div>
              <div className="flex items-center gap-1 mt-0.5">
                <MapPin className="w-3 h-3 text-[#E91E63]" />
                <p className="text-xs font-semibold text-[#E91E63]">{cluster.venue_name}</p>
              </div>
              <button
                onClick={() => navigate(`/create-swarm?venue=${cluster.venue_id}&name=${encodeURIComponent(cluster.venue_name)}`)}
                className="mt-3 px-4 py-2 bg-[#E91E63] text-white text-xs font-bold rounded-xl hover:bg-[#C2185B] transition-colors"
              >
                Create Swarm Here
              </button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
