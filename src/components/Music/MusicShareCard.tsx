import React from 'react';
import { Music, ExternalLink, Play, Heart, Check, User } from 'lucide-react';
import { MusicShare, musicService, Song } from '../../services/musicService';

interface MusicShareCardProps {
  share?: MusicShare;
  isReceived?: boolean;
  song?: Song;
  fromUserName?: string;
  fromUserAvatar?: string;
  message?: string;
  timestamp?: string;
  status?: 'sent' | 'played' | 'saved';
  isInChat?: boolean;
}

export function MusicShareCard({
  share,
  isReceived = false,
  song,
  fromUserName,
  fromUserAvatar,
  message: chatMessage,
  timestamp,
  status: chatStatus,
  isInChat = false
}: MusicShareCardProps) {
  const displaySong = song || (share ? {
    id: share.song_id,
    title: share.song_title,
    artist: share.artist_name,
    albumArtUrl: share.album_art_url,
    previewUrl: share.preview_url,
    externalUrl: share.external_url,
    platform: share.platform
  } as Song : null);

  const displayMessage = chatMessage || share?.message;
  const displayStatus = chatStatus || share?.status;

  if (!displaySong) return null;
  const handlePlay = async () => {
    if (displaySong.externalUrl) {
      window.open(displaySong.externalUrl, '_blank');

      if (share && isReceived && share.status === 'pending') {
        await musicService.updateMusicShareStatus(share.id, 'played');
      }
    }
  };

  const handleSave = async () => {
    if (share && isReceived && share.status !== 'saved') {
      await musicService.updateMusicShareStatus(share.id, 'saved');
    }
  };

  const getPlatformColor = () => {
    switch (displaySong.platform) {
      case 'spotify':
        return 'from-green-500 to-green-600';
      case 'apple_music':
        return 'from-red-500 to-pink-600';
      case 'youtube_music':
        return 'from-red-600 to-red-700';
      default:
        return 'from-blue-500 to-purple-600';
    }
  };

  const formatTime = (ts: string) => {
    const date = new Date(ts);
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);

    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    if (hours < 24) return `${hours}h ago`;
    return date.toLocaleDateString();
  };

  if (isInChat) {
    return (
      <div className="bg-white rounded-2xl shadow-md overflow-hidden border border-gray-100 max-w-sm">
        <div className={`bg-gradient-to-r ${getPlatformColor()} p-3`}>
          <div className="flex items-center gap-2">
            {fromUserAvatar ? (
              <img
                src={fromUserAvatar}
                alt={fromUserName}
                className="w-8 h-8 rounded-full border-2 border-white/30 object-cover"
              />
            ) : (
              <div className="w-8 h-8 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center border-2 border-white/30">
                <User className="w-4 h-4 text-white" />
              </div>
            )}
            <div className="flex-1 min-w-0">
              <p className="text-white font-medium text-sm">{fromUserName} sent a song</p>
              {timestamp && (
                <p className="text-white/80 text-xs">{formatTime(timestamp)}</p>
              )}
            </div>
            <span className="px-2 py-1 rounded-full bg-white/20 backdrop-blur-sm border border-white/30 text-white text-xs font-medium capitalize">
              {displaySong.platform.replace('_', ' ')}
            </span>
          </div>
        </div>

        <div className="p-3">
          <div className="flex gap-3 mb-3">
            {displaySong.albumArtUrl && (
              <img
                src={displaySong.albumArtUrl}
                alt={displaySong.title}
                className="w-16 h-16 rounded-lg object-cover shadow-sm flex-shrink-0"
              />
            )}
            <div className="flex-1 min-w-0">
              <h3 className="font-semibold text-gray-900 text-sm leading-tight mb-0.5 line-clamp-2">
                {displaySong.title}
              </h3>
              <p className="text-gray-600 text-xs">{displaySong.artist}</p>
            </div>
          </div>

          {displayMessage && (
            <div className="bg-gray-50 rounded-lg p-2 mb-3">
              <p className="text-gray-700 text-xs italic">"{displayMessage}"</p>
            </div>
          )}

          <div className="flex gap-2">
            <button
              onClick={handlePlay}
              className={`flex-1 px-3 py-1.5 bg-gradient-to-r ${getPlatformColor()} text-white rounded-lg hover:shadow-md transition-all text-xs font-medium flex items-center justify-center gap-1.5`}
            >
              <Play className="w-3 h-3" />
              Listen
            </button>
            <a
              href={displaySong.externalUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="px-3 py-1.5 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-lg transition-all text-xs font-medium flex items-center justify-center"
            >
              <ExternalLink className="w-3 h-3" />
            </a>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-gradient-to-br from-blue-50 to-purple-50 rounded-2xl p-4 border border-blue-200 shadow-sm hover:shadow-md transition-all">
      <div className="flex items-start gap-3 mb-3">
        {displaySong.albumArtUrl ? (
          <img
            src={displaySong.albumArtUrl}
            alt={displaySong.title}
            className="w-20 h-20 rounded-xl object-cover shadow-md"
          />
        ) : (
          <div className="w-20 h-20 rounded-xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center shadow-md">
            <Music className="w-10 h-10 text-white" />
          </div>
        )}

        <div className="flex-1 min-w-0">
          <p className="font-bold text-gray-900 truncate">{displaySong.title}</p>
          <p className="text-sm text-gray-600 truncate">{displaySong.artist}</p>
          <div className="flex items-center gap-2 mt-1">
            <span className="px-2 py-0.5 bg-white rounded-full text-xs font-medium text-gray-700 capitalize">
              {displaySong.platform.replace('_', ' ')}
            </span>
            {displayStatus === 'saved' && (
              <span className="px-2 py-0.5 bg-green-100 rounded-full text-xs font-medium text-green-700 flex items-center gap-1">
                <Heart className="w-3 h-3 fill-green-700" />
                Saved
              </span>
            )}
            {displayStatus === 'played' && (
              <span className="px-2 py-0.5 bg-blue-100 rounded-full text-xs font-medium text-blue-700 flex items-center gap-1">
                <Check className="w-3 h-3" />
                Played
              </span>
            )}
          </div>
        </div>
      </div>

      {displayMessage && (
        <div className="bg-white/80 rounded-lg p-3 mb-3">
          <p className="text-sm text-gray-700 italic">"{displayMessage}"</p>
        </div>
      )}

      <div className="flex gap-2">
        <button
          onClick={handlePlay}
          className="flex-1 px-4 py-2 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-xl font-medium hover:from-blue-600 hover:to-purple-700 transition-all flex items-center justify-center gap-2 shadow-sm"
        >
          <Play className="w-4 h-4" />
          {displaySong.previewUrl ? 'Preview' : 'Listen'}
        </button>

        {share && isReceived && displayStatus !== 'saved' && (
          <button
            onClick={handleSave}
            className="px-4 py-2 bg-white text-gray-700 rounded-xl font-medium hover:bg-gray-50 transition-all flex items-center justify-center gap-2 shadow-sm border border-gray-200"
          >
            <Heart className="w-4 h-4" />
            Save
          </button>
        )}

        <a
          href={displaySong.externalUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="px-4 py-2 bg-white text-gray-700 rounded-xl font-medium hover:bg-gray-50 transition-all flex items-center justify-center shadow-sm border border-gray-200"
        >
          <ExternalLink className="w-4 h-4" />
        </a>
      </div>

      {share && (
        <p className="text-xs text-gray-500 mt-3">
          {isReceived ? 'Received' : 'Sent'} {new Date(share.created_at).toLocaleDateString()}
        </p>
      )}
    </div>
  );
}
