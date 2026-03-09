import { supabase } from '@/lib/supabase';
import { Database } from '@/lib/database.types';

type EmojiReaction = Database['public']['Tables']['emoji_reactions']['Row'];
type EmojiReactionInsert = Database['public']['Tables']['emoji_reactions']['Insert'];

type TargetType = 'message' | 'post' | 'profile' | 'venue' | 'swarm';

export const reactionsService = {
  async addReaction(
    targetId: string,
    targetType: TargetType,
    emoji: string
  ) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('emoji_reactions')
      .insert({
        user_id: user.id,
        target_id: targetId,
        target_type: targetType,
        emoji,
      } as EmojiReactionInsert)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async removeReaction(
    targetId: string,
    targetType: TargetType,
    emoji: string
  ) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await supabase
      .from('emoji_reactions')
      .delete()
      .eq('user_id', user.id)
      .eq('target_id', targetId)
      .eq('target_type', targetType)
      .eq('emoji', emoji);

    if (error) throw error;
  },

  async getReactions(targetId: string, targetType: TargetType) {
    const { data, error } = await supabase
      .from('emoji_reactions')
      .select(`
        *,
        user:users!emoji_reactions_user_id_fkey(id, name, avatar_url)
      `)
      .eq('target_id', targetId)
      .eq('target_type', targetType)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  async getReactionCounts(targetId: string, targetType: TargetType) {
    const { data, error } = await supabase
      .from('emoji_reactions')
      .select('emoji', { count: 'exact' })
      .eq('target_id', targetId)
      .eq('target_type', targetType);

    if (error) throw error;

    const counts = new Map<string, number>();
    (data || []).forEach((reaction) => {
      const count = counts.get(reaction.emoji) || 0;
      counts.set(reaction.emoji, count + 1);
    });

    return Object.fromEntries(counts);
  },

  async getUserReaction(
    targetId: string,
    targetType: TargetType,
    userId: string
  ) {
    const { data, error } = await supabase
      .from('emoji_reactions')
      .select('emoji')
      .eq('target_id', targetId)
      .eq('target_type', targetType)
      .eq('user_id', userId);

    if (error) throw error;
    return (data || []).map((r) => r.emoji);
  },

  async hasReacted(
    targetId: string,
    targetType: TargetType,
    emoji: string
  ) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return false;

    const { data, error } = await supabase
      .from('emoji_reactions')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', user.id)
      .eq('target_id', targetId)
      .eq('target_type', targetType)
      .eq('emoji', emoji);

    if (error) return false;
    return (data?.length || 0) > 0;
  },
};
