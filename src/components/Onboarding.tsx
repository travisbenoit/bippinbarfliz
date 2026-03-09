import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, Sparkles, Play } from 'lucide-react';

const slides = [
  {
    title: 'Find your\nDrinking Partner !',
    subtitle: 'Bored drinking alone?\nFind a new drinking partner 🍻',
    type: 'bees',
  },
  {
    title: 'Real Drinks with\nReal Friends !',
    subtitle: 'Enjoy a drink with friends\nnew or old🔥',
    type: 'bottle',
  },
  {
    title: 'Best Social App To\nDrink With Friends !',
    subtitle: 'Find people with the same\ninterests as you 💕',
    type: 'social',
  },
];

const BeesIllustration = () => (
  <div className="relative w-64 h-64 flex items-center justify-center">
    <div className="absolute top-8 left-12 animate-bounce" style={{ animationDuration: '3s' }}>
      <div className="relative">
        <div className="text-7xl">🐝</div>
        <div className="absolute -top-2 -right-2 text-2xl">💙</div>
      </div>
    </div>
    <div className="absolute bottom-8 right-12 animate-bounce" style={{ animationDuration: '3.5s', animationDelay: '0.5s' }}>
      <div className="relative">
        <div className="text-7xl">🐝</div>
        <div className="absolute -top-2 -right-2 text-2xl">💙</div>
      </div>
    </div>
  </div>
);

const BottleIllustration = () => (
  <div className="relative w-64 h-64 flex items-center justify-center">
    <div className="text-9xl animate-bounce" style={{ animationDuration: '2s' }}>
      🍺
    </div>
  </div>
);

const SocialIllustration = () => (
  <div className="relative w-64 h-64 flex items-center justify-center">
    <div className="absolute inset-0 flex items-center justify-center">
      {[...Array(4)].map((_, i) => (
        <div
          key={i}
          className="absolute"
          style={{
            transform: `rotate(${i * 90}deg) translateY(-80px)`,
          }}
        >
          <div
            className="w-16 h-16 rounded-full flex items-center justify-center text-3xl shadow-lg"
            style={{
              transform: 'rotate(0deg)',
              background: ['linear-gradient(135deg, #E91E63 0%, #FF4081 100%)', 'linear-gradient(135deg, #2196F3 0%, #64B5F6 100%)', 'linear-gradient(135deg, #FF9800 0%, #FFB74D 100%)', 'linear-gradient(135deg, #9C27B0 0%, #BA68C8 100%)'][i]
            }}
          >
            {['😎', '🤓', '😊', '🥳'][i]}
          </div>
        </div>
      ))}
      <div className="w-24 h-24 rounded-full bg-gradient-to-br from-pink-400 to-pink-600 flex items-center justify-center text-5xl shadow-xl z-10">
        😎
      </div>
      <svg className="absolute inset-0 w-full h-full" style={{ transform: 'rotate(-15deg)' }}>
        <circle cx="50%" cy="50%" r="90" fill="none" stroke="#E91E63" strokeWidth="1" opacity="0.2" />
        <circle cx="50%" cy="50%" r="70" fill="none" stroke="#E91E63" strokeWidth="1" opacity="0.2" />
        <circle cx="50%" cy="50%" r="110" fill="none" stroke="#E91E63" strokeWidth="1" opacity="0.2" />
      </svg>
    </div>
  </div>
);

export default function Onboarding() {
  const navigate = useNavigate();
  const [currentSlide, setCurrentSlide] = useState(0);

  const nextSlide = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(currentSlide + 1);
    } else {
      navigate('/signup');
    }
  };

  const renderIllustration = () => {
    switch (slides[currentSlide].type) {
      case 'bees':
        return <BeesIllustration />;
      case 'bottle':
        return <BottleIllustration />;
      case 'social':
        return <SocialIllustration />;
      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-[#FFF5F0] flex flex-col items-center justify-between px-6 py-8 relative overflow-hidden">
      <div className="absolute top-8 left-6 text-gray-400 opacity-50">
        <Sparkles size={32} />
      </div>
      <div className="absolute top-32 right-8 text-gray-300 opacity-40">
        <Sparkles size={24} />
      </div>
      <div className="absolute bottom-64 left-4 text-gray-300 opacity-30">
        <Sparkles size={28} />
      </div>
      <div className="absolute bottom-96 right-6 text-gray-400 opacity-40">
        <Sparkles size={20} />
      </div>

      <div className="text-sm text-gray-600 self-start">
        9:27
      </div>

      <div className="flex-1 flex items-center justify-center">
        {renderIllustration()}
      </div>

      <div className="w-full max-w-md space-y-8">
        <div className="text-center space-y-4">
          <h1 className="text-3xl font-bold text-gray-900 leading-tight whitespace-pre-line">
            {slides[currentSlide].title}
          </h1>
          <p className="text-gray-600 text-base whitespace-pre-line">
            {slides[currentSlide].subtitle}
          </p>
        </div>

        <div className="flex justify-center gap-2">
          {slides.map((_, index) => (
            <div
              key={index}
              className={`h-1 rounded-full transition-all ${
                index === currentSlide
                  ? 'w-8 bg-[#E91E63]'
                  : 'w-1 bg-gray-300'
              }`}
            />
          ))}
        </div>

        <div className="space-y-4">
          <button
            onClick={nextSlide}
            className="w-full bg-[#E91E63] text-white py-4 rounded-full font-semibold text-lg flex items-center justify-center gap-2 hover:bg-[#C2185B] transition-colors shadow-lg"
          >
            Get Started
            <ArrowRight size={24} />
          </button>

          <button
            onClick={() => navigate('/demo')}
            className="w-full bg-gradient-to-r from-blue-500 to-purple-600 text-white py-4 rounded-full font-semibold text-lg flex items-center justify-center gap-2 hover:shadow-xl transition-all"
          >
            <Play size={20} />
            Watch Interactive Demo
          </button>

          <p className="text-center text-gray-600">
            Already have an account?{' '}
            <button
              onClick={() => navigate('/signin')}
              className="text-[#E91E63] font-semibold"
            >
              Sign in
            </button>
          </p>
        </div>
      </div>

      <div className="h-1 w-32 bg-gray-900 rounded-full mt-4" />
    </div>
  );
}
