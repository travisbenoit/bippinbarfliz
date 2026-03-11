import { useState, useEffect, useRef } from 'react';
import { Users, UserCheck, Clock, UserPlus, X, Check, Trash2, MessageCircle, ShieldOff, Shield, ChevronRight, AlertTriangle, Search } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';
import { friendsService, Friendship, FriendUser } from '../../services/friendsService';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import type { Database } from '../../lib/database.types';
import UserProfileModal from '../Profile/UserProfileModal';

type UserProfile = Database['public']['Tables']['users']['Row'];

type Tab = 'friends' | 'requests' | 'sent' | 'blocked';

function StatusDot({ status }: { status: string | null }) {
  if (status === 'out_now') return <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 border border-white flex-shrink-0" />;
  if (status === 'going_out_soon') return <span className="w-2.5 h-2.5 rounded-full bg-amber-400 border border-white flex-shrink-0" />;
  return <span className="w-2.5 h-2.5 rounded-full bg-gray-300 border border-white flex-shrink-0" />;
}

function Avatar({ name, avatarUrl, size = 'md' }: { name: string; avatarUrl: string | null; size?: 'sm' | 'md' | 'lg' }) {
  const sizeClass = size === 'sm' ? 'w-10 h-10 text-base' : size === 'lg' ? 'w-16 h-16 text-2xl' : 'w-12 h-12 text-lg';
  return (
    <div className={`${sizeClass} rounded-full overflow-hidden flex-shrink-0 bg-gradient-to-br from-pink-200 to-orange-200 flex items-center justify-center`}>
      {avatarUrl ? (
        <img src={avatarUrl} alt={name} className="w-full h-full object-cover" />
      ) : (
        <span className="font-bold text-[#E91E63]">{name.charAt(0)}</span>
      )}
    </div>
  );
}

interface BlockedEntry {
  id: string;
  blocked_user_id: string;
  blocked_at: string;
  blocked_user?: FriendUser;
}

