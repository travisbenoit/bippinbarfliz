import { useState, useEffect } from 'react';
import { Loader2, RefreshCw, Download, AlertCircle, CheckCircle } from 'lucide-react';

type VenueCityStat = {
  city: string;
  state: string | null;
  country: string | null;
  venueCount: number;
};

interface ImportResult {
  regionType: string;
  countryCode?: string;
  totalProcessed: number;
  insertedCount: number;
  updatedCount: number;
  skippedCount: number;
  errors: string[];
}

type ImportStatus = 'idle' | 'loading' | 'success' | 'error';

export default function AdminVenues() {
  const [stats, setStats] = useState<VenueCityStat[]>([]);
  const [statsLoading, setStatsLoading] = useState(true);
  const [statsError, setStatsError] = useState<string | null>(null);
  const [countryCodeFilter, setCountryCodeFilter] = useState('');
  const [stateFilter, setStateFilter] = useState('');

  const [australiaImportStatus, setAustraliaImportStatus] = useState<ImportStatus>('idle');
  const [australiaImportResult, setAustraliaImportResult] = useState<ImportResult | null>(null);
  const [australiaImportError, setAustraliaImportError] = useState<string | null>(null);

  const [floridaImportStatus, setFloridaImportStatus] = useState<ImportStatus>('idle');
  const [floridaImportResult, setFloridaImportResult] = useState<ImportResult | null>(null);
  const [floridaImportError, setFloridaImportError] = useState<string | null>(null);

  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

  const fetchStats = async (countryCode?: string, state?: string) => {
    setStatsLoading(true);
    setStatsError(null);

    try {
      const params = new URLSearchParams();
      if (countryCode?.trim()) params.append('countryCode', countryCode.trim());
      if (state?.trim()) params.append('state', state.trim());

      const queryString = params.toString();
      const url = `${supabaseUrl}/functions/v1/venue-stats-by-city${queryString ? `?${queryString}` : ''}`;

      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${supabaseAnonKey}`,
        },
      });

      if (!response.ok) throw new Error('Failed to fetch venue stats');

      const data = await response.json();
      const mapped: VenueCityStat[] = data.map((row: { city: string; state: string | null; country: string | null; venue_count: number }) => ({
        city: row.city,
        state: row.state,
        country: row.country,
        venueCount: row.venue_count,
      }));

      mapped.sort((a, b) => {
        const countryCompare = (a.country || '').localeCompare(b.country || '');
        if (countryCompare !== 0) return countryCompare;
        const stateCompare = (a.state || '').localeCompare(b.state || '');
        if (stateCompare !== 0) return stateCompare;
        return (a.city || '').localeCompare(b.city || '');
      });

      setStats(mapped);
    } catch (error) {
      setStatsError('Failed to load venue stats. Please try again.');
      console.error('Error fetching stats:', error);
    } finally {
      setStatsLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, []);

  const handleRefresh = () => {
    fetchStats(countryCodeFilter, stateFilter);
  };

  const importAustralia = async () => {
    setAustraliaImportStatus('loading');
    setAustraliaImportResult(null);
    setAustraliaImportError(null);

    try {
      const response = await fetch(`${supabaseUrl}/functions/v1/import-venues-osm`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${supabaseAnonKey}`,
        },
        body: JSON.stringify({ regionType: 'country', countryCode: 'AU' }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(errorText);
      }

      const result: ImportResult = await response.json();
      setAustraliaImportResult(result);
      setAustraliaImportStatus('success');
      fetchStats(countryCodeFilter, stateFilter);
    } catch (error) {
      setAustraliaImportError(String(error));
      setAustraliaImportStatus('error');
    }
  };

  const importSouthFlorida = async () => {
    setFloridaImportStatus('loading');
    setFloridaImportResult(null);
    setFloridaImportError(null);

    try {
      const response = await fetch(`${supabaseUrl}/functions/v1/import-venues-osm`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${supabaseAnonKey}`,
        },
        body: JSON.stringify({ regionType: 'southFlorida' }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(errorText);
      }

      const result: ImportResult = await response.json();
      setFloridaImportResult(result);
      setFloridaImportStatus('success');
      fetchStats(countryCodeFilter, stateFilter);
    } catch (error) {
      setFloridaImportError(String(error));
      setFloridaImportStatus('error');
    }
  };

  const totalCities = stats.length;
  const totalVenues = stats.reduce((sum, s) => sum + s.venueCount, 0);

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="max-w-5xl mx-auto px-4 py-8">
        <header className="mb-8">
          <h1 className="text-2xl font-bold text-gray-900">Barfliz Venue Admin</h1>
        </header>

        <div className="bg-white shadow rounded-xl p-6 space-y-4 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
            <Download className="w-5 h-5 text-gray-600" />
            Run Imports
          </h2>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <button
                onClick={importAustralia}
                disabled={australiaImportStatus === 'loading'}
                className="w-full px-4 py-2 rounded-md text-sm font-medium border border-gray-300 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {australiaImportStatus === 'loading' ? (
                  <span className="flex items-center justify-center gap-2">
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Importing...
                  </span>
                ) : (
                  'Import Australia'
                )}
              </button>

              {australiaImportStatus === 'success' && australiaImportResult && (
                <div className="mt-3 p-3 bg-green-50 border border-green-200 rounded-md">
                  <div className="flex items-start gap-2">
                    <CheckCircle className="w-4 h-4 text-green-600 mt-0.5 shrink-0" />
                    <p className="text-sm text-green-800">
                      Imported Australia: {australiaImportResult.totalProcessed.toLocaleString()} processed,{' '}
                      {australiaImportResult.insertedCount.toLocaleString()} inserted,{' '}
                      {australiaImportResult.updatedCount.toLocaleString()} updated,{' '}
                      {australiaImportResult.skippedCount.toLocaleString()} skipped.
                    </p>
                  </div>
                </div>
              )}

              {australiaImportStatus === 'error' && australiaImportError && (
                <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded-md">
                  <div className="flex items-start gap-2">
                    <AlertCircle className="w-4 h-4 text-red-600 mt-0.5 shrink-0" />
                    <p className="text-sm text-red-800">{australiaImportError}</p>
                  </div>
                </div>
              )}
            </div>

            <div>
              <button
                onClick={importSouthFlorida}
                disabled={floridaImportStatus === 'loading'}
                className="w-full px-4 py-2 rounded-md text-sm font-medium border border-gray-300 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {floridaImportStatus === 'loading' ? (
                  <span className="flex items-center justify-center gap-2">
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Importing...
                  </span>
                ) : (
                  'Import South Florida'
                )}
              </button>

              {floridaImportStatus === 'success' && floridaImportResult && (
                <div className="mt-3 p-3 bg-green-50 border border-green-200 rounded-md">
                  <div className="flex items-start gap-2">
                    <CheckCircle className="w-4 h-4 text-green-600 mt-0.5 shrink-0" />
                    <p className="text-sm text-green-800">
                      Imported South Florida: {floridaImportResult.totalProcessed.toLocaleString()} processed,{' '}
                      {floridaImportResult.insertedCount.toLocaleString()} inserted,{' '}
                      {floridaImportResult.updatedCount.toLocaleString()} updated,{' '}
                      {floridaImportResult.skippedCount.toLocaleString()} skipped.
                    </p>
                  </div>
                </div>
              )}

              {floridaImportStatus === 'error' && floridaImportError && (
                <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded-md">
                  <div className="flex items-start gap-2">
                    <AlertCircle className="w-4 h-4 text-red-600 mt-0.5 shrink-0" />
                    <p className="text-sm text-red-800">{floridaImportError}</p>
                  </div>
                </div>
              )}
            </div>
          </div>

          <p className="text-xs text-gray-500">
            Note: Imports use free OpenStreetMap data via Overpass, there are no paid API calls, but large imports can take some time.
          </p>
        </div>

        <div className="bg-white shadow rounded-xl p-6 space-y-4">
          <h2 className="text-lg font-semibold text-gray-900">Venue Counts by City</h2>

          <div>
            <p className="text-sm text-gray-600 mb-2">Filters</p>
            <div className="flex flex-col sm:flex-row gap-3">
              <input
                type="text"
                value={countryCodeFilter}
                onChange={(e) => setCountryCodeFilter(e.target.value)}
                placeholder="Country code, e.g. AU, US"
                className="flex-1 border border-gray-300 rounded-md px-3 py-2 text-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
              <input
                type="text"
                value={stateFilter}
                onChange={(e) => setStateFilter(e.target.value)}
                placeholder="State, e.g. FL"
                className="flex-1 border border-gray-300 rounded-md px-3 py-2 text-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
              <button
                onClick={handleRefresh}
                disabled={statsLoading}
                className="flex items-center justify-center gap-2 px-4 py-2 rounded-md text-sm font-medium border border-gray-300 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <RefreshCw className={`w-4 h-4 ${statsLoading ? 'animate-spin' : ''}`} />
                Refresh
              </button>
            </div>
          </div>

          {statsLoading ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="w-5 h-5 animate-spin text-gray-400 mr-2" />
              <span className="text-gray-500 text-sm">Loading venue stats...</span>
            </div>
          ) : statsError ? (
            <div className="p-4 bg-red-50 border border-red-200 rounded-md">
              <div className="flex items-center gap-2">
                <AlertCircle className="w-5 h-5 text-red-600" />
                <p className="text-red-800 text-sm">{statsError}</p>
              </div>
            </div>
          ) : stats.length === 0 ? (
            <div className="text-center py-12 text-gray-500 text-sm">
              No venues found. Run an import to populate data.
            </div>
          ) : (
            <>
              <div className="flex items-center justify-between text-xs text-gray-500">
                <span>{totalCities.toLocaleString()} cities displayed</span>
                <span>{totalVenues.toLocaleString()} total venues</span>
              </div>

              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead>
                    <tr>
                      <th className="text-left py-3 px-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Country</th>
                      <th className="text-left py-3 px-3 text-xs font-medium text-gray-500 uppercase tracking-wider">State</th>
                      <th className="text-left py-3 px-3 text-xs font-medium text-gray-500 uppercase tracking-wider">City</th>
                      <th className="text-right py-3 px-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Venue Count</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {stats.map((stat, index) => (
                      <tr
                        key={`${stat.country}-${stat.state}-${stat.city}-${index}`}
                        className="hover:bg-gray-50"
                      >
                        <td className="py-3 px-3 text-sm text-gray-900">{stat.country || '-'}</td>
                        <td className="py-3 px-3 text-sm text-gray-600">{stat.state || '-'}</td>
                        <td className="py-3 px-3 text-sm text-gray-900">{stat.city}</td>
                        <td className="py-3 px-3 text-sm text-right font-medium text-gray-900">
                          {stat.venueCount.toLocaleString()}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div className="text-xs text-gray-500 text-center pt-2">
                {totalCities.toLocaleString()} cities | {totalVenues.toLocaleString()} total venues
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
