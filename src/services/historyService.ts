import { supabase } from '@/lib/supabase';
import { Database } from '@/lib/database.types';

type ActivityHistory = Database['public']['Tables']['user_activity_history']['Row'];
type ActivityHistoryInsert = Database['public']['Tables']['user_activity_history']['Insert'];

type ActivityType = 'uber_ride' | 'venue_visit' | 'swarm_join' | 'gift_sent' | 'message_sent' | 'music_shared' | 'other';

export const historyService = {
  async logActivity(
    activityType: ActivityType,
    activityData: Record<string, any>,
    options?: {
      latitude?: number;
      longitude?: number;
      venueId?: string;
      relatedUserId?: string;
    }
  ) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('user_activity_history')
      .insert({
        user_id: user.id,
        activity_type: activityType,
        activity_data: activityData,
        location_lat: options?.latitude,
        location_lng: options?.longitude,
        venue_id: options?.venueId,
        related_user_id: options?.relatedUserId,
      } as ActivityHistoryInsert)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getActivityHistory(limit = 50, activityType?: ActivityType) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    let query = supabase
      .from('user_activity_history')
      .select(`
        *,
        venue:venues!venue_id(id, name, address),
        related_user:users!related_user_id(id, name, avatar_url)
      `)
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (activityType) {
      query = query.eq('activity_type', activityType);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data || [];
  },

  async deleteActivity(activityId: string) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await supabase
      .from('user_activity_history')
      .delete()
      .eq('id', activityId)
      .eq('user_id', user.id);

    if (error) throw error;
  },

  async deleteAllActivity() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await supabase
      .from('user_activity_history')
      .delete()
      .eq('user_id', user.id);

    if (error) throw error;
  },

  async deleteActivityByType(activityType: ActivityType) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await supabase
      .from('user_activity_history')
      .delete()
      .eq('user_id', user.id)
      .eq('activity_type', activityType);

    if (error) throw error;
  },

  async getActivityCount(activityType?: ActivityType) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    let query = supabase
      .from('user_activity_history')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.id);

    if (activityType) {
      query = query.eq('activity_type', activityType);
    }

    const { count, error } = await query;

    if (error) throw error;
    return count || 0;
  },

  async searchActivity(searchTerm: string, limit = 50) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('user_activity_history')
      .select(`
        *,
        venue:venues!venue_id(id, name, address),
        related_user:users!related_user_id(id, name, avatar_url)
      `)
      .eq('user_id', user.id)
      .textSearch('activity_data', searchTerm)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  },
};
