import { useState, useEffect, useCallback, useRef } from 'react';
import {
  Camera, Heart, Trash2, Flag, X, ImagePlus, User,
  ChevronLeft, ChevronRight, ZoomIn, Download,
} from 'lucide-react';
import { roomService, WallPhoto } from '../../services/roomService';
import { supabase } from '../../lib/supabase';

// ── helpers ───────────────────────────────────────────────────────────────────

function timeAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  const hrs = Math.floor(mins / 60);
  const days = Math.floor(hrs / 24);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  if (hrs < 24) return `${hrs}h ago`;
  if (days < 7) return `${days}d ago`;
  return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

async function compressWallPhoto(file: File): Promise<File> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const url = URL.createObjectURL(file);
    img.onload = () => {
      URL.revokeObjectURL(url);
      const maxW = 1600;
      const scale = img.width > maxW ? maxW / img.width : 1;
      const canvas = document.createElement('canvas');
      canvas.width = Math.round(img.width * scale);
      canvas.height = Math.round(img.height * scale);
      canvas.getContext('2d')!.drawImage(img, 0, 0, canvas.width, canvas.height);
      canvas.toBlob(
        blob => {
          if (!blob) { reject(new Error('compress failed')); return; }
          resolve(new File([blob], 'wall.jpg', { type: 'image/jpeg' }));
        },
        'image/jpeg',
        0.85,
      );
    };
    img.onerror = reject;
    img.src = url;
  });
}

// ── LightboxViewer ─────────────────────────────────────────────────────────────

interface LightboxProps {
  photos: WallPhoto[];
  startIndex: number;
  likedIds: Set<string>;
  currentUserId: string | null;
  onLike: (id: string) => void;
  onDelete: (id: string) => void;
  onReport: (id: string) => void;
  onClose: () => void;
}

