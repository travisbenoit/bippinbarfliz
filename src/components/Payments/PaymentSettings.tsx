import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router';
import { ChevronLeft, ExternalLink } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { usePaymentProvider } from '../../hooks/usePaymentProvider';

export function PaymentSettings() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const provider = usePaymentProvider();
  const [paymentLinked, setPaymentLinked] = useState(false);
  const [paymentUsername, setPaymentUsername] = useState('');
  const [lushCoinBalance, setLushCoinBalance] = useState(0);

  useEffect(() => {
    if (user) {
      loadUserPaymentInfo();
    }
  }, [user]);

  const loadUserPaymentInfo = async () => {
    if (!user) return;

    const { data } = await supabase
      .from('users')
      .select('payment_provider_linked, payment_provider_username, venmo_linked, venmo_username, lush_coin_balance')
      .eq('id', user.id)
      .maybeSingle();

    if (data) {
      const linked = data.payment_provider_linked || data.venmo_linked || false;
      const username = data.payment_provider_username || data.venmo_username || '';
      setPaymentLinked(linked);
      setPaymentUsername(username);
      setLushCoinBalance(Number(data.lush_coin_balance) || 0);
    }
  };

  const handlePaymentSetup = () => {
    if (paymentLinked) {
      navigate('/payments/setup');
    } else {
      navigate('/payments/setup');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-white border-b border-gray-200 px-4 py-4 flex items-center">
        <button
          onClick={() => navigate('/payments')}
          className="mr-4 p-2 hover:bg-gray-100 rounded-full"
        >
          <ChevronLeft className="w-6 h-6" />
        </button>
        <h1 className="text-xl font-bold">Payments Setting</h1>
      </div>

      <div className="p-6 space-y-4">
        <div className="bg-gray-100 rounded-2xl p-6">
          <h2 className="font-bold text-gray-900 text-lg mb-2">
            Receive and gives drinks
          </h2>
          <p className="text-gray-700 text-sm mb-4 leading-relaxed">
            Adding Payment Option will let you get drinks from your friends and you can also give drinks to others.
          </p>
          <button
            onClick={handlePaymentSetup}
            className="text-blue-600 font-semibold hover:text-blue-700"
          >
            {paymentLinked && paymentUsername
              ? `Manage ${provider.displayName} Account (@${paymentUsername})`
              : `Link ${provider.displayName} Account`}
          </button>
        </div>

        <div className="bg-gray-100 rounded-2xl p-6">
          <h2 className="font-bold text-gray-900 text-lg mb-2">
            Lush Coin
          </h2>
          <p className="text-gray-700 text-sm mb-2 leading-relaxed">
            Lush Coin is a ner privacy focused digital currency.
          </p>
          <div className="flex items-center justify-between mb-4">
            <span className="text-sm text-gray-600">Your Balance:</span>
            <span className="font-bold text-lg text-gray-900">{lushCoinBalance} LC</span>
          </div>
          <button
            onClick={() => navigate('/payments/lush-coin')}
            className="text-blue-600 font-semibold hover:text-blue-700"
          >
            Learn more
          </button>
        </div>

        <div className="bg-gray-100 rounded-2xl p-6">
          <h2 className="font-bold text-gray-900 text-lg mb-2">
            Adding Funds
          </h2>
          <p className="text-gray-700 text-sm mb-4 leading-relaxed">
            You can add funds for use in Barfliz to send drinks to your friends by attaching your {provider.displayName.toLowerCase()} account
          </p>
          <button
            onClick={handlePaymentSetup}
            className="text-blue-600 font-semibold hover:text-blue-700"
          >
            Link Account
          </button>
        </div>

        <button
          onClick={() => navigate('/payments/setup')}
          className="w-full bg-blue-500 text-white rounded-full py-4 flex items-center justify-center space-x-2 hover:bg-blue-600 transition-colors mt-8"
        >
          <span className="font-bold text-lg">{provider.name}</span>
          <ExternalLink className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
}
