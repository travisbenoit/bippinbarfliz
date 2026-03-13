import { useState, useEffect } from 'react';
import { Plus, Clock, Sparkles, X, Trash2, MessageCircle, Share2, Receipt, Pencil } from 'lucide-react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';
import { xpService } from '../../services/xpService';
import type { Database } from '../../lib/database.types';
import SwarmDateFilter, { DateFilterOption, filterSwarmsByDate } from './SwarmDateFilter';
import { GroupSplit } from '../Payments/GroupSplit';
import EditSwarm from './EditSwarm';

type Swarm = Database['public']['Tables']['swarms']['Row'];

export default function SwarmsView() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { showSuccess, showError, showInfo } = useToast();
  const [swarms, setSwarms] = useState<Swarm[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'my-swarms'>('all');
  const [dateFilter, setDateFilter] = useState<DateFilterOption>('all');
  const [selectedSwarm, setSelectedSwarm] = useState<Swarm | null>(null);
  const [showManageModal, setShowManageModal] = useState(false);
  const [showEditSwarm, setShowEditSwarm] = useState(false);
  const [showSplit, setShowSplit] = useState(false);
  const [cancelling, setCancelling] = useState(false);

  useEffect(() => {
    loadSwarms();
  }, [filter, user]);

  // Auto-open swarm from push notification deep-link (?id=swarm-uuid&tab=chat)
  useEffect(() => {
    const deepLinkId = searchParams.get('id');
    const deepLinkTab = searchParams.get('tab');
    if (!deepLinkId || swarms.length === 0) return;
    const target = swarms.find(s => s.id === deepLinkId);
    if (!target) return;
    if (deepLinkTab === 'chat') {
      navigate('/messages', { state: { openSwarmChat: target.id, swarmName: target.title } });
    } else {
      setSelectedSwarm(target);
      setShowManageModal(true);
    }
  }, [searchParams, swarms]);

  const loadSwarms = async () => {
    setLoading(true);

    let query = supabase
      .from('swarms')
      .select('*')
      .eq('status', 'active')
      .order('start_time', { ascending: true });

    if (filter === 'my-swarms' && user) {
      query = query.eq('host_user_id', user.id);
    }

    const { data } = await query;

    if (data) {
      const now = new Date();
      const expiredIds: string[] = [];
      const activeSwarms = data.filter((s) => {
        const endTime = s.end_time ? new Date(s.end_time) : null;
        if (endTime && endTime < now) {
          expiredIds.push(s.id);
          return false;
        }
        return true;
      });

      if (expiredIds.length > 0) {
        supabase
          .from('swarms')
          .update({ status: 'completed' })
          .in('id', expiredIds)
          .then(() => {});
      }

      setSwarms(activeSwarms);
    }

    setLoading(false);
  };

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const today = new Date();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    if (date.toDateString() === today.toDateString()) {
      return 'Today';
    } else if (date.toDateString() === tomorrow.toDateString()) {
      return 'Tomorrow';
    } else {
      return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
    }
  };

  const handleManageSwarm = (swarm: Swarm) => {
    setSelectedSwarm(swarm);
    setShowManageModal(true);
  };

  const handleCancelSwarm = async () => {
    if (!selectedSwarm) return;
    setCancelling(true);

    const { error } = await supabase
      .from('swarms')
      .update({ status: 'cancelled' })
      .eq('id', selectedSwarm.id);

    if (error) {
      showError('Could not cancel swarm. Please try again.');
    } else {
      showSuccess('Swarm cancelled');
      loadSwarms();
    }

    setCancelling(false);
    setShowManageModal(false);
    setSelectedSwarm(null);
  };

  const handleJoinSwarm = async (swarm: Swarm) => {
    try {
      const { error } = await supabase.from('swarm_members').insert({
        swarm_id: swarm.id,
        user_id: user!.id,
        role: 'member',
        rsvp: 'going',
      });

      if (error) {
        if (error.code === '23505') {
          showInfo('You have already joined this swarm');
        } else {
          throw error;
        }
      } else {
        showSuccess(`Joined "${swarm.title}"! +5 🪙`);
        if (user) xpService.onSwarmJoined(user.id).catch(() => null);
      }
    } catch {
      showError('Could not join swarm. Please try again.');
    }
  };

  const handleShareSwarm = async (swarm: Swarm) => {
    const shareText = `Join my swarm "${swarm.title}" on Barfliz!`;
    if (navigator.share) {
      try {
        await navigator.share({ title: swarm.title, text: shareText });
      } catch {
        // user cancelled share
      }
    } else {
      try {
        await navigator.clipboard.writeText(shareText);
        showSuccess('Swarm details copied to clipboard!');
      } catch {
        showError('Could not share swarm');
      }
    }
  };

  return (
    <div className="h-full flex flex-col bg-[#FFF5F0]">
      <div className="bg-white shadow-sm p-4 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Swarms</h1>
            <p className="text-sm text-gray-600">Group meetups nearby</p>
          </div>
          <button
            onClick={() => navigate('/create-swarm')}
            className="p-3 bg-[#E91E63] text-white rounded-full shadow-lg hover:bg-[#C2185B] transition-colors"
          >
            <Plus size={24} />
          </button>
        </div>

        <div className="space-y-3">
          <div className="flex gap-2">
            <button
              onClick={() => setFilter('all')}
              className={`flex-1 py-2 px-4 rounded-full font-medium transition-colors ${
                filter === 'all'
                  ? 'bg-[#E91E63] text-white'
                  : 'bg-gray-100 text-gray-700'
              }`}
            >
              All Swarms
            </button>
            <button
              onClick={() => setFilter('my-swarms')}
              className={`flex-1 py-2 px-4 rounded-full font-medium transition-colors ${
                filter === 'my-swarms'
                  ? 'bg-[#E91E63] text-white'
                  : 'bg-gray-100 text-gray-700'
              }`}
            >
              My Swarms
            </button>
          </div>
          <div className="flex justify-end">
            <SwarmDateFilter selectedFilter={dateFilter} onFilterChange={setDateFilter} />
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {loading ? (
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <div className="w-16 h-16 border-4 border-[#E91E63] border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
              <p className="text-gray-600">Loading swarms...</p>
            </div>
          </div>
        ) : swarms.length === 0 ? (
          <div className="flex items-center justify-center h-full p-8">
            <div className="text-center space-y-4">
              <Sparkles size={64} className="mx-auto text-gray-300" />
              <div>
                <p className="text-xl font-bold text-gray-900">
                  {filter === 'my-swarms' ? 'No swarms created' : 'No active swarms'}
                </p>
                <p className="text-gray-600 mt-2">
                  {filter === 'my-swarms'
                    ? 'Create your first swarm to meet people!'
                    : 'Be the first to create a swarm!'}
                </p>
              </div>
              <button
                onClick={() => navigate('/create-swarm')}
                className="bg-[#E91E63] text-white px-6 py-3 rounded-full font-semibold hover:bg-[#C2185B] transition-colors shadow-lg"
              >
                Create Swarm
              </button>
            </div>
          </div>
        ) : filterSwarmsByDate(swarms, dateFilter).length === 0 ? (
          <div className="flex items-center justify-center h-full p-8">
            <div className="text-center space-y-3">
              <Clock size={48} className="mx-auto text-gray-300" />
              <div>
                <p className="text-lg font-bold text-gray-900">No swarms for this date</p>
                <p className="text-gray-500 mt-1 text-sm">Try selecting a different date or browse all swarms.</p>
              </div>
              <button
                onClick={() => setDateFilter('all')}
                className="text-[#E91E63] font-medium text-sm hover:underline"
              >
                Show all swarms
              </button>
            </div>
          </div>
        ) : (
          filterSwarmsByDate(swarms, dateFilter).map((swarm) => (
            <div
              key={swarm.id}
              className="bg-white rounded-2xl p-5 shadow-sm hover:shadow-md transition-shadow cursor-pointer"
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex-1">
                  <h3 className="font-bold text-lg text-gray-900 mb-1">
                    {swarm.title}
                  </h3>
                  {swarm.description && (
                    <p className="text-sm text-gray-600 line-clamp-2 mb-3">
                      {swarm.description}
                    </p>
                  )}
                </div>
                <span className="ml-2 px-3 py-1 bg-green-100 text-green-700 text-xs font-semibold rounded-full">
                  Active
                </span>
              </div>

              <div className="space-y-2 mb-3">
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Clock size={16} className="text-[#E91E63]" />
                  <span>{swarm.start_time ? `${formatDate(swarm.start_time)} at ${formatTime(swarm.start_time)}` : 'Tonight'}</span>
                  {swarm.join_mode && (
                    <>
                      <span className="text-xs text-gray-400">•</span>
                      <span className="text-xs capitalize">{swarm.join_mode.replace('_', ' ')}</span>
                    </>
                  )}
                </div>
              </div>

              {swarm.vibe_tags.length > 0 && (
                <div className="flex flex-wrap gap-1 mb-3">
                  {swarm.vibe_tags.slice(0, 3).map((tag, i) => (
                    <span
                      key={i}
                      className="text-xs px-2 py-1 bg-[#E91E63] bg-opacity-10 text-[#E91E63] rounded-full"
                    >
                      {tag}
                    </span>
                  ))}
                  {swarm.vibe_tags.length > 3 && (
                    <span className="text-xs px-2 py-1 bg-gray-100 text-gray-600 rounded-full">
                      +{swarm.vibe_tags.length - 3}
                    </span>
                  )}
                </div>
              )}

              <button
                onClick={() => {
                  swarm.host_user_id === user?.id ? handleManageSwarm(swarm) : handleJoinSwarm(swarm);
                }}
                className="w-full py-3 bg-[#E91E63] text-white rounded-xl font-semibold hover:bg-[#C2185B] transition-colors"
              >
                {swarm.host_user_id === user?.id ? 'Manage Swarm' : 'Join Swarm'}
              </button>
            </div>
          ))
        )}
      </div>

      {showManageModal && selectedSwarm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/60" onClick={() => setShowManageModal(false)} />
          <div className="relative bg-white rounded-2xl w-full max-w-md overflow-hidden">
            <div className="p-5 border-b border-gray-100">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-gray-900">Manage Swarm</h2>
                <button
                  onClick={() => setShowManageModal(false)}
                  className="p-2 hover:bg-gray-100 rounded-full transition-colors"
                >
                  <X size={20} className="text-gray-500" />
                </button>
              </div>
            </div>

            <div className="p-5 space-y-4">
              <div className="p-4 bg-gray-50 rounded-xl">
                <h3 className="font-bold text-gray-900 mb-1">{selectedSwarm.title}</h3>
                <p className="text-sm text-gray-600">
                  {selectedSwarm.start_time ? `${formatDate(selectedSwarm.start_time)} at ${formatTime(selectedSwarm.start_time)}` : 'Tonight'}
                </p>
              </div>

              <button
                onClick={() => { setShowManageModal(false); setShowEditSwarm(true); }}
                className="w-full flex items-center gap-3 p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors"
              >
                <Pencil size={20} className="text-[#E91E63]" />
                <span className="font-medium text-gray-900">Edit Swarm</span>
              </button>

              <button
                onClick={() => navigate('/messages')}
                className="w-full flex items-center gap-3 p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors"
              >
                <MessageCircle size={20} className="text-[#E91E63]" />
                <span className="font-medium text-gray-900">Message Members</span>
              </button>

              <button
                onClick={() => { handleShareSwarm(selectedSwarm); setShowManageModal(false); }}
                className="w-full flex items-center gap-3 p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors"
              >
                <Share2 size={20} className="text-[#E91E63]" />
                <span className="font-medium text-gray-900">Share Swarm</span>
              </button>

              <button
                onClick={() => { setShowManageModal(false); setShowSplit(true); }}
                className="w-full flex items-center gap-3 p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors"
              >
                <Receipt size={20} className="text-[#E91E63]" />
                <span className="font-medium text-gray-900">Split the Tab</span>
              </button>

              <div className="pt-4 border-t border-gray-100">
                <button
                  onClick={handleCancelSwarm}
                  disabled={cancelling}
                  className="w-full flex items-center justify-center gap-2 p-4 bg-red-50 text-red-600 rounded-xl hover:bg-red-100 transition-colors font-medium"
                >
                  <Trash2 size={20} />
                  {cancelling ? 'Cancelling...' : 'Cancel Swarm'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {showEditSwarm && selectedSwarm && (
        <EditSwarm
          swarm={selectedSwarm}
          onClose={() => setShowEditSwarm(false)}
          onSaved={() => { setShowEditSwarm(false); setSelectedSwarm(null); loadSwarms(); }}
        />
      )}

      <GroupSplit
        swarmId={selectedSwarm?.id}
        isOpen={showSplit}
        onClose={() => setShowSplit(false)}
      />
    </div>
  );
}
