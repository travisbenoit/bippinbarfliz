import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router';
import { ChevronLeft, User, Search, Wallet } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';
import { useToast } from '../../contexts/ToastContext';
import { CRYPTO_ENABLED } from '../../lib/featureFlags';
import { useWallet } from '../../hooks/useWallet';
import { CryptoPaymentModal } from './CryptoPaymentModal';

interface Friend {
  id: string;
  name: string;
  avatar_url: string | null;
  wallet_address?: string | null;
}

const DRINK_AMOUNTS = [
  { label: '$5', value: 5 },
  { label: '$10', value: 10 },
  { label: '$15', value: 15 },
  { label: '$20', value: 20 },
  { label: '$25', value: 25 },
  { label: '$30', value: 30 },
];

export function SendPayment() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { showError, showSuccess } = useToast();
  const wallet = useWallet();
  const [friends, setFriends] = useState<Friend[]>([]);
  const [selectedFriend, setSelectedFriend] = useState<Friend | null>(null);
  const [amount, setAmount] = useState(10);
  const [customAmount, setCustomAmount] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [showCryptoModal, setShowCryptoModal] = useState(false);

  useEffect(() => {
    loadFriends();
  }, []);

  const loadFriends = async () => {
    const { data } = await supabase
      .from('users')
      .select('id, name, avatar_url, wallet_address')
      .neq('id', user?.id)
      .limit(50);

    if (data) {
      setFriends(data);
    }
  };

  const handleSendPayment = async () => {
    if (!selectedFriend || !user) return;

    const finalAmount = customAmount ? parseFloat(customAmount) : amount;

    if (isNaN(finalAmount) || finalAmount <= 0) {
      showError('Please enter a valid amount');
      return;
    }

    setLoading(true);

    const { error } = await supabase
      .from('payment_transactions')
      .insert({
        from_user_id: user.id,
        to_user_id: selectedFriend.id,
        amount: finalAmount,
        transaction_type: 'drink_payment',
        description: message || 'Drink payment',
        status: 'completed',
      });

    setLoading(false);

    if (error) {
      showError('Failed to send payment. Please try again.');
      return;
    }

    showSuccess('Payment sent!');
    navigate('/payments');
  };

  const filteredFriends = friends.filter(friend =>
    friend.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  if (selectedFriend) {
    return (
      <div className="min-h-screen bg-white flex flex-col">
        <div className="bg-gradient-to-r from-[#E91E63] to-[#C2185B] px-4 py-4 flex items-center">
          <button
            onClick={() => setSelectedFriend(null)}
            className="mr-4 p-2 hover:bg-white/10 rounded-full"
          >
            <ChevronLeft className="w-6 h-6 text-white" />
          </button>
          <h1 className="text-xl font-bold text-white">Pay For Drink</h1>
        </div>

        <div className="flex-1 p-6">
          <div className="flex flex-col items-center mb-8">
            <div className="w-24 h-24 rounded-full bg-gradient-to-br from-[#E91E63] to-[#C2185B] flex items-center justify-center overflow-hidden mb-4">
              {selectedFriend.avatar_url ? (
                <img
                  src={selectedFriend.avatar_url}
                  alt={selectedFriend.name}
                  className="w-full h-full object-cover"
                />
              ) : (
                <User className="w-12 h-12 text-white" />
              )}
            </div>
            <h2 className="text-2xl font-bold text-gray-900">{selectedFriend.name}</h2>
          </div>

          <div className="space-y-6">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-3">
                Select Amount
              </label>
              <div className="grid grid-cols-3 gap-3">
                {DRINK_AMOUNTS.map((preset) => (
                  <button
                    key={preset.value}
                    onClick={() => {
                      setAmount(preset.value);
                      setCustomAmount('');
                    }}
                    className={`py-3 rounded-xl font-semibold transition-colors ${
                      amount === preset.value && !customAmount
                        ? 'bg-[#E91E63] text-white'
                        : 'bg-gray-100 text-gray-900 hover:bg-gray-200'
                    }`}
                  >
                    {preset.label}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Or Custom Amount
              </label>
              <input
                type="number"
                value={customAmount}
                onChange={(e) => setCustomAmount(e.target.value)}
                placeholder="Enter amount"
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#E91E63]"
              />
            </div>

            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Message (Optional)
              </label>
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Add a note..."
                rows={3}
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#E91E63] resize-none"
              />
            </div>
          </div>
        </div>

        <div className="p-6 border-t border-gray-200 space-y-3">
          <button
            onClick={handleSendPayment}
            disabled={loading}
            className="w-full bg-[#E91E63] text-white rounded-full py-4 font-bold hover:bg-[#C2185B] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? (
              <div className="w-6 h-6 border-2 border-white border-t-transparent rounded-full animate-spin mx-auto" />
            ) : (
              `Send $${customAmount || amount}`
            )}
          </button>

          {CRYPTO_ENABLED && wallet.address && selectedFriend?.wallet_address && (
            <button
              onClick={() => setShowCryptoModal(true)}
              className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-full py-4 font-bold transition-all active:scale-95"
            >
              <Wallet className="w-5 h-5" />
              Pay with USDC
            </button>
          )}
        </div>

        {CRYPTO_ENABLED && selectedFriend?.wallet_address && (
          <CryptoPaymentModal
            isOpen={showCryptoModal}
            onClose={() => setShowCryptoModal(false)}
            recipientName={selectedFriend.name}
            recipientUserId={selectedFriend.id}
            recipientWalletAddress={selectedFriend.wallet_address}
          />
        )}
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white flex flex-col">
      <div className="bg-gradient-to-r from-[#E91E63] to-[#C2185B] px-4 py-4 flex items-center">
        <button
          onClick={() => navigate('/payments')}
          className="mr-4 p-2 hover:bg-white/10 rounded-full"
        >
          <ChevronLeft className="w-6 h-6 text-white" />
        </button>
        <h1 className="text-xl font-bold text-white">Pay For Drink</h1>
      </div>

      <div className="p-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search friends..."
            className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#E91E63]"
          />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-4">
        <h2 className="text-sm font-semibold text-gray-500 mb-3">Select Friend</h2>
        <div className="space-y-2">
          {filteredFriends.map((friend) => (
            <button
              key={friend.id}
              onClick={() => setSelectedFriend(friend)}
              className="w-full flex items-center space-x-3 p-3 hover:bg-gray-50 rounded-xl transition-colors"
            >
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#E91E63] to-[#C2185B] flex items-center justify-center overflow-hidden">
                {friend.avatar_url ? (
                  <img
                    src={friend.avatar_url}
                    alt={friend.name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <User className="w-6 h-6 text-white" />
                )}
              </div>
              <span className="font-semibold text-gray-900">{friend.name}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
