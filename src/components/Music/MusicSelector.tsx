import React, { useState, useEffect } from 'react';
import { Search, Music, Play, Loader2 } from 'lucide-react';
import { musicService, Song, MusicPlatform } from '../../services/musicService';

interface MusicSelectorProps {
  onSelectSong: (song: Song) => void;
  selectedSong: Song | null;
}

export function MusicSelector({ onSelectSong, selectedSong }: MusicSelectorProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<Song[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [selectedPlatform, setSelectedPlatform] = useState<MusicPlatform>('spotify');

  useEffect(() => {
    const timeoutId = setTimeout(() => {
      if (searchQuery.trim()) {
        handleSearch();
      } else {
        setSearchResults([]);
      }
    }, 500);

    return () => clearTimeout(timeoutId);
  }, [searchQuery, selectedPlatform]);

  const [searchError, setSearchError] = useState<string | null>(null);

  const handleSearch = async () => {
    setIsSearching(true);
    setSearchError(null);
    try {
      const results = await musicService.searchSongs(searchQuery, selectedPlatform);
      setSearchResults(results);
    } catch (err) {
      setSearchResults([]);
      setSearchError(err instanceof Error ? err.message : 'Search failed. Try again.');
    } finally {
      setIsSearching(false);
    }
  };

  const platforms: { id: MusicPlatform; name: string; color: string }[] = [
    { id: 'spotify', name: 'Spotify', color: 'bg-green-500' },
    { id: 'apple_music', name: 'Apple Music', color: 'bg-pink-500' },
    { id: 'youtube_music', name: 'YouTube', color: 'bg-red-500' }
  ];

  return (
    <div className="space-y-4">
      <div className="flex gap-2 mb-4">
        {platforms.map((platform) => (
          <button
            key={platform.id}
            onClick={() => setSelectedPlatform(platform.id)}
            className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
              selectedPlatform === platform.id
                ? `${platform.color} text-white`
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            {platform.name}
          </button>
        ))}
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
        <input
          type="text"
          placeholder="Search for a song..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        />
      </div>

      {selectedSong && (
        <div className="bg-gradient-to-r from-blue-50 to-purple-50 rounded-xl p-4 border-2 border-blue-200">
          <div className="flex items-center gap-3">
            {selectedSong.albumArtUrl ? (
              <img
                src={selectedSong.albumArtUrl}
                alt={selectedSong.title}
                className="w-16 h-16 rounded-lg object-cover"
              />
            ) : (
              <div className="w-16 h-16 rounded-lg bg-gradient-to-br from-blue-400 to-purple-500 flex items-center justify-center">
                <Music className="w-8 h-8 text-white" />
              </div>
            )}
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-gray-900 truncate">{selectedSong.title}</p>
              <p className="text-sm text-gray-600 truncate">{selectedSong.artist}</p>
            </div>
            <div className="flex items-center gap-2">
              <span className="px-2 py-1 bg-white rounded-full text-xs font-medium text-gray-700 capitalize">
                {selectedSong.platform.replace('_', ' ')}
              </span>
            </div>
          </div>
        </div>
      )}

      {isSearching && (
        <div className="flex items-center justify-center py-8">
          <Loader2 className="w-6 h-6 text-blue-500 animate-spin" />
        </div>
      )}

      {searchError && (
        <div className="text-center py-6 px-4">
          <div className="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center mx-auto mb-3">
            <Music className="w-6 h-6 text-red-400" />
          </div>
          <p className="text-sm text-red-600 font-medium">{searchError}</p>
        </div>
      )}

      {!isSearching && !searchError && searchResults.length > 0 && (
        <div className="space-y-2 max-h-80 overflow-y-auto">
          {searchResults.map((song) => (
            <button
              key={song.id}
              onClick={() => onSelectSong(song)}
              className={`w-full flex items-center gap-3 p-3 rounded-xl transition-all hover:scale-[1.02] ${
                selectedSong?.id === song.id
                  ? 'bg-gradient-to-r from-blue-50 to-purple-50 border-2 border-blue-200'
                  : 'bg-white border border-gray-200 hover:border-blue-300 hover:shadow-md'
              }`}
            >
              {song.albumArtUrl ? (
                <img
                  src={song.albumArtUrl}
                  alt={song.title}
                  className="w-12 h-12 rounded-lg object-cover"
                />
              ) : (
                <div className="w-12 h-12 rounded-lg bg-gradient-to-br from-blue-400 to-purple-500 flex items-center justify-center flex-shrink-0">
                  <Music className="w-6 h-6 text-white" />
                </div>
              )}
              <div className="flex-1 min-w-0 text-left">
                <p className="font-medium text-gray-900 truncate">{song.title}</p>
                <p className="text-sm text-gray-600 truncate">{song.artist}</p>
              </div>
              {song.previewUrl && (
                <div className="flex-shrink-0">
                  <Play className="w-5 h-5 text-gray-400" />
                </div>
              )}
            </button>
          ))}
        </div>
      )}

      {!isSearching && !searchError && searchQuery && searchResults.length === 0 && (
        <div className="text-center py-8">
          <Music className="w-12 h-12 text-gray-300 mx-auto mb-2" />
          <p className="text-gray-500">No songs found</p>
          <p className="text-sm text-gray-400">Try a different search term</p>
        </div>
      )}

      {!searchQuery && searchResults.length === 0 && (
        <div className="text-center py-8">
          <Music className="w-12 h-12 text-gray-300 mx-auto mb-2" />
          <p className="text-gray-500">Search for a song to share</p>
          <p className="text-sm text-gray-400">Choose from {selectedPlatform === 'spotify' ? 'Spotify' : selectedPlatform === 'apple_music' ? 'Apple Music' : 'YouTube Music'}</p>
        </div>
      )}
    </div>
  );
}
