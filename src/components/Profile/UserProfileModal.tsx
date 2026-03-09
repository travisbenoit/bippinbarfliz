import { useState, useEffect } from 'react';
import { X, MapPin, MessageCircle, UserPlus, User, Sparkles, Wine, Music, Gift, Briefcase, GraduationCap, Instagram, CheckCircle, Heart, MessageSquare, Mic, UserCheck, Clock, Shield, ShieldOff, Check, AlertTriangle } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import type { Database } from '../../lib/database.types';
import { parseDrinkFromStorage } from '../../data/drinkOptions';
import { friendsService, FriendshipStatus } from '../../services/friendsService';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';

type UserProfile = Database['public']['Tables']['users']['Row'];

interface UserProfileModalProps {
  isOpen: boolean;
  onClose: () => void;
  user: UserProfile | null;
  onMessage?: (userId: string) => void;
  onFollow?: (userId: string) => void;
}

export default function UserProfileModal({
  isOpen,
  onClose,
  user,
  onMessage,
  onFollow,
}: UserProfileModalProps) {
  const { user: currentUser } = useAuth();
  const { showSuccess, showError } = useToast();
  const [friendStatus, setFriendStatus] = useState<FriendshipStatus | null>(null);
  const [friendshipId, setFriendshipId] = useState<string | null>(null);
  const [friendshipUserId, setFriendshipUserId] = useState<string | null>(null);
  const [friendLoading, setFriendLoading] = useState(false);
  const [isBlocked, setIsBlocked] = useState(false);
  const [iBlockedThem, setIBlockedThem] = useState(false);
  const [showBlockConfirm, setShowBlockConfirm] = useState(false);

  useEffect(() => {
    if (isOpen && user && currentUser && user.id !== currentUser.id) {
      friendsService.getFriendshipRow(user.id).then((row) => {
        setFriendStatus(row ? row.status : null);
        setFriendshipId(row ? row.id : null);
        setFriendshipUserId(row ? row.user_id : null);
      });
      // Check block state
      friendsService.isBlockedBy(user.id).then(setIsBlocked);
      // Check if I blocked them
      import('../../lib/supabase').then(({ supabase }) => {
        supabase.auth.getUser().then(({ data: { user: me } }) => {
          if (!me) return;
          supabase
            .from('user_blocks')
            .select('id')
            .eq('blocking_user_id', me.id)
            .eq('blocked_user_id', user.id)
            .maybeSingle()
            .then(({ data }) => setIBlockedThem(!!data));
        });
      });
    }
  }, [isOpen, user?.id, currentUser?.id]);

  const handleFriendAction = async () => {
    if (!user || !currentUser) return;
    setFriendLoading(true);
    try {
      if (!friendStatus) {
        await friendsService.sendFriendRequest(user.id);
        setFriendStatus('pending');
        setFriendshipId(null);
        showSuccess('Friend request sent!');
      } else if (friendStatus === 'accepted') {
        if (friendshipId) {
          await friendsService.removeFriend(friendshipId);
          setFriendStatus(null);
          setFriendshipId(null);
          showSuccess('Friend removed.');
        }
      } else if (friendStatus === 'pending') {
        // If I sent the request, cancel it; if they sent it, accept it
        const iSentIt = friendshipUserId === currentUser.id;
        if (friendshipId) {
          if (iSentIt) {
            await friendsService.cancelFriendRequest(friendshipId);
            showSuccess('Request cancelled.');
          } else {
            await friendsService.acceptFriendRequest(friendshipId);
            showSuccess('Friend request accepted!');
          }
          setFriendStatus(iSentIt ? null : 'accepted');
          setFriendshipId(iSentIt ? null : friendshipId);
        }
      }
    } catch (e: any) {
      showError(e?.message || 'Action failed. Please try again.');
    } finally {
      setFriendLoading(false);
    }
  };

  const handleBlockAction = async () => {
    if (!user) return;
    setFriendLoading(true);
    try {
      if (iBlockedThem) {
        await friendsService.unblockUser(user.id);
        setIBlockedThem(false);
        showSuccess('User unblocked.');
      } else {
        await friendsService.blockUser(user.id);
        setIBlockedThem(true);
        setFriendStatus(null);
        setFriendshipId(null);
        showSuccess('User blocked.');
      }
    } catch {
      showError('Action failed.');
    } finally {
      setFriendLoading(false);
      setShowBlockConfirm(false);
    }
  };

  const navigate = useNavigate();

  const handleMessage = () => {
    if (!user) return;
    if (onMessage) {
      onMessage(user.id);
      return;
    }
    onClose();
    navigate('/messages', {
      state: {
        openDmWith: user.id,
        dmUserName: user.name,
        dmUserAvatar: user.avatar_url,
      },
    });
  };

  const getFriendButtonLabel = () => {
    if (isBlocked) return 'Blocked by them';
    if (friendStatus === 'accepted') return 'Friends';
    if (friendStatus === 'pending') {
      const iSentIt = friendshipUserId === currentUser?.id;
      return iSentIt ? 'Pending' : 'Accept';
    }
    return 'Add Friend';
  };

  const getFriendButtonIcon = () => {
    if (isBlocked) return <Shield className="w-5 h-5" />;
    if (friendStatus === 'accepted') return <UserCheck className="w-5 h-5" />;
    if (friendStatus === 'pending') {
      const iSentIt = friendshipUserId === currentUser?.id;
      return iSentIt ? <Clock className="w-5 h-5" /> : <Check className="w-5 h-5" />;
    }
    return <UserPlus className="w-5 h-5" />;
  };

  if (!isOpen || !user) return null;

  const calculateAge = (dob: string) => {
    const birthDate = new Date(dob);
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    return age;
  };

  const age = calculateAge(user.dob);

  const getStatusInfo = (status: UserProfile['tonight_status']) => {
    switch (status) {
      case 'out_now':
        return { label: 'Out Now', color: 'bg-green-500', glow: 'shadow-[0_0_12px_rgba(34,197,94,0.5)]', textColor: 'text-green-400', bgColor: 'bg-green-500/20' };
      case 'going_out_soon':
        return { label: 'Going Out Soon', color: 'bg-amber-500', glow: 'shadow-[0_0_12px_rgba(245,158,11,0.5)]', textColor: 'text-amber-400', bgColor: 'bg-amber-500/20' };
      default:
        return { label: 'Staying In', color: 'bg-gray-500', glow: '', textColor: 'text-gray-400', bgColor: 'bg-gray-500/20' };
    }
  };

  const statusInfo = getStatusInfo(user.tonight_status);

  return (
    <>
    <div className="fixed inset-0 z-[2000] flex items-end sm:items-center justify-center">
      <div className="absolute inset-0 bg-black/70 backdrop-blur-md" onClick={onClose} />
      <div className="relative bg-white rounded-t-3xl sm:rounded-3xl w-full sm:max-w-md max-h-[95vh] overflow-hidden animate-slide-up border-t sm:border border-gray-200 flex flex-col">
        <div className="relative">
          <div className="h-44 bg-gradient-to-br from-[#E91E63] via-[#C2185B] to-[#D81B60] overflow-hidden">
            <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZGVmcz48cGF0dGVybiBpZD0iZG90cyIgd2lkdGg9IjIwIiBoZWlnaHQ9IjIwIiBwYXR0ZXJuVW5pdHM9InVzZXJTcGFjZU9uVXNlIj48Y2lyY2xlIGN4PSIxMCIgY3k9IjEwIiByPSIxLjUiIGZpbGw9InJnYmEoMjU1LDI1NSwyNTUsMC4xKSIvPjwvcGF0dGVybj48L2RlZnM+PHJlY3Qgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgZmlsbD0idXJsKCNkb3RzKSIvPjwvc3ZnPg==')] opacity-50" />
          </div>
          <button
            onClick={onClose}
            className="absolute top-4 right-4 p-2 bg-black/20 backdrop-blur rounded-full hover:bg-black/30 transition-colors"
          >
            <X className="w-5 h-5 text-white" />
          </button>
          <div className="absolute -bottom-16 left-1/2 -translate-x-1/2">
            <div className="relative">
              <div className="w-32 h-32 rounded-full border-4 border-white shadow-xl overflow-hidden bg-gradient-to-br from-[#E91E63] to-[#C2185B]">
                {user.avatar_url ? (
                  <img src={user.avatar_url} alt={user.name} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <User className="w-12 h-12 text-white" />
                  </div>
                )}
              </div>
              <div className={`absolute bottom-2 right-2 w-7 h-7 ${statusInfo.color} ${statusInfo.glow} rounded-full border-3 border-white`} />
              {user.verified_profile && (
                <div className="absolute top-0 right-0 bg-blue-500 rounded-full p-1">
                  <CheckCircle className="w-5 h-5 text-white" />
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="pt-20 pb-6 px-6 space-y-5 overflow-y-auto flex-1 scrollbar-hide">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-gray-900">{user.name}</h2>
            <p className="text-gray-500">{age} years old</p>
            {user.home_city && (
              <p className="text-sm text-gray-400 mt-1 flex items-center justify-center gap-1">
                <MapPin size={14} />
                {user.home_city}
              </p>
            )}
          </div>

          <div className={`flex items-center justify-center gap-2 py-2.5 px-4 rounded-full ${statusInfo.bgColor} mx-auto w-fit`}>
            <div className={`w-2.5 h-2.5 rounded-full ${statusInfo.color} ${statusInfo.glow}`} />
            <span className={`text-sm font-medium ${statusInfo.textColor}`}>{statusInfo.label}</span>
          </div>

          {user.first_drink_on_me && (
            <div className="bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200 rounded-xl p-3 flex items-center justify-center gap-2">
              <Wine className="w-5 h-5 text-amber-600" />
              <span className="text-sm font-medium text-amber-900">First drink on me!</span>
            </div>
          )}

          {user.bio && (
            <div className="bg-gray-50 rounded-2xl p-4 border border-gray-100">
              <p className="text-gray-700 text-center leading-relaxed">{user.bio}</p>
            </div>
          )}

          {user.looking_for && (
            <div className="bg-gradient-to-br from-[#E91E63]/10 to-[#C2185B]/10 rounded-2xl p-4 border border-[#E91E63]/20">
              <div className="flex items-center gap-2 mb-2">
                <Heart className="w-4 h-4 text-[#E91E63]" />
                <h3 className="text-xs font-semibold text-gray-600 uppercase tracking-wider">Looking For</h3>
              </div>
              <p className="text-gray-800 font-medium">{user.looking_for}</p>
            </div>
          )}

          {user.occupation && (
            <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
              <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                <Briefcase className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Occupation</p>
                <p className="text-sm text-gray-900 font-semibold">{user.occupation}</p>
              </div>
            </div>
          )}

          {user.education && (
            <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
              <div className="w-10 h-10 bg-purple-100 rounded-full flex items-center justify-center">
                <GraduationCap className="w-5 h-5 text-purple-600" />
              </div>
              <div>
                <p className="text-xs text-gray-500 font-medium">Education</p>
                <p className="text-sm text-gray-900 font-semibold">{user.education}</p>
              </div>
            </div>
          )}

          {user.vibe_tags && user.vibe_tags.length > 0 && (
            <div>
              <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3 text-center">Vibes</h3>
              <div className="flex flex-wrap justify-center gap-2">
                {user.vibe_tags.map(vibe => (
                  <span key={vibe} className="px-3 py-1.5 bg-[#E91E63] text-white rounded-full text-xs font-medium">
                    {vibe}
                  </span>
                ))}
              </div>
            </div>
          )}

          {user.favorite_drinks && user.favorite_drinks.length > 0 && (
            <div>
              <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3 text-center flex items-center justify-center gap-1.5">
                <Wine className="w-3.5 h-3.5" />
                Favorite Drinks
              </h3>
              <div className="flex flex-wrap justify-center gap-2">
                {user.favorite_drinks.map(drink => {
                  const parsed = parseDrinkFromStorage(drink);
                  const displayName = parsed.mixedDrink || parsed.category;
                  return (
                    <span
                      key={drink}
                      className="px-3 py-1.5 bg-amber-100 text-amber-800 rounded-full text-xs font-medium"
                    >
                      {displayName}
                    </span>
                  );
                })}
              </div>
            </div>
          )}

          {user.interests && user.interests.length > 0 && (
            <div>
              <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3 text-center flex items-center justify-center gap-1.5">
                <Sparkles className="w-3.5 h-3.5" />
                Interests
              </h3>
              <div className="flex flex-wrap justify-center gap-2">
                {user.interests.map((interest, i) => (
                  <span
                    key={i}
                    className="px-3 py-1.5 bg-blue-50 text-blue-700 rounded-full text-xs font-medium"
                  >
                    {interest}
                  </span>
                ))}
              </div>
            </div>
          )}

          {user.conversation_starters && user.conversation_starters.length > 0 && (
            <div>
              <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3 text-center flex items-center justify-center gap-1.5">
                <MessageSquare className="w-3.5 h-3.5" />
                Love Talking About
              </h3>
              <div className="space-y-2">
                {user.conversation_starters.map((starter, i) => (
                  <div key={i} className="bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200 rounded-xl p-3">
                    <p className="text-sm text-green-900">{starter}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {user.ideal_night_out && (
            <div>
              <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3 text-center flex items-center justify-center gap-1.5">
                <Sparkles className="w-3.5 h-3.5" />
                Ideal Night Out
              </h3>
              <div className="bg-gradient-to-br from-purple-50 to-pink-50 border border-purple-200 rounded-xl p-4">
                <p className="text-sm text-purple-900 leading-relaxed">{user.ideal_night_out}</p>
              </div>
            </div>
          )}

          {user.go_to_karaoke_song && (
            <div>
              <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3 text-center flex items-center justify-center gap-1.5">
                <Mic className="w-3.5 h-3.5" />
                Go-To Karaoke Song
              </h3>
              <div className="bg-gradient-to-r from-pink-50 to-rose-50 border border-pink-200 rounded-xl p-4 text-center">
                <p className="text-lg font-bold text-pink-900">{user.go_to_karaoke_song}</p>
              </div>
            </div>
          )}

          {user.fun_fact && (
            <div>
              <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3 text-center flex items-center justify-center gap-1.5">
                <Sparkles className="w-3.5 h-3.5" />
                Fun Fact
              </h3>
              <div className="bg-gradient-to-r from-yellow-50 to-amber-50 border border-yellow-200 rounded-xl p-4">
                <p className="text-sm text-amber-900 leading-relaxed italic">{user.fun_fact}</p>
              </div>
            </div>
          )}

          {(user.spotify_username || user.instagram_username) && (
            <div>
              <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3 text-center">Connect</h3>
              <div className="flex justify-center gap-3">
                {user.spotify_username && (
                  <a
                    href={`https://open.spotify.com/user/${user.spotify_username}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 px-4 py-2 bg-green-500 text-white rounded-full text-sm font-medium hover:bg-green-600 transition-colors"
                  >
                    <Music className="w-4 h-4" />
                    Spotify
                  </a>
                )}
                {user.instagram_username && (
                  <a
                    href={`https://instagram.com/${user.instagram_username}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-purple-500 to-pink-500 text-white rounded-full text-sm font-medium hover:from-purple-600 hover:to-pink-600 transition-colors"
                  >
                    <Instagram className="w-4 h-4" />
                    Instagram
                  </a>
                )}
              </div>
            </div>
          )}
        </div>

        <div className="p-6 border-t border-gray-200 bg-gray-50 space-y-3 flex-shrink-0">
          <div className="flex gap-3">
            <button
              onClick={handleMessage}
              className="flex-1 bg-[#E91E63] hover:bg-[#C2185B] text-white py-4 rounded-xl font-medium transition-all flex items-center justify-center gap-2 shadow-md"
            >
              <MessageCircle className="w-5 h-5" />
              Message
            </button>
            {currentUser && user.id !== currentUser.id && (
              <button
                onClick={handleFriendAction}
                disabled={friendLoading || isBlocked || iBlockedThem}
                className={`py-4 px-5 rounded-xl font-medium transition-all flex items-center justify-center gap-2 disabled:opacity-60 ${
                  friendStatus === 'accepted'
                    ? 'bg-emerald-50 border-2 border-emerald-400 text-emerald-600'
                    : friendStatus === 'pending'
                    ? (friendshipUserId === currentUser.id
                        ? 'bg-amber-50 border-2 border-amber-300 text-amber-600'
                        : 'bg-[#E91E63] text-white border-2 border-[#E91E63]')
                    : isBlocked || iBlockedThem
                    ? 'bg-gray-100 border-2 border-gray-200 text-gray-400'
                    : 'bg-white hover:bg-gray-50 border-2 border-[#E91E63] text-[#E91E63]'
                }`}
              >
                {getFriendButtonIcon()}
                {getFriendButtonLabel()}
              </button>
            )}
          </div>
          <div className="grid grid-cols-2 gap-3">
            <button
              onClick={handleMessage}
              className="py-3 bg-gradient-to-r from-pink-500 to-rose-600 hover:from-pink-600 hover:to-rose-700 text-white rounded-xl font-medium transition-all flex items-center justify-center gap-2 shadow-md"
            >
              <Gift className="w-4 h-4" />
              Send Gift
            </button>
            <button
              onClick={handleMessage}
              className="py-3 bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white rounded-xl font-medium transition-all flex items-center justify-center gap-2 shadow-md"
            >
              <Music className="w-4 h-4" />
              Send Song
            </button>
          </div>
          {currentUser && user.id !== currentUser.id && (
            <button
              onClick={() => setShowBlockConfirm(true)}
              className={`w-full py-2.5 rounded-xl text-sm font-medium transition-all flex items-center justify-center gap-2 ${
                iBlockedThem
                  ? 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  : 'bg-red-50 text-red-500 hover:bg-red-100'
              }`}
            >
              {iBlockedThem ? <ShieldOff className="w-4 h-4" /> : <Shield className="w-4 h-4" />}
              {iBlockedThem ? 'Unblock User' : 'Block User'}
            </button>
          )}
        </div>
      </div>
    </div>

    {showBlockConfirm && (
      <div className="fixed inset-0 z-[3000] flex items-center justify-center px-4">
        <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setShowBlockConfirm(false)} />
        <div className="relative bg-white rounded-2xl p-6 w-full max-w-sm shadow-2xl">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center flex-shrink-0">
              <Shield size={22} className="text-red-600" />
            </div>
            <div>
              <h3 className="font-bold text-gray-900">
                {iBlockedThem ? `Unblock ${user.name}?` : `Block ${user.name}?`}
              </h3>
              <p className="text-sm text-gray-500">
                {iBlockedThem ? 'They will be able to find and contact you again.' : "They won't be able to find or contact you."}
              </p>
            </div>
          </div>
          {!iBlockedThem && (
            <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 mb-5 flex items-start gap-2">
              <AlertTriangle size={16} className="text-amber-600 mt-0.5 flex-shrink-0" />
              <p className="text-xs text-amber-800">This will remove any friendship and prevent them from sending future requests. You can unblock at any time.</p>
            </div>
          )}
          <div className="flex gap-3 mt-4">
            <button
              onClick={() => setShowBlockConfirm(false)}
              className="flex-1 py-3 rounded-xl border-2 border-gray-200 text-gray-700 font-medium hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleBlockAction}
              disabled={friendLoading}
              className={`flex-1 py-3 rounded-xl font-medium transition-colors disabled:opacity-50 ${
                iBlockedThem ? 'bg-[#E91E63] text-white hover:bg-[#C2185B]' : 'bg-red-600 text-white hover:bg-red-700'
              }`}
            >
              {iBlockedThem ? 'Unblock' : 'Block'}
            </button>
          </div>
        </div>
      </div>
    )}
    </>
  );
}
