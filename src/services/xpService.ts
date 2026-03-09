import { supabase } from '../lib/supabase';

export interface UserStats {
  user_id: string;
  total_xp: number;
  current_streak: number;
  longest_streak: number;
  last_streak_at: string | null;
  unique_venues: number;
  total_checkins: number;
  updated_at: string;
}

export interface Badge {
  id: string;
  user_id: string;
  badge_key: string;
  earned_at: string;
}

export interface Challenge {
  id: string;
  user_id: string;
  challenge_key: string;
  progress: number;
  target: number;
  reward_xp: number;
  status: 'active' | 'completed' | 'expired';
  started_at: string;
  completed_at: string | null;
  expires_at: string | null;
}

export interface BadgeDefinition {
  badge_key: string;
  name: string;
  emoji: string;
  requirement: string;
  sort_order: number;
}

export interface ChallengeDefinition {
  challenge_key: string;
  name: string;
  description: string;
  target: number;
  reward_xp: number;
  expiry_days: number;
  sort_order: number;
}

const BADGE_DEFINITIONS_FALLBACK: Record<string, Omit<BadgeDefinition, 'badge_key' | 'sort_order'>> = {
  first_checkin:        { name: 'First Check-In',       emoji: '🎯', requirement: 'Check in once' },
  regular:              { name: 'Regular',               emoji: '⭐', requirement: '10 check-ins' },
  night_owl:            { name: 'Night Owl',             emoji: '🦉', requirement: '25 check-ins' },
  venue_explorer:       { name: 'Venue Explorer',        emoji: '🗺️', requirement: 'Visit 10 unique venues' },
  social_butterfly:     { name: 'Social Butterfly',      emoji: '🦋', requirement: '5 swarms joined' },
  dive_bar_legend:      { name: 'Dive Bar Legend',       emoji: '🍺', requirement: 'Visit 5 pubs' },
  cocktail_connoisseur: { name: 'Cocktail Connoisseur',  emoji: '🍸', requirement: 'Visit 5 lounges' },
  weekend_warrior:      { name: 'Weekend Warrior',       emoji: '🔥', requirement: '4-week streak' },
  barfliz_og:           { name: 'Barfliz OG',            emoji: '👑', requirement: '12-week streak' },
};

const CHALLENGE_DEFINITIONS_FALLBACK: Record<string, Omit<ChallengeDefinition, 'challenge_key' | 'sort_order' | 'expiry_days'>> = {
  new_horizons:   { name: 'New Horizons',   target: 2, reward_xp: 50, description: "Visit 2 venues you've never been to" },
  swarm_leader:   { name: 'Swarm Leader',   target: 1, reward_xp: 50, description: 'Create a swarm with 3+ people' },
  buzz_creator:   { name: 'Buzz Creator',   target: 5, reward_xp: 25, description: 'Post 5 messages in Venue Buzz' },
  friday_starter: { name: 'Friday Starter', target: 1, reward_xp: 25, description: 'Check in before 9 PM on Friday' },
  venue_hopper:   { name: 'Venue Hopper',   target: 3, reward_xp: 75, description: 'Check in at 3 different venues in one night' },
};

let _badgeDefsCache: BadgeDefinition[] | null = null;
let _challengeDefsCache: ChallengeDefinition[] | null = null;

