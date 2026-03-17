import { supabase } from '../lib/supabase';

export interface NightRecapData {
  date: string;
  displayDate: string;
  barsVisited: string[];
  peopleMet: number;
  drinksSent: number;
  swarmsJoined: string[];
  musicShared: number;
  xpEarned: number;
  startTime: string | null;
  endTime: string | null;
}

function getLastNightWindow(): { start: Date; end: Date } {
  const now = new Date();
  const end = new Date(now);

  const hour = now.getHours();
  if (hour < 6) {
    end.setDate(end.getDate() - 1);
  }

  end.setHours(6, 0, 0, 0);

  const start = new Date(end);
  start.setDate(start.getDate() - 1);
  start.setHours(18, 0, 0, 0);

  return { start, end };
}

function formatNightDate(date: Date): string {
  return date.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });
}

export const nightRecapService = {
  async getLastNightRecap(): Promise<NightRecapData | null> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;

    const { start, end } = getLastNightWindow();

    const [presenceResult, giftsResult, activityResult, xpResult, swarmsResult] = await Promise.all([
      supabase
        .from('user_venue_presence')
        .select('entered_at, left_at, venue:venues!venue_id(id, name)')
        .eq('user_id', user.id)
        .gte('entered_at', start.toISOString())
        .lte('entered_at', end.toISOString())
        .order('entered_at', { ascending: true }),

      supabase
        .from('user_gifts')
        .select('id')
        .eq('from_user_id', user.id)
        .gte('created_at', start.toISOString())
        .lte('created_at', end.toISOString()),

      supabase
        .from('activity_feed')
        .select('activity_type, created_at, metadata')
        .eq('actor_user_id', user.id)
        .gte('created_at', start.toISOString())
        .lte('created_at', end.toISOString()),

      supabase
        .from('user_stats')
        .select('total_xp')
        .eq('user_id', user.id)
        .maybeSingle(),

      supabase
        .from('swarm_members')
        .select('swarm_id, joined_at, swarm:swarms!swarm_id(id, title)')
        .eq('user_id', user.id)
        .gte('joined_at', start.toISOString())
        .lte('joined_at', end.toISOString()),
    ]);

    const presenceData = presenceResult.data || [];
    const giftsData = giftsResult.data || [];
    const activityData = activityResult.data || [];
    const xpData = xpResult.data;
    const swarmsData = swarmsResult.data || [];

    const barsVisited = [
      ...new Set(
        presenceData
          .map((p: any) => p.venue?.name)
          .filter(Boolean)
      )
    ] as string[];

    const friendMeets = activityData.filter(
      a => a.activity_type === 'friend_request_accepted'
    ).length;

    const crossingPaths = activityData.filter(
      a => a.activity_type === 'crossing_paths'
    ).length;

    const peopleMet = friendMeets + crossingPaths;

    const drinksSent = giftsData.length;

    const musicShared = activityData.filter(
      a => a.activity_type === 'music_shared'
    ).length;

    const xpEarned = xpData?.total_xp || 0;

    const swarmNames = [
      ...new Set(
        swarmsData
          .map((s: any) => s.swarm?.title)
          .filter(Boolean)
      )
    ] as string[];

    if (barsVisited.length === 0 && peopleMet === 0 && drinksSent === 0 && swarmNames.length === 0) {
      return null;
    }

    const times = presenceData.map((p: any) => new Date(p.entered_at).getTime());
    const startTime = times.length > 0
      ? new Date(Math.min(...times)).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true })
      : null;
    const endTime = presenceData.length > 0 && presenceData[presenceData.length - 1].left_at
      ? new Date(presenceData[presenceData.length - 1].left_at).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true })
      : null;

    return {
      date: start.toISOString(),
      displayDate: formatNightDate(start),
      barsVisited,
      peopleMet,
      drinksSent,
      swarmsJoined: swarmNames,
      musicShared,
      xpEarned,
      startTime,
      endTime,
    };
  },

  async hasMorningRecap(): Promise<boolean> {
    const now = new Date();
    const hour = now.getHours();
    if (hour < 5 || hour > 13) return false;
    const recap = await nightRecapService.getLastNightRecap();
    return recap !== null;
  },
};
