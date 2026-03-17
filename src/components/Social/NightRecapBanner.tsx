import { useState, useEffect } from 'react';
import { Moon, ChevronRight, Sparkles } from 'lucide-react';
import { nightRecapService } from '../../services/nightRecapService';
import { NightRecapModal } from './NightRecapModal';

export function NightRecapBanner() {
  const [show, setShow] = useState(false);
  const [open, setOpen] = useState(false);
  const [dismissed, setDismissed] = useState(false);

  useEffect(() => {
    const checkVisibility = async () => {
      const isMorning = await nightRecapService.hasMorningRecap();
      const today = new Date().toDateString();
      const lastDismissed = localStorage.getItem('night_recap_dismissed');
      if (lastDismissed === today) {
        setDismissed(true);
        return;
      }
      setShow(isMorning);
    };
    checkVisibility();
  }, []);

  const handleDismiss = () => {
    const today = new Date().toDateString();
    localStorage.setItem('night_recap_dismissed', today);
    setDismissed(true);
  };

  if (!show || dismissed) return null;

  return (
    <>
      <button
        onClick={() => setOpen(true)}
        className="w-full relative overflow-hidden rounded-2xl text-left group"
        style={{
          background: 'linear-gradient(135deg, #0f0c29 0%, #1a1035 60%, #0f2027 100%)',
        }}
      >
        <div
          className="absolute inset-0 opacity-30"
          style={{
            backgroundImage:
              'radial-gradient(circle at 80% 50%, #E91E63 0%, transparent 60%)',
          }}
        />

        <div className="relative z-10 px-5 py-4 flex items-center gap-4">
          <div className="w-11 h-11 rounded-2xl bg-white/10 flex items-center justify-center flex-shrink-0">
            <Moon className="w-5 h-5 text-[#E91E63]" />
          </div>

          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-1.5 mb-0.5">
              <Sparkles className="w-3 h-3 text-yellow-400" />
              <span className="text-yellow-400 text-xs font-semibold uppercase tracking-wider">
                Good morning
              </span>
            </div>
            <p className="text-white font-bold text-sm">See your night recap</p>
            <p className="text-white/50 text-xs mt-0.5">How was last night?</p>
          </div>

          <ChevronRight className="w-5 h-5 text-white/40 group-hover:text-white/70 transition-colors flex-shrink-0" />
        </div>

        <button
          onClick={(e) => {
            e.stopPropagation();
            handleDismiss();
          }}
          className="absolute top-2 right-2 w-6 h-6 rounded-full bg-white/10 flex items-center justify-center text-white/40 hover:bg-white/20 hover:text-white/70 transition-all text-xs z-20"
          aria-label="Dismiss"
        >
          \u00d7
        </button>
      </button>

      {open && <NightRecapModal onClose={() => setOpen(false)} />}
    </>
  );
}