export const xpService = {
  async awardXP(userId: string, amount: number): Promise<UserStats> {
    const { data: stats, error: fetchError } = await supabase
      .from('user_stats')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

    if (fetchError) throw fetchError;

    const newXP = (stats?.total_xp || 0) + amount;

    const { data, error } = await supabase
      .from('user_stats')
      .upsert({
        user_id: userId,
        total_xp: newXP,
        current_streak: stats?.current_streak ?? 0,
        longest_streak: stats?.longest_streak ?? 0,
        unique_venues: stats?.unique_venues ?? 0,
        total_checkins: stats?.total_checkins ?? 0,
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async awardBadge(userId: string, badgeKey: string): Promise<Badge | null> {
    const { data: existing } = await supabase
      .from('user_badges')
      .select('id')
      .eq('user_id', userId)
      .eq('badge_key', badgeKey)
      .maybeSingle();

    if (existing) return null;

    const { data, error } = await supabase
      .from('user_badges')
      .insert([
        {
          user_id: userId,
          badge_key: badgeKey,
        },
      ])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async getUserStats(userId: string): Promise<UserStats | null> {
    const { data, error } = await supabase
      .from('user_stats')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  async getUserBadges(userId: string): Promise<Badge[]> {
    const { data, error } = await supabase
      .from('user_badges')
      .select('*')
      .eq('user_id', userId)
      .order('earned_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  async getActiveChallenges(userId: string): Promise<Challenge[]> {
    const { data, error } = await supabase
      .from('user_challenges')
      .select('*')
      .eq('user_id', userId)
      .eq('status', 'active')
      .order('started_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  async updateChallengeProgress(
    userId: string,
    challengeKey: string,
    newProgress: number
  ): Promise<Challenge | null> {
    const { data: challenge } = await supabase
      .from('user_challenges')
      .select('*')
      .eq('user_id', userId)
      .eq('challenge_key', challengeKey)
      .eq('status', 'active')
      .maybeSingle();

    if (!challenge) return null;

    const definition = CHALLENGE_DEFINITIONS_FALLBACK[challengeKey];
    if (!definition) return null;

    const isCompleted = newProgress >= definition.target;
    const status = isCompleted ? 'completed' : 'active';

    const { data, error } = await supabase
      .from('user_challenges')
      .update({
        progress: newProgress,
        status,
        completed_at: isCompleted ? new Date().toISOString() : null,
      })
      .eq('id', challenge.id)
      .select()
      .single();

    if (error) throw error;

    if (isCompleted) {
      await this.awardXP(userId, definition.reward_xp);
    }

    return data;
  },

  async createChallenge(userId: string, challengeKey: string): Promise<Challenge> {
    const definition = CHALLENGE_DEFINITIONS_FALLBACK[challengeKey];
    if (!definition) throw new Error('Invalid challenge key');

    const now = new Date();
    const expiresAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const { data, error } = await supabase
      .from('user_challenges')
      .insert([
        {
          user_id: userId,
          challenge_key: challengeKey,
          target: definition.target,
          reward_xp: definition.reward_xp,
          expires_at: expiresAt.toISOString(),
        },
      ])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  async recordCheckin(userId: string, venueId: string): Promise<void> {
    const { data: session } = await supabase.auth.getSession();
    if (!session?.user?.id) throw new Error('Not authenticated');

    const { data: stats } = await supabase
      .from('user_stats')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

    const newCheckins = (stats?.total_checkins || 0) + 1;

    const { data: uniqueVenues } = await supabase
      .from('venue_sessions')
      .select('venue_id')
      .eq('user_id', userId)
      .neq('venue_id', null);

    const distinctVenueIds = new Set((uniqueVenues || []).map((r: { venue_id: string }) => r.venue_id));
    if (venueId) distinctVenueIds.add(venueId);
    const uniqueCount = distinctVenueIds.size;

    await supabase
      .from('user_stats')
      .upsert({
        user_id: userId,
        total_checkins: newCheckins,
        unique_venues: uniqueCount,
        updated_at: new Date().toISOString(),
      });

    await this.awardXP(userId, 10);

    if (newCheckins === 1) {
      await this.awardBadge(userId, 'first_checkin');
    }

    if (newCheckins === 10) {
      await this.awardBadge(userId, 'regular');
    }

    if (newCheckins === 25) {
      await this.awardBadge(userId, 'night_owl');
    }
  },

  async getAllBadgeDefinitions(): Promise<BadgeDefinition[]> {
    if (_badgeDefsCache) return _badgeDefsCache;
    const { data, error } = await supabase
      .from('badge_definitions')
      .select('*')
      .order('sort_order', { ascending: true });
    if (!error && data && data.length > 0) {
      _badgeDefsCache = data as BadgeDefinition[];
      return _badgeDefsCache;
    }
    return Object.entries(BADGE_DEFINITIONS_FALLBACK).map(([badge_key, v], i) => ({
      badge_key,
      ...v,
      sort_order: i + 1,
    }));
  },

  async getAllChallengeDefinitions(): Promise<ChallengeDefinition[]> {
    if (_challengeDefsCache) return _challengeDefsCache;
    const { data, error } = await supabase
      .from('challenge_definitions')
      .select('*')
      .order('sort_order', { ascending: true });
    if (!error && data && data.length > 0) {
      _challengeDefsCache = data as ChallengeDefinition[];
      return _challengeDefsCache;
    }
    return Object.entries(CHALLENGE_DEFINITIONS_FALLBACK).map(([challenge_key, v], i) => ({
      challenge_key,
      ...v,
      expiry_days: 7,
      sort_order: i + 1,
    }));
  },

  getBadgeDefinition(key: string): { name: string; emoji: string; requirement: string } | null {
    return BADGE_DEFINITIONS_FALLBACK[key] || null;
  },

  getChallengeDef(key: string): { name: string; target: number; reward_xp: number; description: string } | null {
    return CHALLENGE_DEFINITIONS_FALLBACK[key] || null;
  },
};
