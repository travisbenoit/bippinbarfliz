import { useState, useEffect, useRef } from 'react';
import { X, Users, MessageCircle, Zap, Camera, Trophy } from 'lucide-react';
import { roomService, RoomStats } from '../../services/roomService';
import { supabase } from '../../lib/supabase';
import { RoomChat } from './RoomChat';
import { WhoIsHere } from './WhoIsHere';
import { VibeTab } from './VibeTab';
import { MomentsTab } from './MomentsTab';
import { VenueLeaderboard } from './VenueLeaderboard';

type RoomTab = 'chat' | 'who' | 'vibe' | 'moments' | 'regulars';

interface TheRoomProps {
  venueId: string;
  venueName: string;
  venuePhoto?: string | null;
  isInsideVenue: boolean;
  onClose: () => void;
  onMessageUser?: (userId: string) => void;
}

const TABS: { id: RoomTab; label: string; icon: React.ReactNode }[] = [
  { id: 'chat', label: 'Chat', icon: <MessageCircle className="w-4 h-4" /> },
  { id: 'who', label: "Who's Here", icon: <Users className="w-4 h-4" /> },
  { id: 'vibe', label: 'Vibe', icon: <Zap className="w-4 h-4" /> },
  { id: 'moments', label: 'Moments', icon: <Camera className="w-4 h-4" /> },
  { id: 'regulars', label: 'Regulars', icon: <Trophy className="w-4 h-4" /> },
];

export function TheRoom({ venueId, venueName, venuePhoto, isInsideVenue, onClose, onMessageUser }: TheRoomProps) {
  const [tab, setTab] = useState<RoomTab>('chat');
  const [stats, setStats] = useState<RoomStats>({ message_count: 0, active_users: 0, top_drink: null, top_music: null });
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const heartbeatRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (user) setCurrentUserId(user.id);
    });
  }, []);

  useEffect(() => {
    roomService.getStats(venueId).then(setStats).catch(() => {});

    if (isInsideVenue) {
      roomService.joinRoom(venueId).catch(() => {});
      heartbeatRef.current = setInterval(() => {
        roomService.joinRoom(venueId).catch(() => {});
        roomService.getStats(venueId).then(setStats).catch(() => {});
      }, 60_000);
    }

    return () => {
      if (heartbeatRef.current) clearInterval(heartbeatRef.current);
    };
  }, [venueId, isInsideVenue]);

  return (
    <div className="fixed inset-0 z-[3000] flex flex-col" style={{ background: '#0a0a0f' }}>
      <div className="relative flex-shrink-0">
        {venuePhoto ? (
          <div className="relative h-32 overflow-hidden">
            <img src={venuePhoto} alt={venueName} className="w-full h-full object-cover opacity-40" />
            <div className="absolute inset-0 bg-gradient-to-b from-black/40 via-transparent to-[#0a0a0f]" />
          </div>
        ) : (
          <div className="h-20 bg-gradient-to-br from-amber-900/40 to-orange-900/20" />
        )}

        <div className={`${venuePhoto ? 'absolute bottom-0 left-0 right-0' : ''} px-4 pb-3`}>
          <div className="flex items-end justify-between">
            <div>
              <div className="flex items-center gap-2 mb-1">
                <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
                <span className="text-green-400 text-xs font-bold uppercase tracking-wider">The Room</span>
                {isInsideVenue && (
                  <span className="text-xs px-2 py-0.5 bg-green-500/20 text-green-400 border border-green-500/30 rounded-full">
                    You're inside
                  </span>
                )}
              </div>
              <h1 className="text-xl font-black text-white leading-tight">{venueName}</h1>
              <div className="flex items-center gap-3 mt-1">
                <span className="text-xs text-gray-400">
                  🔥 <span className="text-white font-semibold">{stats.active_users}</span> in The Room
                </span>
                <span className="text-xs text-gray-400">
                  💬 <span className="text-white font-semibold">{stats.message_count}</span> messages
                </span>
              </div>
            </div>
            <button
              onClick={onClose}
              className="mb-1 w-9 h-9 bg-gray-800/80 border border-gray-700 rounded-full flex items-center justify-center hover:bg-gray-700 transition-colors"
            >
              <X className="w-5 h-5 text-gray-300" />
            </button>
          </div>
        </div>
      </div>

      <div className="flex-shrink-0 flex border-b border-gray-800 px-2">
        {TABS.map((t) => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            className={`flex-1 flex items-center justify-center gap-1.5 py-3 text-xs font-semibold transition-all relative ${
              tab === t.id ? 'text-amber-400' : 'text-gray-500 hover:text-gray-400'
            }`}
          >
            {t.icon}
            <span className="hidden sm:inline">{t.label}</span>
            {tab === t.id && (
              <span className="absolute bottom-0 left-2 right-2 h-0.5 bg-amber-500 rounded-t-full" />
            )}
          </button>
        ))}
      </div>

      <div className="flex-1 flex flex-col overflow-hidden">
        {tab === 'chat' && (
          <RoomChat
            venueId={venueId}
            isInsideVenue={isInsideVenue}
            currentUserId={currentUserId}
          />
        )}
        {tab === 'who' && (
          <WhoIsHere
            venueId={venueId}
            onMessageUser={onMessageUser}
            currentUserId={currentUserId}
          />
        )}
        {tab === 'vibe' && (
          <VibeTab
            venueId={venueId}
            isInsideVenue={isInsideVenue}
          />
        )}
        {tab === 'moments' && (
          <MomentsTab
            venueId={venueId}
            isInsideVenue={isInsideVenue}
            currentUserId={currentUserId}
          />
        )}
        {tab === 'regulars' && (
          <VenueLeaderboard
            venueId={venueId}
            currentUserId={currentUserId}
          />
        )}
      </div>
    </div>
  );
}
