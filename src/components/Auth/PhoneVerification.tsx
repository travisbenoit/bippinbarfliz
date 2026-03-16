import { useState, useRef, useEffect, FormEvent } from 'react';
import { useNavigate, useLocation } from 'react-router';
import { ArrowLeft, ArrowRight } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';

const DEMO_PHONE = '+15550000001';
const DEMO_AU_PHONE = '+61400000001';

export default function PhoneVerification() {
  const navigate = useNavigate();
  const location = useLocation();
  const phone = location.state?.phone || '';
  const countryCode = location.state?.countryCode || localStorage.getItem('userCountryCode') || 'US';
  const isSignIn = location.state?.isSignIn || false;
  const initialDevOtp = location.state?.devOtp || null;
  const isDemo = phone === DEMO_PHONE || phone === DEMO_AU_PHONE;
  const [otp, setOtp] = useState(isDemo ? ['0', '0', '0', '1'] : ['', '', '', '']);
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [error, setError] = useState('');
  const [resendTimer, setResendTimer] = useState(13);
  const [devOtp, setDevOtp] = useState<string | null>(initialDevOtp);
  const inputRefs = [
    useRef<HTMLInputElement>(null),
    useRef<HTMLInputElement>(null),
    useRef<HTMLInputElement>(null),
    useRef<HTMLInputElement>(null),
  ];
  const { twilioVerifyOtp, twilioSendOtp } = useAuth();

  useEffect(() => {
    inputRefs[0].current?.focus();
  }, []);

  useEffect(() => {
    if (resendTimer > 0) {
      const timer = setTimeout(() => setResendTimer(resendTimer - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [resendTimer]);

  const handleOtpChange = (index: number, value: string) => {
    if (value.length > 1) {
      value = value[0];
    }

    if (!/^\d*$/.test(value)) {
      return;
    }

    const newOtp = [...otp];
    newOtp[index] = value;
    setOtp(newOtp);

    if (value && index < 3) {
      inputRefs[index + 1].current?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      inputRefs[index - 1].current?.focus();
    }
  };

  const savePhoneToProfile = async (userId: string) => {
    const pendingPhone = phone;
    const pendingCountryCode = localStorage.getItem('userCountryCode') || countryCode;

    await supabase
      .from('users')
      .update({
        phone_number: pendingPhone,
        phone_country_code: pendingCountryCode,
        registration_country: pendingCountryCode
      })
      .eq('id', userId);

    localStorage.removeItem('pendingPhoneNumber');
    localStorage.removeItem('pendingPhoneCountryCode');
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');

    const otpCode = otp.join('');
    if (otpCode.length !== 4) {
      setError('Please enter the complete OTP');
      return;
    }

    setLoading(true);

    const { data, error: verifyError } = await twilioVerifyOtp(phone, otpCode, isSignIn);
    if (verifyError) {
      setError(verifyError.message);
      setLoading(false);
      return;
    }
    if (data?.user) {
      await savePhoneToProfile(data.user.id);
    }
  };

  const handleResend = async () => {
    if (resendTimer > 0 || resending) return;

    setError('');
    setResending(true);

    const { error, devOtp: newDevOtp } = await twilioSendOtp(phone);

    if (error) {
      setError(error.message);
    } else {
      setResendTimer(13);
      setOtp(['', '', '', '']);
      setDevOtp(newDevOtp || null);
      inputRefs[0].current?.focus();
    }

    setResending(false);
  };

  return (
    <div className="min-h-screen bg-white flex flex-col px-6 py-8">
      <div className="flex items-center justify-between mb-8">
        <button onClick={() => navigate(-1)}>
          <ArrowLeft size={24} className="text-gray-700" />
        </button>
        <div className="text-sm text-gray-600">
          9:27
        </div>
      </div>

      <div className="flex-1 flex flex-col justify-between max-w-md mx-auto w-full">
        <div className="space-y-8 pt-8">
          <div className="text-center space-y-4">
            <h1 className="text-3xl font-bold text-gray-900">
              Verify Phone Number
            </h1>
            <p className="text-gray-600 text-sm">
              We've sent you an SMS with a 4-digit verification code to {phone}
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-8">
            {isDemo && (
              <div className="bg-amber-50 border border-amber-300 text-amber-800 px-4 py-3 rounded-xl text-sm text-center">
                <p className="font-semibold">Demo Mode Active</p>
                <p className="text-xs mt-1">Code pre-filled — tap Continue to explore {phone === DEMO_AU_PHONE ? 'Darwin, NT' : 'Weston, FL'}</p>
              </div>
            )}
            {devOtp && !isDemo && (
              <div className="bg-blue-50 border border-blue-300 text-blue-800 px-4 py-4 rounded-xl text-center">
                <p className="text-xs font-semibold uppercase tracking-wide mb-1 text-blue-500">SMS not configured</p>
                <p className="text-sm mb-2">Your verification code is:</p>
                <p className="text-4xl font-black tracking-[0.3em] text-blue-700">{devOtp}</p>
                <p className="text-xs text-blue-500 mt-2">Enter this code below to continue</p>
              </div>
            )}
            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}

            <div className="flex justify-center gap-3">
              {otp.map((digit, index) => (
                <input
                  key={index}
                  ref={inputRefs[index]}
                  type="text"
                  inputMode="numeric"
                  maxLength={1}
                  value={digit}
                  onChange={(e) => handleOtpChange(index, e.target.value)}
                  onKeyDown={(e) => handleKeyDown(index, e)}
                  className="w-16 h-16 text-center text-2xl font-bold text-[#E91E63] border-2 border-gray-200 rounded-2xl focus:border-[#E91E63] focus:outline-none bg-white"
                />
              ))}
            </div>

            <div className="text-center space-y-2">
              <p className="text-gray-600 text-sm">
                Didn't receive the code?
              </p>
              {resendTimer > 0 ? (
                <p className="text-[#E91E63] font-semibold text-sm">
                  Resend in {resendTimer} sec
                </p>
              ) : (
                <button
                  type="button"
                  onClick={handleResend}
                  disabled={resending}
                  className="text-[#E91E63] font-semibold text-sm hover:underline disabled:opacity-50"
                >
                  {resending ? 'Sending...' : 'Resend Code'}
                </button>
              )}
            </div>
          </form>
        </div>

        <div className="space-y-6 pb-8">
          <button
            onClick={handleSubmit}
            disabled={loading || otp.some(d => !d)}
            className="w-full bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg flex items-center justify-center gap-2 hover:bg-[#C2185B] transition-colors shadow-lg disabled:opacity-50"
          >
            {loading ? 'Verifying...' : 'Continue'}
            <ArrowRight size={24} />
          </button>

          <div className="h-1 w-32 bg-gray-900 rounded-full mx-auto" />
        </div>
      </div>
    </div>
  );
}
