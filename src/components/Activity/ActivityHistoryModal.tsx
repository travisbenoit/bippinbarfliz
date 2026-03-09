import { useState, useEffect } from 'react';
import { X, Trash2, Calendar, MapPin, Loader, AlertCircle, Sparkles } from 'lucide-react';
import { historyService } from '../../services/historyService';

interface ActivityHistoryModalProps {
  isOpen: boolean;
  onClose: () => void;
}

interface ActivityRecord {
  id: string;
  activity_type: string;
  activity_data: Record<string, any>;
  location_lat: number | null;
  location_lng: number | null;
  created_at: string;
  venue?: {
    name: string;
    address: string;
  } | null;
  related_user?: {
    name: string;
  } | null;
}

const ACTIVITY_ICONS: Record<string, string> = {
  uber_ride: '🚗',
  venue_visit: '🏢',
  swarm_join: '✨',
  gift_sent: '🎁',
  message_sent: '💬',
  music_shared: '🎵',
  other: '📝',
};

const ACTIVITY_LABELS: Record<string, string> = {
  uber_ride: 'Uber Ride',
  venue_visit: 'Venue Visit',
  swarm_join: 'Swarm Join',
  gift_sent: 'Gift Sent',
  message_sent: 'Message Sent',
  music_shared: 'Music Shared',
  other: 'Activity',
};

export default function ActivityHistoryModal({ isOpen, onClose }: ActivityHistoryModalProps) {
  const [activities, setActivities] = useState<ActivityRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      loadActivities();
    }
  }, [isOpen]);

  const loadActivities = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await historyService.getActivityHistory(100);
      setActivities(data as unknown as ActivityRecord[]);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load activities');
      console.error('Error loading activities:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (activityId: string) => {
    try {
      setDeleting(activityId);
      setError(null);
      await historyService.deleteActivity(activityId);
      setActivities(activities.filter(a => a.id !== activityId));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete activity');
      console.error('Error deleting activity:', err);
    } finally {
      setDeleting(null);
    }
  };

  const handleDeleteAll = async () => {
    if (!window.confirm('Are you sure you want to delete all activity history? This cannot be undone.')) {
      return;
    }

    try {
      setLoading(true);
      setError(null);
      await historyService.deleteAllActivity();
      setActivities([]);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete all activities');
      console.error('Error deleting all activities:', err);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;
    return date.toLocaleDateString();
  };

  const getActivityDescription = (activity: ActivityRecord): string => {
    const data = activity.activity_data;
    switch (activity.activity_type) {
      case 'uber_ride':
        return `${data.productType} - ${data.estimate}`;
      case 'venue_visit':
        return activity.venue?.name || 'Venue visit';
      case 'swarm_join':
        return data.swarmName || 'Joined a swarm';
      case 'gift_sent':
        return `Sent ${data.itemName || 'a gift'} to ${activity.related_user?.name || 'someone'}`;
      case 'message_sent':
        return `Messaged ${activity.related_user?.name || 'someone'}`;
      case 'music_shared':
        return `Shared "${data.songTitle || 'a song'}" with ${activity.related_user?.name || 'someone'}`;
      default:
        return 'Activity';
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[80vh] overflow-hidden flex flex-col">
        <div className="p-6 border-b border-gray-200 flex items-center justify-between bg-gradient-to-r from-[#E91E63]/10 to-[#FF6B6B]/10">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#E91E63] to-[#FF6B6B] flex items-center justify-center">
              <Calendar className="w-5 h-5 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-900">Activity History</h2>
              <p className="text-sm text-gray-600">{activities.length} activities</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
          >
            <X className="w-6 h-6 text-gray-600" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-3">
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-3 flex gap-3">
              <AlertCircle size={16} className="text-red-600 flex-shrink-0 mt-0.5" />
              <p className="text-sm text-red-700">{error}</p>
            </div>
          )}

          {loading && activities.length === 0 ? (
            <div className="flex items-center justify-center py-12">
              <Loader size={24} className="text-gray-400 animate-spin" />
            </div>
          ) : activities.length === 0 ? (
            <div className="text-center py-12">
              <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Sparkles className="w-8 h-8 text-gray-400" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900 mb-2">No activity yet</h3>
              <p className="text-gray-500 text-sm">
                Your activities will appear here as you explore
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {activities.map((activity) => (
                <div
                  key={activity.id}
                  className="flex items-start gap-3 p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors group"
                >
                  <div className="text-2xl flex-shrink-0 pt-1">
                    {ACTIVITY_ICONS[activity.activity_type] || '📝'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <p className="font-semibold text-gray-900 text-sm">
                        {ACTIVITY_LABELS[activity.activity_type]}
                      </p>
                      <span className="text-xs text-gray-500">
                        {formatDate(activity.created_at)}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600">
                      {getActivityDescription(activity)}
                    </p>
                    {activity.venue && (
                      <div className="flex items-center gap-1 mt-2 text-xs text-gray-500">
                        <MapPin size={12} />
                        <span>{activity.venue.address}</span>
                      </div>
                    )}
                  </div>
                  <button
                    onClick={() => handleDelete(activity.id)}
                    disabled={deleting === activity.id}
                    className="flex-shrink-0 p-2 opacity-0 group-hover:opacity-100 hover:bg-red-100 rounded-lg transition-all text-red-600 disabled:opacity-50"
                    title="Delete activity"
                  >
                    {deleting === activity.id ? (
                      <Loader size={16} className="animate-spin" />
                    ) : (
                      <Trash2 size={16} />
                    )}
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        {activities.length > 0 && (
          <div className="p-6 border-t border-gray-200 bg-gray-50 flex gap-3">
            <button
              onClick={onClose}
              className="flex-1 px-6 py-3 border border-gray-300 rounded-xl font-medium text-gray-700 hover:bg-gray-100 transition-colors"
            >
              Close
            </button>
            <button
              onClick={handleDeleteAll}
              disabled={loading}
              className="flex-1 px-6 py-3 bg-red-50 border border-red-200 rounded-xl font-medium text-red-700 hover:bg-red-100 disabled:opacity-50 transition-colors"
            >
              Delete All
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
