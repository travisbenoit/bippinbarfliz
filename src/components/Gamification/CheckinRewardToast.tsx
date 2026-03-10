import { useEffect } from 'react';
import { useToast } from '../../contexts/ToastContext';
import { xpService } from '../../services/xpService';

/**
 * Mounts once at the app root. Listens for the 'barfliz:checkin' custom event
 * dispatched by GeofenceProvider and shows streak/XP/badge toasts.
 */
export function CheckinRewardToast() {
  const { showSuccess, showInfo } = useToast();

  useEffect(() => {
    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail as {
        xpAwarded: number;
        coinsAwarded: number;
        newBadges: string[];
        streakDay: number;
        streakMilestone: boolean;
      };

      if (!detail) return;

      // Main check-in reward
      showSuccess(`Checked in! +${detail.xpAwarded} XP · +${detail.coinsAwarded} 🪙`);

      // Streak milestones
      if (detail.streakMilestone) {
        const msg =
          detail.streakDay >= 30 ? `🔥🔥🔥 ${detail.streakDay}-night streak! Legendary!` :
          detail.streakDay >= 14 ? `🔥🔥 ${detail.streakDay}-night streak! On fire!` :
          `🔥 ${detail.streakDay}-night streak! Keep it up!`;
        showInfo(msg);
      } else if (detail.streakDay > 1) {
        showInfo(`🔥 ${detail.streakDay}-night streak!`);
      }

      // New badges
      detail.newBadges.forEach(key => {
        const def = xpService.getBadgeDefinition(key);
        if (def) showSuccess(`${def.emoji} Badge unlocked: ${def.name}!`);
      });
    };

    window.addEventListener('barfliz:checkin', handler);
    return () => window.removeEventListener('barfliz:checkin', handler);
  }, []);

  return null;
}
