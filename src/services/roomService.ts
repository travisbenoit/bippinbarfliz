import { supabase } from '../lib/supabase';

export type MessageType = 'text' | 'drink' | 'music' | 'prompt' | 'gif';
export type ReactionType = 'beer' | 'cocktail' | 'fire' | 'dance' | 'music' | 'whiskey' | 'heart' | 'laugh';
export type PollType = 'music' | 'energy' | 'drink';

export interface RoomMessage {
  id: string;
  venue_id: string;
  user_id: string;
  body: string;
  message_type: MessageType;
  metadata: Record<string, any> | null;
  report_count: number;
  created_at: string;
  expires_at: string;
  user?: {
    id: string;
    name: string;
    avatar_url: string | null;
    tonight_status: string | null;
    home_city: string | null;
  };
  reactions?: RoomReaction[];
}

export interface RoomReaction {
  id: string;
  message_id: string;
  user_id: string;
  reaction: ReactionType;
  created_at: string;
}

export interface RoomMoment {
  id: string;
  venue_id: string;
  user_id: string;
  media_url: string | null;
  caption: string | null;
  moment_type: 'photo' | 'video' | 'text';
  like_count: number;
  report_count: number;
  created_at: string;
  expires_at: string;
  user?: {
    id: string;
    name: string;
    avatar_url: string | null;
  };
}

export interface RoomPresenceUser {
  id: string;
  venue_id: string;
  user_id: string;
  joined_at: string;
  last_active_at: string;
  user?: {
    id: string;
    name: string;
    avatar_url: string | null;
    tonight_status: string | null;
    home_city: string | null;
    favorite_drinks: string[] | null;
  };
}

export interface WallPhoto {
  id: string;
  venue_id: string;
  user_id: string;
  photo_url: string;
  caption: string | null;
  like_count: number;
  report_count: number;
  created_at: string;
  user?: {
    id: string;
    name: string;
    avatar_url: string | null;
  };
}

export interface RoomStats {
  message_count: number;
  active_users: number;
  top_drink: string | null;
  top_music: string | null;
}

export interface VibePollResults {
  music: Record<string, number>;
  energy: Record<string, number>;
  drink: Record<string, number>;
}

export interface UserVotes {
  music: string | null;
  energy: string | null;
  drink: string | null;
}

const RATE_LIMIT_MS = 5000;

