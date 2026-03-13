import { useState, useEffect } from 'react';
import { ArrowLeft, Download, RefreshCw, MapPin, Loader2, CheckCircle, AlertCircle } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';

interface CityStats {
  city: string | null;
  state: string | null;
  country: string | null;
  venue_count: number;
}

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

export default function AdminOSMImport() {
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState<boolean | null>(null);
  const [stats, setStats] = useState<CityStats[]>([]);
  const [statsLoading, setStatsLoading] = useState(true);
  const [countryFilter, setCountryFilter] = useState<string>('all');
  const [importStatus, setImportStatus] = useState<ImportStatus>('idle');
  const [importResult, setImportResult] = useState<ImportResult | null>(null);
  const [importError, setImportError] = useState<string | null>(null);

  const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
  const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

  const fetchStats = async () => {
    setStatsLoading(true);
    try {
      let url = `${supabaseUrl}/functions/v1/venue-stats-by-city`;
      if (countryFilter !== 'all') {
        url += `?countryCode=${encodeURIComponent(countryFilter)}`;
      }

      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${supabaseAnonKey}`,
        },
      });

      if (!response.ok) throw new Error('Failed to fetch stats');

      const data = await response.json();
      setStats(data);
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setStatsLoading(false);
    }
  };

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (!user) { navigate('/'); return; }
      supabase.from('users').select('is_admin').eq('id', user.id).single().then(({ data }) => {
        if (!data?.is_admin) { navigate('/'); return; }
        setIsAdmin(true);
      });
    });
  }, []);

  useEffect(() => {
    if (isAdmin) fetchStats();
  }, [countryFilter, isAdmin]);

  if (isAdmin === null) return null;

  const triggerImport = async (regionType: 'country' | 'southFlorida', countryCode?: string) => {
    setImportStatus('loading');
    setImportResult(null);
    setImportError(null);

    try {
      const body = regionType === 'country'
        ? { regionType, countryCode }
        : { regionType };

      const response = await fetch(`${supabaseUrl}/functions/v1/import-venues-osm`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${supabaseAnonKey}`,
        },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(errorText);
      }

      const result: ImportResult = await response.json();
      setImportResult(result);
      setImportStatus('success');
      fetchStats();
    } catch (error) {
      setImportError(String(error));
      setImportStatus('error');
    }
  };

  const totalVenues = stats.reduce((sum, s) => sum + s.venue_count, 0);
  const uniqueCountries = [...new Set(stats.map(s => s.country).filter(Boolean))];

  return (
    <div className="min-h-screen bg-gray-900 text-white">
      <div className="sticky top-0 z-10 bg-gray-900/95 backdrop-blur-sm border-b border-gray-800">
        <div className="flex items-center justify-between p-4">
          <div className="flex items-center gap-3">
            <button
              onClick={() => navigate('/settings')}
              className="p-2 hover:bg-gray-800 rounded-lg transition-colors"
            >
              <ArrowLeft className="w-5 h-5" />
            </button>
            <div>
              <h1 className="text-lg font-semibold">OSM Venue Import</h1>
              <p className="text-sm text-gray-400">Admin Tools</p>
            </div>
          </div>
          <button
            onClick={fetchStats}
            disabled={statsLoading}
            className="p-2 hover:bg-gray-800 rounded-lg transition-colors"
          >
            <RefreshCw className={`w-5 h-5 ${statsLoading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="p-4 space-y-6">
        <section className="bg-gray-800 rounded-xl p-4">
          <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
            <Download className="w-5 h-5 text-blue-400" />
            Import Venues from OpenStreetMap
          </h2>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <button
              onClick={() => triggerImport('country', 'AU')}
              disabled={importStatus === 'loading'}
              className="flex items-center justify-center gap-2 bg-emerald-600 hover:bg-emerald-700 disabled:bg-gray-700 disabled:cursor-not-allowed text-white font-medium py-3 px-4 rounded-lg transition-colors"
            >
              {importStatus === 'loading' ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <MapPin className="w-5 h-5" />
              )}
              Import Australia
            </button>

            <button
              onClick={() => triggerImport('southFlorida')}
              disabled={importStatus === 'loading'}
              className="flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-700 disabled:cursor-not-allowed text-white font-medium py-3 px-4 rounded-lg transition-colors"
            >
              {importStatus === 'loading' ? (
                <Loader2 className="w-5 h-5 animate-spin" />
              ) : (
                <MapPin className="w-5 h-5" />
              )}
              Import South Florida
            </button>
          </div>

          {importStatus === 'loading' && (
            <div className="mt-4 p-4 bg-gray-700 rounded-lg">
              <div className="flex items-center gap-3">
                <Loader2 className="w-5 h-5 animate-spin text-blue-400" />
                <span className="text-gray-300">
                  Importing venues... This may take several minutes.
                </span>
              </div>
            </div>
          )}

          {importStatus === 'success' && importResult && (
            <div className="mt-4 p-4 bg-emerald-900/50 border border-emerald-700 rounded-lg">
              <div className="flex items-start gap-3">
                <CheckCircle className="w-5 h-5 text-emerald-400 mt-0.5" />
                <div>
                  <p className="font-medium text-emerald-300">Import Complete</p>
                  <div className="mt-2 text-sm text-gray-300 space-y-1">
                    <p>Region: {importResult.regionType} {importResult.countryCode || ''}</p>
                    <p>Total Processed: {importResult.totalProcessed.toLocaleString()}</p>
                    <p>Inserted: {importResult.insertedCount.toLocaleString()}</p>
                    <p>Updated: {importResult.updatedCount.toLocaleString()}</p>
                    <p>Skipped: {importResult.skippedCount.toLocaleString()}</p>
                    {importResult.errors.length > 0 && (
                      <p className="text-amber-400">
                        Errors: {importResult.errors.length}
                      </p>
                    )}
                  </div>
                </div>
              </div>
            </div>
          )}

          {importStatus === 'error' && importError && (
            <div className="mt-4 p-4 bg-red-900/50 border border-red-700 rounded-lg">
              <div className="flex items-start gap-3">
                <AlertCircle className="w-5 h-5 text-red-400 mt-0.5" />
                <div>
                  <p className="font-medium text-red-300">Import Failed</p>
                  <p className="mt-1 text-sm text-gray-300">{importError}</p>
                </div>
              </div>
            </div>
          )}
        </section>

        <section className="bg-gray-800 rounded-xl p-4">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold flex items-center gap-2">
              <MapPin className="w-5 h-5 text-amber-400" />
              Venue Statistics
            </h2>
            <div className="text-sm text-gray-400">
              {totalVenues.toLocaleString()} total venues
            </div>
          </div>

          <div className="mb-4">
            <select
              value={countryFilter}
              onChange={(e) => setCountryFilter(e.target.value)}
              className="bg-gray-700 border border-gray-600 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="all">All Countries</option>
              <option value="Australia">Australia</option>
              <option value="United States">United States</option>
              {uniqueCountries
                .filter(c => c !== 'Australia' && c !== 'United States')
                .map(country => (
                  <option key={country} value={country!}>
                    {country}
                  </option>
                ))}
            </select>
          </div>

          {statsLoading ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="w-6 h-6 animate-spin text-gray-400" />
            </div>
          ) : stats.length === 0 ? (
            <div className="text-center py-8 text-gray-400">
              No venues found. Run an import to populate data.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-700">
                    <th className="text-left py-2 px-3 font-medium text-gray-400">City</th>
                    <th className="text-left py-2 px-3 font-medium text-gray-400">State</th>
                    <th className="text-left py-2 px-3 font-medium text-gray-400">Country</th>
                    <th className="text-right py-2 px-3 font-medium text-gray-400">Venues</th>
                  </tr>
                </thead>
                <tbody>
                  {stats.slice(0, 50).map((stat, index) => (
                    <tr
                      key={`${stat.city}-${stat.state}-${stat.country}-${index}`}
                      className="border-b border-gray-700/50 hover:bg-gray-700/30"
                    >
                      <td className="py-2 px-3">{stat.city || '—'}</td>
                      <td className="py-2 px-3 text-gray-400">{stat.state || '—'}</td>
                      <td className="py-2 px-3 text-gray-400">{stat.country || '—'}</td>
                      <td className="py-2 px-3 text-right font-medium">
                        {stat.venue_count.toLocaleString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {stats.length > 50 && (
                <p className="text-center text-sm text-gray-400 mt-3">
                  Showing top 50 of {stats.length} cities
                </p>
              )}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}