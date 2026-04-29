import { useState } from 'react';
import { X, AlertTriangle, ChevronRight } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';

export type ReportTargetType = 'user' | 'message' | 'venue' | 'swarm';

export interface ReportContentModalProps {
  open: boolean;
  onClose: () => void;
  targetType: ReportTargetType;
  // For user/message/swarm: the user being reported (message sender, swarm host).
  // For venue: ignored — pass venueId instead.
  targetUserId?: string;
  // For venue reports.
  venueId?: string;
  // Display label for the user/venue/etc.
  targetLabel?: string;
}

const REASONS: ReadonlyArray<{ key: string; label: string }> = [
  { key: 'spam', label: 'Spam or fake account' },
  { key: 'harassment', label: 'Harassment or bullying' },
  { key: 'hate_speech', label: 'Hate speech' },
  { key: 'sexual_content', label: 'Sexual or inappropriate content' },
  { key: 'violence', label: 'Threats or violence' },
  { key: 'underage', label: 'User appears to be underage' },
  { key: 'impersonation', label: 'Impersonation' },
  { key: 'safety', label: 'Safety concern' },
  { key: 'other', label: 'Other' },
];

const VENUE_REASON_MAP: Record<string, string> = {
  spam: 'spam',
  harassment: 'inappropriate',
  hate_speech: 'inappropriate',
  sexual_content: 'inappropriate',
  violence: 'safety_concern',
  safety: 'safety_concern',
  underage: 'safety_concern',
  impersonation: 'incorrect_info',
  other: 'other',
};

export default function ReportContentModal({
  open,
  onClose,
  targetType,
  targetUserId,
  venueId,
  targetLabel,
}: ReportContentModalProps) {
  const { user: currentUser } = useAuth();
  const { showSuccess, showError } = useToast();
  const [selectedReason, setSelectedReason] = useState<string | null>(null);
  const [details, setDetails] = useState('');
  const [submitting, setSubmitting] = useState(false);

  if (!open) return null;

  const close = () => {
    setSelectedReason(null);
    setDetails('');
    setSubmitting(false);
    onClose();
  };

  const submit = async () => {
    if (!selectedReason || !currentUser) return;

    if (targetType === 'venue') {
      if (!venueId) {
        showError('Missing venue.');
        return;
      }
      setSubmitting(true);
      const { error } = await supabase.from('venue_reports').insert({
        venue_id: venueId,
        reporter_id: currentUser.id,
        report_type: VENUE_REASON_MAP[selectedReason] ?? 'other',
        description: details.trim() || REASONS.find((r) => r.key === selectedReason)?.label || 'No details provided',
      });
      setSubmitting(false);
      if (error) {
        showError('Could not submit report. Please try again.');
        return;
      }
      showSuccess('Thanks for reporting. We review within 24 hours.');
      close();
      return;
    }

    // user / message / swarm: insert into reports table.
    if (!targetUserId) {
      showError('Missing target user.');
      return;
    }
    if (targetUserId === currentUser.id) {
      showError("You can't report yourself.");
      return;
    }

    const context: 'dm' | 'swarm' | 'profile' =
      targetType === 'message' ? 'dm' : targetType === 'swarm' ? 'swarm' : 'profile';

    setSubmitting(true);
    const { error } = await supabase.from('reports').insert({
      reporter_user_id: currentUser.id,
      reported_user_id: targetUserId,
      context,
      reason: selectedReason,
      details: details.trim() || '',
    });
    setSubmitting(false);

    if (error) {
      showError('Could not submit report. Please try again.');
      return;
    }
    showSuccess('Thanks for reporting. We review within 24 hours.');
    close();
  };

  const headerLabel =
    targetType === 'venue' ? 'this venue' : targetLabel ? targetLabel : 'this content';

  return (
    <div className="fixed inset-0 z-[9100] bg-black/60 backdrop-blur-sm flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="bg-white rounded-t-2xl sm:rounded-2xl w-full max-w-md shadow-2xl max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          <div className="flex items-start justify-between mb-4">
            <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center">
              <AlertTriangle size={24} className="text-red-600" />
            </div>
            <button
              onClick={close}
              className="p-1 hover:bg-gray-100 rounded-full transition-colors"
              aria-label="Close"
            >
              <X size={20} className="text-gray-500" />
            </button>
          </div>

          <h2 className="text-xl font-bold text-gray-900 mb-1">Report {headerLabel}</h2>
          <p className="text-sm text-gray-600 mb-4">Choose a reason. We review every report within 24 hours.</p>

          <div className="space-y-1 mb-4">
            {REASONS.map((r) => (
              <button
                key={r.key}
                onClick={() => setSelectedReason(r.key)}
                className={`w-full px-4 py-3 flex items-center justify-between rounded-xl border transition-colors text-left ${
                  selectedReason === r.key
                    ? 'border-red-400 bg-red-50'
                    : 'border-gray-200 hover:bg-gray-50'
                }`}
              >
                <span className={`text-sm font-medium ${selectedReason === r.key ? 'text-red-700' : 'text-gray-900'}`}>
                  {r.label}
                </span>
                <ChevronRight size={18} className={selectedReason === r.key ? 'text-red-400' : 'text-gray-300'} />
              </button>
            ))}
          </div>

          <div className="mb-4">
            <label htmlFor="report-details" className="block text-xs text-gray-500 mb-1">
              Additional details (optional)
            </label>
            <textarea
              id="report-details"
              value={details}
              onChange={(e) => setDetails(e.target.value.slice(0, 500))}
              placeholder="What happened?"
              rows={3}
              className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:border-red-400 focus:outline-none focus:ring-1 focus:ring-red-400 resize-none"
            />
            <p className="text-xs text-gray-400 mt-1 text-right">{details.length}/500</p>
          </div>

          <button
            onClick={submit}
            disabled={!selectedReason || submitting}
            className="w-full py-3 bg-red-600 text-white rounded-xl font-semibold text-sm hover:bg-red-700 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
          >
            {submitting ? 'Submitting...' : 'Submit Report'}
          </button>
          <button
            onClick={close}
            className="w-full py-3 mt-2 text-gray-600 text-sm font-medium hover:text-gray-900 transition-colors"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
}
