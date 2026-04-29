import { useEffect, useState } from 'react';
import { Sparkles, MapPin, UsersRound, MessageCircle, ChevronRight, X } from 'lucide-react';

const STORAGE_KEY = 'first_run_tour_complete_v1';

interface Step {
  icon: typeof Sparkles;
  title: string;
  body: string;
  accent: string;
}

const STEPS: ReadonlyArray<Step> = [
  {
    icon: Sparkles,
    title: 'Set your Tonight Status',
    body: "Tap 'Out Now', 'Out Soon', or 'Maybe' on Home so friends know if you're up for it. Set the vibe and pick a venue right from the same screen.",
    accent: 'from-pink-500 to-rose-500',
  },
  {
    icon: MapPin,
    title: 'See who is out, live',
    body: "The Map shows every nearby venue, who's there, and how many people are checked in right now. Tap any pin to see the crowd and join.",
    accent: 'from-orange-400 to-pink-500',
  },
  {
    icon: UsersRound,
    title: 'Rally your crew with Swarms',
    body: 'Swarms are 30-second group plans. Pick a venue, set a time, invite friends. Public swarms are discoverable by everyone nearby.',
    accent: 'from-purple-500 to-pink-500',
  },
  {
    icon: MessageCircle,
    title: 'Friends and chat',
    body: 'Add friends from the map or in person. DM them, share a song, send a virtual gift, or split a tab without leaving the chat.',
    accent: 'from-blue-500 to-purple-600',
  },
];

interface FirstRunTourProps {
  // Optional override for testing. When false, the tour will always render.
  respectDismissal?: boolean;
}

export default function FirstRunTour({ respectDismissal = true }: FirstRunTourProps) {
  const [open, setOpen] = useState(false);
  const [stepIndex, setStepIndex] = useState(0);

  useEffect(() => {
    if (!respectDismissal) {
      setOpen(true);
      return;
    }
    try {
      const dismissed = localStorage.getItem(STORAGE_KEY);
      if (!dismissed) setOpen(true);
    } catch {
      // localStorage may be unavailable (private mode); just don't show.
    }
  }, [respectDismissal]);

  const finish = () => {
    try {
      localStorage.setItem(STORAGE_KEY, '1');
    } catch {
      // ignore
    }
    setOpen(false);
  };

  if (!open) return null;

  const step = STEPS[stepIndex];
  const isLast = stepIndex === STEPS.length - 1;
  const Icon = step.icon;

  return (
    <div className="fixed inset-0 z-[8500] bg-black/70 backdrop-blur-sm flex items-end sm:items-center justify-center p-0 sm:p-4">
      <div className="bg-white w-full max-w-md rounded-t-3xl sm:rounded-3xl shadow-2xl overflow-hidden">
        <div className="flex items-center justify-between px-6 pt-5">
          <span className="text-xs font-semibold text-gray-500 uppercase tracking-wide">
            Welcome · Step {stepIndex + 1} of {STEPS.length}
          </span>
          <button
            onClick={finish}
            className="p-1.5 hover:bg-gray-100 rounded-full transition-colors"
            aria-label="Skip tour"
          >
            <X size={18} className="text-gray-400" />
          </button>
        </div>

        <div className="px-6 pt-6 pb-2">
          <div
            className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${step.accent} flex items-center justify-center shadow-lg shadow-pink-500/20 mb-5`}
          >
            <Icon className="w-8 h-8 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">{step.title}</h2>
          <p className="text-sm text-gray-600 leading-relaxed">{step.body}</p>
        </div>

        <div className="flex items-center justify-center gap-1.5 py-5">
          {STEPS.map((_, i) => (
            <span
              key={i}
              className={`h-1.5 rounded-full transition-all ${
                i === stepIndex ? 'w-6 bg-[#E91E63]' : 'w-1.5 bg-gray-200'
              }`}
            />
          ))}
        </div>

        <div className="px-6 pb-6 flex items-center gap-3">
          <button
            onClick={finish}
            className="flex-1 py-3 text-gray-500 text-sm font-medium hover:text-gray-700 transition-colors"
          >
            Skip
          </button>
          <button
            onClick={() => (isLast ? finish() : setStepIndex(stepIndex + 1))}
            className="flex-[2] py-3 bg-[#E91E63] text-white rounded-xl font-semibold text-sm hover:bg-[#C2185B] transition-colors flex items-center justify-center gap-1"
          >
            {isLast ? "Let's go" : 'Next'}
            {!isLast && <ChevronRight size={16} />}
          </button>
        </div>
      </div>
    </div>
  );
}
