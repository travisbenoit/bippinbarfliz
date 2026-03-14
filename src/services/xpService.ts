import { supabase } from '../lib/supabase';
import { CRYPTO_ENABLED } from '../lib/featureFlags';
import { mintLushCoins, burnLushCoins } from './lushCoinService';

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

// Coin earn/spend amounts
export const COIN_REWARDS = {
  checkin: 10,
  checkin_streak_7: 50,
  checkin_streak_14: 100,
  checkin_streak_30: 250,
  cheer_sent: 5,
  swarm_joined: 5,
  swarm_created: 15,
  first_checkin_night: 25, // first venue of a new night
  challenge_complete: 0,   // dynamic: uses challenge.reward_xp value
} as const;

// Gift prices (coins) by rarity — used when DB price is 0
export const RARITY_COIN_COST: Record<string, number> = {
  common: 10,
  rare: 25,
  epic: 50,
  legendary: 150,
};

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
  // ─── Core XP ───────────────────────────────────────────────────────────────

  async awardXP(userId: string, amount: number): Promise<UserStats> {
    const { data: stats } = await supabase
      .from('user_stats')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

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
        last_streak_at: stats?.last_streak_at ?? null,
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
      .insert([{ user_id: userId, badge_key: badgeKey }])
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

  // ─── Coins ─────────────────────────────────────────────────────────────────

  async earnCoins(userId: string, amount: number, event = 'generic'): Promise<number> {
    // On-chain path: mint LUSH via edge function (also updates DB as cache)
    if (CRYPTO_ENABLED) {
      const result = await mintLushCoins(userId, amount, event);
      if (result.success && result.new_balance !== undefined) {
        return result.new_balance;
      }
      // Fall through to DB path on failure
    }

    // DB path (default, or fallback when chain fails)
    const { data, error } = await supabase.rpc('increment_lush_coins', {
      p_user_id: userId,
      p_amount: amount,
    });

    if (error) {
      const { data: u } = await supabase
        .from('users')
        .select('lush_coin_balance')
        .eq('id', userId)
        .maybeSingle();
      const newBalance = (Number(u?.lush_coin_balance) || 0) + amount;
      await supabase.from('users').update({ lush_coin_balance: newBalance }).eq('id', userId);
      return newBalance;
    }
    return data as number;
  },

  async spendCoins(userId: string, amount: number, itemId?: string): Promise<{ success: boolean; newBalance: number }> {
    // On-chain path: burn LUSH via edge function (also updates DB)
    if (CRYPTO_ENABLED) {
      const result = await burnLushCoins(userId, amount, itemId);
      if (result.success) {
        const balance = await this.getCoinBalance(userId);
        return { success: true, newBalance: balance };
      }
      if (result.error === 'Insufficient balance') {
        const balance = await this.getCoinBalance(userId);
        return { success: false, newBalance: balance };
      }
      // Fall through to DB path on other failures
    }

    // DB path (default)
    const { data: u } = await supabase
      .from('users')
      .select('lush_coin_balance')
      .eq('id', userId)
      .maybeSingle();

    const currentBalance = Number(u?.lush_coin_balance) || 0;
    if (currentBalance < amount) {
      return { success: false, newBalance: currentBalance };
    }

    const newBalance = currentBalance - amount;
    await supabase.from('users').update({ lush_coin_balance: newBalance }).eq('id', userId);
    return { success: true, newBalance };
  },

  async getCoinBalance(userId: string): Promise<number> {
    const { data } = await supabase
      .from('users')
      .select('lush_coin_balance')
      .eq('id', userId)
      .maybeSingle();
    return Number(data?.lush_coin_balance) || 0;
  },

  // ─── Challenges ────────────────────────────────────────────────────────────

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
  ): Promise<{ challenge: Challenge | null; completed: boolean; rewardXp: number }> {
    const { data: challenge } = await supabase
      .from('user_challenges')
      .select('*')
      .eq('user_id', userId)
      .eq('challenge_key', challengeKey)
      .eq('status', 'active')
      .maybeSingle();

    if (!challenge) return { challenge: null, completed: false, rewardXp: 0 };

    const isCompleted = newProgress >= challenge.target;
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
      await this.awardXP(userId, challenge.reward_xp);
      await this.earnCoins(userId, challenge.reward_xp); // coins = XP reward amount
    }

    return { challenge: data, completed: isCompleted, rewardXp: challenge.reward_xp };
  },

  async createChallenge(userId: string, challengeKey: string): Promise<Challenge> {
    const definition = CHALLENGE_DEFINITIONS_FALLBACK[challengeKey];
    if (!definition) throw new Error('Invalid challenge key');

    const now = new Date();
    const expiresAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const { data, error } = await supabase
      .from('user_challenges')
      .insert([{
        user_id: userId,
        challenge_key: challengeKey,
        target: definition.target,
        reward_xp: definition.reward_xp,
        expires_at: expiresAt.toISOString(),
      }])
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  /** Assign any challenge_definitions not yet assigned to this user. */
  async autoAssignChallenges(userId: string): Promise<void> {
    const { data: existing } = await supabase
      .from('user_challenges')
      .select('challenge_key')
      .eq('user_id', userId);

    const existingKeys = new Set((existing || []).map((c: any) => c.challenge_key));
    const allKeys = Object.keys(CHALLENGE_DEFINITIONS_FALLBACK);

    await Promise.all(
      allKeys
        .filter(key => !existingKeys.has(key))
        .map(key => this.createChallenge(userId, key).catch(() => null))
    );
  },

  // ─── Check-in (main entry point) ───────────────────────────────────────────

  /**
   * Called every time a user enters a venue via geofence.
   * Awards XP, updates streaks (both tables), checks badges, advances challenges.
   * Returns newBadges earned and streak info for toast display.
   */
  async recordCheckin(
    userId: string,
    venueId: string,
    venueCategory?: string
  ): Promise<{
    xpAwarded: number;
    coinsAwarded: number;
    newBadges: string[];
    streakDay: number;
    streakMilestone: boolean;
  }> {
    const newBadges: string[] = [];
    let xpAwarded = 10;
    let coinsAwarded = COIN_REWARDS.checkin;

    // Load current stats
    const { data: stats } = await supabase
      .from('user_stats')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

    const newCheckins = (stats?.total_checkins || 0) + 1;

    // ── Streak logic ──
    const today = new Date().toISOString().split('T')[0];
    const lastAt = stats?.last_streak_at ? stats.last_streak_at.split('T')[0] : null;
    const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];

    let newStreak: number;
    let isFirstCheckinToday = false;

    if (lastAt === today) {
      // Already checked in today — don't change streak
      newStreak = stats?.current_streak ?? 1;
    } else {
      isFirstCheckinToday = true;
      if (lastAt === yesterday) {
        newStreak = (stats?.current_streak ?? 0) + 1;
      } else {
        newStreak = 1; // streak broken or first ever
      }
    }

    const newLongest = Math.max(newStreak, stats?.longest_streak ?? 0);

    // Bonus coins for first check-in of the night
    if (isFirstCheckinToday) {
      coinsAwarded += COIN_REWARDS.first_checkin_night;
    }

    // Streak milestone bonuses
    const streakMilestone = isFirstCheckinToday && [7, 14, 30, 60, 100].includes(newStreak);
    if (streakMilestone) {
      const bonusMap: Record<number, number> = { 7: 50, 14: 100, 30: 250, 60: 500, 100: 1000 };
      coinsAwarded += bonusMap[newStreak] ?? 50;
      xpAwarded += bonusMap[newStreak] ?? 50;
    }

    // ── Unique venues ──
    const { data: venueVisits } = await supabase
      .from('venue_sessions')
      .select('venue_id')
      .eq('user_id', userId)
      .neq('venue_id', null);

    const distinctVenueIds = new Set((venueVisits || []).map((r: any) => r.venue_id));
    if (venueId) distinctVenueIds.add(venueId);
    const uniqueCount = distinctVenueIds.size;

    // ── Write user_stats ──
    await supabase.from('user_stats').upsert({
      user_id: userId,
      total_checkins: newCheckins,
      unique_venues: uniqueCount,
      current_streak: newStreak,
      longest_streak: newLongest,
      last_streak_at: isFirstCheckinToday ? new Date().toISOString() : (stats?.last_streak_at ?? new Date().toISOString()),
      total_xp: (stats?.total_xp || 0) + xpAwarded,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'user_id' });

    // ── Award coins ──
    await this.earnCoins(userId, coinsAwarded);

    // ── Checkin badges ──
    if (newCheckins === 1) {
      const b = await this.awardBadge(userId, 'first_checkin');
      if (b) newBadges.push('first_checkin');
    }
    if (newCheckins === 10) {
      const b = await this.awardBadge(userId, 'regular');
      if (b) newBadges.push('regular');
    }
    if (newCheckins === 25) {
      const b = await this.awardBadge(userId, 'night_owl');
      if (b) newBadges.push('night_owl');
    }

    // ── Unique venue badge ──
    if (uniqueCount >= 10) {
      const b = await this.awardBadge(userId, 'venue_explorer');
      if (b) newBadges.push('venue_explorer');
    }

    // ── Category-based badges ──
    if (venueCategory === 'bar' || venueCategory === 'brewery' || venueCategory === 'pub') {
      const { count } = await supabase
        .from('venue_sessions')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId)
        .in('venue_id',
          (await supabase.from('venues').select('id').eq('category', venueCategory)).data?.map((v: any) => v.id) || []
        );
      if ((count || 0) >= 5) {
        const b = await this.awardBadge(userId, 'dive_bar_legend');
        if (b) newBadges.push('dive_bar_legend');
      }
    }
    if (venueCategory === 'lounge' || venueCategory === 'cocktail_bar') {
      const { data: loungeSessions } = await supabase
        .from('venue_sessions')
        .select('venue_id')
        .eq('user_id', userId);
      const loungeVenueIds = (loungeSessions || []).map((s: any) => s.venue_id).filter(Boolean);
      if (loungeVenueIds.length > 0) {
        const { count: loungeCount } = await supabase
          .from('venues')
          .select('*', { count: 'exact', head: true })
          .in('id', loungeVenueIds)
          .in('category', ['lounge', 'cocktail_bar']);
        if ((loungeCount || 0) >= 5) {
          const b = await this.awardBadge(userId, 'cocktail_connoisseur');
          if (b) newBadges.push('cocktail_connoisseur');
        }
      }
    }

    // ── Streak badges ──
    if (newStreak >= 4) {
      const b = await this.awardBadge(userId, 'weekend_warrior');
      if (b) newBadges.push('weekend_warrior');
    }
    if (newStreak >= 12) {
      const b = await this.awardBadge(userId, 'barfliz_og');
      if (b) newBadges.push('barfliz_og');
    }

    // ── Challenge progress: new_horizons + venue_hopper ──
    const { data: existingChallenges } = await supabase
      .from('user_challenges')
      .select('challenge_key, progress')
      .eq('user_id', userId)
      .eq('status', 'active');

    for (const c of (existingChallenges || [])) {
      if (c.challenge_key === 'new_horizons' && isFirstCheckinToday) {
        await this.updateChallengeProgress(userId, 'new_horizons', c.progress + 1).catch(() => null);
      }
      if (c.challenge_key === 'venue_hopper' && isFirstCheckinToday) {
        // Count how many distinct venues checked in today
        const todayStart = new Date(today).toISOString();
        const { data: todayPresence } = await supabase
          .from('user_venue_presence')
          .select('venue_id')
          .eq('user_id', userId)
          .gte('entered_at', todayStart);
        const todayVenues = new Set((todayPresence || []).map((p: any) => p.venue_id));
        await this.updateChallengeProgress(userId, 'venue_hopper', todayVenues.size).catch(() => null);
      }
      if (c.challenge_key === 'friday_starter' && isFirstCheckinToday) {
        const now = new Date();
        const isFriday = now.getDay() === 5;
        const hour = now.getHours();
        if (isFriday && hour < 21) {
          await this.updateChallengeProgress(userId, 'friday_starter', 1).catch(() => null);
        }
      }
    }

    return { xpAwarded, coinsAwarded, newBadges, streakDay: newStreak, streakMilestone };
  },

  // ─── Swarm events ──────────────────────────────────────────────────────────

  async onSwarmJoined(userId: string): Promise<void> {
    await this.earnCoins(userId, COIN_REWARDS.swarm_joined).catch(() => null);
    await this.awardXP(userId, 5).catch(() => null);

    // social_butterfly badge: 5 swarms joined
    const { count } = await supabase
      .from('swarm_members')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('role', 'member');
    if ((count || 0) >= 5) {
      await this.awardBadge(userId, 'social_butterfly').catch(() => null);
    }

    // challenge: swarm_leader counts swarms created (not joined), skip here
    // update challenge new_horizons? No - that's venue-based
  },

  async onSwarmCreated(userId: string, memberCount: number): Promise<void> {
    await this.earnCoins(userId, COIN_REWARDS.swarm_created).catch(() => null);
    await this.awardXP(userId, 15).catch(() => null);

    if (memberCount >= 3) {
      await this.updateChallengeProgress(userId, 'swarm_leader', 1).catch(() => null);
    }
  },

  async onCheerSent(userId: string): Promise<void> {
    await this.earnCoins(userId, COIN_REWARDS.cheer_sent).catch(() => null);
  },

  // ─── Definitions ───────────────────────────────────────────────────────────

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
      badge_key, ...v, sort_order: i + 1,
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
      challenge_key, ...v, expiry_days: 7, sort_order: i + 1,
    }));
  },

  getBadgeDefinition(key: string): { name: string; emoji: string; requirement: string } | null {
    return BADGE_DEFINITIONS_FALLBACK[key] || null;
  },

  getChallengeDef(key: string): { name: string; target: number; reward_xp: number; description: string } | null {
    return CHALLENGE_DEFINITIONS_FALLBACK[key] || null;
  },
};
