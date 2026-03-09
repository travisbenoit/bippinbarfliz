import { X } from 'lucide-react';
import { XPProfile } from './XPProfile';

interface XPProfilePageProps {
  isOpen: boolean;
  onClose: () => void;
  userId?: string;
}

export function XPProfilePage({ isOpen, onClose, userId }: XPProfilePageProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[2000] flex items-end justify-center">
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={onClose}
      />
      <div className="relative bg-white rounded-t-3xl w-full max-w-lg max-h-[95vh] overflow-hidden animate-slide-up flex flex-col">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h2 className="text-xl font-bold text-gray-900">Your Nightlife XP</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X size={24} className="text-gray-600" />
          </button>
        </div>

        <div className="overflow-y-auto flex-1 p-6">
          <XPProfile userId={userId} />
        </div>
      </div>
    </div>
  );
}
