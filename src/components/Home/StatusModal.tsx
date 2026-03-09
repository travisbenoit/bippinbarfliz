import { useState } from 'react';
import { X } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

interface StatusModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentStatus: 'out_now' | 'going_out_soon' | 'staying_in';
  onStatusUpdate?: (status: 'out_now' | 'going_out_soon' | 'staying_in') => void;
}

export default function StatusModal({
  isOpen,
  onClose,
  currentStatus,
  onStatusUpdate,
}: StatusModalProps) {
  const { user } = useAuth();
  const [selectedStatus, setSelectedStatus] = useState<'out_now' | 'going_out_soon' | 'staying_in'>(currentStatus);
  const [updating, setUpdating] = useState(false);

  const statuses = [
    {
      value: 'out_now' as const,
      label: '🟢 Out Now',
      description: 'You are out enjoying tonight',
    },
    {
      value: 'going_out_soon' as const,
      label: '🟡 Going Out Soon',
      description: 'You plan to go out soon',
    },
    {
      value: 'staying_in' as const,
      label: '⚪ Staying In',
      description: 'You are staying in tonight',
    },
  ];

  const handleSave = async () => {
    if (!user) return;

    setUpdating(true);
    try {
      await supabase
        .from('users')
        .update({ tonight_status: selectedStatus })
        .eq('id', user.id);

      onStatusUpdate?.(selectedStatus);
      onClose();
    } catch (error) {
      console.error('Failed to update status:', error);
    } finally {
      setUpdating(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/30" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-lg w-full max-w-sm">
        <div className="p-5 border-b border-gray-200 flex items-center justify-between">
          <h2 className="font-bold text-gray-900">Update Your Status</h2>
          <button
            onClick={onClose}
            className="p-1 hover:bg-gray-100 rounded-full transition-colors"
          >
            <X size={20} className="text-gray-500" />
          </button>
        </div>

        <div className="p-5 space-y-3">
          {statuses.map((status) => (
            <button
              key={status.value}
              onClick={() => setSelectedStatus(status.value)}
              className={`w-full p-4 rounded-xl border-2 transition-all text-left ${
                selectedStatus === status.value
                  ? 'border-[#E91E63] bg-[#E91E63]/5'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <p className="font-semibold text-gray-900">{status.label}</p>
              <p className="text-sm text-gray-600 mt-1">{status.description}</p>
            </button>
          ))}
        </div>

        <div className="p-5 border-t border-gray-200 flex gap-3">
          <button
            onClick={onClose}
            className="flex-1 py-2 px-4 text-gray-700 font-medium rounded-xl hover:bg-gray-100 transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={updating}
            className="flex-1 bg-[#E91E63] text-white py-2 px-4 font-medium rounded-xl hover:bg-[#C2185B] disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {updating ? 'Saving...' : 'Update'}
          </button>
        </div>
      </div>
    </div>
  );
}
