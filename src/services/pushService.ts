import Pushy from 'pushy-sdk-web';
import { supabase } from '../lib/supabase';

const PUSHY_APP_ID = import.meta.env.VITE_PUSHY_APP_ID as string | undefined;

export async function subscribeToPush(userId: string): Promise<boolean> {
  if (!PUSHY_APP_ID) return false;
  if (!('serviceWorker' in navigator)) return false;

  try {
    Pushy.init({ appId: PUSHY_APP_ID });

    const deviceToken: string = await Pushy.register({ serviceWorkerFile: '/service-worker.js' });

    const { error } = await supabase.from('push_subscriptions').upsert(
      {
        user_id: userId,
        endpoint: `pushy:${deviceToken}`,
        p256dh: '',
        auth: '',
        native_token: deviceToken,
        platform: 'web',
      },
      { onConflict: 'user_id,endpoint' }
    );

    if (!error) {
      Pushy.setNotificationListener((data: Record<string, string>) => {
        if ('Notification' in window && Notification.permission === 'granted') {
          const reg = navigator.serviceWorker.controller;
          if (reg) {
            reg.postMessage({ type: 'PUSHY_NOTIFY', payload: data });
          }
        }
      });
    }

    return !error;
  } catch {
    return false;
  }
}

export async function unsubscribeFromPush(userId: string): Promise<void> {
  try {
    const { data: sub } = await supabase
      .from('push_subscriptions')
      .select('native_token')
      .eq('user_id', userId)
      .eq('platform', 'web')
      .maybeSingle();

    if (sub?.native_token) {
      await supabase
        .from('push_subscriptions')
        .delete()
        .eq('user_id', userId)
        .eq('native_token', sub.native_token);
    }
  } catch {
    // ignore
  }
}

export async function sendPushToUser(
  userId: string,
  payload: { title: string; body: string; url?: string; tag?: string }
): Promise<void> {
  await supabase.functions.invoke('send-push-notification', {
    body: { user_id: userId, ...payload },
  });
}
