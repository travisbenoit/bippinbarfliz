import { useState, useEffect } from 'react';
import { MapPin, RefreshCw, Check, X, Radio } from 'lucide-react';
import { radarService } from '../../services/radarService';
import { supabase } from '../../lib/supabase';
import PageHeader from '../Layout/PageHeader';

export default function RadarSettings() {
  const [isInitialized, setIsInitialized] = useState(false);
  const [isSyncing, setIsSyncing] = useState(false);
  const [syncResult, setSyncResult] = useState<{ success: number; failed: number } | null>(null);
  const [geofencesCount, setGeofencesCount] = useState<number>(0);
  const [venuesCount, setVenuesCount] = useState<number>(0);
  const [isTracking, setIsTracking] = useState(false);
  const [currentLocation, setCurrentLocation] = useState<{ lat: number; lng: number } | null>(null);

  useEffect(() => {
    checkInitialization();
    loadCounts();
  }, []);

  const checkInitialization = async () => {
    try {
      await radarService.initialize();
      setIsInitialized(radarService.isInitialized());
    } catch (error) {
      console.error('Failed to initialize Radar:', error);
    }
  };

  const loadCounts = async () => {
    try {
      const { count: vCount } = await supabase
        .from('venues')
        .select('*', { count: 'exact', head: true })
        .eq('is_active', true);

      setVenuesCount(vCount || 0);

      const geofences = await radarService.getGeofences();
      setGeofencesCount(geofences.length);
    } catch (error) {
      console.error('Failed to load counts:', error);
    }
  };

  const handleSyncVenues = async () => {
    try {
      setIsSyncing(true);
      setSyncResult(null);

      const { data: venues, error } = await supabase
        .from('venues')
        .select('*')
        .eq('is_active', true);

      if (error) throw error;

      const result = await radarService.syncVenuesToRadar(venues || []);
      setSyncResult(result);

      await loadCounts();
    } catch (error) {
      console.error('Failed to sync venues:', error);
    } finally {
      setIsSyncing(false);
    }
  };

  const handleStartTracking = async () => {
    try {
      radarService.startTracking({
        desiredStoppedUpdateInterval: 60,
        desiredMovingUpdateInterval: 30,
      });
      setIsTracking(true);

      const location = await radarService.getUserLocation();
      setCurrentLocation(location);
    } catch (error) {
      console.error('Failed to start tracking:', error);
    }
  };

  const handleStopTracking = () => {
    radarService.stopTracking();
    setIsTracking(false);
  };

  const handleTestLocation = async () => {
    const location = await radarService.getUserLocation();
    setCurrentLocation(location);
  };

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      <PageHeader title="Radar Settings" showBack />

      <div className="px-4 py-6 space-y-6">
        <div className="bg-white rounded-xl p-4 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-blue-50 rounded-lg">
              <Radio className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-900">Radar Status</h3>
              <p className="text-sm text-gray-500">Location tracking service</p>
            </div>
          </div>

          <div className="space-y-3">
            <div className="flex items-center justify-between py-2 border-b border-gray-100">
              <span className="text-sm text-gray-600">Status</span>
              <div className="flex items-center gap-2">
                {isInitialized ? (
                  <>
                    <div className="w-2 h-2 bg-green-500 rounded-full" />
                    <span className="text-sm font-medium text-green-600">Connected</span>
                  </>
                ) : (
                  <>
                    <div className="w-2 h-2 bg-gray-300 rounded-full" />
                    <span className="text-sm font-medium text-gray-600">Disconnected</span>
                  </>
                )}
              </div>
            </div>

            <div className="flex items-center justify-between py-2 border-b border-gray-100">
              <span className="text-sm text-gray-600">Tracking</span>
              <div className="flex items-center gap-2">
                {isTracking ? (
                  <>
                    <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse" />
                    <span className="text-sm font-medium text-blue-600">Active</span>
                  </>
                ) : (
                  <span className="text-sm font-medium text-gray-600">Inactive</span>
                )}
              </div>
            </div>

            <div className="flex items-center justify-between py-2">
              <span className="text-sm text-gray-600">Environment</span>
              <span className="text-sm font-medium text-gray-900">{import.meta.env.RADAR_ENV || 'test'}</span>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl p-4 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-purple-50 rounded-lg">
              <MapPin className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-900">Geofences</h3>
              <p className="text-sm text-gray-500">Sync venues to Radar</p>
            </div>
          </div>

          <div className="space-y-3 mb-4">
            <div className="flex items-center justify-between py-2 border-b border-gray-100">
              <span className="text-sm text-gray-600">Active Venues</span>
              <span className="text-sm font-medium text-gray-900">{venuesCount}</span>
            </div>

            <div className="flex items-center justify-between py-2">
              <span className="text-sm text-gray-600">Radar Geofences</span>
              <span className="text-sm font-medium text-gray-900">{geofencesCount}</span>
            </div>
          </div>

          {syncResult && (
            <div className={`mb-4 p-3 rounded-lg ${
              syncResult.failed === 0 ? 'bg-green-50' : 'bg-yellow-50'
            }`}>
              <div className="flex items-start gap-2">
                {syncResult.failed === 0 ? (
                  <Check className="w-5 h-5 text-green-600 flex-shrink-0 mt-0.5" />
                ) : (
                  <X className="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5" />
                )}
                <div className="text-sm">
                  <p className={`font-medium ${
                    syncResult.failed === 0 ? 'text-green-900' : 'text-yellow-900'
                  }`}>
                    Sync Complete
                  </p>
                  <p className={syncResult.failed === 0 ? 'text-green-700' : 'text-yellow-700'}>
                    {syncResult.success} successful, {syncResult.failed} failed
                  </p>
                </div>
              </div>
            </div>
          )}

          <button
            onClick={handleSyncVenues}
            disabled={isSyncing || !isInitialized}
            className="w-full px-4 py-3 bg-purple-600 text-white rounded-xl font-medium
                     hover:bg-purple-700 active:scale-95 transition-all
                     disabled:opacity-50 disabled:cursor-not-allowed
                     flex items-center justify-center gap-2"
          >
            <RefreshCw className={`w-5 h-5 ${isSyncing ? 'animate-spin' : ''}`} />
            {isSyncing ? 'Syncing...' : 'Sync All Venues'}
          </button>

          <p className="text-xs text-gray-500 mt-2">
            This will create geofences in Radar for all active venues in your database.
          </p>
        </div>

        <div className="bg-white rounded-xl p-4 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-green-50 rounded-lg">
              <MapPin className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-900">Location Tracking</h3>
              <p className="text-sm text-gray-500">Test location services</p>
            </div>
          </div>

          {currentLocation && (
            <div className="mb-4 p-3 bg-gray-50 rounded-lg">
              <p className="text-xs text-gray-500 mb-1">Current Location</p>
              <p className="text-sm font-mono text-gray-900">
                {currentLocation.lat.toFixed(6)}, {currentLocation.lng.toFixed(6)}
              </p>
            </div>
          )}

          <div className="space-y-2">
            {!isTracking ? (
              <button
                onClick={handleStartTracking}
                disabled={!isInitialized}
                className="w-full px-4 py-3 bg-green-600 text-white rounded-xl font-medium
                         hover:bg-green-700 active:scale-95 transition-all
                         disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Start Tracking
              </button>
            ) : (
              <button
                onClick={handleStopTracking}
                className="w-full px-4 py-3 bg-red-600 text-white rounded-xl font-medium
                         hover:bg-red-700 active:scale-95 transition-all"
              >
                Stop Tracking
              </button>
            )}

            <button
              onClick={handleTestLocation}
              disabled={!isInitialized}
              className="w-full px-4 py-3 bg-gray-100 text-gray-900 rounded-xl font-medium
                       hover:bg-gray-200 active:scale-95 transition-all
                       disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Test Location
            </button>
          </div>
        </div>

        <div className="bg-blue-50 rounded-xl p-4">
          <h4 className="font-medium text-blue-900 mb-2">About Radar</h4>
          <p className="text-sm text-blue-700 mb-3">
            Radar provides production-ready geofencing, location tracking, and fraud detection
            for your app. It handles battery optimization and works across web, iOS, and Android.
          </p>
          <a
            href="https://radar.com/dashboard"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm font-medium text-blue-600 hover:text-blue-700"
          >
            Open Radar Dashboard →
          </a>
        </div>
      </div>
    </div>
  );
}
