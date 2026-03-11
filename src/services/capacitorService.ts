import { Capacitor } from '@capacitor/core';
import { App } from '@capacitor/app';
import { StatusBar, Style } from '@capacitor/status-bar';
import { SplashScreen } from '@capacitor/splash-screen';

export const isNative = Capacitor.isNativePlatform();
export const platform = Capacitor.getPlatform(); // 'ios' | 'android' | 'web'

/**
 * Initialize all Capacitor plugins. Call once from main.tsx after React mounts.
 */
export async function initCapacitor() {
  if (!isNative) return;

  // Status bar styling
  try {
    await StatusBar.setStyle({ style: Style.Light });
    await StatusBar.setBackgroundColor({ color: '#ffffff' });
  } catch { /* not available on all devices */ }

  // Hide splash screen after app loads
  try {
    await SplashScreen.hide({ fadeOutDuration: 300 });
  } catch { /* ignore */ }

  // Handle deep links (share links, notification taps)
  App.addListener('appUrlOpen', ({ url }) => {
    const path = url.replace('barfliz:/', '').replace('https://barfliz.app', '');
    if (path) {
      window.location.href = path;
    }
  });
}
