import { useEffect, useState } from 'react';
import { MapPin, Navigation, Clock, Eye, EyeOff } from 'lucide-react';
import { useGeofenceContext } from '../../geolocation/GeofenceProvider';
import { formatDwellTime, calculateDwellTime } from '../../geolocation/utils';
import { useRegionalSettings } from '../../contexts/RegionalSettingsContext';

export default function GeofenceDebug() {
  const {
    state,
    isLoading,
    error,
    isLocationEnabled,
    startTracking,
    stopTracking,
    addEventListener,
  } = useGeofenceContext();

  const { formatDistance } = useRegionalSettings();

  const [events, setEvents] = useState<string[]>([]);

  useEffect(() => {
    const unsubscribe = addEventListener((event) => {
      const timestamp = new Date().toLocaleTimeString();
      const message = `[${timestamp}] ${event.type}: ${event.venue?.name || 'Unknown'}`;
      setEvents((prev) => [message, ...prev.slice(0, 9)]);
    });

    return unsubscribe;
  }, [addEventListener]);

  const currentDwell = state.currentPresence
    ? calculateDwellTime(state.currentPresence.entered_at)
    : 0;

  return (
    <div className="h-full overflow-y-auto bg-gray-50 pb-20">
      <div className="bg-gradient-to-r from-[#E91E63] to-[#C2185B] p-6 text-white">
        <h1 className="text-2xl font-bold mb-2">Geofence Debug</h1>
        <p className="text-sm opacity-90">Monitor venue tracking in real-time</p>
      </div>

      <div className="p-4 space-y-4">
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4">
            <p className="text-red-800 font-medium">Error</p>
            <p className="text-red-600 text-sm">{error}</p>
          </div>
        )}

        <div className="bg-white rounded-2xl shadow-sm p-5">
          <h2 className="font-bold text-gray-900 mb-4">Tracking Status</h2>

          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Location Permission</span>
              <span
                className={`px-3 py-1 rounded-full text-sm font-medium ${
                  isLocationEnabled
                    ? 'bg-green-100 text-green-700'
                    : 'bg-red-100 text-red-700'
                }`}
              >
                {isLocationEnabled ? 'Granted' : 'Denied'}
              </span>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-gray-600">Tracking Active</span>
              <span
                className={`px-3 py-1 rounded-full text-sm font-medium ${
                  state.isTracking
                    ? 'bg-green-100 text-green-700'
                    : 'bg-gray-100 text-gray-700'
                }`}
              >
                {state.isTracking ? 'Active' : 'Inactive'}
              </span>
            </div>

            {state.lastLocation && (
              <div className="text-sm text-gray-600">
                <p>
                  Last Location: {state.lastLocation.lat.toFixed(6)},{' '}
                  {state.lastLocation.lng.toFixed(6)}
                </p>
                {state.lastUpdateTime && (
                  <p className="text-xs text-gray-400">
                    Updated: {new Date(state.lastUpdateTime).toLocaleTimeString()}
                  </p>
                )}
              </div>
            )}
          </div>

          <div className="flex gap-2 mt-4">
            {!state.isTracking ? (
              <button
                onClick={startTracking}
                disabled={isLoading}
                className="flex-1 bg-[#E91E63] text-white py-2 px-4 rounded-lg font-medium hover:bg-[#C2185B] disabled:opacity-50 flex items-center justify-center gap-2"
              >
                <Navigation size={20} />
                Start Tracking
              </button>
            ) : (
              <button
                onClick={stopTracking}
                className="flex-1 bg-gray-600 text-white py-2 px-4 rounded-lg font-medium hover:bg-gray-700 flex items-center justify-center gap-2"
              >
                Stop Tracking
              </button>
            )}
          </div>
        </div>

        {state.currentVenue && state.currentPresence && (
          <div className="bg-gradient-to-br from-green-50 to-emerald-50 border-2 border-green-200 rounded-2xl shadow-sm p-5">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-12 h-12 bg-green-600 rounded-full flex items-center justify-center">
                <MapPin size={24} className="text-white" />
              </div>
              <div>
                <p className="text-xs text-green-600 font-medium uppercase">
                  Currently at
                </p>
                <p className="text-lg font-bold text-gray-900">
                  {state.currentVenue.name}
                </p>
              </div>
            </div>

            <div className="space-y-2 text-sm">
              <div className="flex items-center gap-2 text-gray-600">
                <Clock size={16} />
                <span>
                  Dwell Time: {formatDwellTime(currentDwell)}
                </span>
              </div>

              <div className="flex items-center gap-2 text-gray-600">
                {state.currentPresence.is_visible_in_venue ? (
                  <>
                    <Eye size={16} />
                    <span>Visible to others</span>
                  </>
                ) : (
                  <>
                    <EyeOff size={16} />
                    <span>Invisible mode</span>
                  </>
                )}
              </div>

              <div className="text-xs text-gray-500 pt-2 border-t border-green-200">
                <p>Venue ID: {state.currentVenue.id}</p>
                <p>Presence ID: {state.currentPresence.id}</p>
                <p>Entry Method: {state.currentPresence.entry_method}</p>
              </div>
            </div>
          </div>
        )}

        {!state.currentVenue && state.isTracking && (
          <div className="bg-gray-100 border-2 border-dashed border-gray-300 rounded-2xl p-5 text-center">
            <MapPin size={48} className="text-gray-400 mx-auto mb-2" />
            <p className="text-gray-600 font-medium">Not in any venue</p>
            <p className="text-sm text-gray-500">
              Move within a venue geofence to check in
            </p>
          </div>
        )}

        <div className="bg-white rounded-2xl shadow-sm p-5">
          <h2 className="font-bold text-gray-900 mb-4">
            Nearby Venues ({state.nearbyVenues.length})
          </h2>

          {state.nearbyVenues.length === 0 ? (
            <p className="text-gray-500 text-center py-4">
              No venues found nearby
            </p>
          ) : (
            <div className="space-y-2">
              {state.nearbyVenues.slice(0, 5).map((venue) => (
                <div
                  key={venue.id}
                  className={`flex items-center justify-between p-3 rounded-lg ${
                    venue.is_in_geofence
                      ? 'bg-green-50 border border-green-200'
                      : 'bg-gray-50 border border-gray-200'
                  }`}
                >
                  <div className="flex-1">
                    <p className="font-medium text-gray-900">{venue.name}</p>
                    <p className="text-xs text-gray-500">
                      {venue.type} • {venue.city}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-medium text-gray-700">
                      {formatDistance(venue.distance_meters)}
                    </p>
                    {venue.is_in_geofence && (
                      <span className="inline-block px-2 py-0.5 bg-green-600 text-white text-xs rounded-full">
                        In Range
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {state.nearbyClusters.length > 0 && (
          <div className="bg-white rounded-2xl shadow-sm p-5">
            <h2 className="font-bold text-gray-900 mb-4">
              Venue Clusters ({state.nearbyClusters.length})
            </h2>

            <div className="space-y-2">
              {state.nearbyClusters.map((cluster) => (
                <div
                  key={cluster.id}
                  className="flex items-center justify-between p-3 rounded-lg bg-purple-50 border border-purple-200"
                >
                  <div>
                    <p className="font-medium text-gray-900">{cluster.name}</p>
                    <p className="text-xs text-gray-500">
                      {cluster.venue_ids.length} venues
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-gray-600">
                      {cluster.radius_meters}m radius
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="bg-white rounded-2xl shadow-sm p-5">
          <h2 className="font-bold text-gray-900 mb-4">Event Log</h2>

          {events.length === 0 ? (
            <p className="text-gray-500 text-center py-4">
              No events yet
            </p>
          ) : (
            <div className="space-y-1">
              {events.map((event, index) => (
                <div
                  key={index}
                  className="text-xs font-mono bg-gray-50 p-2 rounded border border-gray-200"
                >
                  {event}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
