/**
 * AI Service — calls Edge Functions for Vibe Matchmaker, Smart Night Planner, and Wingman.
 */
import { supabase } from '../lib/supabase';
import type {
  AIResponse,
  VibeRecommendation,
  SmartNightPlan,
  WingmanResult,
} from '../types/ai';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;

async function callEdgeFunction<T>(
  fnName: string,
  body: Record<string, unknown>,
): Promise<AIResponse<T>> {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) return { success: false, error: 'Not authenticated' };

  const res = await fetch(`${SUPABASE_URL}/functions/v1/${fnName}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${session.access_token}`,
    },
    body: JSON.stringify(body),
  });

  const json = await res.json();
  if (!res.ok) return { success: false, error: json.error || 'Request failed' };
  return json as AIResponse<T>;
}

export const aiService = {
  /** Get AI-powered venue recommendations based on user's history and preferences */
  getVibeRecommendations(
    userLat: number,
    userLng: number,
    radiusMeters = 8000,
  ): Promise<AIResponse<VibeRecommendation[]>> {
    return callEdgeFunction('ai-vibe-matchmaker', {
      user_lat: userLat,
      user_lng: userLng,
      radius_meters: radiusMeters,
    });
  },

  /** Generate a multi-stop night plan from a natural language prompt */
  getSmartNightPlan(
    userLat: number,
    userLng: number,
    prompt: string,
    groupSize?: number,
  ): Promise<AIResponse<SmartNightPlan>> {
    return callEdgeFunction('ai-night-planner', {
      user_lat: userLat,
      user_lng: userLng,
      radius_meters: 8000,
      prompt,
      group_size: groupSize,
    });
  },

  /** Get wingman insights and ice breakers for a target user */
  getWingmanInsights(targetUserId: string): Promise<AIResponse<WingmanResult>> {
    return callEdgeFunction('ai-wingman', { target_user_id: targetUserId });
  },
};
