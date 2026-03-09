import { useState, FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';

export default function NameSetup() {
  const navigate = useNavigate();
  const [name, setName] = useState('');

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (name.trim()) {
      localStorage.setItem('pendingUserName', name);
      navigate('/location-permission');
    }
  };

  return (
    <div className="min-h-screen bg-white flex flex-col px-6 py-8">
      <div className="text-sm text-gray-600 mb-8">
        9:27
      </div>

      <div className="flex-1 flex flex-col justify-between max-w-md mx-auto w-full">
        <div className="space-y-8 pt-8">
          <div className="text-center space-y-2">
            <h1 className="text-3xl font-bold text-gray-900">
              Let's set up your profile
            </h1>
            <h2 className="text-3xl font-bold text-gray-900">
              What's your name?
            </h2>
            <p className="text-gray-600 text-sm pt-4">
              Enter your name this will be shown to other person in the app
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <input
              type="text"
              placeholder="Enter your name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              className="w-full px-6 py-4 rounded-full border-2 border-gray-200 focus:border-[#E91E63] focus:outline-none bg-white text-center"
            />
          </form>
        </div>

        <div className="space-y-6 pb-8">
          <button
            onClick={handleSubmit}
            disabled={!name.trim()}
            className="w-full bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg flex items-center justify-center gap-2 hover:bg-[#C2185B] transition-colors shadow-lg disabled:opacity-30 disabled:bg-gray-300"
          >
            Get Started
            <ArrowRight size={24} />
          </button>

          <div className="h-1 w-32 bg-gray-900 rounded-full mx-auto" />
        </div>
      </div>
    </div>
  );
}