export default function FriendsView() {
  const { user } = useAuth();
  const { showSuccess, showError } = useToast();
  const navigate = useNavigate();
  const [tab, setTab] = useState<Tab>('friends');
  const [friends, setFriends] = useState<Friendship[]>([]);
  const [pendingRequests, setPendingRequests] = useState<Friendship[]>([]);
  const [sentRequests, setSentRequests] = useState<Friendship[]>([]);
  const [blockedUsers, setBlockedUsers] = useState<BlockedEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [confirmBlock, setConfirmBlock] = useState<{ friendship: Friendship; user: FriendUser } | null>(null);
  const [selectedProfile, setSelectedProfile] = useState<UserProfile | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<UserProfile[]>([]);
  const [searching, setSearching] = useState(false);
  const [searchSentIds, setSearchSentIds] = useState<Set<string>>(new Set());
  const searchTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const friendIds = new Set([
    ...friends.map(f => friendsService.getFriendProfile(f, user?.id || '')?.id).filter(Boolean),
    ...pendingRequests.map(f => f.requester?.id).filter(Boolean),
    ...sentRequests.map(f => friendsService.getFriendProfile(f, user?.id || '')?.id).filter(Boolean),
  ]);

  const runSearch = async (q: string) => {
    if (!q.trim() || !user) { setSearchResults([]); setSearching(false); return; }
    setSearching(true);
    try {
      const { data } = await supabase
        .from('users')
        .select('*')
        .or(`name.ilike.%${q}%,username.ilike.%${q}%`)
        .neq('id', user.id)
        .limit(20);
      setSearchResults((data || []).filter(u => !friendIds.has(u.id)));
    } catch {
      setSearchResults([]);
    } finally {
      setSearching(false);
    }
  };

  const handleSearchChange = (q: string) => {
    setSearchQuery(q);
    if (searchTimerRef.current) clearTimeout(searchTimerRef.current);
    if (!q.trim()) { setSearchResults([]); setSearching(false); return; }
    setSearching(true);
    searchTimerRef.current = setTimeout(() => runSearch(q), 400);
  };

  const handleSearchAddFriend = async (targetId: string) => {
    setActionLoading(targetId);
    try {
      await friendsService.sendFriendRequest(targetId);
      setSearchSentIds(prev => new Set([...prev, targetId]));
      showSuccess('Friend request sent!');
    } catch {
      showError('Could not send request.');
    } finally {
      setActionLoading(null);
    }
  };

  const handleViewProfile = async (userId: string) => {
    try {
      const { data } = await supabase.from('users').select('*').eq('id', userId).maybeSingle();
      if (data) setSelectedProfile(data);
    } catch {
      showError('Could not load profile.');
    }
  };

  useEffect(() => {
    loadAll();
  }, []);

  const loadAll = async () => {
    setLoading(true);
    try {
      const [f, p, s] = await Promise.all([
        friendsService.getFriends(),
        friendsService.getPendingRequests(),
        friendsService.getSentRequests(),
      ]);
      setFriends(f);
      setPendingRequests(p);
      setSentRequests(s);
      if (p.length > 0 && f.length === 0) {
        setTab('requests');
      }
      await loadBlocked();
    } catch {
      showError('Could not load friends. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const loadBlocked = async () => {
    const { data } = await (async () => {
      const { supabase } = await import('../../lib/supabase');
      return supabase
        .from('user_blocks')
        .select('id, blocked_user_id, blocked_at, blocked_user:users!user_blocks_blocked_user_id_fkey(id, name, avatar_url, tonight_status, home_city, occupation, vibe_tags)')
        .eq('blocking_user_id', (await supabase.auth.getUser()).data.user?.id || '');
    })();
    setBlockedUsers((data || []) as BlockedEntry[]);
  };

  const handleAccept = async (friendship: Friendship) => {
    setActionLoading(friendship.id);
    try {
      await friendsService.acceptFriendRequest(friendship.id);
      showSuccess('Friend request accepted!');
      await loadAll();
    } catch {
      showError('Could not accept request.');
    } finally {
      setActionLoading(null);
    }
  };

  const handleDecline = async (friendship: Friendship) => {
    setActionLoading(friendship.id);
    try {
      await friendsService.declineFriendRequest(friendship.id);
      showSuccess('Request declined.');
      await loadAll();
    } catch {
      showError('Could not decline request.');
    } finally {
      setActionLoading(null);
    }
  };

  const handleRemove = async (friendship: Friendship) => {
    setActionLoading(friendship.id);
    try {
      await friendsService.removeFriend(friendship.id);
      showSuccess('Friend removed.');
      await loadAll();
    } catch {
      showError('Could not remove friend.');
    } finally {
      setActionLoading(null);
    }
  };

  const handleCancel = async (friendship: Friendship) => {
    setActionLoading(friendship.id);
    try {
      await friendsService.cancelFriendRequest(friendship.id);
      showSuccess('Request cancelled.');
      await loadAll();
    } catch {
      showError('Could not cancel request.');
    } finally {
      setActionLoading(null);
    }
  };

  const handleBlock = async (targetUserId: string, fromFriendship?: Friendship) => {
    setActionLoading(targetUserId);
    setConfirmBlock(null);
    try {
      await friendsService.blockUser(targetUserId);
      showSuccess('User blocked.');
      await loadAll();
    } catch {
      showError('Could not block user.');
    } finally {
      setActionLoading(null);
    }
  };

  const handleUnblock = async (targetUserId: string) => {
    setActionLoading(targetUserId);
    try {
      await friendsService.unblockUser(targetUserId);
      showSuccess('User unblocked.');
      await loadBlocked();
    } catch {
      showError('Could not unblock user.');
    } finally {
      setActionLoading(null);
    }
  };

  const tabs: { id: Tab; label: string; count?: number }[] = [
    { id: 'friends', label: 'Friends', count: friends.length },
    { id: 'requests', label: 'Requests', count: pendingRequests.length },
    { id: 'sent', label: 'Sent' },
    { id: 'blocked', label: 'Blocked', count: blockedUsers.length },
  ];

  return (
    <div className="h-full flex flex-col bg-[#FFF5F0]">
      <div className="bg-white shadow-sm p-5 space-y-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-[#E91E63]/10 flex items-center justify-center">
            <Users size={20} className="text-[#E91E63]" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Friends</h1>
            <p className="text-sm text-gray-500">{friends.length} connection{friends.length !== 1 ? 's' : ''}</p>
          </div>
        </div>

        {/* Search bar */}
        <div className="relative">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
          <input
            type="text"
            placeholder="Search by name or @username..."
            value={searchQuery}
            onChange={(e) => handleSearchChange(e.target.value)}
            className="w-full bg-gray-50 border border-gray-200 rounded-xl pl-9 pr-9 py-2.5 text-sm focus:outline-none focus:border-[#E91E63] focus:bg-white transition-colors"
          />
          {searchQuery && (
            <button
              onClick={() => handleSearchChange('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
            >
              <X size={15} />
            </button>
          )}
        </div>

        {!searchQuery && (
          <div className="flex border-b border-gray-100 overflow-x-auto">
            {tabs.map((t) => (
              <button
                key={t.id}
                onClick={() => setTab(t.id)}
                className={`flex-shrink-0 flex-1 py-2.5 text-sm font-semibold transition-colors relative ${
                  tab === t.id ? 'text-[#E91E63]' : 'text-gray-500'
                }`}
              >
                {t.label}
                {t.count !== undefined && t.count > 0 && (
                  <span className={`ml-1.5 px-1.5 py-0.5 text-xs rounded-full ${
                    t.id === 'requests' ? 'bg-[#E91E63] text-white' :
                    t.id === 'blocked' ? 'bg-gray-500 text-white' :
                    'bg-gray-200 text-gray-600'
                  }`}>
                    {t.count}
                  </span>
                )}
                {tab === t.id && (
                  <span className="absolute bottom-0 left-0 right-0 h-0.5 bg-[#E91E63] rounded-full" />
                )}
              </button>
            ))}
          </div>
        )}
      </div>

      <div className="flex-1 overflow-y-auto">
        {searchQuery ? (
          <div className="p-4 space-y-3">
            {searching ? (
              <div className="flex items-center justify-center py-12">
                <div className="w-8 h-8 border-4 border-[#E91E63]/30 border-t-[#E91E63] rounded-full animate-spin" />
              </div>
            ) : searchResults.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-16 text-center">
                <Search size={36} className="text-gray-200 mb-3" />
                <p className="text-gray-500 font-medium">No users found</p>
                <p className="text-gray-400 text-sm mt-1">Try a different name or @username</p>
              </div>
            ) : (
              <>
                <p className="text-xs text-gray-400 font-medium uppercase tracking-wide px-1">
                  {searchResults.length} result{searchResults.length !== 1 ? 's' : ''}
                </p>
                {searchResults.map((u) => {
                  const isFriend = friendIds.has(u.id);
                  const isPending = searchSentIds.has(u.id);
                  return (
                    <div key={u.id} className="bg-white rounded-2xl p-4 shadow-sm flex items-center gap-3">
                      <button onClick={() => setSelectedProfile(u)} className="flex items-center gap-3 flex-1 min-w-0 text-left">
                        <Avatar name={u.name} avatarUrl={u.avatar_url} />
                        <div className="min-w-0 flex-1">
                          <p className="font-semibold text-gray-900 truncate">{u.name}</p>
                          {u.username && (
                            <p className="text-xs text-gray-400">@{u.username}</p>
                          )}
                          {u.home_city && (
                            <p className="text-xs text-gray-400 truncate">{u.home_city}</p>
                          )}
                        </div>
                      </button>
                      <button
                        onClick={() => !isPending && !isFriend && handleSearchAddFriend(u.id)}
                        disabled={isPending || isFriend || actionLoading === u.id}
                        className={`flex-shrink-0 flex items-center gap-1.5 px-3 py-2 rounded-xl text-sm font-semibold transition-colors disabled:opacity-60 ${
                          isFriend
                            ? 'bg-gray-100 text-gray-400 cursor-default'
                            : isPending
                            ? 'bg-amber-50 text-amber-600 cursor-default'
                            : 'bg-[#E91E63] text-white hover:bg-[#C2185B]'
                        }`}
                      >
                        {isFriend ? (
                          <><UserCheck size={14} /> Friends</>
                        ) : isPending ? (
                          <><Clock size={14} /> Sent</>
                        ) : actionLoading === u.id ? (
                          <div className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                        ) : (
                          <><UserPlus size={14} /> Add</>
                        )}
                      </button>
                    </div>
                  );
                })}
              </>
            )}
          </div>
        ) : loading ? (
          <div className="flex items-center justify-center h-full">
            <div className="w-10 h-10 border-4 border-[#E91E63]/30 border-t-[#E91E63] rounded-full animate-spin" />
          </div>
        ) : (
          <>
            {tab === 'friends' && (
              <FriendsList
                friends={friends}
                currentUserId={user!.id}
                actionLoading={actionLoading}
                onRemove={handleRemove}
                onBlock={(friendship, friendUser) => setConfirmBlock({ friendship, user: friendUser })}
                onMessage={(friendUser) => navigate('/messages', {
                  state: {
                    openDmWith: friendUser.id,
                    dmUserName: friendUser.name,
                    dmUserAvatar: friendUser.avatar_url,
                  },
                })}
                onViewProfile={(friendUser) => handleViewProfile(friendUser.id)}
              />
            )}
            {tab === 'requests' && (
              <RequestsList
                requests={pendingRequests}
                actionLoading={actionLoading}
                onAccept={handleAccept}
                onDecline={handleDecline}
                onBlock={(friendship) => {
                  const requester = friendship.requester;
                  if (requester) setConfirmBlock({ friendship, user: requester });
                }}
              />
            )}
            {tab === 'sent' && (
              <SentList
                sent={sentRequests}
                currentUserId={user!.id}
                actionLoading={actionLoading}
                onCancel={handleCancel}
              />
            )}
            {tab === 'blocked' && (
              <BlockedList
                blocked={blockedUsers}
                actionLoading={actionLoading}
                onUnblock={(id) => handleUnblock(id)}
              />
            )}
          </>
        )}
      </div>

      <UserProfileModal
        isOpen={!!selectedProfile}
        onClose={() => setSelectedProfile(null)}
        user={selectedProfile}
      />

      {confirmBlock && (
        <div className="fixed inset-0 z-[3000] flex items-center justify-center px-4">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setConfirmBlock(null)} />
          <div className="relative bg-white rounded-2xl p-6 w-full max-w-sm shadow-2xl">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center flex-shrink-0">
                <Shield size={22} className="text-red-600" />
              </div>
              <div>
                <h3 className="font-bold text-gray-900">Block {confirmBlock.user.name}?</h3>
                <p className="text-sm text-gray-500">They won't be able to find or contact you.</p>
              </div>
            </div>
            <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 mb-5 flex items-start gap-2">
              <AlertTriangle size={16} className="text-amber-600 mt-0.5 flex-shrink-0" />
              <p className="text-xs text-amber-800">This will remove any existing friendship and prevent them from sending future requests. You can unblock from the Blocked tab.</p>
            </div>
            <div className="flex gap-3">
              <button
                onClick={() => setConfirmBlock(null)}
                className="flex-1 py-3 rounded-xl border-2 border-gray-200 text-gray-700 font-medium hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={() => handleBlock(confirmBlock.user.id, confirmBlock.friendship)}
                disabled={actionLoading === confirmBlock.user.id}
                className="flex-1 py-3 rounded-xl bg-red-600 text-white font-medium hover:bg-red-700 transition-colors disabled:opacity-50"
              >
                Block
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function FriendsList({
  friends,
  currentUserId,
  actionLoading,
  onRemove,
  onBlock,
  onMessage,
  onViewProfile,
}: {
  friends: Friendship[];
  currentUserId: string;
  actionLoading: string | null;
  onRemove: (f: Friendship) => void;
  onBlock: (f: Friendship, u: FriendUser) => void;
  onMessage: (f: any) => void;
  onViewProfile: (u: FriendUser) => void;
}) {
  const [menuOpen, setMenuOpen] = useState<string | null>(null);

  if (friends.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-8 text-center">
        <div className="w-20 h-20 rounded-full bg-[#E91E63]/10 flex items-center justify-center mb-4">
          <UserPlus size={36} className="text-[#E91E63]/40" />
        </div>
        <p className="text-xl font-bold text-gray-900">No friends yet</p>
        <p className="text-gray-500 mt-2 text-sm">Find people on the map or in swarms and send them a friend request!</p>
      </div>
    );
  }

  return (
    <div className="p-4 space-y-3">
      {friends.map((friendship) => {
        const friendUser = friendsService.getFriendProfile(friendship, currentUserId);
        if (!friendUser) return null;
        return (
          <div key={friendship.id} className="bg-white rounded-2xl p-4 shadow-sm flex items-center gap-3">
            <button
              onClick={() => onViewProfile(friendUser)}
              className="flex items-center gap-3 flex-1 min-w-0 text-left"
            >
              <div className="relative">
                <Avatar name={friendUser.name} avatarUrl={friendUser.avatar_url} />
                <div className="absolute -bottom-0.5 -right-0.5">
                  <StatusDot status={friendUser.tonight_status} />
                </div>
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-gray-900 truncate">{friendUser.name}</p>
                {friendUser.occupation && (
                  <p className="text-sm text-gray-500 truncate">{friendUser.occupation}</p>
                )}
                {friendUser.vibe_tags && friendUser.vibe_tags.length > 0 && (
                  <div className="flex gap-1 mt-1 flex-wrap">
                    {friendUser.vibe_tags.slice(0, 2).map((tag) => (
                      <span key={tag} className="text-xs px-2 py-0.5 bg-[#E91E63]/10 text-[#E91E63] rounded-full">
                        {tag}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </button>
            <div className="flex items-center gap-2 flex-shrink-0 relative">
              <button
                onClick={() => onMessage(friendUser)}
                className="p-2 rounded-full bg-[#E91E63]/10 hover:bg-[#E91E63]/20 transition-colors"
              >
                <MessageCircle size={18} className="text-[#E91E63]" />
              </button>
              <button
                onClick={() => setMenuOpen(menuOpen === friendship.id ? null : friendship.id)}
                className="p-2 rounded-full bg-gray-100 hover:bg-gray-200 transition-colors"
              >
                <ChevronRight size={18} className="text-gray-400" />
              </button>
              {menuOpen === friendship.id && (
                <>
                  <div className="fixed inset-0 z-10" onClick={() => setMenuOpen(null)} />
                  <div className="absolute right-0 top-10 z-20 bg-white rounded-xl shadow-xl border border-gray-100 py-1 min-w-[140px]">
                    <button
                      onClick={() => { setMenuOpen(null); onRemove(friendship); }}
                      disabled={actionLoading === friendship.id}
                      className="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                    >
                      <Trash2 size={15} className="text-gray-400" />
                      Remove friend
                    </button>
                    <button
                      onClick={() => { setMenuOpen(null); onBlock(friendship, friendUser); }}
                      className="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-red-600 hover:bg-red-50 transition-colors"
                    >
                      <Shield size={15} className="text-red-400" />
                      Block user
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}

function RequestsList({
  requests,
  actionLoading,
  onAccept,
  onDecline,
  onBlock,
}: {
  requests: Friendship[];
  actionLoading: string | null;
  onAccept: (f: Friendship) => void;
  onDecline: (f: Friendship) => void;
  onBlock: (f: Friendship) => void;
}) {
  if (requests.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-8 text-center">
        <div className="w-20 h-20 rounded-full bg-gray-100 flex items-center justify-center mb-4">
          <UserCheck size={36} className="text-gray-300" />
        </div>
        <p className="text-xl font-bold text-gray-900">No pending requests</p>
        <p className="text-gray-500 mt-2 text-sm">When someone sends you a friend request, it'll appear here.</p>
      </div>
    );
  }

  return (
    <div className="p-4 space-y-3">
      <p className="text-sm text-gray-500 px-1">{requests.length} pending request{requests.length !== 1 ? 's' : ''}</p>
      {requests.map((friendship) => {
        const requester = friendship.requester;
        if (!requester) return null;
        return (
          <div key={friendship.id} className="bg-white rounded-2xl p-4 shadow-sm">
            <div className="flex items-center gap-3 mb-3">
              <Avatar name={requester.name} avatarUrl={requester.avatar_url} />
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-gray-900 truncate">{requester.name}</p>
                {requester.occupation && (
                  <p className="text-sm text-gray-500 truncate">{requester.occupation}</p>
                )}
                {requester.home_city && (
                  <p className="text-xs text-gray-400 truncate">{requester.home_city}</p>
                )}
              </div>
            </div>
            {requester.vibe_tags && requester.vibe_tags.length > 0 && (
              <div className="flex gap-1 mb-3 flex-wrap">
                {requester.vibe_tags.slice(0, 3).map((tag) => (
                  <span key={tag} className="text-xs px-2 py-0.5 bg-[#E91E63]/10 text-[#E91E63] rounded-full">
                    {tag}
                  </span>
                ))}
              </div>
            )}
            <div className="flex gap-2">
              <button
                onClick={() => onAccept(friendship)}
                disabled={actionLoading === friendship.id}
                className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-[#E91E63] text-white rounded-xl font-medium hover:bg-[#C2185B] transition-colors disabled:opacity-50"
              >
                <Check size={16} />
                Accept
              </button>
              <button
                onClick={() => onDecline(friendship)}
                disabled={actionLoading === friendship.id}
                className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-gray-100 text-gray-700 rounded-xl font-medium hover:bg-gray-200 transition-colors disabled:opacity-50"
              >
                <X size={16} />
                Decline
              </button>
              <button
                onClick={() => onBlock(friendship)}
                disabled={actionLoading === friendship.id}
                className="flex items-center justify-center p-2.5 bg-red-50 text-red-500 rounded-xl hover:bg-red-100 transition-colors disabled:opacity-50"
                title="Block user"
              >
                <ShieldOff size={18} />
              </button>
            </div>
          </div>
        );
      })}
    </div>
  );
}

function SentList({
  sent,
  currentUserId,
  actionLoading,
  onCancel,
}: {
  sent: Friendship[];
  currentUserId: string;
  actionLoading: string | null;
  onCancel: (f: Friendship) => void;
}) {
  if (sent.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-8 text-center">
        <div className="w-20 h-20 rounded-full bg-gray-100 flex items-center justify-center mb-4">
          <Clock size={36} className="text-gray-300" />
        </div>
        <p className="text-xl font-bold text-gray-900">No sent requests</p>
        <p className="text-gray-500 mt-2 text-sm">Requests you've sent will appear here until accepted.</p>
      </div>
    );
  }

  return (
    <div className="p-4 space-y-3">
      {sent.map((friendship) => {
        const friendUser = friendship.friend;
        if (!friendUser) return null;
        return (
          <div key={friendship.id} className="bg-white rounded-2xl p-4 shadow-sm flex items-center gap-3">
            <Avatar name={friendUser.name} avatarUrl={friendUser.avatar_url} />
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-gray-900 truncate">{friendUser.name}</p>
              <div className="flex items-center gap-1.5 mt-0.5">
                <Clock size={12} className="text-amber-500" />
                <p className="text-xs text-amber-600 font-medium">Pending</p>
              </div>
            </div>
            <button
              onClick={() => onCancel(friendship)}
              disabled={actionLoading === friendship.id}
              className="px-3 py-1.5 text-sm text-gray-500 border border-gray-300 rounded-full hover:bg-red-50 hover:border-red-300 hover:text-red-600 transition-colors disabled:opacity-50"
            >
              Cancel
            </button>
          </div>
        );
      })}
    </div>
  );
}

function BlockedList({
  blocked,
  actionLoading,
  onUnblock,
}: {
  blocked: BlockedEntry[];
  actionLoading: string | null;
  onUnblock: (userId: string) => void;
}) {
  if (blocked.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-8 text-center">
        <div className="w-20 h-20 rounded-full bg-gray-100 flex items-center justify-center mb-4">
          <ShieldOff size={36} className="text-gray-300" />
        </div>
        <p className="text-xl font-bold text-gray-900">No blocked users</p>
        <p className="text-gray-500 mt-2 text-sm">Users you block will appear here. You can unblock them at any time.</p>
      </div>
    );
  }

  return (
    <div className="p-4 space-y-3">
      <p className="text-sm text-gray-500 px-1">{blocked.length} blocked user{blocked.length !== 1 ? 's' : ''}</p>
      {blocked.map((entry) => {
        const blockedUser = entry.blocked_user;
        const displayName = blockedUser?.name || 'Unknown User';
        return (
          <div key={entry.id} className="bg-white rounded-2xl p-4 shadow-sm flex items-center gap-3">
            <div className="w-12 h-12 rounded-full overflow-hidden flex-shrink-0 bg-gray-200 flex items-center justify-center">
              {blockedUser?.avatar_url ? (
                <img src={blockedUser.avatar_url} alt={displayName} className="w-full h-full object-cover opacity-60" />
              ) : (
                <span className="font-bold text-gray-400 text-lg">{displayName.charAt(0)}</span>
              )}
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-gray-500 truncate">{displayName}</p>
              <p className="text-xs text-gray-400">Blocked</p>
            </div>
            <button
              onClick={() => onUnblock(entry.blocked_user_id)}
              disabled={actionLoading === entry.blocked_user_id}
              className="px-3 py-1.5 text-sm text-[#E91E63] border border-[#E91E63]/30 rounded-full hover:bg-[#E91E63]/10 transition-colors disabled:opacity-50 flex-shrink-0"
            >
              Unblock
            </button>
          </div>
        );
      })}
    </div>
  );
}
