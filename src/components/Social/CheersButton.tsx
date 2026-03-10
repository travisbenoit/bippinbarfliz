import { useState } from 'react';
import { Wine } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { activityService } from '../../services/activityService';
import { xpService } from '../../services/xpService';

interface Props {
  recipientId: string;
  recipientName: string;
  venueId?: string;
  venueName?: string;
  compact?: boolean;
}

export function CheersButton({ recipientId, recipientName, venueId, venueName, compact = false }: Props) {
  const { user } = useAuth();
  const [sent, setSent] = useState(false);
  const [loading, setLoading] = useState(false);

  const sendCheers = async () => {
    if (!user || loading || sent) return;
    setLoading(true);
    try {
      await supabase.from('cheers').insert({
        sender_id: user.id,
        recipient_id: recipientId,
        venue_id: venueId || null,
      });
      await activityService.createNotificationsForFriends(
        user.id,
        'cheers',
        `Cheers!`,
        `Someone raised a glass to you${venueName ? ` at ${venueName}` : ''}!`,
        { venueId }
      );
      setSent(true);
      xpService.onCheerSent(user.id).catch(() => null);
    } catch {
      // silent fail
    } finally {
      setLoading(false);
    }
  };

  if (compact) {
    return (
      <button
        onClick={sendCheers}
        disabled={loading || sent}
        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-all ${
          sent
            ? 'bg-amber-100 text-amber-700 cursor-default'
            : 'bg-amber-500 text-white hover:bg-amber-600 active:scale-95'
        }`}
      >
        <Wine className="w-3.5 h-3.5" />
        {sent ? 'Cheers!' : 'Cheers'}
      </button>
    );
  }

  return (
    <button
      onClick={sendCheers}
      disabled={loading || sent}
      className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-semibold transition-all ${
        sent
          ? 'bg-amber-100 text-amber-700 cursor-default'
          : 'bg-gradient-to-r from-amber-400 to-orange-400 text-white hover:shadow-md active:scale-95'
      }`}
    >
      <Wine className="w-4 h-4" />
      {sent ? `Cheers sent to ${recipientName.split(' ')[0]}!` : `Cheers ${recipientName.split(' ')[0]}!`}
    </button>
  );
}
