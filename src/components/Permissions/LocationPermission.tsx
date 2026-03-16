import { useState } from 'react';
import { useNavigate } from 'react-router';
import { MapPin, ArrowRight } from 'lucide-react';

export default function LocationPermission() {
  const navigate = useNavigate();
  const [requesting, setRequesting] = useState(false);

  const requestLocationPermission = async () => {
    setRequesting(true);
    try {
      await new Promise<void>((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(
          () => resolve(),
          () => reject(),
          { timeout: 8000 }
        );
      });
      localStorage.setItem('location_permission', 'granted');
    } catch {
      localStorage.setItem('location_permission', 'skipped');
    } finally {
      setRequesting(false);
      navigate('/contacts-permission');
    }
  };

  const handleSkip = () => {
    localStorage.setItem('location_permission', 'skipped');
    navigate('/contacts-permission');
  };

  return (
    <div className="min-h-screen bg-white flex flex-col px-6 py-8">
      <div className="text-sm text-gray-600 mb-8">
        9:27
      </div>

      <div className="flex-1 flex flex-col justify-between max-w-md mx-auto w-full">
        <div className="flex-1 flex flex-col items-center justify-center space-y-8">
          <div className="relative w-64 h-64 flex items-center justify-center">
            <div className="absolute inset-0 bg-gradient-to-br from-pink-100 via-purple-50 to-blue-100 rounded-3xl transform rotate-6 opacity-50"></div>
            <div className="relative bg-white rounded-3xl shadow-xl p-12 border-4 border-indigo-200 transform -rotate-3">
              <div className="absolute top-4 left-4 w-12 h-12 bg-gradient-to-br from-pink-200 to-pink-300 rounded-lg"></div>
              <div className="absolute bottom-6 left-6 w-16 h-16 bg-gradient-to-br from-cyan-200 to-cyan-300 rounded-xl"></div>
              <div className="absolute top-8 right-4 flex flex-col gap-1">
                <div className="w-8 h-2 bg-indigo-400 rounded"></div>
                <div className="w-8 h-2 bg-indigo-400 rounded"></div>
                <div className="w-6 h-6 bg-indigo-500 rounded"></div>
              </div>
              <MapPin size={48} className="text-indigo-600 relative z-10" />
            </div>
          </div>

          <div className="text-center space-y-4">
            <h1 className="text-3xl font-bold text-gray-900">
              Barfliz Works Best<br />when you allow location
            </h1>
            <p className="text-gray-600 text-base max-w-sm mx-auto">
              Click on allow to give access to location
            </p>
          </div>
        </div>

        <div className="space-y-4 pb-8">
          <button
            onClick={requestLocationPermission}
            disabled={requesting}
            className="w-full bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg flex items-center justify-center gap-2 hover:bg-[#C2185B] transition-colors shadow-lg disabled:opacity-50"
          >
            {requesting ? 'Requesting...' : 'Allow access'}
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
