import { useState, useEffect } from 'react';
import { Plus, Trash2, Flag, User, Clock, Heart } from 'lucide-react';
import { roomService, RoomMoment } from '../../services/roomService';

function timeLeft(expiresAt: string): string {
  const diff = new Date(expiresAt).getTime() - Date.now();
  const hours = Math.floor(diff / 3600000);
  const mins = Math.floor((diff % 3600000) / 60000);
  if (hours > 0) return `${hours}h left`;
  if (mins > 0) return `${mins}m left`;
  return 'expiring';
}

function timeAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  const hrs = Math.floor(mins / 60);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  return `${hrs}h ago`;
}

interface MomentsTabProps {
  venueId: string;
  isInsideVenue: boolean;
  currentUserId: string | null;
}

export function MomentsTab({ venueId, isInsideVenue, currentUserId }: MomentsTabProps) {
  const [moments, setMoments] = useState<RoomMoment[]>([]);
  const [loading, setLoading] = useState(true);
  const [showPostForm, setShowPostForm] = useState(false);
  const [caption, setCaption] = useState('');
  const [posting, setPosting] = useState(false);
  const [likedIds, setLikedIds] = useState<Set<string>>(new Set());
  const [likingIds, setLikingIds] = useState<Set<string>>(new Set());

  const load = async () => {
    try {
      const [data, liked] = await Promise.all([
        roomService.getMoments(venueId),
        roomService.getUserMomentLikes(venueId),
      ]);
      setMoments(data);
      setLikedIds(liked);
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    const sub = roomService.subscribeToMoments(venueId, load);
    return () => { sub.unsubscribe(); };
  }, [venueId]);

  const handleLike = async (momentId: string) => {
    if (likingIds.has(momentId)) return;
    setLikingIds((prev) => new Set(prev).add(momentId));
    const wasLiked = likedIds.has(momentId);
    setLikedIds((prev) => {
      const next = new Set(prev);
      wasLiked ? next.delete(momentId) : next.add(momentId);
      return next;
    });
    setMoments((prev) =>
      prev.map((m) =>
        m.id === momentId
          ? { ...m, like_count: m.like_count + (wasLiked ? -1 : 1) }
          : m
      )
    );
    try {
      await roomService.toggleMomentLike(momentId);
    } catch {
      setLikedIds((prev) => {
        const next = new Set(prev);
        wasLiked ? next.add(momentId) : next.delete(momentId);
        return next;
      });
      setMoments((prev) =>
        prev.map((m) =>
          m.id === momentId
            ? { ...m, like_count: m.like_count + (wasLiked ? 1 : -1) }
            : m
        )
      );
    } finally {
      setLikingIds((prev) => { const next = new Set(prev); next.delete(momentId); return next; });
    }
  };

  const handlePost = async () => {
    if (!caption.trim() || posting) return;
    setPosting(true);
    try {
      const moment = await roomService.postMoment(venueId, caption.trim(), 'text');
      setMoments((prev) => [moment, ...prev]);
      setCaption('');
      setShowPostForm(false);
    } catch {
      // silent
    } finally {
      setPosting(false);
    }
  };

  const handleDelete = async (id: string) => {
    await roomService.deleteMoment(id);
    setMoments((prev) => prev.filter((m) => m.id !== id));
  };

  const handleReport = async (id: string) => {
    await roomService.reportMoment(id);
    setMoments((prev) => prev.filter((m) => m.id !== id));
  };

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-amber-400/30 border-t-amber-400 rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {isInsideVenue && (
        <div className="px-4 pt-3 pb-2">
          {!showPostForm ? (
            <button
              onClick={() => setShowPostForm(true)}
              className="w-full flex items-center gap-3 px-4 py-3 bg-gray-800/60 border border-gray-700/50 rounded-2xl hover:border-amber-500/40 transition-all text-gray-400 hover:text-white"
            >
              <Plus className="w-5 h-5" />
              <span className="text-sm">Drop a moment...</span>
            </button>
          ) : (
            <div className="bg-gray-800/80 border border-amber-500/30 rounded-2xl p-4 space-y-3">
              <textarea
                value={caption}
                onChange={(e) => setCaption(e.target.value.slice(0, 150))}
                placeholder="What's happening right now? (expires in 24h)"
                className="w-full bg-transparent text-white placeholder-gray-500 text-sm resize-none focus:outline-none"
                rows={3}
                autoFocus
              />
              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-600">{caption.length}/150</span>
                <div className="flex gap-2">
                  <button
                    onClick={() => { setShowPostForm(false); setCaption(''); }}
                    className="px-3 py-1.5 text-gray-400 text-sm hover:text-white transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handlePost}
                    disabled={!caption.trim() || posting}
                    className="px-4 py-1.5 bg-amber-500 text-black text-sm font-bold rounded-xl disabled:opacity-40 hover:bg-amber-400 transition-colors"
                  >
                    Post
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      <div className="flex-1 overflow-y-auto px-4 pb-4 space-y-3">
        {moments.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 gap-3">
            <div className="text-4xl">📸</div>
            <p className="text-gray-400 font-semibold">No moments yet tonight</p>
            {isInsideVenue && (
              <p className="text-gray-500 text-sm text-center">
                Post a moment — it disappears in 24h
              </p>
            )}
          </div>
        ) : (
          moments.map((m) => {
            const isOwn = m.user_id === currentUserId;
            return (
              <div
                key={m.id}
                className="bg-gray-800/60 border border-gray-700/50 rounded-2xl overflow-hidden hover:border-gray-600 transition-all group"
              >
                {m.media_url && (
                  <img src={m.media_url} alt={m.caption || ''} className="w-full aspect-video object-cover" />
                )}
                <div className="p-3">
                  <div className="flex items-start gap-3">
                    <div className="flex-shrink-0">
                      {m.user?.avatar_url ? (
                        <img src={m.user.avatar_url} alt={m.user.name} className="w-8 h-8 rounded-full object-cover" />
                      ) : (
                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center">
                          <User className="w-4 h-4 text-white" />
                        </div>
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs text-gray-400 font-medium">{m.user?.name || 'Someone'}</p>
                      {m.caption && <p className="text-sm text-white mt-1 leading-snug">{m.caption}</p>}
                      <div className="flex items-center gap-3 mt-2">
                        <span className="text-xs text-gray-600 flex items-center gap-1">
                          <Clock className="w-3 h-3" />
                          {timeAgo(m.created_at)}
                        </span>
                        <span className="text-xs text-amber-600 font-medium">
                          {timeLeft(m.expires_at)}
                        </span>
                        <button
                          onClick={() => handleLike(m.id)}
                          disabled={likingIds.has(m.id)}
                          className={`flex items-center gap-1 text-xs transition-colors ${
                            likedIds.has(m.id)
                              ? 'text-rose-400'
                              : 'text-gray-600 hover:text-rose-400'
                          }`}
                        >
                          <Heart
                            className="w-3 h-3"
                            fill={likedIds.has(m.id) ? 'currentColor' : 'none'}
                          />
                          {m.like_count > 0 && <span>{m.like_count}</span>}
                        </button>
                      </div>
                    </div>
                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      {isOwn ? (
                        <button
                          onClick={() => handleDelete(m.id)}
                          className="w-7 h-7 bg-red-900/60 rounded-lg flex items-center justify-center hover:bg-red-800"
                        >
                          <Trash2 className="w-3 h-3 text-red-400" />
                        </button>
                      ) : (
                        <button
                          onClick={() => handleReport(m.id)}
                          className="w-7 h-7 bg-orange-900/60 rounded-lg flex items-center justify-center hover:bg-orange-800"
                        >
                          <Flag className="w-3 h-3 text-orange-400" />
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
