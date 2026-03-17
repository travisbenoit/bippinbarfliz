import { supabase } from '../lib/supabase';

export type VibeType = 'lit' | 'chill' | 'vibing' | 'dead' | 'dancing';

export interface VibeVote {
  id: string;
  venue_id: string;
  user_id: string;
  vibe: VibeType;
  created_at: string;
}

export interface VibeStats {
  lit: number;
  chill: number;
  vibing: number;
  dead: number;
  dancing: number;
  total: number;
}

export const vibeService = {
  async castVote(venueId: string, vibe: VibeType): Promise<VibeVote> {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.user?.id) throw new Error('Not authenticated');

    const { data: existing } = await supabase
      .from('vibe_votes')
      .select('id')
      .eq('venue_id', venueId)
      .eq('user_id', session.user.id)
      .gte('created_at', new Date(new Date().setHours(0, 0, 0, 0)).toISOString())
      .maybeSingle();

    if (existing) {
      return supabase
        .from('vibe_votes')
        .update({ vibe })
        .eq('id', existing.id)
        .select()
        .single()
        .then(({ data, error }) => {
          if (error) throw error;
          return data;
        });
    }

    const { data, error } = await supabase
      .from('vibe_votes')
      .insert([
        {
          venue_id: venueId,
          user_id: session.user.id,
          vibe,
        },
      ])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getVibeStats(venueId: string): Promise<VibeStats> {
    const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString();

    const { data, error } = await supabase
      .from('vibe_votes')
      .select('vibe')
      .eq('venue_id', venueId)
      .gte('created_at', threeHoursAgo);

    if (error) throw error;

    const stats: VibeStats = {
      lit: 0,
      chill: 0,
      vibing: 0,
      dead: 0,
      dancing: 0,
      total: data?.length || 0,
    };

    data?.forEach((vote) => {
      stats[vote.vibe]++;
    });

    return stats;
  },

  async getUserVoteForToday(venueId: string): Promise<VibeType | null> {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session?.user?.id) return null;

    const todayStart = new Date(new Date().setHours(0, 0, 0, 0)).toISOString();

    const { data, error } = await supabase
      .from('vibe_votes')
      .select('vibe')
      .eq('venue_id', venueId)
      .eq('user_id', session.user.id)
      .gte('created_at', todayStart)
      .maybeSingle();

    if (error) throw error;
    return data?.vibe || null;
  },

  subscribeToVibeStats(venueId: string, callback: (stats: VibeStats) => void) {
    const subscription = supabase
      .channel(`vibe:${venueId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'vibe_votes',
          filter: `venue_id=eq.${venueId}`,
        },
        async () => {
          const stats = await this.getVibeStats(venueId);
          callback(stats);
        }
      )
      .subscribe();

    return subscription;
  },
};
