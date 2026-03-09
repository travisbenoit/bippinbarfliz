export const VIBE_TAGS = [
  'Happy Hour',
  'Big Game',
  'Chill Night',
  'Dance Party',
  'Live Music',
  'Karaoke',
  'Trivia Night',
  'Sports Bar',
  'Rooftop',
  'Dive Bar',
] as const;

export type VibeTag = typeof VIBE_TAGS[number];

export const GROUP_SIZE_OPTIONS = [
  { label: 'Any Size', value: null },
  { label: 'Small (2-4)', min: 2, max: 4, value: 'small' },
  { label: 'Medium (5-10)', min: 5, max: 10, value: 'medium' },
  { label: 'Large (11+)', min: 11, max: 100, value: 'large' },
] as const;

export const DISTANCE_OPTIONS = [
  { label: '1 mi', value: 1.6 },
  { label: '3 mi', value: 4.8 },
  { label: '5 mi', value: 8 },
  { label: '10 mi', value: 16 },
  { label: '25 mi', value: 40 },
] as const;
