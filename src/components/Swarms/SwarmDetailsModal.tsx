import { useState, useEffect } from 'react';
import { X, MapPin, Clock, Users, MessageCircle, Share2, User, Crown, Check, Sparkles, Pencil } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import type { MapSwarm } from '../../hooks/useMapData';
import type { Database } from '../../lib/database.types';

type SwarmRow = Database['public']['Tables']['swarms']['Row'];

interface SwarmMember {
  id: string;
  name: string;
  username: string | null;
  avatar_url: string | null;
}

interface SwarmDetailsModalProps {
  isOpen: boolean;
  onClose: () => void;
  swarm: MapSwarm | null;
  onJoin: (swarmId: string) => void;
  onMessage: (swarmId: string) => void;
  onViewProfile: (userId: string) => void;
  currentUserId?: string;
  onEdit?: (swarmRow: SwarmRow) => void;
}

export default function SwarmDetailsModal({
  isOpen,
  onClose,
  swarm,
  onJoin,
  onMessage,
  onViewProfile,
  currentUserId,
  onEdit,
}: SwarmDetailsModalProps) {
  const [isJoined, setIsJoined] = useState(false);
  const [isJoining, setIsJoining] = useState(false);
  const [host, setHost] = useState<SwarmMember | null>(null);
  const [members, setMembers] = useState<SwarmMember[]>([]);
  const [isLoadingEdit, setIsLoadingEdit] = useState(false);

  const isHost = !!(currentUserId && swarm && currentUserId === swarm.hostId);

  const handleEditClick = async () => {
    if (!swarm || !onEdit) return;
    setIsLoadingEdit(true);
    const { data } = await supabase
      .from('swarms')
      .select('*')
      .eq('id', swarm.id)
      .maybeSingle();
    setIsLoadingEdit(false);
    if (data) onEdit(data as SwarmRow);
  };

  useEffect(() => {
    if (!isOpen || !swarm) return;

    supabase
      .from('users')
      .select('id, name, username, avatar_url')
      .eq('id', swarm.hostId)
      .maybeSingle()
      .then(({ data }) => { if (data) setHost(data); });

    supabase
      .from('swarm_members')
      .select('user:users!swarm_members_user_id_fkey(id, name, username, avatar_url)')
      .eq('swarm_id', swarm.id)
      .limit(12)
      .then(({ data }) => {
        if (data) {
          setMembers(data.map((row: any) => row.user).filter(Boolean));
        }
      });
  }, [isOpen, swarm?.id]);

  if (!isOpen || !swarm) return null;

  const handleJoin = async () => {
    setIsJoining(true);
    await new Promise(resolve => setTimeout(resolve, 800));
    setIsJoined(true);
    setIsJoining(false);
    onJoin(swarm.id);
  };

  return (
    <div className="fixed inset-0 z-[2000] flex items-end sm:items-center justify-center">
      <div className="absolute inset-0 bg-black/70 backdrop-blur-md" onClick={onClose} />
      <div className="relative bg-midnight-900 rounded-t-3xl sm:rounded-3xl w-full sm:max-w-lg max-h-[95vh] overflow-hidden animate-slide-up border-t sm:border border-white/10 flex flex-col">
        <div className="relative h-36 bg-gradient-to-br from-coral-500 via-coral-600 to-rose-600 overflow-hidden flex-shrink-0">
          <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZGVmcz48cGF0dGVybiBpZD0iZG90cyIgd2lkdGg9IjIwIiBoZWlnaHQ9IjIwIiBwYXR0ZXJuVW5pdHM9InVzZXJTcGFjZU9uVXNlIj48Y2lyY2xlIGN4PSIxMCIgY3k9IjEwIiByPSIxLjUiIGZpbGw9InJnYmEoMjU1LDI1NSwyNTUsMC4xKSIvPjwvcGF0dGVybj48L2RlZnM+PHJlY3Qgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgZmlsbD0idXJsKCNkb3RzKSIvPjwvc3ZnPg==')] opacity-50" />
          <button
            onClick={onClose}
            className="absolute top-4 right-4 p-2 bg-black/20 backdrop-blur rounded-full hover:bg-black/30 transition-colors"
          >
            <X className="w-5 h-5 text-white" />
          </button>
          <div className="absolute bottom-4 left-6 right-6">
            <div className="flex items-center gap-2 mb-1">
              <Sparkles className="w-5 h-5 text-white/80" />
              <span className="text-white/80 text-sm font-medium">Swarm</span>
            </div>
            <h2 className="text-2xl font-bold text-white text-shadow">{swarm.name}</h2>
          </div>
        </div>

        <div className="p-6 space-y-6 overflow-y-auto flex-1 scrollbar-hide">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2 px-3 py-1.5 bg-white/5 rounded-full">
                <Clock className="w-4 h-4 text-white/60" />
                <span className="text-sm font-medium text-white/80">{swarm.startTime}</span>
              </div>
              <div className="flex items-center gap-2 px-3 py-1.5 bg-white/5 rounded-full">
                <Users className="w-4 h-4 text-white/60" />
                <span className="text-sm font-medium text-white/80">{swarm.memberCount} going</span>
              </div>
            </div>
            <button className="p-2 hover:bg-white/10 rounded-full transition-colors">
              <Share2 className="w-5 h-5 text-white/50" />
            </button>
          </div>

          <div className="flex flex-wrap gap-2">
            {swarm.vibes.map(vibe => (
              <span key={vibe} className="badge-coral">{vibe}</span>
            ))}
          </div>

          <p className="text-white/70 leading-relaxed">{swarm.description}</p>

          {host && (
            <div className="border-t border-white/10 pt-6">
              <h3 className="text-xs font-semibold text-white/40 uppercase tracking-wider mb-3">Host</h3>
              <button
                onClick={() => onViewProfile(host.id)}
                className="flex items-center gap-3 w-full p-3 bg-white/5 rounded-xl hover:bg-white/10 transition-colors"
              >
                <div className="relative">
                  <div className="w-12 h-12 rounded-full overflow-hidden border-2 border-white/10">
                    {host.avatar_url ? (
                      <img src={host.avatar_url} alt={host.name} className="w-full h-full object-cover" />
                    ) : (
                      <div className="w-full h-full bg-gradient-to-br from-coral-400 to-coral-600 flex items-center justify-center">
                        <User className="w-6 h-6 text-white" />
                      </div>
                    )}
                  </div>
                  <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-amber-500 rounded-full flex items-center justify-center border-2 border-midnight-900">
                    <Crown className="w-3 h-3 text-white" />
                  </div>
                </div>
                <div className="flex-1 text-left">
                  <p className="font-semibold text-white">{host.name}</p>
                  <p className="text-sm text-white/40">{host.username || ''}</p>
                </div>
              </button>
            </div>
          )}

          {members.length > 0 && (
            <div className="border-t border-white/10 pt-6">
              <h3 className="text-xs font-semibold text-white/40 uppercase tracking-wider mb-3">
                Members ({swarm.memberCount})
              </h3>
              <div className="flex flex-wrap gap-2">
                {members.map((member) => (
                  <button
                    key={member.id}
                    onClick={() => onViewProfile(member.id)}
                    className="flex items-center gap-2 px-3 py-2 bg-white/5 rounded-full hover:bg-white/10 transition-colors"
                  >
                    <div className="w-7 h-7 rounded-full overflow-hidden">
                      {member.avatar_url ? (
                        <img src={member.avatar_url} alt={member.name} className="w-full h-full object-cover" />
                      ) : (
                        <div className="w-full h-full bg-gradient-to-br from-coral-400 to-coral-600 flex items-center justify-center">
                          <User className="w-3.5 h-3.5 text-white" />
                        </div>
                      )}
                    </div>
                    <span className="text-sm font-medium text-white/80">{member.name.split(' ')[0]}</span>
                    {member.id === swarm.hostId && (
                      <Crown className="w-3 h-3 text-amber-400" />
                    )}
                  </button>
                ))}
              </div>
            </div>
          )}

          <button className="flex items-center gap-3 w-full p-4 bg-amber-500/10 rounded-xl border border-amber-500/20 hover:bg-amber-500/20 transition-colors">
            <MapPin className="w-5 h-5 text-amber-400" />
            <div className="flex-1 text-left">
              <p className="font-medium text-amber-300">{swarm.venueName}</p>
              <p className="text-sm text-amber-400/60">Tap for directions</p>
            </div>
          </button>
        </div>

        <div className="p-6 border-t border-white/10 bg-midnight-950/50 flex-shrink-0 space-y-3">
          {isHost && onEdit && (
            <button
              onClick={handleEditClick}
              disabled={isLoadingEdit}
              className="w-full py-3.5 rounded-2xl font-semibold transition-all flex items-center justify-center gap-2 bg-white/10 hover:bg-white/15 text-white border border-white/20"
            >
              {isLoadingEdit ? (
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <Pencil className="w-5 h-5" />
              )}
              Edit Swarm
            </button>
          )}
          {isHost ? (
            <button
              onClick={() => onMessage(swarm.id)}
              className="w-full btn-primary py-4 flex items-center justify-center gap-2"
            >
              <MessageCircle className="w-5 h-5" />
              Message Members
            </button>
          ) : isJoined ? (
            <div className="flex gap-3">
              <button
                onClick={() => onMessage(swarm.id)}
                className="flex-1 btn-primary py-4 flex items-center justify-center gap-2"
              >
                <MessageCircle className="w-5 h-5" />
                Message Group
              </button>
              <button className="py-4 px-5 bg-emerald-500/20 text-emerald-400 rounded-2xl font-semibold flex items-center justify-center border border-emerald-500/30">
                <Check className="w-5 h-5" />
              </button>
            </div>
          ) : (
            <button
              onClick={handleJoin}
              disabled={isJoining}
              className="w-full py-4 rounded-2xl font-semibold transition-all flex items-center justify-center gap-2 btn-primary"
            >
              {isJoining ? (
                <>
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  Joining...
                </>
              ) : (
                <>
                  <Sparkles className="w-5 h-5" />
                  Join Swarm
                </>
              )}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
