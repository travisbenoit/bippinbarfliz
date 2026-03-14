import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Wine, HandCoins, Settings, Wallet, Copy, Check } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { usePaymentProvider } from '../../hooks/usePaymentProvider';
import { CRYPTO_ENABLED } from '../../lib/featureFlags';
import { useWallet } from '../../hooks/useWallet';
import { TransactionHistory } from './TransactionHistory';

interface Transaction {
  id: string;
  from_user_id: string;
  to_user_id: string;
  amount: number;
  transaction_type: string;
  description: string | null;
  drink_name: string | null;
  created_at: string;
  from_user?: {
    name: string;
    avatar_url: string | null;
  };
  to_user?: {
    name: string;
    avatar_url: string | null;
  };
}

export function PaymentsView() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const provider = usePaymentProvider();
  const wallet = useWallet();
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState(true);
  const [paymentLinked, setPaymentLinked] = useState(false);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (user) {
      loadUserPaymentStatus();
      loadTransactions();
    }
  }, [user]);

  const loadUserPaymentStatus = async () => {
    if (!user) return;

    const { data } = await supabase
      .from('users')
      .select('payment_provider_linked, venmo_linked')
      .eq('id', user.id)
      .maybeSingle();

    if (data) {
      setPaymentLinked(data.payment_provider_linked || data.venmo_linked || false);
    }
  };

  const loadTransactions = async () => {
    if (!user) return;

    const { data, error } = await supabase
      .from('payment_transactions')
      .select(`
        *,
        from_user:from_user_id(name, avatar_url),
        to_user:to_user_id(name, avatar_url)
      `)
      .or(`from_user_id.eq.${user.id},to_user_id.eq.${user.id}`)
      .order('created_at', { ascending: false })
      .limit(20);

    if (data && !error) {
      setTransactions(data as Transaction[]);
    }
    setLoading(false);
  };

  const handleReceiveDrink = () => {
    if (!paymentLinked) {
      navigate('/payments/setup');
      return;
    }
    navigate('/payments/receive');
  };

  const handlePayForDrink = () => {
    if (!paymentLinked) {
      navigate('/payments/setup');
      return;
    }
    navigate('/payments/send');
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-600 to-blue-500 pb-20">
      <div className="px-6 pt-12 pb-6 flex items-center justify-between">
        <h1 className="text-3xl font-bold text-white">Payments</h1>
        <button
          onClick={() => navigate('/payments/settings')}
          className="p-2 hover:bg-white/10 rounded-full transition-colors"
        >
          <Settings className="w-6 h-6 text-white" />
        </button>
      </div>

      {!provider.loading && (
        <div className="px-6 mb-4 flex items-center gap-3">
          <div className="bg-white/20 rounded-2xl px-4 py-2 inline-flex items-center space-x-2">
            <span className="text-white text-sm font-medium">
              Payments via {provider.displayName}
            </span>
          </div>
          <div className="bg-white/20 rounded-2xl px-3 py-2 inline-flex items-center">
            <span className="text-white text-sm font-medium">
              {provider.currency}
            </span>
          </div>
        </div>
      )}

      {/* Crypto wallet card — only shown when CRYPTO_ENABLED */}
      {CRYPTO_ENABLED && wallet.address && (
        <div className="px-6 mb-4">
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-4 border border-white/20">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-pink-500 rounded-xl flex items-center justify-center">
                <Wallet className="w-5 h-5 text-white" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white text-sm font-semibold">Solana Wallet</p>
                <button
                  onClick={() => {
                    navigator.clipboard.writeText(wallet.address!);
                    setCopied(true);
                    setTimeout(() => setCopied(false), 2000);
                  }}
                  className="flex items-center gap-1 text-white/60 text-xs hover:text-white/80 transition-colors"
                >
                  <span className="truncate max-w-[180px]">{wallet.address}</span>
                  {copied ? <Check className="w-3 h-3 text-green-400" /> : <Copy className="w-3 h-3" />}
                </button>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="bg-white/10 rounded-xl px-3 py-2">
                <p className="text-white/50 text-[10px] uppercase tracking-wider font-semibold">LUSH</p>
                <p className="text-white text-lg font-bold">{wallet.balances.lush.toLocaleString()}</p>
              </div>
              <div className="bg-white/10 rounded-xl px-3 py-2">
                <p className="text-white/50 text-[10px] uppercase tracking-wider font-semibold">USDC</p>
                <p className="text-white text-lg font-bold">${wallet.balances.usdc.toFixed(2)}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="px-6 grid grid-cols-2 gap-4 mb-6">
        <button
          onClick={handleReceiveDrink}
          className="bg-cyan-100 rounded-3xl p-8 flex flex-col items-center justify-center space-y-4 hover:bg-cyan-200 transition-all transform hover:scale-105 active:scale-95"
        >
          <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center">
            <Wine className="w-8 h-8 text-cyan-600" strokeWidth={2} />
          </div>
          <div className="text-center">
            <p className="font-bold text-gray-900 text-lg">Receive Drink</p>
            <p className="text-sm text-gray-600 mt-1">Send Request</p>
          </div>
        </button>

        <button
          onClick={handlePayForDrink}
          className="bg-orange-100 rounded-3xl p-8 flex flex-col items-center justify-center space-y-4 hover:bg-orange-200 transition-all transform hover:scale-105 active:scale-95"
        >
          <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center">
            <HandCoins className="w-8 h-8 text-orange-600" strokeWidth={2} />
          </div>
          <div className="text-center">
            <p className="font-bold text-gray-900 text-lg">Pay For Drink</p>
            <p className="text-sm text-gray-600 mt-1">Surprise Your Friend</p>
          </div>
        </button>
      </div>

      <div className="bg-white rounded-t-3xl min-h-[60vh] pt-6 px-6">
        <h2 className="text-xl font-bold text-gray-900 mb-4">History</h2>

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full animate-spin" />
          </div>
        ) : transactions.length === 0 ? (
          <div className="text-center py-12 text-gray-500">
            <p>No transactions yet</p>
            <p className="text-sm mt-2">Send or receive your first drink!</p>
          </div>
        ) : (
          <TransactionHistory transactions={transactions} currentUserId={user?.id} />
        )}
      </div>
    </div>
  );
}
