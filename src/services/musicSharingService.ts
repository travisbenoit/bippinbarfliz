import { supabase } from '@/lib/supabase';
import { Database } from '@/lib/database.types';

type MusicShare = Database['public']['Tables']['music_shares']['Row'];
type MusicShareInsert = Database['public']['Tables']['music_shares']['Insert'];

export const musicSharingService = {
  async shareMusic(
    recipientId: string,
    songData: {
      songId: string;
      songTitle: string;
      artistName: string;
      platform: 'spotify' | 'apple_music' | 'youtube_music';
      externalUrl: string;
      albumArtUrl?: string;
      previewUrl?: string;
    },
    message?: string,
    swarmId?: string,
    venueId?: string
  ) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('music_shares')
      .insert({
        sender_id: user.id,
        recipient_id: recipientId,
        song_id: songData.songId,
        song_title: songData.songTitle,
        artist_name: songData.artistName,
        platform: songData.platform,
        external_url: songData.externalUrl,
        album_art_url: songData.albumArtUrl,
        preview_url: songData.previewUrl,
        message,
        swarm_id: swarmId,
        venue_id: venueId,
        status: 'pending',
      } as MusicShareInsert)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getReceivedMusic(limit = 50) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('music_shares')
      .select(`
        *,
        sender:users!music_shares_sender_id_fkey(id, name, avatar_url)
      `)
      .eq('recipient_id', user.id)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  },

  async getSentMusic(limit = 50) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('music_shares')
      .select(`
        *,
        recipient:users!music_shares_recipient_id_fkey(id, name, avatar_url)
      `)
      .eq('sender_id', user.id)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  },

  async getSwarmMusic(swarmId: string, limit = 50) {
    const { data, error } = await supabase
      .from('music_shares')
      .select(`
        *,
        sender:users!music_shares_sender_id_fkey(id, name, avatar_url)
      `)
      .eq('swarm_id', swarmId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;
    return data || [];
  },

  async updateMusicStatus(
    musicId: string,
    status: 'pending' | 'played' | 'saved' | 'expired'
  ) {
    const updateData: any = { status };
    if (status === 'played') {
      updateData.played_at = new Date().toISOString();
    }

    const { data, error } = await supabase
      .from('music_shares')
      .update(updateData)
      .eq('id', musicId)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getReceivedMusicCount() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { count, error } = await supabase
      .from('music_shares')
      .select('*', { count: 'exact', head: true })
      .eq('recipient_id', user.id)
      .eq('status', 'pending');

    if (error) throw error;
    return count || 0;
  },

  async deleteMusic(musicId: string) {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error } = await supabase
      .from('music_shares')
      .delete()
      .eq('id', musicId)
      .eq('sender_id', user.id);

    if (error) throw error;
  },

  async expirePendingMusic(daysOld = 30) {
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() - daysOld);

    const { error } = await supabase
      .from('music_shares')
      .update({ status: 'expired' })
      .eq('status', 'pending')
      .lt('created_at', expiryDate.toISOString());

    if (error) throw error;
  },
};
