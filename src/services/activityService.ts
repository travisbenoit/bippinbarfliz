import { supabase } from '../lib/supabase';
import { RealtimeChannel } from '@supabase/supabase-js';

export interface ActivityEvent {
  id: string;
  actor_user_id: string;
  actor_name: string;
  actor_avatar?: string;
  activity_type: 'venue_enter' | 'venue_leave' | 'swarm_join' | 'swarm_create' | 'friend_request_accepted' | 'status_update';
  venue_id?: string;
  venue_name?: string;
  swarm_id?: string;
  swarm_name?: string;
  metadata: Record<string, unknown>;
  created_at: string;
}

export interface AppNotification {
  id: string;
  recipient_user_id: string;
  actor_user_id?: string;
  actor_name?: string;
  actor_avatar?: string;
  notification_type: string;
  title: string;
  body: string;
  venue_id?: string;
  swarm_id?: string;
  is_read: boolean;
  created_at: string;
}

class ActivityService {
  private notifChannel: RealtimeChannel | null = null;
  private activityChannel: RealtimeChannel | null = null;

  async logActivity(
    activityType: ActivityEvent['activity_type'],
    opts: { venueId?: string; swarmId?: string; metadata?: Record<string, unknown> } = {}
  ): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    await supabase.from('activity_feed').insert({
      actor_user_id: user.id,
      activity_type: activityType,
      venue_id: opts.venueId || null,
      swarm_id: opts.swarmId || null,
      metadata: opts.metadata || {},
    });
  }

  async getFriendActivity(limit = 30): Promise<ActivityEvent[]> {
    const { data, error } = await supabase
      .from('activity_feed')
      .select(`
        id,
        actor_user_id,
        activity_type,
        venue_id,
        swarm_id,
        metadata,
        created_at,
        actor:users!activity_feed_actor_user_id_fkey(name, avatar_url),
        venue:venues!activity_feed_venue_id_fkey(name),
        swarm:swarms!activity_feed_swarm_id_fkey(title)
      `)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) {
      console.error('Error fetching activity feed:', error);
      return [];
    }

    return (data || []).map((item: any) => ({
      id: item.id,
      actor_user_id: item.actor_user_id,
      actor_name: item.actor?.name || 'Someone',
      actor_avatar: item.actor?.avatar_url,
      activity_type: item.activity_type,
      venue_id: item.venue_id,
      venue_name: item.venue?.name,
      swarm_id: item.swarm_id,
      swarm_name: item.swarm?.title,
      metadata: item.metadata || {},
      created_at: item.created_at,
    }));
  }

  async getNotifications(): Promise<AppNotification[]> {
    const { data, error } = await supabase
      .from('notifications')
      .select(`
        id,
        recipient_user_id,
        actor_user_id,
        notification_type,
        title,
        body,
        venue_id,
        swarm_id,
        is_read,
        created_at,
        actor:users!notifications_actor_user_id_fkey(name, avatar_url)
      `)
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) {
      console.error('Error fetching notifications:', error);
      return [];
    }

    return (data || []).map((n: any) => ({
      id: n.id,
      recipient_user_id: n.recipient_user_id,
      actor_user_id: n.actor_user_id,
      actor_name: n.actor?.name,
      actor_avatar: n.actor?.avatar_url,
      notification_type: n.notification_type,
      title: n.title,
      body: n.body,
      venue_id: n.venue_id,
      swarm_id: n.swarm_id,
      is_read: n.is_read,
      created_at: n.created_at,
    }));
  }

  async getUnreadCount(): Promise<number> {
    const { count, error } = await supabase
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('is_read', false);

    if (error) return 0;
    return count || 0;
  }

  async markAsRead(notificationId: string): Promise<void> {
    await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', notificationId);
  }

  async markAllAsRead(): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('recipient_user_id', user.id)
      .eq('is_read', false);
  }

  async createNotificationsForFriends(
    actorUserId: string,
    type: string,
    title: string,
    body: string,
    opts: { venueId?: string; swarmId?: string } = {}
  ): Promise<void> {
    const { data: friends } = await supabase
      .from('friendships')
      .select('user_id, friend_id')
      .eq('status', 'accepted')
      .or(`user_id.eq.${actorUserId},friend_id.eq.${actorUserId}`);

    if (!friends || friends.length === 0) return;

    const friendIds = friends.map(f => f.user_id === actorUserId ? f.friend_id : f.user_id);

    const notifications = friendIds.map(friendId => ({
      recipient_user_id: friendId,
      actor_user_id: actorUserId,
      notification_type: type,
      title,
      body,
      venue_id: opts.venueId || null,
      swarm_id: opts.swarmId || null,
    }));

    await supabase.from('notifications').insert(notifications);
  }

  subscribeToNotifications(callback: (notifications: AppNotification[]) => void): () => void {
    this.notifChannel = supabase
      .channel('notifications_inbox')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notifications' }, async () => {
        const notifs = await this.getNotifications();
        callback(notifs);
      })
      .subscribe();

    return () => {
      if (this.notifChannel) {
        supabase.removeChannel(this.notifChannel);
        this.notifChannel = null;
      }
    };
  }

  subscribeToActivityFeed(callback: (events: ActivityEvent[]) => void): () => void {
    this.activityChannel = supabase
      .channel('activity_feed_changes')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'activity_feed' }, async () => {
        const events = await this.getFriendActivity();
        callback(events);
      })
      .subscribe();

    return () => {
      if (this.activityChannel) {
        supabase.removeChannel(this.activityChannel);
        this.activityChannel = null;
      }
    };
  }
}

export const activityService = new ActivityService();
