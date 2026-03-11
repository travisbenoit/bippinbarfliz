import { supabase } from '../lib/supabase';

export type FriendshipStatus = 'pending' | 'accepted' | 'declined' | 'blocked';

export interface FriendUser {
  id: string;
  name: string;
  avatar_url: string | null;
  tonight_status: string | null;
  home_city: string | null;
  occupation: string | null;
  vibe_tags: string[];
}

export interface Friendship {
  id: string;
  user_id: string;
  friend_id: string;
  status: FriendshipStatus;
  requested_at: string;
  responded_at: string | null;
  friend?: FriendUser;
  requester?: FriendUser;
}

export interface CrossingPath {
  other_user_id: string;
  venue_id: string;
  overlap_start: string;
  overlap_end: string;
  other_entered_at: string;
  other_left_at: string;
  venue?: {
    id: string;
    name: string;
    address: string | null;
    place_type: string | null;
    google_place_id: string | null;
  };
  other_user?: FriendUser & { dob?: string; bio?: string; ghost_mode?: boolean };
}

export interface VenueHistory {
  venue_id: string;
  entered_at: string;
  left_at: string | null;
  venue?: {
    id: string;
    name: string;
    address: string | null;
    place_type: string | null;
    google_place_id: string | null;
  };
  crossing_paths?: CrossingPath[];
}

