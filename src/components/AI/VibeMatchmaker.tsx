import { useState, useEffect } from 'react';
import { Sparkles, X, MapPin, Users, Loader2, RefreshCw } from 'lucide-react';
import { aiService } from '../../services/aiService';
import type { VibeRecommendation } from '../../types/ai';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  userLocation: { lat: number; lng: number } | null;
  onVenueSelect?: (venueId: string) => void;
}

const CATEGORY_EMOJI: Record<string, string> = {
  club: '🎵', brewery: '🍺', rooftop: '🌆', lounge: '🍸',
  sports_bar: '🏈', bar: '🍻', restaurant: '🍽️', nightclub: '💃',
  pub: '🍺', wine_bar: '🍷',
};

export function VibeMatchmaker({ isOpen, onClose, userLocation, onVenueSelect }: Props) {
  const [recommendations, setRecommendations] = useState<VibeRecommendation[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen && userLocation) {
      loadRecommendations();
    }
  }, [isOpen, userLocation]);

  const loadRecommendations = async () => {
    if (!userLocation) return;
    setLoading(true);
    setError(null);
    try {
      const res = await aiService.getVibeRecommendations(userLocation.lat, userLocation.lng);
      if (res.success && res.data) {
        setRecommendations(res.data);
      } else {
        setError(res.error || 'Failed to get recommendations');
      }
    } catch {
      setError('Something went wrong');
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[2000] flex flex-col" onClick={onClose}>
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" />
      <div
        className="relative mt-auto bg-white rounded-t-3xl shadow-2xl max-h-[85vh] flex flex-col"
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-gradient-to-br from-purple-500 to-pink-500 rounded-lg flex items-center justify-center">
              <Sparkles className="w-4 h-4 text-white" />
            </div>
            <div>
              <h2 className="font-bold text-gray-900 text-lg">Vibe Matchmaker</h2>
              <p className="text-xs text-gray-500">AI-picked spots for your vibe</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {!loading && (
              <button
                onClick={loadRecommendations}
                className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100"
              >
                <RefreshCw className="w-4 h-4 text-gray-500" />
              </button>
            )}
            <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100">
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto overscroll-contain px-5 py-4 space-y-3">
          {loading && (
            <div className="flex flex-col items-center justify-center py-16 gap-3">
              <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-pink-500 rounded-2xl flex items-center justify-center animate-pulse">
                <Sparkles className="w-6 h-6 text-white" />
              </div>
              <p className="text-sm text-gray-500 font-medium">Reading your vibe...</p>
              <Loader2 className="w-5 h-5 text-[#E91E63] animate-spin" />
            </div>
          )}

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
              {error}
            </div>
          )}

          {!loading && !error && recommendations.length === 0 && (
            <div className="text-center py-12">
              <Sparkles className="w-10 h-10 text-gray-200 mx-auto mb-3" />
              <p className="text-gray-400 font-medium">No recommendations yet</p>
              <p className="text-gray-300 text-sm mt-1">Check in to more venues to unlock personalized picks</p>
            </div>
          )}

          {!loading && recommendations.map((rec, i) => (
            <button
              key={rec.venue_id}
              onClick={() => onVenueSelect?.(rec.venue_id)}
              className="w-full text-left bg-gray-50 hover:bg-gray-100 rounded-2xl p-4 transition-all"
            >
              <div className="flex items-start gap-3">
                <div className="w-11 h-11 bg-white rounded-xl border border-gray-200 flex items-center justify-center flex-shrink-0 text-xl">
                  {CATEGORY_EMOJI[rec.category?.toLowerCase()] || '🍻'}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="font-semibold text-gray-900 truncate">{rec.venue_name}</p>
                    <span className="text-xs bg-purple-100 text-purple-700 px-1.5 py-0.5 rounded-full font-medium flex-shrink-0">
                      {rec.score}%
                    </span>
                  </div>
                  <p className="text-xs text-gray-500 capitalize mt-0.5">{rec.category}</p>
                  <p className="text-sm text-gray-700 mt-2 leading-relaxed">{rec.contextual_message}</p>
                  <div className="flex items-center gap-3 mt-2 text-xs text-gray-400">
                    {rec.current_occupancy > 0 && (
                      <span className="flex items-center gap-1">
                        <Users className="w-3 h-3" /> {rec.current_occupancy} there now
                      </span>
                    )}
                    {rec.address && (
                      <span className="flex items-center gap-1 truncate">
                        <MapPin className="w-3 h-3" /> {rec.address}
                      </span>
                    )}
                  </div>
                </div>
                <div className="w-8 h-8 bg-gradient-to-br from-purple-500 to-pink-500 rounded-full flex items-center justify-center flex-shrink-0 text-white text-xs font-bold">
                  {i + 1}
                </div>
              </div>
            </button>
          ))}
        </div>
        <div className="h-6 flex-shrink-0" />
      </div>
    </div>
  );
}
