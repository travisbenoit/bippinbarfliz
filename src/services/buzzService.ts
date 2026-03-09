import { supabase } from '../lib/supabase';

export interface BuzzMessage {
  id: string;
  venue_id: string;
  user_id: string;
  body: string;
  report_count: number;
  created_at: string;
  expires_at: string;
  user?: {
    id: string;
    name: string;
    avatar_url: string | null;
  };
}

export const buzzService = {
  async postBuzz(venueId: string, body: string): Promise<BuzzMessage> {
    const { data: session } = await supabase.auth.getSession();
    if (!session?.user?.id) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('venue_buzz')
      .insert([
        {
          venue_id: venueId,
          user_id: session.user.id,
          body,
        },
      ])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getBuzzForVenue(venueId: string, limit = 50): Promise<BuzzMessage[]> {
    const { data, error } = await supabase
      .from('venue_buzz')
      .select('*, user:users!venue_buzz_user_id_fkey(id, name, avatar_url)')
      .eq('venue_id', venueId)
      .lt('report_count', 3)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return (data || []) as BuzzMessage[];
  },

  async deleteBuzz(buzzId: string): Promise<void> {
    const { data: session } = await supabase.auth.getSession();
    if (!session?.user?.id) throw new Error('Not authenticated');

    const { error } = await supabase
      .from('venue_buzz')
      .delete()
      .eq('id', buzzId)
      .eq('user_id', session.user.id);

    if (error) throw error;
  },

  async reportBuzz(buzzId: string): Promise<void> {
    const { error } = await supabase.rpc('report_buzz', {
      buzz_id: buzzId,
    });

    if (error) throw error;
  },

  subscribeToVenueBuzz(
    venueId: string,
    callback: (message: BuzzMessage) => void
  ) {
    const subscription = supabase
      .channel(`buzz:${venueId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'venue_buzz',
          filter: `venue_id=eq.${venueId}`,
        },
        async (payload: any) => {
          if (payload.new) {
            const newMsg = payload.new as BuzzMessage;
            const { data: userData } = await supabase
              .from('users')
              .select('id, name, avatar_url')
              .eq('id', newMsg.user_id)
              .maybeSingle();
            callback({ ...newMsg, user: userData || undefined });
          }
        }
      )
      .subscribe();

    return subscription;
  },
};
