export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string
          name: string
          dob: string
          is_21_plus_confirmed: boolean
          photos: Json
          bio: string
          vibe_tags: string[]
          favorite_drinks: string[]
          tonight_status: 'out_now' | 'going_out_soon' | 'staying_in'
          home_city: string
          privacy_mode: 'invisible' | 'friends_only' | 'nearby'
          last_known_lat: number | null
          last_known_lng: number | null
          last_active_at: string
          created_at: string
          venmo_username: string | null
          venmo_linked: boolean
          preferred_radius_meters: number | null
          weather_location: string | null
          looking_for: string | null
          fun_fact: string | null
          go_to_karaoke_song: string | null
          ideal_night_out: string | null
          conversation_starters: string[]
          interests: string[]
          occupation: string | null
          education: string | null
          spotify_username: string | null
          instagram_username: string | null
          first_drink_on_me: boolean
          verified_profile: boolean
          ghost_mode: boolean
          username?: string
          age: number | null
          avatar_url: string | null
          is_premium: boolean
          lush_coin_balance: number
          venue_preferences: string[]
          weather_enabled: boolean
          phone_number: string | null
          phone_country_code: string | null
          registration_country: string | null
          payment_provider: string | null
          payment_provider_username: string | null
          payment_provider_linked: boolean
        }
        Insert: {
          id: string
          name: string
          dob: string
          is_21_plus_confirmed?: boolean
          photos?: Json
          bio?: string
          vibe_tags?: string[]
          favorite_drinks?: string[]
          tonight_status?: 'out_now' | 'going_out_soon' | 'staying_in'
          home_city?: string
          privacy_mode?: 'invisible' | 'friends_only' | 'nearby'
          last_known_lat?: number | null
          last_known_lng?: number | null
          last_active_at?: string
          created_at?: string
          venmo_username?: string | null
          venmo_linked?: boolean
          preferred_radius_meters?: number | null
          weather_location?: string | null
          looking_for?: string | null
          fun_fact?: string | null
          go_to_karaoke_song?: string | null
          ideal_night_out?: string | null
          conversation_starters?: string[]
          interests?: string[]
          occupation?: string | null
          education?: string | null
          spotify_username?: string | null
          instagram_username?: string | null
          first_drink_on_me?: boolean
          verified_profile?: boolean
          ghost_mode?: boolean
          username?: string
          age?: number | null
          avatar_url?: string | null
          is_premium?: boolean
          lush_coin_balance?: number
          venue_preferences?: string[]
          weather_enabled?: boolean
          phone_number?: string | null
          phone_country_code?: string | null
          registration_country?: string | null
          payment_provider?: string | null
          payment_provider_username?: string | null
          payment_provider_linked?: boolean
        }
        Update: {
          id?: string
          name?: string
          dob?: string
          is_21_plus_confirmed?: boolean
          photos?: Json
          bio?: string
          vibe_tags?: string[]
          favorite_drinks?: string[]
          tonight_status?: 'out_now' | 'going_out_soon' | 'staying_in'
          home_city?: string
          privacy_mode?: 'invisible' | 'friends_only' | 'nearby'
          last_known_lat?: number | null
          last_known_lng?: number | null
          last_active_at?: string
          created_at?: string
          venmo_username?: string | null
          venmo_linked?: boolean
          preferred_radius_meters?: number | null
          weather_location?: string | null
          looking_for?: string | null
          fun_fact?: string | null
          go_to_karaoke_song?: string | null
          ideal_night_out?: string | null
          conversation_starters?: string[]
          interests?: string[]
          occupation?: string | null
          education?: string | null
          spotify_username?: string | null
          instagram_username?: string | null
          first_drink_on_me?: boolean
          verified_profile?: boolean
          ghost_mode?: boolean
          username?: string
          age?: number | null
          avatar_url?: string | null
          is_premium?: boolean
          lush_coin_balance?: number
          venue_preferences?: string[]
          weather_enabled?: boolean
          phone_number?: string | null
          phone_country_code?: string | null
          registration_country?: string | null
          payment_provider?: string | null
          payment_provider_username?: string | null
          payment_provider_linked?: boolean
        }
      }
      venues: {
        Row: {
          id: string
          name: string
          address: string
          lat: number
          lng: number
          latitude?: number
          longitude?: number
          category: string
          hours: Json
          verified: boolean
          created_at: string
          photo_url: string | null
          place_id: string | null
          rating: number | null
          user_ratings_total: number | null
          city: string | null
          state: string | null
          country: string
          postal_code: string | null
          type: string
          geofence_shape: Json | null
          geofence_radius_meters: number
          is_active: boolean
          metadata: Json
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          address: string
          lat: number
          lng: number
          latitude?: number
          longitude?: number
          category?: string
          hours?: Json
          verified?: boolean
          created_at?: string
          photo_url?: string | null
          place_id?: string | null
          rating?: number | null
          user_ratings_total?: number | null
          city?: string | null
          state?: string | null
          country?: string
          postal_code?: string | null
          type?: string
          geofence_shape?: Json | null
          geofence_radius_meters?: number
          is_active?: boolean
          metadata?: Json
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          address?: string
          lat?: number
          lng?: number
          latitude?: number
          longitude?: number
          category?: string
          hours?: Json
          verified?: boolean
          created_at?: string
          photo_url?: string | null
          place_id?: string | null
          rating?: number | null
          user_ratings_total?: number | null
          city?: string | null
          state?: string | null
          country?: string
          postal_code?: string | null
          type?: string
          geofence_shape?: Json | null
          geofence_radius_meters?: number
          is_active?: boolean
          metadata?: Json
          updated_at?: string
        }
      }
      swarms: {
        Row: {
          id: string
          host_user_id: string
          venue_id: string | null
          venue_name: string | null
          title: string
          description: string | null
          vibe_tags: string[]
          start_time: string | null
          end_time: string | null
          max_attendees: number | null
          max_size: number
          current_size: number
          join_mode: 'open' | 'friends' | 'invite_only' | 'request_approval'
          is_public: boolean
          status: 'active' | 'completed' | 'cancelled'
          created_at: string
          updated_at: string | null
        }
        Insert: {
          id?: string
          host_user_id: string
          venue_id?: string | null
          venue_name?: string | null
          title: string
          description?: string | null
          vibe_tags?: string[]
          start_time?: string | null
          end_time?: string | null
          max_attendees?: number | null
          max_size?: number
          current_size?: number
          join_mode?: 'open' | 'friends' | 'invite_only' | 'request_approval'
          is_public?: boolean
          status?: 'active' | 'completed' | 'cancelled'
          created_at?: string
          updated_at?: string | null
        }
        Update: {
          id?: string
          host_user_id?: string
          venue_id?: string | null
          venue_name?: string | null
          title?: string
          description?: string | null
          vibe_tags?: string[]
          start_time?: string | null
          end_time?: string | null
          max_attendees?: number | null
          max_size?: number
          current_size?: number
          join_mode?: 'open' | 'friends' | 'invite_only' | 'request_approval'
          is_public?: boolean
          status?: 'active' | 'completed' | 'cancelled'
          created_at?: string
          updated_at?: string | null
        }
      }
      swarm_members: {
        Row: {
          id: string
          swarm_id: string
          user_id: string
          role: 'host' | 'member'
          rsvp: 'going' | 'maybe'
          joined_at: string
        }
        Insert: {
          id?: string
          swarm_id: string
          user_id: string
          role?: 'host' | 'member'
          rsvp?: 'going' | 'maybe'
          joined_at?: string
        }
        Update: {
          id?: string
          swarm_id?: string
          user_id?: string
          role?: 'host' | 'member'
          rsvp?: 'going' | 'maybe'
          joined_at?: string
        }
      }
      messages: {
        Row: {
          id: string
          conversation_type: 'dm' | 'swarm'
          dm_user_a: string | null
          dm_user_b: string | null
          swarm_id: string | null
          sender_user_id: string
          body: string
          media_url: string | null
          delivery_status: 'sent' | 'delivered' | 'read'
          read_at: string | null
          edited_at: string | null
          deleted_at: string | null
          created_at: string
        }
        Insert: {
          id?: string
          conversation_type: 'dm' | 'swarm'
          dm_user_a?: string | null
          dm_user_b?: string | null
          swarm_id?: string | null
          sender_user_id: string
          body: string
          media_url?: string | null
          delivery_status?: 'sent' | 'delivered' | 'read'
          read_at?: string | null
          edited_at?: string | null
          deleted_at?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          conversation_type?: 'dm' | 'swarm'
          dm_user_a?: string | null
          dm_user_b?: string | null
          swarm_id?: string | null
          sender_user_id?: string
          body?: string
          media_url?: string | null
          delivery_status?: 'sent' | 'delivered' | 'read'
          read_at?: string | null
          edited_at?: string | null
          deleted_at?: string | null
          created_at?: string
        }
      }
      friendships: {
        Row: {
          id: string
          user_id: string
          friend_id: string
          status: 'pending' | 'accepted' | 'declined' | 'blocked'
          requested_at: string
          responded_at: string | null
        }
        Insert: {
          id?: string
          user_id: string
          friend_id: string
          status?: 'pending' | 'accepted' | 'declined' | 'blocked'
          requested_at?: string
          responded_at?: string | null
        }
        Update: {
          id?: string
          user_id?: string
          friend_id?: string
          status?: 'pending' | 'accepted' | 'declined' | 'blocked'
          requested_at?: string
          responded_at?: string | null
        }
      }
      user_blocks: {
        Row: {
          id: string
          blocking_user_id: string
          blocked_user_id: string
          created_at: string
        }
        Insert: {
          id?: string
          blocking_user_id: string
          blocked_user_id: string
          created_at?: string
        }
        Update: {
          id?: string
          blocking_user_id?: string
          blocked_user_id?: string
          created_at?: string
        }
      }
      message_edits: {
        Row: {
          id: string
          message_id: string
          edited_by: string
          previous_body: string
          created_at: string
        }
        Insert: {
          id?: string
          message_id: string
          edited_by: string
          previous_body: string
          created_at?: string
        }
        Update: {
          id?: string
          message_id?: string
          edited_by?: string
          previous_body?: string
          created_at?: string
        }
      }
      regions: {
        Row: {
          id: string
          country_code: string
          locale_tag: string
          distance_unit: 'miles' | 'km'
          temperature_unit: 'F' | 'C'
          currency_code: string
          currency_symbol: string
          date_format: string
          time_format: string
          created_at: string
        }
        Insert: {
          id?: string
          country_code: string
          locale_tag?: string
          distance_unit?: 'miles' | 'km'
          temperature_unit?: 'F' | 'C'
          currency_code?: string
          currency_symbol?: string
          date_format?: string
          time_format?: string
          created_at?: string
        }
        Update: {
          id?: string
          country_code?: string
          locale_tag?: string
          distance_unit?: 'miles' | 'km'
          temperature_unit?: 'F' | 'C'
          currency_code?: string
          currency_symbol?: string
          date_format?: string
          time_format?: string
          created_at?: string
        }
      }
      reports: {
        Row: {
          id: string
          reporter_user_id: string
          reported_user_id: string
          context: 'dm' | 'swarm' | 'profile'
          reason: string
          details: string
          status: 'pending' | 'reviewed' | 'actioned'
          created_at: string
        }
        Insert: {
          id?: string
          reporter_user_id: string
          reported_user_id: string
          context: 'dm' | 'swarm' | 'profile'
          reason: string
          details?: string
          status?: 'pending' | 'reviewed' | 'actioned'
          created_at?: string
        }
        Update: {
          id?: string
          reporter_user_id?: string
          reported_user_id?: string
          context?: 'dm' | 'swarm' | 'profile'
          reason?: string
          details?: string
          status?: 'pending' | 'reviewed' | 'actioned'
          created_at?: string
        }
      }
      blocks: {
        Row: {
          id: string
          blocker_user_id: string
          blocked_user_id: string
          created_at: string
        }
        Insert: {
          id?: string
          blocker_user_id: string
          blocked_user_id: string
          created_at?: string
        }
        Update: {
          id?: string
          blocker_user_id?: string
          blocked_user_id?: string
          created_at?: string
        }
      }
      safety_friends: {
        Row: {
          id: string
          user_id: string
          friend_name: string
          friend_phone: string
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          friend_name: string
          friend_phone: string
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          friend_name?: string
          friend_phone?: string
          created_at?: string
        }
      }
      safety_alerts: {
        Row: {
          id: string
          user_id: string
          latitude: number | null
          longitude: number | null
          location_url: string | null
          alert_type: string
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          latitude?: number | null
          longitude?: number | null
          location_url?: string | null
          alert_type?: string
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          latitude?: number | null
          longitude?: number | null
          location_url?: string | null
          alert_type?: string
          created_at?: string
        }
      }
      payment_transactions: {
        Row: {
          id: string
          swarm_id: string | null
          from_user_id: string
          to_user_id: string
          amount: number
          currency: string
          status: 'pending' | 'completed' | 'failed' | 'refunded'
          provider_ref: string | null
          created_at: string
        }
        Insert: {
          id?: string
          swarm_id?: string | null
          from_user_id: string
          to_user_id: string
          amount: number
          currency?: string
          status?: 'pending' | 'completed' | 'failed' | 'refunded'
          provider_ref?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          swarm_id?: string | null
          from_user_id?: string
          to_user_id?: string
          amount?: number
          currency?: string
          status?: 'pending' | 'completed' | 'failed' | 'refunded'
          provider_ref?: string | null
          created_at?: string
        }
      }
      music_shares: {
        Row: {
          id: string
          sender_id: string
          recipient_id: string
          song_id: string
          song_title: string
          artist_name: string
          album_art_url: string | null
          preview_url: string | null
          external_url: string
          platform: 'spotify' | 'apple_music' | 'youtube_music'
          message: string | null
          status: 'pending' | 'played' | 'saved' | 'expired'
          swarm_id: string | null
          venue_id: string | null
          created_at: string
          played_at: string | null
          expires_at: string
        }
        Insert: {
          id?: string
          sender_id: string
          recipient_id: string
          song_id: string
          song_title: string
          artist_name: string
          album_art_url?: string | null
          preview_url?: string | null
          external_url: string
          platform: 'spotify' | 'apple_music' | 'youtube_music'
          message?: string | null
          status?: 'pending' | 'played' | 'saved' | 'expired'
          swarm_id?: string | null
          venue_id?: string | null
          created_at?: string
          played_at?: string | null
          expires_at?: string
        }
        Update: {
          id?: string
          sender_id?: string
          recipient_id?: string
          song_id?: string
          song_title?: string
          artist_name?: string
          album_art_url?: string | null
          preview_url?: string | null
          external_url?: string
          platform?: 'spotify' | 'apple_music' | 'youtube_music'
          message?: string | null
          status?: 'pending' | 'played' | 'saved' | 'expired'
          swarm_id?: string | null
          venue_id?: string | null
          created_at?: string
          played_at?: string | null
          expires_at?: string
        }
      }
      bars: {
        Row: {
          bar_id: string
          name: string
          lat: number
          lng: number
          city: string
          state: string
          country: string
          radar_place_id: string | null
          google_place_id: string | null
          created_at: string
          updated_at: string
          google_last_fetched_at: string | null
          google_last_linked_at: string | null
          rating: number | null
          review_count: number
          photo_urls: string[]
          address: string | null
          opening_hours: Json | null
          google_last_synced_at: string | null
        }
        Insert: {
          bar_id?: string
          name: string
          lat: number
          lng: number
          city?: string
          state?: string
          country?: string
          radar_place_id?: string | null
          google_place_id?: string | null
          created_at?: string
          updated_at?: string
          google_last_fetched_at?: string | null
          google_last_linked_at?: string | null
          rating?: number | null
          review_count?: number
          photo_urls?: string[]
          address?: string | null
          opening_hours?: Json | null
          google_last_synced_at?: string | null
        }
        Update: {
          bar_id?: string
          name?: string
          lat?: number
          lng?: number
          city?: string
          state?: string
          country?: string
          radar_place_id?: string | null
          google_place_id?: string | null
          created_at?: string
          updated_at?: string
          google_last_fetched_at?: string | null
          google_last_linked_at?: string | null
          rating?: number | null
          review_count?: number
          photo_urls?: string[]
          address?: string | null
          opening_hours?: Json | null
          google_last_synced_at?: string | null
        }
      }
      emoji_reactions: {
        Row: {
          id: string
          user_id: string
          target_type: 'message' | 'post' | 'profile' | 'venue' | 'swarm'
          target_id: string
          emoji: string
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          target_type: 'message' | 'post' | 'profile' | 'venue' | 'swarm'
          target_id: string
          emoji: string
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          target_type?: 'message' | 'post' | 'profile' | 'venue' | 'swarm'
          target_id?: string
          emoji?: string
          created_at?: string
        }
      }
      user_gifts: {
        Row: {
          id: string
          from_user_id: string
          to_user_id: string
          item_id: string
          message: string | null
          status: 'sent' | 'viewed' | 'reacted'
          reaction: string | null
          context_type: 'direct_message' | 'profile' | 'swarm' | 'venue'
          context_id: string | null
          viewed_at: string | null
          created_at: string
        }
        Insert: {
          id?: string
          from_user_id: string
          to_user_id: string
          item_id: string
          message?: string | null
          status?: 'sent' | 'viewed' | 'reacted'
          reaction?: string | null
          context_type: 'direct_message' | 'profile' | 'swarm' | 'venue'
          context_id?: string | null
          viewed_at?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          from_user_id?: string
          to_user_id?: string
          item_id?: string
          message?: string | null
          status?: 'sent' | 'viewed' | 'reacted'
          reaction?: string | null
          context_type?: 'direct_message' | 'profile' | 'swarm' | 'venue'
          context_id?: string | null
          viewed_at?: string | null
          created_at?: string
        }
      }
      virtual_items: {
        Row: {
          id: string
          name: string
          category: 'emoji' | 'drink' | 'gift' | 'sticker' | 'celebration' | 'seasonal'
          emoji: string
          price: number
          is_premium: boolean
          rarity: 'common' | 'rare' | 'epic' | 'legendary'
          description: string | null
          animation_url: string | null
          is_active: boolean
          created_at: string
        }
        Insert: {
          id?: string
          name: string
          category: 'emoji' | 'drink' | 'gift' | 'sticker' | 'celebration' | 'seasonal'
          emoji: string
          price?: number
          is_premium?: boolean
          rarity?: 'common' | 'rare' | 'epic' | 'legendary'
          description?: string | null
          animation_url?: string | null
          is_active?: boolean
          created_at?: string
        }
        Update: {
          id?: string
          name?: string
          category?: 'emoji' | 'drink' | 'gift' | 'sticker' | 'celebration' | 'seasonal'
          emoji?: string
          price?: number
          is_premium?: boolean
          rarity?: 'common' | 'rare' | 'epic' | 'legendary'
          description?: string | null
          animation_url?: string | null
          is_active?: boolean
          created_at?: string
        }
      }
    }
  }
}
