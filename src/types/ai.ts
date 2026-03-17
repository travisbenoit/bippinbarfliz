export interface VibeRecommendation {
  venue_id: string;
  venue_name: string;
  category: string;
  current_occupancy: number;
  score: number;
  contextual_message: string;
  address?: string;
}

export interface SmartPlanStop {
  order: number;
  venue_id: string;
  venue_name: string;
  category: string;
  suggested_arrival: string;
  suggested_departure: string;
  reason: string;
}

export interface SmartNightPlan {
  plan_name: string;
  overview: string;
  stops: SmartPlanStop[];
}

export interface WingmanInsight {
  type: 'shared_venue' | 'mutual_friend' | 'music_taste' | 'vibe_match' | 'crossing_paths';
  message: string;
  data_point: string;
}

export interface WingmanResult {
  insights: WingmanInsight[];
  ice_breakers: string[];
}

export interface AIResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  cached?: boolean;
}
