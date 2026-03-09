import { useState, useEffect } from 'react';
import { Shield, CheckCircle, Clock, Heart, AlertCircle, X } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { activityService } from '../../services/activityService';

function timeAgo(date: string) {
  const diff = Math.floor((Date.now() - new Date(date).getTime()) / 1000);
  if (diff < 60) return 'just now';
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

interface FriendArrival {
  id: string;
  user_id: string;
  user_name: string;
  checked_in_at: string;
}

export function SafeArrivalButton() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [sent, setSent] = useState(false);
  const [loading, setLoading] = useState(false);
  const [lastSent, setLastSent] = useState<string | null>(null);
  const [showNoFriendsModal, setShowNoFriendsModal] = useState(false);

  useEffect(() => {
    if (!user) return;
    supabase
      .from('safe_arrivals')
      .select('checked_in_at')
      .eq('user_id', user.id)
      .order('checked_in_at', { ascending: false })
      .limit(1)
      .maybeSingle()
      .then(({ data }) => {
        if (data) {
          const age = Date.now() - new Date(data.checked_in_at).getTime();
          if (age < 60 * 1000) {
            setSent(true);
            setLastSent(data.checked_in_at);
          }
        }
      });
  }, [user]);

  useEffect(() => {
    if (!sent) return;
    const timer = setTimeout(() => setSent(false), 60 * 1000);
    return () => clearTimeout(timer);
  }, [sent]);

  const confirm = async () => {
    if (!user || loading) return;
    setLoading(true);
    try {
      const { data: safetyFriends } = await supabase
        .from('safety_friends')
        .select('id')
        .eq('user_id', user.id);

      if (!safetyFriends || safetyFriends.length === 0) {
        setShowNoFriendsModal(true);
        setLoading(false);
        return;
      }

      await supabase.from('safe_arrivals').insert({
        user_id: user.id,
      });

      const { data: profile } = await supabase.from('users').select('name').eq('id', user.id).maybeSingle();
      const name = profile?.name || 'Your friend';

      const { data: friends } = await supabase
        .from('friendships')
        .select('user_id, friend_id')
        .eq('status', 'accepted')
        .or(`user_id.eq.${user.id},friend_id.eq.${user.id}`);

      const friendIds = (friends || []).map(f => f.user_id === user.id ? f.friend_id : f.user_id);

      if (friendIds.length > 0) {
        await supabase.from('notifications').insert(
          friendIds.map(fid => ({
            recipient_user_id: fid,
            actor_user_id: user.id,
            notification_type: 'safe_arrival',
            title: `${name} is home safe`,
            body: 'They confirmed they got home safely tonight.',
          }))
        );
      }

      setSent(true);
      setLastSent(new Date().toISOString());
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <button
        onClick={confirm}
        disabled={loading || sent}
        className={`w-full flex items-center gap-4 p-4 rounded-2xl border-2 transition-all ${
          sent
            ? 'bg-emerald-50 border-emerald-400'
            : 'bg-white border-gray-200 hover:border-emerald-300 hover:bg-emerald-50/50'
        }`}
      >
        <div className={`w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 ${sent ? 'bg-emerald-100' : 'bg-gray-100'}`}>
          {sent ? <CheckCircle className="w-6 h-6 text-emerald-600" /> : <Shield className="w-6 h-6 text-gray-500" />}
        </div>
        <div className="flex-1 text-left">
          <p className={`font-semibold text-sm ${sent ? 'text-emerald-800' : 'text-gray-900'}`}>
            {sent ? 'Safe arrival confirmed!' : "I'm home safe"}
          </p>
          <p className={`text-xs mt-0.5 ${sent ? 'text-emerald-600' : 'text-gray-500'}`}>
            {sent && lastSent ? `Sent ${timeAgo(lastSent)} · friends notified` : 'Notify friends you got home safely'}
          </p>
        </div>
        <Heart className={`w-5 h-5 flex-shrink-0 ${sent ? 'text-emerald-500 fill-emerald-500' : 'text-gray-300'}`} />
      </button>

      {showNoFriendsModal && (
        <div className="fixed inset-0 z-[9000] bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-sm shadow-2xl">
            <div className="p-6">
              <div className="flex items-start justify-between mb-4">
                <div className="w-12 h-12 bg-amber-100 rounded-full flex items-center justify-center">
                  <AlertCircle size={24} className="text-amber-600" />
                </div>
                <button
                  onClick={() => setShowNoFriendsModal(false)}
                  className="p-1 hover:bg-gray-100 rounded-full transition-colors"
                >
                  <X size={20} className="text-gray-500" />
                </button>
              </div>

              <h2 className="text-xl font-bold text-gray-900 mb-2">Add Safety Friends</h2>
              <p className="text-sm text-gray-600 mb-6 leading-relaxed">
                You haven't added any safety friends yet. Add trusted contacts who can receive your safe arrival notifications.
              </p>

              <div className="space-y-3">
                <button
                  onClick={() => {
                    setShowNoFriendsModal(false);
                    navigate('/settings/safety');
                  }}
                  className="w-full py-3 bg-emerald-600 text-white rounded-xl font-semibold hover:bg-emerald-700 transition-colors"
                >
                  Add Safety Friends
                </button>
                <button
                  onClick={() => setShowNoFriendsModal(false)}
                  className="w-full py-3 text-gray-600 text-sm font-medium hover:text-gray-900 transition-colors"
                >
                  Maybe Later
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

export function FriendSafeArrivals() {
  const { user } = useAuth();
  const [arrivals, setArrivals] = useState<FriendArrival[]>([]);

  useEffect(() => {
    if (!user) return;
    load();
  }, [user]);

  const load = async () => {
    if (!user) return;
    const { data: friends } = await supabase
      .from('friendships')
      .select('user_id, friend_id')
      .eq('status', 'accepted')
      .or(`user_id.eq.${user.id},friend_id.eq.${user.id}`);

    const friendIds = (friends || []).map(f => f.user_id === user.id ? f.friend_id : f.user_id);
    if (!friendIds.length) return;

    const since = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
    const { data } = await supabase
      .from('safe_arrivals')
      .select('id, user_id, checked_in_at, user:users(name)')
      .in('user_id', friendIds)
      .gte('checked_in_at', since)
      .order('checked_in_at', { ascending: false });

    setArrivals((data || []).map((a: any) => ({
      id: a.id,
      user_id: a.user_id,
      user_name: a.user?.name || 'A friend',
      checked_in_at: a.checked_in_at,
    })));
  };

  if (arrivals.length === 0) return null;

  return (
    <div className="bg-emerald-50 border border-emerald-200 rounded-2xl p-4">
      <div className="flex items-center gap-2 mb-3">
        <CheckCircle className="w-4 h-4 text-emerald-600" />
        <p className="text-sm font-semibold text-emerald-800">Friends home safe</p>
      </div>
      <div className="space-y-2">
        {arrivals.map(a => (
          <div key={a.id} className="flex items-center justify-between">
            <p className="text-sm text-emerald-700 font-medium">{a.user_name}</p>
            <div className="flex items-center gap-1 text-xs text-emerald-500">
              <Clock className="w-3 h-3" />
              {timeAgo(a.checked_in_at)}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
