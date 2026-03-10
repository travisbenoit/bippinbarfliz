import { supabase } from '@/lib/supabase';
import { Database } from '@/lib/database.types';
import { sendPushToUser } from './pushService';

type Message = Database['public']['Tables']['messages']['Row'];
type MessageInsert = Database['public']['Tables']['messages']['Insert'];

export const messagesService = {
  async checkIfBlocked(otherUserId: string): Promise<boolean> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return false;

    const { count, error } = await supabase
      .from('user_blocks')
      .select('*', { count: 'exact', head: true })
      .or(
        `and(blocked_id.eq.${user.id},blocker_id.eq.${otherUserId}),` +
        `and(blocked_id.eq.${otherUserId},blocker_id.eq.${user.id})`
      );

    if (error) {
      console.error('Error checking block status:', error);
      return false;
    }

    return (count || 0) > 0;
  },

  async sendDMMessage(
    recipientId: string,
    body: string,
    mediaUrl?: string
  ) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const isBlocked = await messagesService.checkIfBlocked(recipientId);
    if (isBlocked) throw new Error('You cannot message this user');

    const [userA, userB] = [user.id, recipientId].sort();

    const { data, error } = await supabase
      .from('messages')
      .insert({
        conversation_type: 'dm',
        dm_user_a: userA,
        dm_user_b: userB,
        sender_user_id: user.id,
        body,
        media_url: mediaUrl,
        delivery_status: 'sent',
      } as MessageInsert)
      .select()
      .single();

    if (error) throw error;

    // Fire push notification to recipient (non-blocking)
    const { data: senderProfile } = await supabase
      .from('users')
      .select('name')
      .eq('id', user.id)
      .maybeSingle();
    const senderName = senderProfile?.name || 'Someone';
    sendPushToUser(recipientId, {
      title: senderName,
      body: body.length > 100 ? body.slice(0, 97) + '…' : body,
      url: '/messages',
      tag: `dm-${user.id}`,
    }).catch(() => null);

    return data;
  },

  async sendSwarmMessage(
    swarmId: string,
    body: string,
    mediaUrl?: string
  ) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('messages')
      .insert({
        conversation_type: 'swarm',
        swarm_id: swarmId,
        sender_user_id: user.id,
        body,
        media_url: mediaUrl,
        delivery_status: 'sent',
      } as MessageInsert)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getDMMessages(otherUserId: string, limit = 50, offset = 0) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const [userA, userB] = [user.id, otherUserId].sort();

    const { data, error } = await supabase
      .from('messages')
      .select(`
        *,
        sender:users!messages_sender_user_id_fkey(id, name, avatar_url)
      `)
      .eq('conversation_type', 'dm')
      .eq('dm_user_a', userA)
      .eq('dm_user_b', userB)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;
    return (data || []).reverse();
  },

  async getSwarmMessages(swarmId: string, limit = 50, offset = 0) {
    const { data, error } = await supabase
      .from('messages')
      .select(`
        *,
        sender:users!messages_sender_user_id_fkey(id, name, avatar_url)
      `)
      .eq('conversation_type', 'swarm')
      .eq('swarm_id', swarmId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;
    return (data || []).reverse();
  },

  async markAsRead(messageId: string) {
    const { data, error } = await supabase
      .from('messages')
      .update({
        read_at: new Date().toISOString(),
        delivery_status: 'read'
      })
      .eq('id', messageId)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async editMessage(messageId: string, newBody: string) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: message, error: fetchError } = await supabase
      .from('messages')
      .select('*')
      .eq('id', messageId)
      .maybeSingle();

    if (fetchError) throw fetchError;
    if (!message) throw new Error('Message not found');
    if (message.sender_user_id !== user.id) throw new Error('Can only edit your own messages');
    if (message.deleted_at) throw new Error('Cannot edit deleted message');

    const { data, error } = await supabase
      .from('messages')
      .update({
        body: newBody,
        edited_at: new Date().toISOString()
      })
      .eq('id', messageId)
      .select()
      .single();

    if (error) throw error;

    await supabase
      .from('message_edits')
      .insert({
        message_id: messageId,
        edited_by: user.id,
        previous_body: message.body,
      });

    return data;
  },

  async deleteMessage(messageId: string) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: message, error: fetchError } = await supabase
      .from('messages')
      .select('*')
      .eq('id', messageId)
      .maybeSingle();

    if (fetchError) throw fetchError;
    if (!message) throw new Error('Message not found');
    if (message.sender_user_id !== user.id) throw new Error('Can only delete your own messages');

    const { data, error } = await supabase
      .from('messages')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', messageId)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getDMConversations() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('messages')
      .select(`
        dm_user_a,
        dm_user_b,
        sender_user_id,
        body,
        created_at,
        read_at
      `)
      .eq('conversation_type', 'dm')
      .or(`dm_user_a.eq.${user.id},dm_user_b.eq.${user.id}`)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    if (error) throw error;

    const conversationMap = new Map<string, any>();
    (data || []).forEach((msg) => {
      const otherId = msg.dm_user_a === user.id ? msg.dm_user_b : msg.dm_user_a;
      if (!conversationMap.has(otherId)) {
        conversationMap.set(otherId, { ...msg, otherUserId: otherId });
      }
    });

    const otherUserIds = Array.from(conversationMap.keys());
    if (otherUserIds.length === 0) return [];

    const { data: profiles } = await supabase
      .from('users')
      .select('id, name, avatar_url, tonight_status')
      .in('id', otherUserIds);

    const profileMap = new Map((profiles || []).map(p => [p.id, p]));

    return Array.from(conversationMap.values()).map(msg => ({
      ...msg,
      otherUser: profileMap.get(msg.otherUserId) || null,
    }));
  },

  async getUnreadCount() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return 0;

    const { count, error } = await supabase
      .from('messages')
      .select('*', { count: 'exact', head: true })
      .eq('conversation_type', 'dm')
      .or(`dm_user_a.eq.${user.id},dm_user_b.eq.${user.id}`)
      .neq('sender_user_id', user.id)
      .is('read_at', null)
      .is('deleted_at', null);

    if (error) return 0;
    return count || 0;
  },

  subscribeToDMMessages(
    otherUserId: string,
    onMessage: (message: Message & { sender: { id: string; name: string; avatar_url: string | null } | null }) => void
  ) {
    let channel: any = null;
    let subscriptionPromise: Promise<any> | null = null;

    const setupSubscription = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;

      const [userA, userB] = [user.id, otherUserId].sort();

      channel = supabase
        .channel(`dm:${userA}:${userB}`)
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: 'messages',
            filter: `conversation_type=eq.dm`,
          },
          async (payload) => {
            const newMsg = payload.new as Message;
            if (newMsg.dm_user_a === userA && newMsg.dm_user_b === userB && !newMsg.deleted_at) {
              const { data: sender } = await supabase
                .from('users')
                .select('id, name, avatar_url')
                .eq('id', newMsg.sender_user_id)
                .maybeSingle();

              onMessage({ ...newMsg, sender });
            }
          }
        )
        .subscribe();

      return channel;
    };

    subscriptionPromise = setupSubscription();

    return {
      unsubscribe: async () => {
        if (channel) {
          supabase.removeChannel(channel);
        } else if (subscriptionPromise) {
          const resolvedChannel = await subscriptionPromise;
          if (resolvedChannel) {
            supabase.removeChannel(resolvedChannel);
          }
        }
      },
    };
  },

  subscribeToSwarmMessages(
    swarmId: string,
    onMessage: (message: Message & { sender: { id: string; name: string; avatar_url: string | null } | null }) => void
  ) {
    const channel = supabase
      .channel(`swarm:${swarmId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `swarm_id=eq.${swarmId}`,
        },
        async (payload) => {
          const newMsg = payload.new as Message;
          if (!newMsg.deleted_at) {
            const { data: sender } = await supabase
              .from('users')
              .select('id, name, avatar_url')
              .eq('id', newMsg.sender_user_id)
              .maybeSingle();

            onMessage({ ...newMsg, sender });
          }
        }
      )
      .subscribe();

    return {
      unsubscribe: () => {
        supabase.removeChannel(channel);
      },
    };
  },

  subscribeToAllMessages(
    onMessage: (message: Message) => void
  ) {
    const subscription = supabase.auth.getUser().then(({ data: { user } }) => {
      if (!user) return null;

      return supabase
        .channel(`user-messages:${user.id}`)
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: 'messages',
          },
          (payload) => {
            const newMsg = payload.new as Message;
            if (
              newMsg.dm_user_a === user.id ||
              newMsg.dm_user_b === user.id ||
              newMsg.sender_user_id === user.id
            ) {
              onMessage(newMsg);
            }
          }
        )
        .subscribe();
    });

    return {
      unsubscribe: async () => {
        const channel = await subscription;
        if (channel) {
          supabase.removeChannel(channel);
        }
      },
    };
  },
};

export async function markConversationAsRead(
  conversationTarget: string,
  type: 'dm' | 'swarm'
) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;

  const now = new Date().toISOString();

  if (type === 'dm') {
    const [userA, userB] = [user.id, conversationTarget].sort();
    await supabase
      .from('messages')
      .update({ read_at: now, delivery_status: 'read' })
      .eq('conversation_type', 'dm')
      .eq('dm_user_a', userA)
      .eq('dm_user_b', userB)
      .neq('sender_user_id', user.id)
      .is('read_at', null)
      .is('deleted_at', null);
  } else {
    await supabase
      .from('messages')
      .update({ read_at: now, delivery_status: 'read' })
      .eq('conversation_type', 'swarm')
      .eq('swarm_id', conversationTarget)
      .neq('sender_user_id', user.id)
      .is('read_at', null)
      .is('deleted_at', null);
  }
}
