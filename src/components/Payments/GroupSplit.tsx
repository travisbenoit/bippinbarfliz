import { useState, useEffect } from 'react';
import { DollarSign, Users, Plus, Send, CheckCircle, X, Receipt } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

interface SplitMember {
  user_id: string;
  name: string;
  amount: number;
  paid: boolean;
  paid_at?: string;
}

interface Split {
  id: string;
  description: string;
  total_amount: number;
  status: string;
  created_at: string;
  creator_id: string;
  items: SplitMember[];
}

interface Props {
  swarmId?: string;
  isOpen: boolean;
  onClose: () => void;
}

export function GroupSplit({ swarmId, isOpen, onClose }: Props) {
  const { user } = useAuth();
  const [splits, setSplits] = useState<Split[]>([]);
  const [creating, setCreating] = useState(false);
  const [description, setDescription] = useState('');
  const [totalAmount, setTotalAmount] = useState('');
  const [swarmMembers, setSwarmMembers] = useState<Array<{ id: string; name: string }>>([]);
  const [selectedMembers, setSelectedMembers] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!isOpen || !user) return;
    loadSplits();
    if (swarmId) loadSwarmMembers();
  }, [isOpen, swarmId, user]);

  const loadSplits = async () => {
    const query = supabase
      .from('group_splits')
      .select('id, description, total_amount, status, created_at, creator_id')
      .order('created_at', { ascending: false });

    const { data } = swarmId ? await query.eq('swarm_id', swarmId) : await query.eq('creator_id', user!.id);
    if (!data) return;

    const enriched = await Promise.all(data.map(async (split) => {
      const { data: items } = await supabase
        .from('group_split_items')
        .select('user_id, amount, paid, paid_at, user:users(name)')
        .eq('split_id', split.id);
      return {
        ...split,
        items: (items || []).map((i: any) => ({
          user_id: i.user_id,
          name: i.user?.name || 'Unknown',
          amount: i.amount,
          paid: i.paid,
          paid_at: i.paid_at,
        })),
      };
    }));
    setSplits(enriched);
  };

  const loadSwarmMembers = async () => {
    if (!swarmId) return;
    const { data } = await supabase
      .from('swarm_members')
      .select('user_id, user:users(id, name)')
      .eq('swarm_id', swarmId);
    if (data) setSwarmMembers(data.map((m: any) => ({ id: m.user_id, name: m.user?.name || 'Unknown' })));
  };

  const perPersonAmount = () => {
    const total = parseFloat(totalAmount);
    const count = selectedMembers.length + 1;
    if (!total || count < 2) return 0;
    return +(total / count).toFixed(2);
  };

  const createSplit = async () => {
    if (!user || !totalAmount || selectedMembers.length < 1) return;
    setSaving(true);
    try {
      const total = parseFloat(totalAmount);
      const perPerson = perPersonAmount();

      const { data: split } = await supabase
        .from('group_splits')
        .insert({
          swarm_id: swarmId || null,
          creator_id: user.id,
          total_amount: total,
          description: description || 'Bar tab',
          status: 'open',
        })
        .select()
        .maybeSingle();

      if (!split) return;

      const allMemberIds = [user.id, ...selectedMembers];
      await supabase.from('group_split_items').insert(
        allMemberIds.map(uid => ({
          split_id: split.id,
          user_id: uid,
          amount: perPerson,
          paid: uid === user.id,
        }))
      );

      await supabase.from('notifications').insert(
        selectedMembers.map(uid => ({
          recipient_user_id: uid,
          actor_user_id: user.id,
          notification_type: 'split_request',
          title: 'You owe on a split tab',
          body: `$${perPerson} for "${description || 'Bar tab'}"`,
        }))
      );

      await loadSplits();
      setCreating(false);
      setDescription('');
      setTotalAmount('');
      setSelectedMembers([]);
    } catch {
      // silent
    } finally {
      setSaving(false);
    }
  };

  const markPaid = async (splitId: string) => {
    if (!user) return;
    await supabase
      .from('group_split_items')
      .update({ paid: true, paid_at: new Date().toISOString() })
      .eq('split_id', splitId)
      .eq('user_id', user.id);
    await loadSplits();
  };

  if (!isOpen) return null;

  const displayMembers = swarmMembers.length > 0 ? swarmMembers : [];

  return (
    <div className="fixed inset-0 z-[2000] flex flex-col" onClick={onClose}>
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" />
      <div
        className="relative mt-auto bg-white rounded-t-3xl shadow-2xl max-h-[90vh] flex flex-col"
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <div className="flex items-center gap-2">
            <Receipt className="w-5 h-5 text-[#E91E63]" />
            <h2 className="font-bold text-gray-900 text-lg">Split Tab</h2>
          </div>
          <div className="flex items-center gap-2">
            {!creating && (
              <button
                onClick={() => setCreating(true)}
                className="flex items-center gap-1.5 bg-[#E91E63] text-white px-3 py-1.5 rounded-full text-sm font-semibold"
              >
                <Plus className="w-4 h-4" /> New Split
              </button>
            )}
            <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100">
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto overscroll-contain px-5 py-4 space-y-4">
          {creating && (
            <div className="space-y-4 border border-gray-100 rounded-2xl p-4">
              <h3 className="font-semibold text-gray-900">New Split</h3>

              <div>
                <label className="text-sm font-medium text-gray-600 block mb-1.5">What for?</label>
                <input
                  type="text"
                  value={description}
                  onChange={e => setDescription(e.target.value)}
                  placeholder="Bar tab, bottles, etc."
                  className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-[#E91E63]"
                />
              </div>

              <div>
                <label className="text-sm font-medium text-gray-600 block mb-1.5">Total amount</label>
                <div className="relative">
                  <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                  <input
                    type="number"
                    value={totalAmount}
                    onChange={e => setTotalAmount(e.target.value)}
                    placeholder="0.00"
                    className="w-full border border-gray-200 rounded-xl pl-8 pr-4 py-3 text-sm focus:outline-none focus:border-[#E91E63]"
                  />
                </div>
              </div>

              {displayMembers.length > 0 && (
                <div>
                  <label className="text-sm font-medium text-gray-600 block mb-2">Who's in?</label>
                  <div className="flex flex-wrap gap-2">
                    {displayMembers.filter(m => m.id !== user?.id).map(m => (
                      <button
                        key={m.id}
                        onClick={() => setSelectedMembers(prev =>
                          prev.includes(m.id) ? prev.filter(id => id !== m.id) : [...prev, m.id]
                        )}
                        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm transition-all ${
                          selectedMembers.includes(m.id)
                            ? 'bg-[#E91E63] text-white'
                            : 'bg-gray-100 text-gray-700'
                        }`}
                      >
                        <Users className="w-3.5 h-3.5" />
                        {m.name.split(' ')[0]}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {totalAmount && selectedMembers.length > 0 && (
                <div className="bg-gray-50 rounded-xl p-3">
                  <p className="text-sm text-gray-600">Each person pays: <span className="font-bold text-gray-900">${perPersonAmount()}</span></p>
                  <p className="text-xs text-gray-400 mt-0.5">{selectedMembers.length + 1} people sharing ${parseFloat(totalAmount).toFixed(2)}</p>
                </div>
              )}

              <div className="flex gap-3">
                <button
                  onClick={() => setCreating(false)}
                  className="flex-1 py-3 border border-gray-200 rounded-xl text-sm font-medium text-gray-700"
                >
                  Cancel
                </button>
                <button
                  onClick={createSplit}
                  disabled={saving || !totalAmount || selectedMembers.length < 1}
                  className="flex-1 py-3 bg-[#E91E63] text-white rounded-xl text-sm font-semibold disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  <Send className="w-4 h-4" />
                  {saving ? 'Creating...' : 'Send Requests'}
                </button>
              </div>
            </div>
          )}

          {splits.length === 0 && !creating ? (
            <div className="text-center py-12">
              <Receipt className="w-10 h-10 text-gray-200 mx-auto mb-3" />
              <p className="text-gray-400 font-medium">No splits yet</p>
              <p className="text-gray-300 text-sm mt-1">Split the tab with your swarm</p>
            </div>
          ) : (
            splits.map(split => {
              const myItem = split.items.find(i => i.user_id === user?.id);
              const paid = split.items.filter(i => i.paid).length;
              const total = split.items.length;
              return (
                <div key={split.id} className="border border-gray-100 rounded-2xl overflow-hidden">
                  <div className="p-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="font-semibold text-gray-900">{split.description}</p>
                        <p className="text-2xl font-black text-gray-900 mt-1">${split.total_amount.toFixed(2)}</p>
                      </div>
                      <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                        split.status === 'settled' ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'
                      }`}>{split.status}</span>
                    </div>
                    <div className="flex items-center gap-2 mt-3">
                      <div className="flex-1 bg-gray-100 rounded-full h-2">
                        <div
                          className="bg-emerald-500 h-2 rounded-full transition-all"
                          style={{ width: `${(paid / total) * 100}%` }}
                        />
                      </div>
                      <span className="text-xs text-gray-500">{paid}/{total} paid</span>
                    </div>
                  </div>
                  <div className="border-t border-gray-50 divide-y divide-gray-50">
                    {split.items.map(item => (
                      <div key={item.user_id} className="flex items-center gap-3 px-4 py-2.5">
                        <div className="w-7 h-7 bg-gray-100 rounded-full flex items-center justify-center text-xs font-bold text-gray-600">
                          {item.name.charAt(0)}
                        </div>
                        <p className="flex-1 text-sm text-gray-700">{item.name}</p>
                        <p className="text-sm font-semibold text-gray-900">${item.amount.toFixed(2)}</p>
                        {item.paid ? (
                          <CheckCircle className="w-5 h-5 text-emerald-500" />
                        ) : item.user_id === user?.id ? (
                          <button
                            onClick={() => markPaid(split.id)}
                            className="text-xs bg-[#E91E63] text-white px-2.5 py-1 rounded-full font-semibold"
                          >
                            Mark paid
                          </button>
                        ) : (
                          <span className="w-5 h-5 rounded-full border-2 border-gray-200" />
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              );
            })
          )}
        </div>
        <div className="h-6 flex-shrink-0" />
      </div>
    </div>
  );
}
