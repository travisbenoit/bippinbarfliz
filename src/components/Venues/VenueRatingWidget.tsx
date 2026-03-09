import { useState, useEffect } from 'react';
import { Star, Users } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

interface Props {
  venueId: string;
  venueName: string;
}

interface FriendRating {
  user_name: string;
  rating: number;
  notes: string;
}

export function VenueRatingWidget({ venueId, venueName }: Props) {
  const { user } = useAuth();
  const [myRating, setMyRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);
  const [friendRatings, setFriendRatings] = useState<FriendRating[]>([]);
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    load();
  }, [venueId]);

  const load = async () => {
    if (!user) return;
    const { data: own } = await supabase
      .from('venue_ratings')
      .select('rating, notes')
      .eq('user_id', user.id)
      .eq('venue_id', venueId)
      .maybeSingle();
    if (own) { setMyRating(own.rating); setNotes(own.notes || ''); setSaved(true); }

    const { data: friends } = await supabase
      .from('venue_ratings')
      .select('rating, notes, user:users(name)')
      .eq('venue_id', venueId)
      .neq('user_id', user.id);

    setFriendRatings((friends || []).map((r: any) => ({
      user_name: r.user?.name || 'A friend',
      rating: r.rating,
      notes: r.notes || '',
    })));
  };

  const avgFriendRating = friendRatings.length > 0
    ? friendRatings.reduce((s, r) => s + r.rating, 0) / friendRatings.length
    : null;

  const saveRating = async (rating: number) => {
    if (!user) return;
    setSaving(true);
    await supabase.from('venue_ratings').upsert({
      user_id: user.id,
      venue_id: venueId,
      rating,
      notes,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'user_id,venue_id' });
    setMyRating(rating);
    setSaved(true);
    setSaving(false);
  };

  const StarRow = ({ value, interactive, size = 20 }: { value: number; interactive?: boolean; size?: number }) => (
    <div className="flex items-center gap-1">
      {[1, 2, 3, 4, 5].map(i => (
        <button
          key={i}
          disabled={!interactive || saving}
          onClick={() => interactive && saveRating(i)}
          onMouseEnter={() => interactive && setHoverRating(i)}
          onMouseLeave={() => interactive && setHoverRating(0)}
          className={interactive ? 'transition-transform hover:scale-110' : 'cursor-default'}
        >
          <Star
            width={size}
            height={size}
            className={`transition-colors ${
              i <= (hoverRating || value)
                ? 'text-amber-400 fill-amber-400'
                : 'text-gray-200 fill-gray-200'
            }`}
          />
        </button>
      ))}
    </div>
  );

  return (
    <div className="space-y-4">
      <div>
        <p className="text-sm font-semibold text-gray-700 mb-2">Your vibe rating</p>
        <StarRow value={myRating} interactive size={28} />
        {myRating > 0 && (
          <div className="mt-2">
            <input
              type="text"
              value={notes}
              onChange={e => setNotes(e.target.value)}
              onBlur={() => myRating > 0 && saveRating(myRating)}
              placeholder="Add a note (optional)"
              className="w-full text-sm border border-gray-200 rounded-xl px-3 py-2 focus:outline-none focus:border-[#E91E63]"
            />
          </div>
        )}
        {saved && !saving && <p className="text-xs text-emerald-600 mt-1">Rating saved</p>}
      </div>

      {friendRatings.length > 0 && (
        <div>
          <div className="flex items-center gap-2 mb-3">
            <Users className="w-4 h-4 text-gray-400" />
            <p className="text-sm font-semibold text-gray-700">
              Friend ratings
              {avgFriendRating && (
                <span className="ml-2 text-amber-600">avg {avgFriendRating.toFixed(1)}</span>
              )}
            </p>
          </div>
          <div className="space-y-2">
            {friendRatings.map((r, i) => (
              <div key={i} className="flex items-start gap-3">
                <div className="w-7 h-7 bg-[#E91E63]/10 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-[10px] font-bold text-[#E91E63]">{r.user_name.charAt(0)}</span>
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <p className="text-xs font-medium text-gray-700">{r.user_name}</p>
                    <StarRow value={r.rating} size={12} />
                  </div>
                  {r.notes && <p className="text-xs text-gray-500 mt-0.5">{r.notes}</p>}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