export const friendsService = {
  async getFriends(): Promise<Friendship[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];

    const { data, error } = await supabase
      .from('friendships')
      .select(`
        *,
        friend:users!friendships_friend_id_fkey(id, name, avatar_url, tonight_status, home_city, occupation, vibe_tags),
        requester:users!friendships_user_id_fkey(id, name, avatar_url, tonight_status, home_city, occupation, vibe_tags)
      `)
      .or(`user_id.eq.${user.id},friend_id.eq.${user.id}`)
      .eq('status', 'accepted');

    if (error) throw error;
    return data || [];
  },

  async getPendingRequests(): Promise<Friendship[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];

    const { data, error } = await supabase
      .from('friendships')
      .select(`
        *,
        requester:users!friendships_user_id_fkey(id, name, avatar_url, tonight_status, home_city, occupation, vibe_tags)
      `)
      .eq('friend_id', user.id)
      .eq('status', 'pending');

    if (error) throw error;
    return data || [];
  },

  async getSentRequests(): Promise<Friendship[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];

    const { data, error } = await supabase
      .from('friendships')
      .select(`
        *,
        friend:users!friendships_friend_id_fkey(id, name, avatar_url, tonight_status, home_city, occupation, vibe_tags)
      `)
      .eq('user_id', user.id)
      .eq('status', 'pending');

    if (error) throw error;
    return data || [];
  },

  async getFriendshipStatus(otherUserId: string): Promise<FriendshipStatus | null> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;

    const { data } = await supabase
      .from('friendships')
      .select('status, user_id, friend_id')
      .or(
        `and(user_id.eq.${user.id},friend_id.eq.${otherUserId}),and(user_id.eq.${otherUserId},friend_id.eq.${user.id})`
      )
      .maybeSingle();

    return data ? data.status as FriendshipStatus : null;
  },

  async getFriendshipRow(otherUserId: string): Promise<{ id: string; status: FriendshipStatus; user_id: string; friend_id: string } | null> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;

    const { data } = await supabase
      .from('friendships')
      .select('id, status, user_id, friend_id')
      .or(
        `and(user_id.eq.${user.id},friend_id.eq.${otherUserId}),and(user_id.eq.${otherUserId},friend_id.eq.${user.id})`
      )
      .maybeSingle();

    return data || null;
  },

  async sendFriendRequest(toUserId: string): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data: block } = await supabase
      .from('user_blocks')
      .select('id')
      .eq('blocker_id', toUserId)
      .eq('blocked_id', user.id)
      .maybeSingle();

    if (block) throw new Error('You cannot send a friend request to this user.');

    const existing = await this.getFriendshipRow(toUserId);
    if (existing) {
      if (existing.status === 'accepted') throw new Error('You are already friends.');
      if (existing.status === 'pending' && existing.user_id === user.id) throw new Error('Friend request already sent.');
      if (existing.status === 'pending' && existing.friend_id === user.id) {
        await this.acceptFriendRequest(existing.id);
        return;
      }
    }

    const { error } = await supabase
      .from('friendships')
      .insert({ user_id: user.id, friend_id: toUserId, status: 'pending' });

    if (error) throw error;


  },

  async acceptFriendRequest(friendshipId: string): Promise<void> {
    const { error } = await supabase
      .from('friendships')
      .update({ status: 'accepted', responded_at: new Date().toISOString() })
      .eq('id', friendshipId);

    if (error) throw error;
  },

  async declineFriendRequest(friendshipId: string): Promise<void> {
    const { error } = await supabase
      .from('friendships')
      .delete()
      .eq('id', friendshipId);

    if (error) throw error;
  },

  async removeFriend(friendshipId: string): Promise<void> {
    const { error } = await supabase
      .from('friendships')
      .delete()
      .eq('id', friendshipId);

    if (error) throw error;
  },

  async cancelFriendRequest(friendshipId: string): Promise<void> {
    const { error } = await supabase
      .from('friendships')
      .delete()
      .eq('id', friendshipId);

    if (error) throw error;
  },

  async blockUser(targetUserId: string): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Remove any existing friendship row between the two
    await supabase
      .from('friendships')
      .delete()
      .or(
        `and(user_id.eq.${user.id},friend_id.eq.${targetUserId}),and(user_id.eq.${targetUserId},friend_id.eq.${user.id})`
      );

    // Insert block
    const { error } = await supabase
      .from('user_blocks')
      .insert({ blocking_user_id: user.id, blocked_user_id: targetUserId });

    if (error && !error.message.includes('duplicate')) throw error;
  },

  async unblockUser(targetUserId: string): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await supabase
      .from('user_blocks')
      .delete()
      .eq('blocking_user_id', user.id)
      .eq('blocked_user_id', targetUserId);

    if (error) throw error;
  },

  async getBlockedUsers(): Promise<string[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];

    const { data } = await supabase
      .from('user_blocks')
      .select('blocked_user_id')
      .eq('blocking_user_id', user.id);

    return (data || []).map((b: any) => b.blocked_user_id);
  },

  async isBlockedBy(otherUserId: string): Promise<boolean> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return false;

    const { data } = await supabase
      .from('user_blocks')
      .select('id')
      .eq('blocking_user_id', otherUserId)
      .eq('blocked_user_id', user.id)
      .maybeSingle();

    return !!data;
  },

  async getVenueHistory(days = 7): Promise<VenueHistory[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];

    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

    const { data, error } = await supabase
      .from('user_venue_presence')
      .select(`
        venue_id,
        entered_at,
        left_at,
        venue:bars(id, name, address, place_type, google_place_id)
      `)
      .eq('user_id', user.id)
      .gte('entered_at', since)
      .order('entered_at', { ascending: false });

    if (error) throw error;
    return (data || []) as VenueHistory[];
  },

  async getCrossingPathsForVenue(venueId: string, enteredAt: string): Promise<CrossingPath[]> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];

    // Find other users who overlapped at this venue within 24 hours of this visit
    const windowStart = new Date(new Date(enteredAt).getTime() - 24 * 60 * 60 * 1000).toISOString();
    const windowEnd = new Date(new Date(enteredAt).getTime() + 24 * 60 * 60 * 1000).toISOString();

    const { data, error } = await supabase
      .from('user_venue_presence')
      .select(`
        user_id,
        venue_id,
        entered_at,
        left_at,
        other_user:users!user_venue_presence_user_id_fkey(id, name, avatar_url, tonight_status, home_city, occupation, vibe_tags, ghost_mode)
      `)
      .eq('venue_id', venueId)
      .neq('user_id', user.id)
      .gte('entered_at', windowStart)
      .lte('entered_at', windowEnd);

    if (error) return [];

    const rows = (data || []) as any[];

    // Filter out ghost mode users
    const visible = rows.filter((r) => !r.other_user?.ghost_mode);

    // Also filter out users who have blocked the current user
    const blockedByCheck = await Promise.all(
      visible.map(async (r) => {
        const blocked = await this.isBlockedBy(r.user_id);
        return { ...r, isBlockedBy: blocked };
      })
    );

    return blockedByCheck
      .filter((r) => !r.isBlockedBy)
      .map((r) => ({
        other_user_id: r.user_id,
        venue_id: r.venue_id,
        overlap_start: r.entered_at,
        overlap_end: r.left_at || new Date().toISOString(),
        other_entered_at: r.entered_at,
        other_left_at: r.left_at || new Date().toISOString(),
        other_user: r.other_user,
      }));
  },

  getFriendProfile(friendship: Friendship, currentUserId: string): FriendUser | null {
    if (friendship.user_id === currentUserId) {
      return friendship.friend || null;
    }
    return friendship.requester || null;
  },
};
