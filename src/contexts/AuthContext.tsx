import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import Radar from 'radar-sdk-js';
import { radarService } from '../services/radarService';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  signUp: (email: string, password: string) => Promise<{ error: any }>;
  signIn: (email: string, password: string) => Promise<{ error: any }>;
  signInWithPhone: (phone: string) => Promise<{ error: any }>;
  verifyOtp: (phone: string, token: string) => Promise<{ data: any; error: any }>;
  twilioSendOtp: (phone: string) => Promise<{ error: any; devOtp?: string }>;
  twilioVerifyOtp: (phone: string, code: string, isSignIn?: boolean) => Promise<{ data: any; error: any }>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const publishableKey = import.meta.env.VITE_RADAR_PUBLISHABLE_KEY;
    if (publishableKey) {
      Radar.initialize(publishableKey);
      radarService.initialize().catch(() => {});
    }

    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      setLoading(false);

      if (session?.user && publishableKey) {
        Radar.setUserId(session.user.id);
        if (radarService.isInitialized()) {
          radarService.setUserId(session.user.id);
        }
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      (async () => {
        setSession(session);
        setUser(session?.user ?? null);

        if (session?.user && publishableKey) {
          Radar.setUserId(session.user.id);
          if (!radarService.isInitialized()) {
            await radarService.initialize().catch(() => {});
          }
          if (radarService.isInitialized()) {
            radarService.setUserId(session.user.id);
          }
        } else {
          Radar.setUserId(null);
        }
      })();
    });

    return () => subscription.unsubscribe();
  }, []);

  const signUp = async (email: string, password: string) => {
    const { error } = await supabase.auth.signUp({
      email,
      password,
    });
    return { error };
  };

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    return { error };
  };

  const signInWithPhone = async (phone: string) => {
    const { error } = await supabase.auth.signInWithOtp({
      phone,
    });
    return { error };
  };

  const verifyOtp = async (phone: string, token: string) => {
    const { data, error } = await supabase.auth.verifyOtp({
      phone,
      token,
      type: 'sms',
    });
    return { data, error };
  };

  const DEMO_AU_PHONE = '+61400000001';
  const DEMO_AU_EMAIL = 'demodarwin@barfliz.phone';
  const DEMO_AU_PASSWORD = 'ph_demodarwin_barfliz';

  const twilioSendOtp = async (phone: string) => {
    if (phone === '+15550000001' || phone === DEMO_AU_PHONE) {
      return { error: null };
    }

    try {
      const { data, error } = await supabase.functions.invoke('twilio-send-otp', {
        body: { phone }
      });

      if (error) throw error;
      if (data.error) throw new Error(data.error);

      localStorage.setItem('pending_otp', data.otp);

      // If Twilio isn't configured, return the OTP so UI can show it on-screen
      if (!data.sms_sent) {
        return { error: null, devOtp: data.otp };
      }
      return { error: null };
    } catch (error: any) {
      return { error };
    }
  };

  const DEMO_PHONE = '+15550000001';
  const DEMO_EMAIL = 'demo33326@barfliz.phone';
  const DEMO_PASSWORD = 'ph_demo33326_barfliz';

  const twilioVerifyOtp = async (phone: string, code: string, isSignIn = false) => {
    if (phone === DEMO_PHONE && code === '0001') {
      const { error: signUpError } = await supabase.auth.signUp({ email: DEMO_EMAIL, password: DEMO_PASSWORD });
      if (signUpError && !signUpError.message.includes('already registered')) {
        return { data: null, error: signUpError };
      }
      const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({ email: DEMO_EMAIL, password: DEMO_PASSWORD });
      if (signInError) return { data: null, error: signInError };
      localStorage.setItem('userCountryCode', 'US');
      localStorage.setItem('demo_mode', 'true');
      return { data: signInData, error: null };
    }

    if (phone === DEMO_AU_PHONE && code === '0001') {
      const { error: signUpError } = await supabase.auth.signUp({ email: DEMO_AU_EMAIL, password: DEMO_AU_PASSWORD });
      if (signUpError && !signUpError.message.includes('already registered')) {
        return { data: null, error: signUpError };
      }
      const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({ email: DEMO_AU_EMAIL, password: DEMO_AU_PASSWORD });
      if (signInError) return { data: null, error: signInError };
      localStorage.setItem('userCountryCode', 'AU');
      localStorage.setItem('demo_mode', 'true');
      return { data: signInData, error: null };
    }

    try {
      const storedOtp = localStorage.getItem('pending_otp');
      if (!storedOtp) {
        throw new Error('No OTP found. Please request a new code.');
      }

      const { data: verifyData, error: verifyError } = await supabase.functions.invoke('twilio-verify-otp', {
        body: { phone, code, storedOtp }
      });

      if (verifyError) throw verifyError;
      if (verifyData.error) throw new Error(verifyData.error);

      localStorage.removeItem('pending_otp');

      const phoneEmail = `${phone.replace(/\+/g, 'p').replace(/\s/g, '')}@barfliz.phone`;
      const phonePassword = `ph_${phone.slice(-8)}_barfliz`;

      let authData;
      let authError;

      if (isSignIn) {
        const result = await supabase.auth.signInWithPassword({
          email: phoneEmail,
          password: phonePassword,
        });
        authData = result.data;
        authError = result.error;
      } else {
        const result = await supabase.auth.signUp({
          email: phoneEmail,
          password: phonePassword,
        });
        authData = result.data;
        authError = result.error;

        if (authError && authError.message.includes('already registered')) {
          const signInResult = await supabase.auth.signInWithPassword({
            email: phoneEmail,
            password: phonePassword,
          });
          authData = signInResult.data;
          authError = signInResult.error;
        }
      }

      if (authError) return { data: null, error: authError };

      return { data: authData, error: null };
    } catch (error: any) {
      return { data: null, error };
    }
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    Radar.setUserId(null);
    localStorage.removeItem('demo_mode');
    localStorage.removeItem('pendingUserName');
    localStorage.removeItem('pendingUserBirthday');
    localStorage.removeItem('pendingPhoneNumber');
    localStorage.removeItem('pendingPhoneCountryCode');
    localStorage.removeItem('pendingFavoriteDrinks');
    localStorage.removeItem('pendingVenuePreferences');
    localStorage.removeItem('pendingDrinkingVibes');
    localStorage.removeItem('location_permission');
    localStorage.removeItem('contacts_permission');
    localStorage.removeItem('notification_permission');
    localStorage.removeItem('userCountryCode');
    localStorage.removeItem('minDrinkingAge');
    localStorage.removeItem('age_verified');
    localStorage.removeItem('onboarding_complete');
    window.location.href = '/';
  };

  return (
    <AuthContext.Provider value={{ user, session, loading, signUp, signIn, signInWithPhone, verifyOtp, twilioSendOtp, twilioVerifyOtp, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
