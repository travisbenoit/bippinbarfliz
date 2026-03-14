import { useState } from 'react';
import { Zap, MapPin, Users, Music, Sparkles, Loader2, ChevronDown, ChevronUp, MessageCircle } from 'lucide-react';
import { aiService } from '../../services/aiService';
import type { WingmanResult, WingmanInsight } from '../../types/ai';

interface Props {
  targetUserId: string;
  targetName: string;
}

const INSIGHT_ICONS: Record<string, typeof MapPin> = {
  shared_venue: MapPin,
  mutual_friend: Users,
  music_taste: Music,
  vibe_match: Sparkles,
  crossing_paths: Zap,
};

const INSIGHT_COLORS: Record<string, string> = {
  shared_venue: 'bg-blue-100 text-blue-600',
  mutual_friend: 'bg-emerald-100 text-emerald-600',
  music_taste: 'bg-purple-100 text-purple-600',
  vibe_match: 'bg-pink-100 text-pink-600',
  crossing_paths: 'bg-amber-100 text-amber-600',
};

export function WingmanPanel({ targetUserId, targetName }: Props) {
  const [result, setResult] = useState<WingmanResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [expanded, setExpanded] = useState(false);
  const [loaded, setLoaded] = useState(false);

  const loadInsights = async () => {
    if (loaded) {
      setExpanded(!expanded);
      return;
    }
    setLoading(true);
    setError(null);
    setExpanded(true);
    try {
      const res = await aiService.getWingmanInsights(targetUserId);
      if (res.success && res.data) {
        setResult(res.data);
        setLoaded(true);
      } else {
        setError(res.error || 'Failed to load');
      }
    } catch {
      setError('Something went wrong');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="mt-3">
      <button
        onClick={loadInsights}
        className="w-full flex items-center justify-between bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200 rounded-xl px-4 py-3 hover:from-amber-100 hover:to-orange-100 transition-all"
      >
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 bg-gradient-to-br from-amber-400 to-orange-500 rounded-lg flex items-center justify-center">
            <Zap className="w-3.5 h-3.5 text-white" />
          </div>
          <div className="text-left">
            <p className="text-sm font-semibold text-gray-900">Wingman</p>
            <p className="text-[11px] text-gray-500">AI conversation starters</p>
          </div>
        </div>
        {loading ? (
          <Loader2 className="w-4 h-4 text-amber-500 animate-spin" />
        ) : expanded ? (
          <ChevronUp className="w-4 h-4 text-gray-400" />
        ) : (
          <ChevronDown className="w-4 h-4 text-gray-400" />
        )}
      </button>

      {expanded && (
        <div className="mt-2 space-y-2 animate-slide-down">
          {error && (
            <p className="text-xs text-red-500 px-2">{error}</p>
          )}

          {loading && (
            <div className="flex items-center justify-center py-6 gap-2">
              <Loader2 className="w-4 h-4 text-amber-500 animate-spin" />
              <p className="text-xs text-gray-500">Analyzing shared vibes...</p>
            </div>
          )}

          {result && (
            <>
              {/* Insights */}
              {result.insights.length > 0 && (
                <div className="space-y-1.5">
                  {result.insights.map((insight, i) => {
                    const Icon = INSIGHT_ICONS[insight.type] || Sparkles;
                    const colorClass = INSIGHT_COLORS[insight.type] || 'bg-gray-100 text-gray-600';
                    return (
                      <div key={i} className="flex items-start gap-2.5 bg-white border border-gray-100 rounded-xl px-3 py-2.5">
                        <div className={`w-6 h-6 rounded-md flex items-center justify-center flex-shrink-0 ${colorClass}`}>
                          <Icon className="w-3 h-3" />
                        </div>
                        <div>
                          <p className="text-sm text-gray-800">{insight.message}</p>
                          <p className="text-[11px] text-gray-400 mt-0.5">{insight.data_point}</p>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}

              {/* Ice Breakers */}
              {result.ice_breakers.length > 0 && (
                <div className="bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-100 rounded-xl p-3">
                  <div className="flex items-center gap-1.5 mb-2">
                    <MessageCircle className="w-3.5 h-3.5 text-amber-600" />
                    <p className="text-xs font-semibold text-amber-700">Try saying...</p>
                  </div>
                  <div className="space-y-1.5">
                    {result.ice_breakers.map((breaker, i) => (
                      <p key={i} className="text-sm text-gray-700 pl-2 border-l-2 border-amber-300">
                        "{breaker}"
                      </p>
                    ))}
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      )}
    </div>
  );
}
