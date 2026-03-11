import { supabase } from '@/lib/supabase';
import { Database } from '@/lib/database.types';
import { sendPushToUser } from './pushService';

type UserGift = Database['public']['Tables']['user_gifts']['Row'];
type UserGiftInsert = Database['public']['Tables']['user_gifts']['Insert'];

export const giftsService = {
  async sendGift(
    toUserId: string,
    itemId: string,
    message?: string,
    contextType?: 'direct_message' | 'profile' | 'swarm' | 'venue',
    contextId?: string
  ) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('user_gifts')
      .insert({
        from_user_id: user.id,
        to_user_id: toUserId,
        item_id: itemId,
        message,
        context_type: contextType || 'profile',
        context_id: contextId,
        status: 'sent',
      } as UserGiftInsert)
      .select()
      .single();

    if (error) throw error;

    // Push to recipient (non-blocking)
    supabase.from('users').select('name').eq('id', user.id).maybeSingle().then(({ data: sender }) => {
      sendPushToUser(toUserId, {
        title: `${sender?.name || 'Someone'} sent you a gift 🎁`,
        body: message || 'You received a virtual gift!',
        url: '/gifts',
        tag: `gift-${user.id}`,
      }).catch(() => null);
    });

    return data;
  },

  async getReceivedGifts() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('user_gifts')
      .select(`
        *,
        from_user:users!user_gifts_from_user_id_fkey(id, name, avatar_url),
        item:virtual_items!user_gifts_item_id_fkey(id, name, emoji, category)
      `)
      .eq('to_user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  async getSentGifts() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('user_gifts')
      .select(`
        *,
        to_user:users!user_gifts_to_user_id_fkey(id, name, avatar_url),
        item:virtual_items!user_gifts_item_id_fkey(id, name, emoji, category)
      `)
      .eq('from_user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  async updateGiftStatus(giftId: string, status: 'sent' | 'viewed' | 'reacted', reaction?: string) {
    const update: any = { status };
    if (reaction) {
      update.reaction = reaction;
    }

    const { data, error } = await supabase
      .from('user_gifts')
      .update(update)
      .eq('id', giftId)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getGiftCount() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { count, error } = await supabase
      .from('user_gifts')
      .select('*', { count: 'exact', head: true })
      .eq('to_user_id', user.id)
      .eq('status', 'sent');

    if (error) throw error;
    return count || 0;
  },

  async deleteGift(giftId: string) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await supabase
      .from('user_gifts')
      .delete()
      .eq('id', giftId)
      .eq('from_user_id', user.id);

    if (error) throw error;
  },
};
