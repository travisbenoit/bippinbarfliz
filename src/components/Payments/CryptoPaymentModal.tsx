import { useState } from 'react';
import { X, Wallet, Loader2, CheckCircle, AlertCircle } from 'lucide-react';
import { useWallet } from '../../hooks/useWallet';
import { buildUSDCTransferTx, verifyAndRecordPayment } from '../../services/usdcPaymentService';

interface CryptoPaymentModalProps {
  isOpen: boolean;
  onClose: () => void;
  recipientName: string;
  recipientUserId: string;
  recipientWalletAddress: string;
}

const PRESETS = [5, 10, 15, 20, 25, 30];

type Step = 'amount' | 'confirming' | 'success' | 'error';

export function CryptoPaymentModal({
  isOpen,
  onClose,
  recipientName,
  recipientUserId,
  recipientWalletAddress,
}: CryptoPaymentModalProps) {
  const wallet = useWallet();
  const [amount, setAmount] = useState<number | null>(null);
  const [customAmount, setCustomAmount] = useState('');
  const [step, setStep] = useState<Step>('amount');
  const [error, setError] = useState('');
  const [txSignature, setTxSignature] = useState('');

  if (!isOpen) return null;

  const finalAmount = amount ?? (Number(customAmount) || 0);
  const canPay = finalAmount > 0 && finalAmount <= wallet.balances.usdc;

  const handlePay = async () => {
    if (!canPay || !wallet.address) return;

    setStep('confirming');
    setError('');

    try {
      // Build the USDC transfer transaction
      const tx = await buildUSDCTransferTx(
        wallet.address,
        recipientWalletAddress,
        finalAmount,
      );

      // Sign and send via Privy embedded wallet
      const signature = await wallet.signAndSendTransaction(tx);
      setTxSignature(signature);

      // Verify on chain and record in DB
      await verifyAndRecordPayment(
        signature,
        wallet.address, // fromUserId would need auth context
        recipientUserId,
        finalAmount,
        `Payment to ${recipientName}`,
      );

      setStep('success');
    } catch (err) {
      setError((err as Error).message || 'Payment failed');
      setStep('error');
    }
  };

  const handleClose = () => {
    setStep('amount');
    setAmount(null);
    setCustomAmount('');
    setError('');
    setTxSignature('');
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 backdrop-blur-sm">
      <div className="w-full max-w-lg bg-white rounded-t-3xl p-6 pb-8 animate-slide-up">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-gray-900">Pay with USDC</h2>
          <button onClick={handleClose} className="p-2 hover:bg-gray-100 rounded-full">
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        {step === 'amount' && (
          <>
            <p className="text-gray-500 text-sm mb-4">
              Send USDC to <span className="font-semibold text-gray-900">{recipientName}</span>
            </p>

            {/* Balance display */}
            <div className="flex items-center gap-2 mb-5 px-4 py-3 bg-gray-50 rounded-2xl">
              <Wallet className="w-4 h-4 text-gray-400" />
              <span className="text-sm text-gray-500">Balance:</span>
              <span className="font-bold text-gray-900">${wallet.balances.usdc.toFixed(2)} USDC</span>
            </div>

            {/* Preset amounts */}
            <div className="grid grid-cols-3 gap-3 mb-4">
              {PRESETS.map((p) => (
                <button
                  key={p}
                  onClick={() => { setAmount(p); setCustomAmount(''); }}
                  className={`py-3 rounded-2xl font-bold text-lg transition-all ${
                    amount === p
                      ? 'bg-blue-600 text-white shadow-lg scale-105'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  ${p}
                </button>
              ))}
            </div>

            {/* Custom amount */}
            <div className="relative mb-6">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 text-lg font-bold">$</span>
              <input
                type="number"
                placeholder="Custom amount"
                value={customAmount}
                onChange={(e) => { setCustomAmount(e.target.value); setAmount(null); }}
                className="w-full pl-8 pr-4 py-3 border border-gray-200 rounded-2xl text-lg font-semibold focus:outline-none focus:ring-2 focus:ring-blue-500"
                min="0.01"
                step="0.01"
              />
            </div>

            {/* Pay button */}
            <button
              onClick={handlePay}
              disabled={!canPay}
              className="w-full py-4 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-2xl font-bold text-lg disabled:opacity-40 disabled:cursor-not-allowed transition-all active:scale-95"
            >
              {finalAmount > 0 ? `Send $${finalAmount.toFixed(2)} USDC` : 'Select amount'}
            </button>

            {finalAmount > wallet.balances.usdc && finalAmount > 0 && (
              <p className="text-red-500 text-xs text-center mt-2">Insufficient USDC balance</p>
            )}
          </>
        )}

        {step === 'confirming' && (
          <div className="flex flex-col items-center py-12">
            <Loader2 className="w-12 h-12 text-blue-600 animate-spin mb-4" />
            <p className="text-gray-900 font-semibold text-lg">Confirming on Solana...</p>
            <p className="text-gray-500 text-sm mt-1">This usually takes a few seconds</p>
          </div>
        )}

        {step === 'success' && (
          <div className="flex flex-col items-center py-12">
            <CheckCircle className="w-16 h-16 text-green-500 mb-4" />
            <p className="text-gray-900 font-bold text-xl">Payment Sent!</p>
            <p className="text-gray-500 text-sm mt-2">
              ${finalAmount.toFixed(2)} USDC sent to {recipientName}
            </p>
            {txSignature && (
              <p className="text-gray-400 text-xs mt-3 truncate max-w-[250px]">
                Tx: {txSignature}
              </p>
            )}
            <button
              onClick={handleClose}
              className="mt-6 px-8 py-3 bg-gray-900 text-white rounded-2xl font-semibold"
            >
              Done
            </button>
          </div>
        )}

        {step === 'error' && (
          <div className="flex flex-col items-center py-12">
            <AlertCircle className="w-16 h-16 text-red-500 mb-4" />
            <p className="text-gray-900 font-bold text-xl">Payment Failed</p>
            <p className="text-red-500 text-sm mt-2 text-center px-4">{error}</p>
            <button
              onClick={() => setStep('amount')}
              className="mt-6 px-8 py-3 bg-gray-900 text-white rounded-2xl font-semibold"
            >
              Try Again
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
