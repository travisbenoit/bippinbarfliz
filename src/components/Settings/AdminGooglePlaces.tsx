import { useState, useEffect } from 'react';
import { Link2, CircleAlert as AlertCircle, CircleCheck as CheckCircle, RefreshCw, Zap, MapPin } from 'lucide-react';
import { useNavigate } from 'react-router';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';
import PageHeader from '../Layout/PageHeader';

interface Venue {
  id: string;
  name: string;
  lat: number;
  lng: number;
  place_id: string | null;
}

interface EnrichResult {
  id: string;
  name: string;
  status: 'linked' | 'low_confidence' | 'no_match' | 'error';
  place_id?: string;
  confidence?: number;
  error?: string;
}

interface MarketSummary {
  name: string;
  total: number;
  linked: number;
  unlinked: number;
}

const MARKETS = [
  { name: 'Darwin, NT, Australia', label: 'Darwin', latMin: -12.55, latMax: -12.35, lngMin: 130.75, lngMax: 131.05 },
  { name: 'South Florida, US (Weston / Sunrise / Davie)', label: 'South Florida', latMin: 25.95, latMax: 26.35, lngMin: -80.45, lngMax: -80.10 },
];

export default function AdminGooglePlaces() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [isAdmin, setIsAdmin] = useState(false);
  const [checkingAdmin, setCheckingAdmin] = useState(true);
  const [markets, setMarkets] = useState<MarketSummary[]>([]);
  const [loadingMarkets, setLoadingMarkets] = useState(true);
  const [enriching, setEnriching] = useState<string | null>(null);
  const [enrichResults, setEnrichResults] = useState<{ market: string; results: EnrichResult[]; linked: number; skipped: number; errors: number } | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    checkAdminStatus();
  }, []);

  const checkAdminStatus = async () => {
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) { setIsAdmin(false); setCheckingAdmin(false); return; }

      const { data: profile } = await supabase
        .from('user_profiles')
        .select('is_admin')
        .eq('id', user!.id)
        .maybeSingle();

      const admin = profile?.is_admin || false;
      setIsAdmin(admin);
      setCheckingAdmin(false);
      if (admin) loadMarketSummaries();
    } catch {
      setCheckingAdmin(false);
      setIsAdmin(false);
    }
  };

  const loadMarketSummaries = async () => {
    setLoadingMarkets(true);
    try {
      const { data } = await supabase
        .from('venues')
        .select('id, lat, lng, place_id');

      const summaries: MarketSummary[] = MARKETS.map(m => {
        const inMarket = (data || []).filter((v: any) =>
          v.lat >= m.latMin && v.lat <= m.latMax &&
          v.lng >= m.lngMin && v.lng <= m.lngMax
        );
        const linked = inMarket.filter((v: any) => v.place_id).length;
        return { name: m.name, total: inMarket.length, linked, unlinked: inMarket.length - linked };
      });
      setMarkets(summaries);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load venues');
    } finally {
      setLoadingMarkets(false);
    }
  };

  const handleBulkEnrich = async (marketName: string) => {
    setEnriching(marketName);
    setError(null);
    setEnrichResults(null);

    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/enrich-venues`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${session.access_token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ market: marketName }),
        }
      );

      const result = await response.json();

      if (!response.ok || result.error) {
        throw new Error(result.error || `HTTP ${response.status}`);
      }

      setEnrichResults({ market: marketName, results: result.results || [], linked: result.linked, skipped: result.skipped, errors: result.errors });
      await loadMarketSummaries();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Enrichment failed');
    } finally {
      setEnriching(null);
    }
  };

  const getMarketLabel = (name: string) => MARKETS.find(m => m.name === name)?.label || name;

  if (!user) return null;

  if (checkingAdmin) {
    return (
      <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-20">
        <PageHeader title="Admin" onBack={() => navigate('/settings')} />
        <div className="p-4 flex justify-center py-8">
          <div className="w-8 h-8 border-4 border-[#E91E63] border-t-transparent rounded-full animate-spin" />
        </div>
      </div>
    );
  }

  if (!isAdmin) {
    return (
      <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-20">
        <PageHeader title="Admin" onBack={() => navigate('/settings')} />
        <div className="p-4">
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <p className="text-red-800 font-medium">Access Denied</p>
            <p className="text-red-700 text-sm mt-1">Admin privileges required.</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-20">
      <PageHeader title="Google Places Enrichment" onBack={() => navigate('/settings')} />

      <div className="p-4 space-y-4">
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
            <AlertCircle size={20} className="text-red-600 flex-shrink-0 mt-0.5" />
            <p className="text-red-800">{error}</p>
          </div>
        )}

        <div className="bg-white rounded-2xl shadow-sm p-4">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <Link2 size={20} className="text-[#E91E63]" />
              <h2 className="font-semibold text-gray-900">Markets</h2>
            </div>
            <button
              onClick={loadMarketSummaries}
              disabled={loadingMarkets}
              className="p-1.5 rounded-lg text-gray-500 hover:bg-gray-100 transition-colors"
            >
              <RefreshCw size={16} className={loadingMarkets ? 'animate-spin' : ''} />
            </button>
          </div>

          {loadingMarkets ? (
            <div className="flex justify-center py-6">
              <div className="w-8 h-8 border-4 border-[#E91E63] border-t-transparent rounded-full animate-spin" />
            </div>
          ) : (
            <div className="space-y-3">
              {markets.map(market => {
                const label = getMarketLabel(market.name);
                const isRunning = enriching === market.name;
                const allDone = market.unlinked === 0;

                return (
                  <div key={market.name} className="border border-gray-100 rounded-xl p-4 space-y-3">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <div className="flex items-center gap-2">
                          <MapPin size={16} className="text-[#E91E63]" />
                          <p className="font-semibold text-gray-900">{label}</p>
                        </div>
                        <p className="text-xs text-gray-500 mt-0.5">{market.name}</p>
                      </div>
                      <div className="text-right shrink-0">
                        <p className="text-sm font-medium text-gray-900">{market.linked}/{market.total} linked</p>
                        {market.unlinked > 0 && (
                          <p className="text-xs text-amber-600">{market.unlinked} need enrichment</p>
                        )}
                        {allDone && (
                          <p className="text-xs text-green-600">All linked</p>
                        )}
                      </div>
                    </div>

                    <div className="w-full bg-gray-100 rounded-full h-1.5">
                      <div
                        className="bg-[#E91E63] h-1.5 rounded-full transition-all"
                        style={{ width: market.total > 0 ? `${(market.linked / market.total) * 100}%` : '0%' }}
                      />
                    </div>

                    <button
                      onClick={() => handleBulkEnrich(market.name)}
                      disabled={isRunning || !!enriching}
                      className={`w-full py-2.5 rounded-xl font-medium text-sm flex items-center justify-center gap-2 transition-all ${
                        allDone
                          ? 'bg-gray-100 text-gray-500'
                          : isRunning
                          ? 'bg-[#E91E63]/20 text-[#E91E63]'
                          : 'bg-[#E91E63] text-white hover:bg-[#C2185B]'
                      }`}
                    >
                      {isRunning ? (
                        <>
                          <div className="w-4 h-4 border-2 border-[#E91E63] border-t-transparent rounded-full animate-spin" />
                          Enriching {market.unlinked} venues...
                        </>
                      ) : (
                        <>
                          <Zap size={16} />
                          {allDone ? 'Re-enrich All' : `Enrich ${market.unlinked} Venues`}
                        </>
                      )}
                    </button>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {enrichResults && (
          <div className="bg-white rounded-2xl shadow-sm p-4">
            <div className="flex items-center gap-2 mb-3">
              <CheckCircle size={20} className="text-green-600" />
              <h2 className="font-semibold text-gray-900">
                {getMarketLabel(enrichResults.market)} — Enrichment Complete
              </h2>
            </div>

            <div className="grid grid-cols-3 gap-2 mb-4">
              <div className="bg-green-50 rounded-lg p-3 text-center">
                <p className="text-2xl font-bold text-green-700">{enrichResults.linked}</p>
                <p className="text-xs text-green-600">Linked</p>
              </div>
              <div className="bg-amber-50 rounded-lg p-3 text-center">
                <p className="text-2xl font-bold text-amber-700">{enrichResults.skipped}</p>
                <p className="text-xs text-amber-600">Skipped</p>
              </div>
              <div className="bg-red-50 rounded-lg p-3 text-center">
                <p className="text-2xl font-bold text-red-700">{enrichResults.errors}</p>
                <p className="text-xs text-red-600">Errors</p>
              </div>
            </div>

            <div className="space-y-1.5 max-h-64 overflow-y-auto">
              {enrichResults.results.map(r => (
                <div key={r.id} className="flex items-center justify-between text-sm py-1.5 border-b border-gray-50 last:border-0">
                  <span className="text-gray-700 truncate flex-1 mr-2">{r.name}</span>
                  <span className={`shrink-0 font-medium ${
                    r.status === 'linked' ? 'text-green-600' :
                    r.status === 'error' ? 'text-red-600' :
                    'text-amber-600'
                  }`}>
                    {r.status === 'linked' ? `Linked (${Math.round((r.confidence || 0) * 100)}%)` :
                     r.status === 'low_confidence' ? `Low confidence (${Math.round((r.confidence || 0) * 100)}%)` :
                     r.status === 'no_match' ? 'No match' :
                     'Error'}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <h3 className="font-semibold text-blue-900 mb-2">How it works</h3>
          <ul className="text-sm text-blue-800 space-y-1">
            <li>• Searches Google Places for every unlinked venue by name + coordinates</li>
            <li>• Scores candidates by name similarity (70%) and distance (30%)</li>
            <li>• Auto-links venues above 70% confidence and fetches photos, ratings, hours, and phone numbers</li>
            <li>• Works for all active markets: Darwin and South Florida</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
