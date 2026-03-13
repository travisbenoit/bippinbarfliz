import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.barfliz.app',
  appName: 'Barfliz',
  webDir: 'dist',
  server: {
    // Remove this block before submitting to app stores — it's for live-reload during dev only
    // url: 'http://192.168.1.x:5173',
    // cleartext: true,
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      launchAutoHide: true,
      backgroundColor: '#FFF5F0',
      androidSplashResourceName: 'splash',
      androidScaleType: 'CENTER_CROP',
      showSpinner: false,
      iosSpinnerStyle: 'small',
      spinnerColor: '#E91E63',
    },
    StatusBar: {
      style: 'Light',
      backgroundColor: '#ffffff',
    },
    PushNotifications: {
      presentationOptions: ['badge', 'sound', 'alert'],
    },
    App: {
      // Deep link URL scheme — must match the scheme in iOS Info.plist and Android intent-filter
    },
  },
  ios: {
    // contentInset: 'automatic',
    // backgroundColor: '#FFF5F0',
  },
  android: {
    // backgroundColor: '#FFF5F0',
  },
};

export default config;