export const roomService = {
  async getMessages(venueId: string, limit = 60): Promise<RoomMessage[]> {
    const { data, error } = await supabase
      .from('venue_room_messages')
      .select(`
        *,
        user:users!venue_room_messages_user_id_fkey(id, name, avatar_url, tonight_status, home_city)
      `)
      .eq('venue_id', venueId)
      .gt('expires_at', new Date().toISOString())
      .lt('report_count', 3)
      .order('created_at', { ascending: true })
      .limit(limit);

    if (error) throw error;
    return (data || []) as RoomMessage[];
  },

  async postMessage(
    venueId: string,
    body: string,
    type: MessageType = 'text',
    metadata?: Record<string, any>
  ): Promise<RoomMessage> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: presence } = await supabase
      .from('venue_room_presence')
      .select('last_post_at')
      .eq('venue_id', venueId)
      .eq('user_id', user.id)
      .maybeSingle();

    if (presence?.last_post_at) {
      const elapsed = Date.now() - new Date(presence.last_post_at).getTime();
      if (elapsed < RATE_LIMIT_MS) {
        throw new Error('rate_limit');
      }
    }

    const { data, error } = await supabase
      .from('venue_room_messages')
      .insert([{ venue_id: venueId, user_id: user.id, body, message_type: type, metadata: metadata || null }])
      .select(`*, user:users!venue_room_messages_user_id_fkey(id, name, avatar_url, tonight_status, home_city)`)
      .single();

    if (error) throw error;

    await supabase
      .from('venue_room_presence')
      .update({ last_post_at: new Date().toISOString(), last_active_at: new Date().toISOString() })
      .eq('venue_id', venueId)
      .eq('user_id', user.id);

    return data as RoomMessage;
  },

  async deleteMessage(messageId: string): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const { error } = await supabase
      .from('venue_room_messages')
      .delete()
      .eq('id', messageId)
      .eq('user_id', user.id);
    if (error) throw error;
  },

  async reportMessage(messageId: string): Promise<void> {
    const { error } = await supabase.rpc('report_room_message', { p_message_id: messageId });
    if (error) throw error;
  },

  async addReaction(messageId: string, reaction: ReactionType): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    await supabase
      .from('venue_room_reactions')
      .insert([{ message_id: messageId, user_id: user.id, reaction }])
      .select();
  },

  async removeReaction(messageId: string, reaction: ReactionType): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    await supabase
      .from('venue_room_reactions')
      .delete()
      .eq('message_id', messageId)
      .eq('user_id', user.id)
      .eq('reaction', reaction);
  },

  async getReactionsForMessages(messageIds: string[]): Promise<RoomReaction[]> {
    if (messageIds.length === 0) return [];
    const { data, error } = await supabase
      .from('venue_room_reactions')
      .select('*')
      .in('message_id', messageIds);
    if (error) throw error;
    return (data || []) as RoomReaction[];
  },

  async getMoments(venueId: string): Promise<RoomMoment[]> {
    const { data, error } = await supabase
      .from('venue_room_moments')
      .select(`*, user:users!venue_room_moments_user_id_fkey(id, name, avatar_url)`)
      .eq('venue_id', venueId)
      .gt('expires_at', new Date().toISOString())
      .lt('report_count', 3)
      .order('created_at', { ascending: false })
      .limit(30);
    if (error) throw error;
    return (data || []) as RoomMoment[];
  },

  async postMoment(venueId: string, caption: string, momentType: 'text' | 'photo' | 'video' = 'text', mediaUrl?: string): Promise<RoomMoment> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const { data, error } = await supabase
      .from('venue_room_moments')
      .insert([{ venue_id: venueId, user_id: user.id, caption, moment_type: momentType, media_url: mediaUrl || null }])
      .select(`*, user:users!venue_room_moments_user_id_fkey(id, name, avatar_url)`)
      .single();
    if (error) throw error;
    return data as RoomMoment;
  },

  async deleteMoment(momentId: string): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    await supabase.from('venue_room_moments').delete().eq('id', momentId).eq('user_id', user.id);
  },

  async reportMoment(momentId: string): Promise<void> {
    const { error } = await supabase.rpc('report_room_moment', { p_moment_id: momentId });
    if (error) throw error;
  },

  async toggleMomentLike(momentId: string): Promise<{ liked: boolean }> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const { data, error } = await supabase.rpc('toggle_moment_like', {
      p_moment_id: momentId,
      p_user_id: user.id,
    });
    if (error) throw error;
    return data as { liked: boolean };
  },

  async getUserMomentLikes(venueId: string): Promise<Set<string>> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return new Set();
    const { data } = await supabase
      .from('venue_room_moment_likes')
      .select('moment_id')
      .eq('user_id', user.id)
      .in('moment_id',
        (await supabase
          .from('venue_room_moments')
          .select('id')
          .eq('venue_id', venueId)
          .then(r => (r.data || []).map((m: any) => m.id)))
      );
    return new Set((data || []).map((r: any) => r.moment_id));
  },

  async getPresence(venueId: string): Promise<RoomPresenceUser[]> {
    const { data, error } = await supabase
      .from('venue_room_presence')
      .select(`
        *,
        user:users!venue_room_presence_user_id_fkey(id, name, avatar_url, tonight_status, home_city, favorite_drinks)
      `)
      .eq('venue_id', venueId)
      .gt('last_active_at', new Date(Date.now() - 30 * 60 * 1000).toISOString())
      .order('joined_at', { ascending: true });
    if (error) throw error;
    return (data || []) as RoomPresenceUser[];
  },

  async joinRoom(venueId: string): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const { error } = await supabase.rpc('upsert_room_presence', {
      p_venue_id: venueId,
      p_user_id: user.id,
    });
    if (error) throw error;
  },

  async leaveRoom(venueId: string): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;
    await supabase
      .from('venue_room_presence')
      .delete()
      .eq('venue_id', venueId)
      .eq('user_id', user.id);
  },

  async getStats(venueId: string): Promise<RoomStats> {
    const { data, error } = await supabase.rpc('get_room_stats', { p_venue_id: venueId });
    if (error) throw error;
    return (data as RoomStats) || { message_count: 0, active_users: 0, top_drink: null, top_music: null };
  },

  async getVibePollResults(venueId: string): Promise<VibePollResults> {
    const { data, error } = await supabase
      .from('venue_room_vibe_polls')
      .select('poll_type, vote_value')
      .eq('venue_id', venueId);
    if (error) throw error;

    const results: VibePollResults = { music: {}, energy: {}, drink: {} };
    (data || []).forEach((row: any) => {
      const pt = row.poll_type as PollType;
      results[pt][row.vote_value] = (results[pt][row.vote_value] || 0) + 1;
    });
    return results;
  },

  async getUserVotes(venueId: string): Promise<UserVotes> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return { music: null, energy: null, drink: null };
    const { data } = await supabase
      .from('venue_room_vibe_polls')
      .select('poll_type, vote_value')
      .eq('venue_id', venueId)
      .eq('user_id', user.id);
    const votes: UserVotes = { music: null, energy: null, drink: null };
    (data || []).forEach((row: any) => {
      votes[row.poll_type as PollType] = row.vote_value;
    });
    return votes;
  },

  async castVibePollVote(venueId: string, pollType: PollType, value: string): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: existing } = await supabase
      .from('venue_room_vibe_polls')
      .select('id')
      .eq('venue_id', venueId)
      .eq('user_id', user.id)
      .eq('poll_type', pollType)
      .maybeSingle();

    if (existing) {
      await supabase
        .from('venue_room_vibe_polls')
        .update({ vote_value: value })
        .eq('id', existing.id);
    } else {
      await supabase
        .from('venue_room_vibe_polls')
        .insert([{ venue_id: venueId, user_id: user.id, poll_type: pollType, vote_value: value }]);
    }
  },

  subscribeToMessages(venueId: string, callback: (msg: RoomMessage) => void) {
    return supabase
      .channel(`room-messages:${venueId}`)
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'venue_room_messages',
        filter: `venue_id=eq.${venueId}`,
      }, async (payload) => {
        const newMsg = payload.new as RoomMessage;
        const { data } = await supabase
          .from('users')
          .select('id, name, avatar_url, tonight_status, home_city')
          .eq('id', newMsg.user_id)
          .maybeSingle();
        callback({ ...newMsg, user: data || undefined });
      })
      .subscribe();
  },

  subscribeToReactions(venueId: string, callback: () => void) {
    return supabase
      .channel(`room-reactions:${venueId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'venue_room_reactions',
      }, callback)
      .subscribe();
  },

  subscribeToPresence(venueId: string, callback: () => void) {
    return supabase
      .channel(`room-presence:${venueId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'venue_room_presence',
        filter: `venue_id=eq.${venueId}`,
      }, callback)
      .subscribe();
  },

  subscribeToMoments(venueId: string, callback: () => void) {
    return supabase
      .channel(`room-moments:${venueId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'venue_room_moments',
        filter: `venue_id=eq.${venueId}`,
      }, callback)
      .subscribe();
  },

  subscribeToVibePolls(venueId: string, callback: () => void) {
    return supabase
      .channel(`room-vibepolls:${venueId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'venue_room_vibe_polls',
        filter: `venue_id=eq.${venueId}`,
      }, callback)
      .subscribe();
  },

  async getWallPhotos(venueId: string, page = 0, pageSize = 24): Promise<WallPhoto[]> {
    const { data, error } = await supabase
      .from('venue_wall_photos')
      .select('*, user:users!venue_wall_photos_user_id_fkey(id, name, avatar_url)')
      .eq('venue_id', venueId)
      .order('created_at', { ascending: false })
      .range(page * pageSize, (page + 1) * pageSize - 1);
    if (error) throw error;
    return (data || []) as WallPhoto[];
  },

  async postWallPhoto(venueId: string, photoUrl: string, caption: string): Promise<WallPhoto> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const { data, error } = await supabase
      .from('venue_wall_photos')
      .insert([{ venue_id: venueId, user_id: user.id, photo_url: photoUrl, caption: caption || null }])
      .select('*, user:users!venue_wall_photos_user_id_fkey(id, name, avatar_url)')
      .single();
    if (error) throw error;
    return data as WallPhoto;
  },

  async deleteWallPhoto(photoId: string): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const { error } = await supabase
      .from('venue_wall_photos')
      .delete()
      .eq('id', photoId)
      .eq('user_id', user.id);
    if (error) throw error;
  },

  async toggleWallPhotoLike(photoId: string): Promise<{ liked: boolean }> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const { data, error } = await supabase.rpc('toggle_wall_photo_like', {
      p_photo_id: photoId,
      p_user_id: user.id,
    });
    if (error) throw error;
    return data as { liked: boolean };
  },

  async reportWallPhoto(photoId: string): Promise<void> {
    const { error } = await supabase.rpc('report_wall_photo', { p_photo_id: photoId });
    if (error) throw error;
  },

  async getUserWallPhotoLikes(venueId: string): Promise<Set<string>> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return new Set();
    const photoIds = await supabase
      .from('venue_wall_photos')
      .select('id')
      .eq('venue_id', venueId)
      .then(r => (r.data || []).map((p: any) => p.id));
    if (photoIds.length === 0) return new Set();
    const { data } = await supabase
      .from('venue_wall_photo_likes')
      .select('photo_id')
      .eq('user_id', user.id)
      .in('photo_id', photoIds);
    return new Set((data || []).map((r: any) => r.photo_id));
  },

  subscribeToWallPhotos(venueId: string, callback: () => void) {
    return supabase
      .channel(`wall-photos:${venueId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'venue_wall_photos',
        filter: `venue_id=eq.${venueId}`,
      }, callback)
      .subscribe();
  },
};
