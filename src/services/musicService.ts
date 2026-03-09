import { supabase } from '../lib/supabase';

export type MusicPlatform = 'spotify' | 'apple_music' | 'youtube_music';

export interface Song {
  id: string;
  title: string;
  artist: string;
  albumArtUrl?: string;
  previewUrl?: string;
  externalUrl: string;
  platform: MusicPlatform;
}

export interface MusicShare {
  id: string;
  sender_id: string;
  recipient_id: string;
  song_id: string;
  song_title: string;
  artist_name: string;
  album_art_url?: string;
  preview_url?: string;
  external_url: string;
  platform: MusicPlatform;
  message?: string;
  status: 'pending' | 'played' | 'saved' | 'expired';
  swarm_id?: string;
  venue_id?: string;
  created_at: string;
  played_at?: string;
  expires_at: string;
}

class MusicService {
  async searchSongs(query: string, platform: MusicPlatform = 'spotify'): Promise<Song[]> {
    if (!query.trim()) return [];

    switch (platform) {
      case 'spotify':
        return this.searchSpotify(query);
      case 'apple_music':
        return this.searchAppleMusic(query);
      case 'youtube_music':
        return this.searchYouTubeMusic(query);
      default:
        return [];
    }
  }

  private async searchSpotify(query: string): Promise<Song[]> {
    const { data: { session } } = await supabase.auth.getSession();

    const response = await fetch(
      `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/spotify-search`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${session?.access_token || import.meta.env.VITE_SUPABASE_ANON_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query }),
      }
    );

    if (!response.ok) {
      throw new Error('Spotify search unavailable. Try again later.');
    }

    const { songs } = await response.json();
    return songs || [];
  }

  private async searchAppleMusic(_query: string): Promise<Song[]> {
    throw new Error('Apple Music search is not yet available.');
  }

  private async searchYouTubeMusic(_query: string): Promise<Song[]> {
    throw new Error('YouTube Music search is not yet available.');
  }

  async sendMusicShare(params: {
    recipientId: string;
    song: Song;
    message?: string;
    swarmId?: string;
    venueId?: string;
  }): Promise<MusicShare | null> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;

    const { data, error } = await supabase
      .from('music_shares')
      .insert({
        sender_id: user.id,
        recipient_id: params.recipientId,
        song_id: params.song.id,
        song_title: params.song.title,
        artist_name: params.song.artist,
        album_art_url: params.song.albumArtUrl,
        preview_url: params.song.previewUrl,
        external_url: params.song.externalUrl,
        platform: params.song.platform,
        message: params.message,
        swarm_id: params.swarmId,
        venue_id: params.venueId,
        status: 'pending'
      })
      .select()
      .single();

    if (error) {
      console.error('Error sending music share:', error);
      return null;
    }

    return data;
  }

  async getMusicShares(userId: string): Promise<MusicShare[]> {
    const { data, error } = await supabase
      .from('music_shares')
      .select('*')
      .or(`sender_id.eq.${userId},recipient_id.eq.${userId}`)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching music shares:', error);
      return [];
    }

    return data || [];
  }

  async getReceivedMusicShares(userId: string): Promise<MusicShare[]> {
    const { data, error } = await supabase
      .from('music_shares')
      .select('*')
      .eq('recipient_id', userId)
      .eq('status', 'pending')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching received music shares:', error);
      return [];
    }

    return data || [];
  }

  async updateMusicShareStatus(
    shareId: string,
    status: 'played' | 'saved' | 'expired'
  ): Promise<boolean> {
    const { error } = await supabase
      .from('music_shares')
      .update({
        status,
        played_at: status === 'played' ? new Date().toISOString() : undefined
      })
      .eq('id', shareId);

    if (error) {
      console.error('Error updating music share status:', error);
      return false;
    }

    return true;
  }
}

export const musicService = new MusicService();
