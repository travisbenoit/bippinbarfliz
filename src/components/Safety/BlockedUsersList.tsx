import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ShieldOff, ChevronLeft } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';
import PageHeader from '../Layout/PageHeader';

interface BlockedUser {
  blockId: string;
  userId: string;
  name: string | null;
  avatarUrl: string | null;
  blockedAt: string;
}

export default function BlockedUsersList() {
  const { user } = useAuth();
  const { showSuccess, showError } = useToast();
  const navigate = useNavigate();
  const [items, setItems] = useState<BlockedUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [removing, setRemoving] = useState<string | null>(null);

  useEffect(() => {
    if (user) load();
  }, [user]);

  const load = async () => {
    if (!user) return;
    setLoading(true);
    const { data: blocks, error } = await supabase
      .from('user_blocks')
      .select('id, blocked_id, created_at')
      .eq('blocker_id', user.id)
      .order('created_at', { ascending: false });

    if (error) {
      showError('Could not load blocked users.');
      setLoading(false);
      return;
    }

    if (!blocks || blocks.length === 0) {
      setItems([]);
      setLoading(false);
      return;
    }

    const ids = blocks.map((b) => b.blocked_id);
    const { data: profiles } = await supabase
      .from('users')
      .select('id, name, avatar_url')
      .in('id', ids);

    const profileMap = new Map((profiles || []).map((p) => [p.id, p]));
    const merged: BlockedUser[] = blocks.map((b) => {
      const profile = profileMap.get(b.blocked_id);
      return {
        blockId: b.id,
        userId: b.blocked_id,
        name: profile?.name ?? 'Unknown user',
        avatarUrl: profile?.avatar_url ?? null,
        blockedAt: b.created_at,
      };
    });
    setItems(merged);
    setLoading(false);
  };

  const unblock = async (blockId: string) => {
    setRemoving(blockId);
    const { error } = await supabase.from('user_blocks').delete().eq('id', blockId);
    setRemoving(null);
    if (error) {
      showError('Could not unblock. Please try again.');
      return;
    }
    showSuccess('Unblocked.');
    setItems((prev) => prev.filter((i) => i.blockId !== blockId));
  };

  return (
    <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-20">
      <PageHeader title="Blocked Users" onBack={() => navigate('/settings')} />

      <div className="p-4">
        {loading ? (
          <div className="text-center py-12 text-gray-400 text-sm">Loading...</div>
        ) : items.length === 0 ? (
          <div className="bg-white rounded-2xl shadow-sm p-8 text-center">
            <div className="w-14 h-14 mx-auto mb-3 bg-gray-100 rounded-full flex items-center justify-center">
              <ShieldOff size={24} className="text-gray-400" />
            </div>
            <p className="text-sm font-semibold text-gray-700 mb-1">No blocked users</p>
            <p className="text-xs text-gray-500">Users you block won't be able to see your profile or message you.</p>
          </div>
        ) : (
          <div className="bg-white rounded-2xl shadow-sm overflow-hidden divide-y divide-gray-100">
            {items.map((item) => (
              <div key={item.blockId} className="px-4 py-3 flex items-center gap-3">
                <div className="w-12 h-12 rounded-full overflow-hidden bg-gray-200 flex items-center justify-center flex-shrink-0">
                  {item.avatarUrl ? (
                    <img src={item.avatarUrl} alt={item.name ?? 'User'} className="w-full h-full object-cover opacity-60" />
                  ) : (
                    <span className="font-bold text-gray-400 text-lg">{(item.name ?? 'U').charAt(0)}</span>
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-gray-700 truncate">{item.name}</p>
                  <p className="text-xs text-gray-400">Blocked {new Date(item.blockedAt).toLocaleDateString()}</p>
                </div>
                <button
                  onClick={() => unblock(item.blockId)}
                  disabled={removing === item.blockId}
                  className="px-3 py-1.5 text-sm text-[#E91E63] border border-[#E91E63]/30 rounded-full hover:bg-[#E91E63]/10 transition-colors disabled:opacity-40"
                >
                  {removing === item.blockId ? 'Removing...' : 'Unblock'}
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
