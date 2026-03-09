import { useState, useEffect, useRef } from 'react';
import { X, Search, User, UserPlus, ChevronRight, MessageCircle } from 'lucide-react';
import { friendsService, FriendUser, Friendship } from '../../services/friendsService';
import { supabase } from '../../lib/supabase';

interface NewChatModalProps {
  isOpen: boolean;
  onClose: () => void;
  onStartChat: (user: { id: string; name: string; avatar_url: string | null }) => void;
}

type TabType = 'friends' | 'search';

function getTonightStatusLabel(status: string | null): { label: string; color: string } | null {
  if (!status) return null;
  if (status === 'out_now') return { label: 'Out now', color: 'bg-green-100 text-green-700' };
  if (status === 'going_out_soon') return { label: 'Going out soon', color: 'bg-amber-100 text-amber-700' };
  return null;
}

export default function NewChatModal({ isOpen, onClose, onStartChat }: NewChatModalProps) {
  const [tab, setTab] = useState<TabType>('friends');
  const [friends, setFriends] = useState<FriendUser[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<FriendUser[]>([]);
  const [loadingFriends, setLoadingFriends] = useState(true);
  const [searching, setSearching] = useState(false);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const searchTimeout = useRef<ReturnType<typeof setTimeout> | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!isOpen) return;
    setSearchQuery('');
    setSearchResults([]);
    setTab('friends');
    loadFriends();
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (user) setCurrentUserId(user.id);
    });
  }, [isOpen]);

  useEffect(() => {
    if (isOpen && tab === 'search') {
      setTimeout(() => inputRef.current?.focus(), 100);
    }
  }, [isOpen, tab]);

  const loadFriends = async () => {
    setLoadingFriends(true);
    try {
      const data = await friendsService.getFriends();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;
      const mapped = data
        .map((f: Friendship) => friendsService.getFriendProfile(f, user.id))
        .filter(Boolean) as FriendUser[];
      setFriends(mapped);
    } catch {
      setFriends([]);
    } finally {
      setLoadingFriends(false);
    }
  };

  const handleSearch = (query: string) => {
    setSearchQuery(query);
    if (searchTimeout.current) clearTimeout(searchTimeout.current);
    if (!query.trim()) {
      setSearchResults([]);
      return;
    }
    setSearching(true);
    searchTimeout.current = setTimeout(async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return;
        const { data } = await supabase
          .from('users')
          .select('id, name, avatar_url, tonight_status, home_city, occupation, vibe_tags')
          .neq('id', user.id)
          .ilike('name', `%${query.trim()}%`)
          .limit(20);
        setSearchResults((data || []) as FriendUser[]);
      } catch {
        setSearchResults([]);
      } finally {
        setSearching(false);
      }
    }, 350);
  };

  const filteredFriends = friends.filter((f) =>
    f.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (!isOpen) return null;

  const renderUser = (person: FriendUser, isFriend: boolean) => {
    const statusBadge = getTonightStatusLabel(person.tonight_status);
    return (
      <button
        key={person.id}
        onClick={() => {
          onStartChat({ id: person.id, name: person.name, avatar_url: person.avatar_url });
          onClose();
        }}
        className="w-full flex items-center gap-3 px-4 py-3.5 hover:bg-gray-50 active:bg-gray-100 transition-colors group"
      >
        <div className="relative flex-shrink-0">
          <div className="w-12 h-12 rounded-full overflow-hidden border-2 border-gray-100">
            {person.avatar_url ? (
              <img src={person.avatar_url} alt={person.name} className="w-full h-full object-cover" />
            ) : (
              <div className="w-full h-full bg-gradient-to-br from-pink-100 to-orange-100 flex items-center justify-center">
                <User className="w-5 h-5 text-[#E91E63]" />
              </div>
            )}
          </div>
          {person.tonight_status === 'out_now' && (
            <span className="absolute bottom-0 right-0 w-3 h-3 bg-green-500 border-2 border-white rounded-full" />
          )}
        </div>

        <div className="flex-1 text-left min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <span className="font-semibold text-gray-900 truncate">{person.name}</span>
            {statusBadge && (
              <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${statusBadge.color}`}>
                {statusBadge.label}
              </span>
            )}
          </div>
          <p className="text-sm text-gray-400 truncate">
            {person.home_city || (person.occupation ? person.occupation : isFriend ? 'Friend' : 'Tap to message')}
          </p>
        </div>

        <div className="flex-shrink-0 flex items-center gap-1">
          <div className="w-8 h-8 rounded-full bg-[#E91E63]/10 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
            <MessageCircle className="w-4 h-4 text-[#E91E63]" />
          </div>
          <ChevronRight className="w-4 h-4 text-gray-300 group-hover:text-[#E91E63] transition-colors" />
        </div>
      </button>
    );
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center"
      style={{ backgroundColor: 'rgba(0,0,0,0.45)' }}
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
    >
      <div
        className="w-full bg-white rounded-t-3xl flex flex-col"
        style={{ maxHeight: '88vh', animation: 'slideUp 0.25s ease-out' }}
      >
        <div className="flex items-center justify-between px-5 pt-5 pb-4 border-b border-gray-100">
          <h2 className="text-xl font-bold text-gray-900">New Message</h2>
          <button
            onClick={onClose}
            className="w-9 h-9 rounded-full bg-gray-100 flex items-center justify-center hover:bg-gray-200 transition-colors"
          >
            <X className="w-5 h-5 text-gray-600" />
          </button>
        </div>

        <div className="flex gap-1 px-5 pt-4 pb-3">
          <button
            onClick={() => { setTab('friends'); setSearchQuery(''); setSearchResults([]); }}
            className={`flex-1 py-2.5 rounded-xl text-sm font-semibold transition-all ${
              tab === 'friends'
                ? 'bg-[#E91E63] text-white shadow-md shadow-[#E91E63]/20'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Friends
          </button>
          <button
            onClick={() => { setTab('search'); setSearchQuery(''); setSearchResults([]); }}
            className={`flex-1 py-2.5 rounded-xl text-sm font-semibold transition-all ${
              tab === 'search'
                ? 'bg-[#E91E63] text-white shadow-md shadow-[#E91E63]/20'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Search People
          </button>
        </div>

        {tab === 'friends' ? (
          <>
            {friends.length > 4 && (
              <div className="px-4 pb-3">
                <div className="relative">
                  <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                  <input
                    type="text"
                    placeholder="Filter friends..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full pl-10 pr-4 py-2.5 bg-gray-100 rounded-xl text-sm border border-transparent focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all"
                  />
                </div>
              </div>
            )}

            <div className="flex-1 overflow-y-auto">
              {loadingFriends ? (
                <div className="flex flex-col items-center justify-center py-16 gap-3">
                  <div className="w-10 h-10 border-4 border-[#E91E63]/20 border-t-[#E91E63] rounded-full animate-spin" />
                  <p className="text-gray-400 text-sm">Loading friends...</p>
                </div>
              ) : filteredFriends.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-16 px-8 text-center gap-4">
                  <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center">
                    <UserPlus className="w-7 h-7 text-gray-400" />
                  </div>
                  <div>
                    <p className="font-semibold text-gray-800">
                      {searchQuery ? 'No friends match' : 'No friends yet'}
                    </p>
                    <p className="text-sm text-gray-400 mt-1">
                      {searchQuery
                        ? 'Try a different name'
                        : 'Add friends to start chatting, or search for anyone on Barfliz'}
                    </p>
                  </div>
                  {!searchQuery && (
                    <button
                      onClick={() => setTab('search')}
                      className="px-5 py-2.5 bg-[#E91E63] text-white rounded-xl text-sm font-semibold hover:bg-[#C2185B] transition-colors"
                    >
                      Search for people
                    </button>
                  )}
                </div>
              ) : (
                <div className="divide-y divide-gray-50">
                  {filteredFriends.map((f) => renderUser(f, true))}
                </div>
              )}
            </div>
          </>
        ) : (
          <>
            <div className="px-4 pb-3">
              <div className="relative">
                <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                <input
                  ref={inputRef}
                  type="text"
                  placeholder="Search by name..."
                  value={searchQuery}
                  onChange={(e) => handleSearch(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 bg-gray-100 rounded-xl text-sm border border-transparent focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all"
                  autoFocus
                />
                {searching && (
                  <div className="absolute right-3.5 top-1/2 -translate-y-1/2">
                    <div className="w-4 h-4 border-2 border-[#E91E63]/30 border-t-[#E91E63] rounded-full animate-spin" />
                  </div>
                )}
              </div>
            </div>

            <div className="flex-1 overflow-y-auto">
              {!searchQuery ? (
                <div className="flex flex-col items-center justify-center py-16 px-8 text-center gap-3">
                  <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center">
                    <Search className="w-7 h-7 text-gray-400" />
                  </div>
                  <p className="text-gray-500 text-sm">Search for anyone on Barfliz to start a conversation</p>
                </div>
              ) : searchResults.length === 0 && !searching ? (
                <div className="flex flex-col items-center justify-center py-16 px-8 text-center gap-3">
                  <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center">
                    <User className="w-7 h-7 text-gray-400" />
                  </div>
                  <p className="font-semibold text-gray-800">No one found</p>
                  <p className="text-sm text-gray-400">Try a different name</p>
                </div>
              ) : (
                <div className="divide-y divide-gray-50">
                  {searchResults.map((u) => renderUser(u, friends.some((f) => f.id === u.id)))}
                </div>
              )}
            </div>
          </>
        )}

        <div className="pb-safe h-4" />
      </div>

      <style>{`
        @keyframes slideUp {
          from { transform: translateY(100%); opacity: 0; }
          to { transform: translateY(0); opacity: 1; }
        }
      `}</style>
    </div>
  );
}
