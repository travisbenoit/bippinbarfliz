import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { ChevronLeft, ExternalLink, CheckCircle, Wallet, ArrowRight, RefreshCw } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { usePaymentProvider } from '../../hooks/usePaymentProvider';
import { useToast } from '../../contexts/ToastContext';

type Step = 'intro' | 'connecting' | 'confirm';

const VENMO_APP_URL = 'venmo://';
const VENMO_WEB_URL = 'https://account.venmo.com/';
const BEEM_APP_URL = 'beemit://';
const BEEM_WEB_URL = 'https://www.beemit.com.au/';

export function VenmoSetup() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const provider = usePaymentProvider();
  const { showError, showSuccess } = useToast();
  const [step, setStep] = useState<Step>('intro');
  const [username, setUsername] = useState('');
  const [saving, setSaving] = useState(false);
  const [alreadyLinked, setAlreadyLinked] = useState(false);
  const [existingUsername, setExistingUsername] = useState('');

  useEffect(() => {
    if (user) checkExisting();
  }, [user]);

  const checkExisting = async () => {
    if (!user) return;
    const { data } = await supabase
      .from('users')
      .select('payment_provider_linked, payment_provider_username, venmo_linked, venmo_username')
      .eq('id', user.id)
      .maybeSingle();

    if (data) {
      const linked = data.payment_provider_linked || data.venmo_linked || false;
      const uname = data.payment_provider_username || data.venmo_username || '';
      if (linked && uname) {
        setAlreadyLinked(true);
        setExistingUsername(uname);
      }
    }
  };

  const handleOpenApp = useCallback(() => {
    const appUrl = provider.isVenmo ? VENMO_APP_URL : BEEM_APP_URL;
    const webUrl = provider.isVenmo ? VENMO_WEB_URL : BEEM_WEB_URL;

    setStep('connecting');

    const opened = window.open(appUrl, '_blank');

    setTimeout(() => {
      if (!opened || opened.closed) {
        window.open(webUrl, '_blank');
      }
    }, 1500);

    setTimeout(() => {
      setStep('confirm');
    }, 2000);
  }, [provider]);

  const handleOpenWeb = useCallback(() => {
    const webUrl = provider.isVenmo ? VENMO_WEB_URL : BEEM_WEB_URL;
    setStep('connecting');
    window.open(webUrl, '_blank');
    setTimeout(() => {
      setStep('confirm');
    }, 2000);
  }, [provider]);

  const handleSaveUsername = async () => {
    if (!username.trim()) {
      showError(`Please enter your ${provider.displayName} username`);
      return;
    }

    if (!user) return;
    setSaving(true);

    const { error } = await supabase
      .from('users')
      .update({
        payment_provider: provider.name,
        payment_provider_username: username.trim().replace(/^@/, ''),
        payment_provider_linked: true,
        venmo_username: provider.isVenmo ? username.trim().replace(/^@/, '') : null,
        venmo_linked: provider.isVenmo,
      })
      .eq('id', user.id);

    setSaving(false);

    if (error) {
      showError(`Failed to link ${provider.displayName} account. Please try again.`);
      return;
    }

    showSuccess(`${provider.displayName} account connected!`);
    navigate('/payments');
  };

  const handleDisconnect = async () => {
    if (!user) return;
    setSaving(true);

    const { error } = await supabase
      .from('users')
      .update({
        payment_provider: null,
        payment_provider_username: null,
        payment_provider_linked: false,
        venmo_username: null,
        venmo_linked: false,
      })
      .eq('id', user.id);

    setSaving(false);

    if (error) {
      showError('Failed to disconnect account. Please try again.');
      return;
    }

    showSuccess('Account disconnected');
    setAlreadyLinked(false);
    setExistingUsername('');
    setStep('intro');
  };

  if (provider.loading) {
    return (
      <div className="min-h-screen bg-white flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-[#E91E63] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (alreadyLinked) {
    return (
      <div className="min-h-screen bg-white flex flex-col">
        <div className="px-4 pt-6 pb-4 flex items-center border-b border-gray-100">
          <button
            onClick={() => navigate('/payments')}
            className="mr-3 p-2 hover:bg-gray-100 rounded-full transition-colors"
          >
            <ChevronLeft className="w-6 h-6 text-gray-700" />
          </button>
          <h1 className="text-xl font-bold text-gray-900">Manage {provider.displayName}</h1>
        </div>

        <div className="flex-1 flex flex-col items-center justify-center px-6 pb-32">
          <div className="w-20 h-20 rounded-full bg-emerald-100 flex items-center justify-center mb-6">
            <CheckCircle className="w-10 h-10 text-emerald-600" />
          </div>

          <h2 className="text-2xl font-bold text-gray-900 mb-2">Account Connected</h2>
          <p className="text-gray-600 text-center mb-2">
            Your {provider.displayName} account is linked
          </p>
          <p className="text-lg font-semibold text-gray-900 mb-8">
            @{existingUsername}
          </p>

          <button
            onClick={() => {
              setAlreadyLinked(false);
              setStep('intro');
            }}
            className="w-full max-w-sm bg-gray-900 text-white rounded-2xl py-4 font-semibold hover:bg-gray-800 transition-colors mb-3"
          >
            Switch Account
          </button>

          <button
            onClick={handleDisconnect}
            disabled={saving}
            className="w-full max-w-sm border-2 border-red-200 text-red-600 rounded-2xl py-4 font-semibold hover:bg-red-50 transition-colors disabled:opacity-50"
          >
            {saving ? 'Disconnecting...' : 'Disconnect Account'}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white flex flex-col">
      <div className="px-4 pt-6 pb-4 flex items-center border-b border-gray-100">
        <button
          onClick={() => navigate('/payments')}
          className="mr-3 p-2 hover:bg-gray-100 rounded-full transition-colors"
        >
          <ChevronLeft className="w-6 h-6 text-gray-700" />
        </button>
        <h1 className="text-xl font-bold text-gray-900">Connect {provider.displayName}</h1>
      </div>

      {step === 'intro' && (
        <div className="flex-1 flex flex-col px-6 pt-8 pb-32">
          <div className="flex-1 flex flex-col items-center justify-center">
            <div className="w-24 h-24 rounded-3xl bg-gradient-to-br from-[#008CFF] to-[#0070CC] flex items-center justify-center mb-6 shadow-lg shadow-blue-200">
              {provider.isVenmo ? (
                <span className="text-white text-4xl font-black tracking-tight">V</span>
              ) : (
                <Wallet className="w-12 h-12 text-white" />
              )}
            </div>

            <h2 className="text-2xl font-bold text-gray-900 mb-3 text-center">
              Connect Your {provider.displayName} Account
            </h2>
            <p className="text-gray-600 text-center leading-relaxed mb-8 max-w-sm">
              Link your {provider.displayName} to send and receive drinks from friends.
              You'll be redirected to {provider.displayName} to sign in, then come back here to confirm.
            </p>

            <div className="w-full max-w-sm space-y-3 mb-8">
              <div className="flex items-start gap-3 p-4 bg-gray-50 rounded-xl">
                <div className="w-8 h-8 rounded-full bg-[#E91E63]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <span className="text-[#E91E63] font-bold text-sm">1</span>
                </div>
                <div>
                  <p className="font-medium text-gray-900">Open {provider.displayName}</p>
                  <p className="text-sm text-gray-500">Sign into your account</p>
                </div>
              </div>

              <div className="flex items-start gap-3 p-4 bg-gray-50 rounded-xl">
                <div className="w-8 h-8 rounded-full bg-[#E91E63]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <span className="text-[#E91E63] font-bold text-sm">2</span>
                </div>
                <div>
                  <p className="font-medium text-gray-900">Come back here</p>
                  <p className="text-sm text-gray-500">Confirm your username</p>
                </div>
              </div>

              <div className="flex items-start gap-3 p-4 bg-gray-50 rounded-xl">
                <div className="w-8 h-8 rounded-full bg-[#E91E63]/10 flex items-center justify-center flex-shrink-0 mt-0.5">
                  <span className="text-[#E91E63] font-bold text-sm">3</span>
                </div>
                <div>
                  <p className="font-medium text-gray-900">Start sending drinks</p>
                  <p className="text-sm text-gray-500">Your friends can send you drinks too</p>
                </div>
              </div>
            </div>
          </div>

          <div className="space-y-3">
            <button
              onClick={handleOpenApp}
              className="w-full bg-[#008CFF] text-white rounded-2xl py-4 flex items-center justify-center gap-3 hover:bg-[#0070CC] transition-colors font-semibold text-lg"
            >
              <span>Open {provider.displayName} App</span>
              <ExternalLink className="w-5 h-5" />
            </button>

            <button
              onClick={handleOpenWeb}
              className="w-full border-2 border-gray-200 text-gray-700 rounded-2xl py-4 flex items-center justify-center gap-2 hover:bg-gray-50 transition-colors font-medium"
            >
              <span>Use {provider.displayName} Website Instead</span>
              <ArrowRight className="w-4 h-4" />
            </button>

            <button
              onClick={() => setStep('confirm')}
              className="w-full text-gray-500 py-3 text-sm hover:text-gray-700 transition-colors"
            >
              I already know my username
            </button>
          </div>
        </div>
      )}

      {step === 'connecting' && (
        <div className="flex-1 flex flex-col items-center justify-center px-6 pb-32">
          <div className="w-16 h-16 rounded-full bg-blue-50 flex items-center justify-center mb-6">
            <RefreshCw className="w-8 h-8 text-[#008CFF] animate-spin" />
          </div>
          <h2 className="text-xl font-bold text-gray-900 mb-2">Opening {provider.displayName}...</h2>
          <p className="text-gray-500 text-center">
            Sign into your account, then come back here
          </p>
        </div>
      )}

      {step === 'confirm' && (
        <div className="flex-1 flex flex-col px-6 pt-8 pb-32">
          <div className="flex-1 flex flex-col items-center justify-center">
            <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-emerald-400 to-emerald-600 flex items-center justify-center mb-6 shadow-lg shadow-emerald-200">
              <CheckCircle className="w-10 h-10 text-white" />
            </div>

            <h2 className="text-2xl font-bold text-gray-900 mb-2 text-center">
              Welcome Back!
            </h2>
            <p className="text-gray-600 text-center mb-8 max-w-sm">
              Enter your {provider.displayName} username below to complete the connection.
              {provider.isVenmo
                ? ' You can find it in the Venmo app under your profile.'
                : ' You can find it in the Beem It app under your profile settings.'}
            </p>

            <div className="w-full max-w-sm mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                {provider.displayName} Username
              </label>
              <div className="relative">
                <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 font-medium">@</span>
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value.replace(/^@/, ''))}
                  placeholder={provider.isVenmo ? 'yourvenmo' : 'yourbeem'}
                  className="w-full pl-9 pr-4 py-4 border-2 border-gray-200 rounded-2xl focus:outline-none focus:border-[#008CFF] focus:ring-4 focus:ring-[#008CFF]/10 text-lg transition-all"
                  autoFocus
                  onKeyDown={(e) => e.key === 'Enter' && handleSaveUsername()}
                />
              </div>
              <p className="text-xs text-gray-500 mt-2">
                This is the username people use to send you money on {provider.displayName}
              </p>
            </div>
          </div>

          <div className="space-y-3">
            <button
              onClick={handleSaveUsername}
              disabled={saving || !username.trim()}
              className="w-full bg-emerald-600 text-white rounded-2xl py-4 font-semibold text-lg hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {saving ? (
                <div className="w-6 h-6 border-2 border-white border-t-transparent rounded-full animate-spin mx-auto" />
              ) : (
                'Connect Account'
              )}
            </button>

            <button
              onClick={() => setStep('intro')}
              className="w-full text-gray-500 py-3 font-medium hover:text-gray-700 transition-colors"
            >
              Go Back
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