function LightboxViewer({
  photos, startIndex, likedIds, currentUserId,
  onLike, onDelete, onReport, onClose,
}: LightboxProps) {
  const [index, setIndex] = useState(startIndex);
  const photo = photos[index];
  if (!photo) return null;

  const isOwn = photo.user_id === currentUserId;
  const prev = () => setIndex(i => Math.max(0, i - 1));
  const next = () => setIndex(i => Math.min(photos.length - 1, i + 1));

  const handleKey = useCallback((e: KeyboardEvent) => {
    if (e.key === 'ArrowLeft') prev();
    else if (e.key === 'ArrowRight') next();
    else if (e.key === 'Escape') onClose();
  }, [index]);

  useEffect(() => {
    document.addEventListener('keydown', handleKey);
    return () => document.removeEventListener('keydown', handleKey);
  }, [handleKey]);

  return (
    <div
      className="fixed inset-0 z-[5000] bg-black/95 flex flex-col"
      onClick={onClose}
    >
      {/* Top bar */}
      <div
        className="flex items-center justify-between px-4 py-3 flex-shrink-0"
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center gap-3">
          {photo.user?.avatar_url ? (
            <img
              src={photo.user.avatar_url}
              alt={photo.user.name}
              className="w-9 h-9 rounded-full object-cover border-2 border-white/20"
            />
          ) : (
            <div className="w-9 h-9 rounded-full bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center">
              <User className="w-4 h-4 text-white" />
            </div>
          )}
          <div>
            <p className="text-white text-sm font-semibold leading-tight">
              {photo.user?.name || 'Someone'}
            </p>
            <p className="text-white/50 text-xs">{timeAgo(photo.created_at)}</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <span className="text-white/40 text-sm">{index + 1} / {photos.length}</span>
          {isOwn ? (
            <button
              onClick={() => { onDelete(photo.id); if (photos.length <= 1) onClose(); else next(); }}
              className="w-8 h-8 bg-red-900/60 rounded-full flex items-center justify-center hover:bg-red-800 transition-colors"
            >
              <Trash2 className="w-3.5 h-3.5 text-red-400" />
            </button>
          ) : (
            <button
              onClick={() => { onReport(photo.id); next(); }}
              className="w-8 h-8 bg-orange-900/60 rounded-full flex items-center justify-center hover:bg-orange-800 transition-colors"
            >
              <Flag className="w-3.5 h-3.5 text-orange-400" />
            </button>
          )}
          <a
            href={photo.photo_url}
            download
            target="_blank"
            rel="noreferrer"
            className="w-8 h-8 bg-gray-800/80 rounded-full flex items-center justify-center hover:bg-gray-700 transition-colors"
            onClick={e => e.stopPropagation()}
          >
            <Download className="w-3.5 h-3.5 text-white/70" />
          </a>
          <button
            onClick={onClose}
            className="w-8 h-8 bg-gray-800/80 rounded-full flex items-center justify-center hover:bg-gray-700 transition-colors"
          >
            <X className="w-4 h-4 text-white" />
          </button>
        </div>
      </div>

      {/* Image */}
      <div
        className="flex-1 flex items-center justify-center relative overflow-hidden px-2"
        onClick={e => e.stopPropagation()}
      >
        {index > 0 && (
          <button
            onClick={prev}
            className="absolute left-3 z-10 w-10 h-10 bg-black/50 rounded-full flex items-center justify-center hover:bg-black/70 transition-colors"
          >
            <ChevronLeft className="w-6 h-6 text-white" />
          </button>
        )}
        <img
          src={photo.photo_url}
          alt={photo.caption || ''}
          className="max-h-full max-w-full object-contain rounded-lg select-none"
          draggable={false}
        />
        {index < photos.length - 1 && (
          <button
            onClick={next}
            className="absolute right-3 z-10 w-10 h-10 bg-black/50 rounded-full flex items-center justify-center hover:bg-black/70 transition-colors"
          >
            <ChevronRight className="w-6 h-6 text-white" />
          </button>
        )}
      </div>

      {/* Bottom */}
      <div
        className="flex items-center justify-between px-6 py-4 flex-shrink-0"
        onClick={e => e.stopPropagation()}
      >
        <div className="flex-1 pr-4">
          {photo.caption && (
            <p className="text-white/90 text-sm leading-snug">{photo.caption}</p>
          )}
        </div>
        <button
          onClick={() => onLike(photo.id)}
          className={`flex items-center gap-2 px-4 py-2 rounded-full border transition-all ${
            likedIds.has(photo.id)
              ? 'border-rose-400 bg-rose-400/20 text-rose-300'
              : 'border-white/20 bg-white/10 text-white hover:border-white/40'
          }`}
        >
          <Heart className="w-4 h-4" fill={likedIds.has(photo.id) ? 'currentColor' : 'none'} />
          <span className="text-sm font-medium">
            {photo.like_count > 0 ? photo.like_count : 'Like'}
          </span>
        </button>
      </div>

      {/* Thumbnail strip */}
      {photos.length > 1 && (
        <div
          className="flex gap-1.5 px-4 pb-4 overflow-x-auto scrollbar-none flex-shrink-0"
          onClick={e => e.stopPropagation()}
        >
          {photos.map((p, i) => (
            <button
              key={p.id}
              onClick={() => setIndex(i)}
              className={`flex-shrink-0 w-12 h-12 rounded-lg overflow-hidden border-2 transition-all ${
                i === index ? 'border-amber-400 opacity-100' : 'border-transparent opacity-50 hover:opacity-80'
              }`}
            >
              <img src={p.photo_url} alt="" className="w-full h-full object-cover" />
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

// ── PhotoWall ─────────────────────────────────────────────────────────────────

interface PhotoWallProps {
  venueId: string;
  venueName: string;
  isInsideVenue: boolean;
  currentUserId: string | null;
}

export function PhotoWall({ venueId, venueName, isInsideVenue, currentUserId }: PhotoWallProps) {
  const [photos, setPhotos] = useState<WallPhoto[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [likedIds, setLikedIds] = useState<Set<string>>(new Set());
  const [likingIds, setLikingIds] = useState<Set<string>>(new Set());
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);
  const [showUploadForm, setShowUploadForm] = useState(false);
  const [caption, setCaption] = useState('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const load = useCallback(async () => {
    try {
      const [data, liked] = await Promise.all([
        roomService.getWallPhotos(venueId),
        roomService.getUserWallPhotoLikes(venueId),
      ]);
      setPhotos(data);
      setLikedIds(liked);
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  }, [venueId]);

  useEffect(() => {
    load();
    const sub = roomService.subscribeToWallPhotos(venueId, load);
    return () => { sub.unsubscribe(); };
  }, [venueId, load]);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setPreviewUrl(URL.createObjectURL(file));
    setSelectedFile(file);
    setUploadError(null);
    e.target.value = '';
  };

  const clearFile = () => {
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setSelectedFile(null);
    setPreviewUrl(null);
  };

  const handleUpload = async () => {
    if (!selectedFile || !currentUserId || uploading) return;
    setUploading(true);
    setUploadError(null);
    try {
      const compressed = await compressWallPhoto(selectedFile);
      const filePath = `wall/${venueId}/${currentUserId}/${Date.now()}.jpg`;
      const { error: storageErr } = await supabase.storage
        .from('profiles')
        .upload(filePath, compressed, { upsert: false });
      if (storageErr) throw storageErr;
      const photoUrl = supabase.storage.from('profiles').getPublicUrl(filePath).data.publicUrl;
      const photo = await roomService.postWallPhoto(venueId, photoUrl, caption.trim());
      setPhotos(prev => [photo, ...prev]);
      setCaption('');
      clearFile();
      setShowUploadForm(false);
    } catch {
      setUploadError('Upload failed. Please try again.');
    } finally {
      setUploading(false);
    }
  };

  const handleLike = async (photoId: string) => {
    if (likingIds.has(photoId)) return;
    setLikingIds(prev => new Set(prev).add(photoId));
    const wasLiked = likedIds.has(photoId);
    setLikedIds(prev => {
      const next = new Set(prev);
      wasLiked ? next.delete(photoId) : next.add(photoId);
      return next;
    });
    setPhotos(prev =>
      prev.map(p => p.id === photoId
        ? { ...p, like_count: p.like_count + (wasLiked ? -1 : 1) }
        : p
      )
    );
    try {
      await roomService.toggleWallPhotoLike(photoId);
    } catch {
      setLikedIds(prev => {
        const next = new Set(prev);
        wasLiked ? next.add(photoId) : next.delete(photoId);
        return next;
      });
      setPhotos(prev =>
        prev.map(p => p.id === photoId
          ? { ...p, like_count: p.like_count + (wasLiked ? 1 : -1) }
          : p
        )
      );
    } finally {
      setLikingIds(prev => { const next = new Set(prev); next.delete(photoId); return next; });
    }
  };

  const handleDelete = async (id: string) => {
    await roomService.deleteWallPhoto(id).catch(() => {});
    setPhotos(prev => prev.filter(p => p.id !== id));
    if (lightboxIndex !== null) setLightboxIndex(null);
  };

  const handleReport = async (id: string) => {
    await roomService.reportWallPhoto(id).catch(() => {});
    setPhotos(prev => prev.filter(p => p.id !== id));
  };

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-amber-400/30 border-t-amber-400 rounded-full animate-spin" />
      </div>
    );
  }

  const canUpload = isInsideVenue && currentUserId;

  return (
    <>
      {lightboxIndex !== null && (
        <LightboxViewer
          photos={photos}
          startIndex={lightboxIndex}
          likedIds={likedIds}
          currentUserId={currentUserId}
          onLike={handleLike}
          onDelete={handleDelete}
          onReport={handleReport}
          onClose={() => setLightboxIndex(null)}
        />
      )}

      <div className="flex-1 flex flex-col overflow-hidden">

        {/* Header stat strip */}
        {photos.length > 0 && (
          <div className="flex-shrink-0 flex items-center justify-between px-4 pt-3 pb-2 border-b border-gray-800/60">
            <div className="flex items-center gap-2 text-gray-400 text-xs">
              <Camera className="w-3.5 h-3.5 text-amber-500" />
              <span className="font-medium">{photos.length} photo{photos.length !== 1 ? 's' : ''}</span>
              <span className="text-gray-700">\u00b7</span>
              <Heart className="w-3 h-3 text-rose-500" />
              <span>{photos.reduce((s, p) => s + p.like_count, 0)} likes</span>
            </div>
            {canUpload && (
              <button
                onClick={() => setShowUploadForm(v => !v)}
                className="flex items-center gap-1.5 px-3 py-1.5 bg-amber-500 text-black text-xs font-bold rounded-xl hover:bg-amber-400 active:scale-95 transition-all"
              >
                <Camera className="w-3.5 h-3.5" />
                Add Photo
              </button>
            )}
          </div>
        )}

        {/* Upload form */}
        {canUpload && showUploadForm && (
          <div className="flex-shrink-0 px-4 py-3 border-b border-gray-800/60">
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={handleFileSelect}
            />
            <div className="bg-gray-800/80 border border-amber-500/30 rounded-2xl p-4 space-y-3">
              {previewUrl ? (
                <div className="relative rounded-xl overflow-hidden">
                  <img
                    src={previewUrl}
                    alt="preview"
                    className="w-full max-h-52 object-cover rounded-xl"
                  />
                  <button
                    onClick={clearFile}
                    className="absolute top-2 right-2 w-7 h-7 bg-black/70 rounded-full flex items-center justify-center hover:bg-black/90 transition-colors"
                  >
                    <X className="w-3.5 h-3.5 text-white" />
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="w-full h-32 border-2 border-dashed border-gray-600 rounded-xl flex flex-col items-center justify-center gap-2 text-gray-500 hover:border-amber-500/50 hover:text-amber-500/70 transition-all"
                >
                  <ImagePlus className="w-6 h-6" />
                  <span className="text-sm">Tap to select a photo</span>
                </button>
              )}

              <input
                type="text"
                value={caption}
                onChange={e => setCaption(e.target.value.slice(0, 200))}
                placeholder={`e.g. "Friday night at ${venueName}"`}
                className="w-full bg-transparent text-white placeholder-gray-600 text-sm border-b border-gray-700 pb-2 focus:outline-none focus:border-amber-500/50 transition-colors"
              />

              {uploadError && (
                <p className="text-red-400 text-xs">{uploadError}</p>
              )}

              <div className="flex items-center justify-between">
                <span className="text-xs text-gray-600">{caption.length}/200</span>
                <div className="flex gap-2">
                  <button
                    onClick={() => { setShowUploadForm(false); setCaption(''); clearFile(); setUploadError(null); }}
                    className="px-3 py-1.5 text-gray-400 text-sm hover:text-white transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleUpload}
                    disabled={!selectedFile || uploading}
                    className="px-4 py-1.5 bg-amber-500 text-black text-sm font-bold rounded-xl disabled:opacity-40 hover:bg-amber-400 active:scale-95 transition-all"
                  >
                    {uploading ? (
                      <span className="flex items-center gap-1.5">
                        <span className="w-3.5 h-3.5 border-2 border-black/30 border-t-black rounded-full animate-spin" />
                        Uploading
                      </span>
                    ) : 'Post'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Empty state */}
        {photos.length === 0 ? (
          <div className="flex-1 flex flex-col items-center justify-center gap-5 px-8 text-center">
            <div className="w-20 h-20 rounded-3xl bg-gray-800/80 border border-gray-700/60 flex items-center justify-center">
              <Camera className="w-9 h-9 text-gray-600" />
            </div>
            <div>
              <p className="text-white font-semibold text-lg">No photos yet</p>
              <p className="text-gray-500 text-sm mt-1 leading-relaxed">
                {canUpload
                  ? `Be the first to capture tonight at ${venueName}`
                  : `Check in at ${venueName} to post photos`}
              </p>
            </div>
            {canUpload && (
              <button
                onClick={() => setShowUploadForm(true)}
                className="flex items-center gap-2 px-5 py-2.5 bg-amber-500 text-black font-bold rounded-xl hover:bg-amber-400 active:scale-95 transition-all"
              >
                <Camera className="w-4 h-4" />
                Add the first photo
              </button>
            )}
          </div>
        ) : (
          /* Photo grid \u2014 masonry-style two-column layout */
          <div className="flex-1 overflow-y-auto">
            <div className="grid grid-cols-2 gap-0.5 p-0.5">
              {photos.map((photo, i) => (
                <PhotoCard
                  key={photo.id}
                  photo={photo}
                  isOwn={photo.user_id === currentUserId}
                  liked={likedIds.has(photo.id)}
                  liking={likingIds.has(photo.id)}
                  onOpen={() => setLightboxIndex(i)}
                  onLike={() => handleLike(photo.id)}
                  onDelete={() => handleDelete(photo.id)}
                  onReport={() => handleReport(photo.id)}
                />
              ))}
            </div>
            {/* Bottom padding for nav bar */}
            <div className="h-4" />
          </div>
        )}
      </div>
    </>
  );
}

// ── PhotoCard ─────────────────────────────────────────────────────────────────

interface PhotoCardProps {
  photo: WallPhoto;
  isOwn: boolean;
  liked: boolean;
  liking: boolean;
  onOpen: () => void;
  onLike: () => void;
  onDelete: () => void;
  onReport: () => void;
}

function PhotoCard({ photo, isOwn, liked, liking, onOpen, onLike, onDelete, onReport }: PhotoCardProps) {
  const [showActions, setShowActions] = useState(false);

  return (
    <div className="relative group overflow-hidden bg-gray-900 aspect-square">
      <img
        src={photo.photo_url}
        alt={photo.caption || ''}
        className="w-full h-full object-cover cursor-pointer transition-transform duration-300 group-hover:scale-105"
        onClick={onOpen}
        loading="lazy"
      />

      {/* Gradient overlay on hover */}
      <div
        className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none"
      />

      {/* Bottom info always visible on mobile, hover on desktop */}
      <div className="absolute bottom-0 left-0 right-0 p-2.5 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
        {photo.caption && (
          <p className="text-white text-xs leading-tight line-clamp-2 mb-1.5 drop-shadow-sm">
            {photo.caption}
          </p>
        )}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-1.5">
            {photo.user?.avatar_url ? (
              <img
                src={photo.user.avatar_url}
                alt={photo.user.name}
                className="w-5 h-5 rounded-full object-cover border border-white/30"
              />
            ) : (
              <div className="w-5 h-5 rounded-full bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center">
                <User className="w-2.5 h-2.5 text-white" />
              </div>
            )}
            <span className="text-white/80 text-xs font-medium truncate max-w-[70px]">
              {photo.user?.name?.split(' ')[0] || 'Someone'}
            </span>
          </div>
          <div className="flex items-center gap-1">
            <button
              onClick={e => { e.stopPropagation(); onLike(); }}
              disabled={liking}
              className={`flex items-center gap-0.5 transition-all active:scale-90 ${
                liked ? 'text-rose-400' : 'text-white/70 hover:text-rose-400'
              }`}
            >
              <Heart className="w-4 h-4" fill={liked ? 'currentColor' : 'none'} />
              {photo.like_count > 0 && (
                <span className="text-xs">{photo.like_count}</span>
              )}
            </button>
          </div>
        </div>
      </div>

      {/* Open lightbox icon */}
      <div className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity">
        <button
          onClick={e => { e.stopPropagation(); onOpen(); }}
          className="w-7 h-7 bg-black/50 rounded-full flex items-center justify-center hover:bg-black/70"
        >
          <ZoomIn className="w-3.5 h-3.5 text-white" />
        </button>
      </div>

      {/* Owner/report actions */}
      <div className="absolute top-2 left-2 opacity-0 group-hover:opacity-100 transition-opacity">
        {showActions ? (
          <div className="flex gap-1">
            {isOwn ? (
              <button
                onClick={e => { e.stopPropagation(); onDelete(); setShowActions(false); }}
                className="w-7 h-7 bg-red-900/80 rounded-full flex items-center justify-center hover:bg-red-800"
              >
                <Trash2 className="w-3 h-3 text-red-400" />
              </button>
            ) : (
              <button
                onClick={e => { e.stopPropagation(); onReport(); setShowActions(false); }}
                className="w-7 h-7 bg-orange-900/80 rounded-full flex items-center justify-center hover:bg-orange-800"
              >
                <Flag className="w-3 h-3 text-orange-400" />
              </button>
            )}
            <button
              onClick={e => { e.stopPropagation(); setShowActions(false); }}
              className="w-7 h-7 bg-gray-800/80 rounded-full flex items-center justify-center hover:bg-gray-700"
            >
              <X className="w-3 h-3 text-white" />
            </button>
          </div>
        ) : (
          <button
            onClick={e => { e.stopPropagation(); setShowActions(true); }}
            className="w-7 h-7 bg-black/40 rounded-full flex items-center justify-center hover:bg-black/60"
          >
            <span className="text-white text-xs leading-none">\u2022\u2022\u2022</span>
          </button>
        )}
      </div>
    </div>
  );
}
