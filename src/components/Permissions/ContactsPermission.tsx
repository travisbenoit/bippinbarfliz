import { useNavigate } from 'react-router';
import { UserPlus, ArrowRight } from 'lucide-react';

export default function ContactsPermission() {
  const navigate = useNavigate();

  const handleAllow = () => {
    localStorage.setItem('contacts_permission', 'granted');
    navigate('/notifications-permission');
  };

  const handleSkip = () => {
    localStorage.setItem('contacts_permission', 'skipped');
    navigate('/notifications-permission');
  };

  return (
    <div className="min-h-screen bg-white flex flex-col px-6 py-8">
      <div className="text-sm text-gray-600 mb-8">
        9:27
      </div>

      <div className="flex-1 flex flex-col justify-between max-w-md mx-auto w-full">
        <div className="flex-1 flex flex-col items-center justify-center space-y-8">
          <div className="relative w-64 h-64 flex items-center justify-center">
            <div className="absolute inset-0 bg-gradient-to-br from-orange-50 via-pink-50 to-purple-50 rounded-3xl opacity-50"></div>
            <div className="relative bg-gradient-to-br from-orange-100 to-pink-100 rounded-3xl p-8 shadow-xl">
              <div className="bg-white rounded-2xl p-8 shadow-lg relative">
                <div className="absolute -left-2 top-6 w-4 h-8 bg-orange-300 rounded-r-lg"></div>
                <div className="absolute -left-2 top-16 w-4 h-8 bg-orange-300 rounded-r-lg"></div>
                <div className="absolute -left-2 top-26 w-4 h-8 bg-orange-300 rounded-r-lg"></div>
                <div className="absolute -left-2 top-36 w-4 h-8 bg-orange-300 rounded-r-lg"></div>
                <div className="absolute bottom-4 left-1/2 -translate-x-1/2 w-12 h-3 bg-orange-400 rounded-t-lg"></div>

                <div className="w-20 h-20 bg-gradient-to-br from-purple-300 to-purple-400 rounded-full mx-auto mb-2 flex items-center justify-center">
                  <div className="w-12 h-12 bg-gradient-to-br from-gray-700 to-gray-800 rounded-t-full"></div>
                </div>
                <div className="w-16 h-8 bg-gradient-to-br from-purple-300 to-purple-400 rounded-b-2xl mx-auto"></div>
              </div>
            </div>
          </div>

          <div className="text-center space-y-4">
            <h1 className="text-3xl font-bold text-gray-900">
              Find Friends on<br />Barfliz
            </h1>
            <p className="text-gray-600 text-base max-w-sm mx-auto">
              Allow Barfliz to access your contacts so we can suggest friends who are already on the app.
            </p>
          </div>
        </div>

        <div className="space-y-4 pb-8">
          <button
            onClick={handleAllow}
            className="w-full bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg flex items-center justify-center gap-2 hover:bg-[#C2185B] transition-colors shadow-lg"
          >
            Allow access
            <ArrowRight size={24} />
          </button>

          <button
            onClick={handleSkip}
            className="w-full text-gray-600 py-2 font-medium"
          >
            Skip for now
          </button>

          <div className="h-1 w-32 bg-gray-900 rounded-full mx-auto" />
        </div>
      </div>
    </div>
  );
}
