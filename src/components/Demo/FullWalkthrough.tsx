import { useState } from 'react';
import { ChevronLeft, ChevronRight, Phone, Lock, User, Cake, MapPin, Bell, Heart, Zap } from 'lucide-react';

interface WalkthroughScreen {
  id: string;
  title: string;
  description: string;
}

const WALKTHROUGH_SCREENS: WalkthroughScreen[] = [
  { id: 'onboarding-1', title: 'Onboarding - Slide 1', description: 'Find your Drinking Partner' },
  { id: 'onboarding-2', title: 'Onboarding - Slide 2', description: 'Real Drinks with Real Friends' },
  { id: 'onboarding-3', title: 'Onboarding - Slide 3', description: 'Best Social App To Drink With Friends' },
  { id: 'signup', title: 'Phone Registration', description: 'Enter your phone number' },
  { id: 'verify', title: 'Verify Phone', description: 'Enter OTP code' },
  { id: 'name', title: 'Name Setup', description: 'What\'s your name?' },
  { id: 'birthday', title: 'Birthday Setup', description: 'When were you born?' },
  { id: 'location-perm', title: 'Location Permission', description: 'Allow location access' },
  { id: 'contacts-perm', title: 'Contacts Permission', description: 'Allow contacts access' },
  { id: 'notify-perm', title: 'Notifications Permission', description: 'Allow notifications' },
  { id: 'profile-1', title: 'Profile Setup - Step 1', description: 'Personal Information' },
  { id: 'profile-2', title: 'Profile Setup - Step 2', description: 'About You' },
  { id: 'profile-3', title: 'Profile Setup - Step 3', description: 'Your Vibes' },
  { id: 'profile-4', title: 'Profile Setup - Step 4', description: 'Favorite Drinks' },
  { id: 'main-dashboard', title: 'Main Experience', description: 'Dashboard & Discovery' },
];

const DARWIN_BARS = [
  { name: 'Mitchell Street Bar', rating: 4.6, distance: '0.8 km', status: 'Open Now', emoji: '🍻' },
  { name: 'Sky Bar Darwin', rating: 4.5, distance: '1.1 km', status: 'Open Now', emoji: '🌆' },
  { name: 'The Deck Bar', rating: 4.3, distance: '0.5 km', status: 'Open Now', emoji: '🍻' },
  { name: 'Monsoons Wine Bar', rating: 4.7, distance: '1.4 km', status: 'Closed', emoji: '🍸' },
  { name: 'Shenanigans Irish Bar', rating: 4.4, distance: '0.6 km', status: 'Open Now', emoji: '🍻' },
];

const SAMPLE_USERS = [
  { name: 'Emma Wilson', vibe: 'Chill Night', status: '🟡' },
  { name: 'Mia Rodriguez', vibe: 'Rooftop', status: '🟡' },
  { name: 'Ashley Brown', vibe: 'Happy Hour', status: '🟢' },
  { name: 'David Kim', vibe: 'Happy Hour', status: '🟢' },
];

const VIBES = ['Happy Hour', 'Big Game', 'Chill Night', 'Dance Party', 'Live Music', 'Karaoke'];
const DRINKS = ['Whiskey', 'Craft Beer', 'Wine', 'Vodka', 'Margarita', 'Gin'];

function OnboardingSlide1() {
  return (
    <div className="flex-1 bg-gradient-to-br from-emerald-500 to-teal-600 flex flex-col items-center justify-center text-white p-6 text-center">
      <div className="text-6xl mb-6">🍹</div>
      <h1 className="text-3xl font-bold mb-4">Find your Drinking Partner</h1>
      <p className="text-xl opacity-90 mb-8">Discover people nearby who share your vibe and want to hang out.</p>
      <div className="space-y-3 text-left">
        <div className="flex items-center gap-3">
          <Zap className="w-5 h-5" />
          <span>Real-time location sharing</span>
        </div>
        <div className="flex items-center gap-3">
          <Heart className="w-5 h-5" />
          <span>Vibe-based matching</span>
        </div>
      </div>
    </div>
  );
}

function OnboardingSlide2() {
  return (
    <div className="flex-1 bg-gradient-to-br from-blue-500 to-cyan-600 flex flex-col items-center justify-center text-white p-6 text-center">
      <div className="text-6xl mb-6">🎉</div>
      <h1 className="text-3xl font-bold mb-4">Real Drinks with Real Friends</h1>
      <p className="text-xl opacity-90 mb-8">Connect instantly with your friends and meet new people out at bars tonight.</p>
      <div className="space-y-3 text-left">
        <div className="flex items-center gap-3">
          <MapPin className="w-5 h-5" />
          <span>See who's out now</span>
        </div>
        <div className="flex items-center gap-3">
          <Zap className="w-5 h-5" />
          <span>Join spontaneous swarms</span>
        </div>
      </div>
    </div>
  );
}

function OnboardingSlide3() {
  return (
    <div className="flex-1 bg-gradient-to-br from-purple-500 to-pink-600 flex flex-col items-center justify-center text-white p-6 text-center">
      <div className="text-6xl mb-6">👥</div>
      <h1 className="text-3xl font-bold mb-4">Best Social App To Drink With Friends</h1>
      <p className="text-xl opacity-90 mb-8">Your night, your crew, your rules. Swarm together and make memories.</p>
      <button className="bg-white text-purple-600 px-8 py-3 rounded-lg font-bold mt-8 hover:bg-gray-100 transition-colors">
        Get Started
      </button>
    </div>
  );
}

function SignUpScreen() {
  return (
    <div className="flex-1 bg-white flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md">
        <h1 className="text-3xl font-bold mb-2">Phone Registration</h1>
        <p className="text-gray-600 mb-8">Let's get you set up. We'll text you a verification code.</p>

        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">Phone Number</label>
          <div className="flex gap-2">
            <select className="w-20 px-3 py-3 border border-gray-300 rounded-lg">
              <option>+61</option>
            </select>
            <input
              type="tel"
              placeholder="2 7345 6789"
              className="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
          </div>
        </div>

        <div className="bg-emerald-50 border border-emerald-200 rounded-lg p-4 mb-6">
          <p className="text-sm text-emerald-800">Australia detected • 18+ drinking age</p>
        </div>

        <button className="w-full bg-emerald-500 text-white py-3 rounded-lg font-bold hover:bg-emerald-600 transition-colors flex items-center justify-center gap-2">
          <Phone className="w-5 h-5" />
          Send Code
        </button>
      </div>
    </div>
  );
}

function VerifyScreen() {
  return (
    <div className="flex-1 bg-white flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md">
        <h1 className="text-3xl font-bold mb-2">Verify Your Phone</h1>
        <p className="text-gray-600 mb-8">Enter the 4-digit code we sent to +61 2 7345 6789</p>

        <div className="flex gap-3 mb-8 justify-center">
          {[1, 2, 3, 4].map((i) => (
            <input
              key={i}
              type="text"
              maxLength={1}
              className="w-16 h-16 text-center text-2xl font-bold border-2 border-gray-300 rounded-lg focus:outline-none focus:border-emerald-500"
            />
          ))}
        </div>

        <p className="text-center text-gray-600 mb-6">
          Didn't get a code? <span className="text-emerald-500 font-medium cursor-pointer">Resend (13s)</span>
        </p>

        <button className="w-full bg-emerald-500 text-white py-3 rounded-lg font-bold hover:bg-emerald-600 transition-colors flex items-center justify-center gap-2">
          <Lock className="w-5 h-5" />
          Verify
        </button>
      </div>
    </div>
  );
}

function NameSetupScreen() {
  return (
    <div className="flex-1 bg-white flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md">
        <h1 className="text-3xl font-bold mb-2">What's Your Name?</h1>
        <p className="text-gray-600 mb-8">This is how people will recognize you in Swarm</p>

        <input
          type="text"
          placeholder="Enter your full name"
          defaultValue="Alex"
          className="w-full px-4 py-3 border-2 border-gray-300 rounded-lg focus:outline-none focus:border-emerald-500 mb-6 text-lg"
        />

        <button className="w-full bg-emerald-500 text-white py-3 rounded-lg font-bold hover:bg-emerald-600 transition-colors flex items-center justify-center gap-2">
          <User className="w-5 h-5" />
          Continue
        </button>
      </div>
    </div>
  );
}

function BirthdaySetupScreen() {
  return (
    <div className="flex-1 bg-white flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md">
        <h1 className="text-3xl font-bold mb-2">When Were You Born?</h1>
        <p className="text-gray-600 mb-8">You must be 18+ to use Swarm in Australia</p>

        <div className="grid grid-cols-3 gap-3 mb-6">
          <input
            type="text"
            placeholder="DD"
            maxLength={2}
            defaultValue="15"
            className="px-4 py-3 border-2 border-gray-300 rounded-lg focus:outline-none focus:border-emerald-500 text-center font-medium"
          />
          <input
            type="text"
            placeholder="MM"
            maxLength={2}
            defaultValue="08"
            className="px-4 py-3 border-2 border-gray-300 rounded-lg focus:outline-none focus:border-emerald-500 text-center font-medium"
          />
          <input
            type="text"
            placeholder="YYYY"
            maxLength={4}
            defaultValue="1998"
            className="px-4 py-3 border-2 border-gray-300 rounded-lg focus:outline-none focus:border-emerald-500 text-center font-medium"
          />
        </div>

        <button className="w-full bg-emerald-500 text-white py-3 rounded-lg font-bold hover:bg-emerald-600 transition-colors flex items-center justify-center gap-2">
          <Cake className="w-5 h-5" />
          Continue
        </button>
      </div>
    </div>
  );
}

function PermissionScreen({ icon: Icon, title, description }: { icon: any; title: string; description: string }) {
  return (
    <div className="flex-1 bg-white flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md text-center">
        <div className="w-16 h-16 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-6">
          <Icon className="w-8 h-8 text-emerald-600" />
        </div>
        <h1 className="text-3xl font-bold mb-2">{title}</h1>
        <p className="text-gray-600 mb-8">{description}</p>

        <div className="space-y-3">
          <button className="w-full bg-emerald-500 text-white py-3 rounded-lg font-bold hover:bg-emerald-600 transition-colors">
            Allow Access
          </button>
          <button className="w-full bg-gray-100 text-gray-700 py-3 rounded-lg font-bold hover:bg-gray-200 transition-colors">
            Skip For Now
          </button>
        </div>
      </div>
    </div>
  );
}

function ProfileSetupStep1() {
  return (
    <div className="flex-1 bg-white flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md">
        <h1 className="text-3xl font-bold mb-2">Profile Setup • Step 1/4</h1>
        <p className="text-gray-600 mb-8">Personal Information</p>

        <div className="space-y-4 mb-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Full Name</label>
            <input type="text" defaultValue="Alex" className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Date of Birth</label>
            <input type="date" defaultValue="1998-08-15" className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </div>
          <div className="flex items-center gap-2">
            <input type="checkbox" defaultChecked className="w-4 h-4 text-emerald-500" />
            <label className="text-sm text-gray-700">I confirm I'm 18+ and can legally drink</label>
          </div>
        </div>

        <button className="w-full bg-emerald-500 text-white py-3 rounded-lg font-bold hover:bg-emerald-600 transition-colors">
          Next
        </button>
      </div>
    </div>
  );
}

function ProfileSetupStep2() {
  return (
    <div className="flex-1 bg-white flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md">
        <h1 className="text-3xl font-bold mb-2">Profile Setup • Step 2/4</h1>
        <p className="text-gray-600 mb-8">About You</p>

        <div className="space-y-4 mb-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Bio</label>
            <textarea
              defaultValue="Weekend vibes and good times. Love exploring new bars!"
              rows={3}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Home City</label>
            <input type="text" defaultValue="Darwin, NT" className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </div>
        </div>

        <button className="w-full bg-emerald-500 text-white py-3 rounded-lg font-bold hover:bg-emerald-600 transition-colors">
          Next
        </button>
      </div>
    </div>
  );
}

function ProfileSetupStep3() {
  return (
    <div className="flex-1 bg-white flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md">
        <h1 className="text-3xl font-bold mb-2">Profile Setup • Step 3/4</h1>
        <p className="text-gray-600 mb-8">Select Your Vibes (choose up to 5)</p>

        <div className="grid grid-cols-2 gap-2 mb-6">
          {VIBES.map((vibe) => (
            <button
              key={vibe}
              className="px-3 py-2 bg-emerald-100 text-emerald-700 rounded-lg font-medium text-sm hover:bg-emerald-200 transition-colors"
            >
              {vibe}
            </button>
          ))}
        </div>

        <button className="w-full bg-emerald-500 text-white py-3 rounded-lg font-bold hover:bg-emerald-600 transition-colors">
          Next
        </button>
      </div>
    </div>
  );
}

function ProfileSetupStep4() {
  return (
    <div className="flex-1 bg-white flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md">
        <h1 className="text-3xl font-bold mb-2">Profile Setup • Step 4/4</h1>
        <p className="text-gray-600 mb-8">Favorite Drinks (choose up to 5)</p>

        <div className="grid grid-cols-2 gap-2 mb-6">
          {DRINKS.map((drink) => (
            <button
              key={drink}
              className="px-3 py-2 bg-emerald-100 text-emerald-700 rounded-lg font-medium text-sm hover:bg-emerald-200 transition-colors"
            >
              {drink}
            </button>
          ))}
        </div>

        <button className="w-full bg-emerald-500 text-white py-3 rounded-lg font-bold hover:bg-emerald-600 transition-colors">
          Complete Profile
        </button>
      </div>
    </div>
  );
}

function MainDashboard() {
  return (
    <div className="flex-1 bg-white overflow-y-auto flex flex-col">
      <div className="p-6 space-y-6">
        <div>
          <h1 className="text-3xl font-bold mb-1">Main Experience</h1>
          <p className="text-gray-600">Welcome to your dashboard</p>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="bg-emerald-50 p-4 rounded-lg">
            <p className="text-2xl font-bold text-emerald-600">6</p>
            <p className="text-sm text-gray-600">Your Vibes</p>
          </div>
          <div className="bg-blue-50 p-4 rounded-lg">
            <p className="text-2xl font-bold text-blue-600">5</p>
            <p className="text-sm text-gray-600">Favorite Drinks</p>
          </div>
        </div>

        <div>
          <h3 className="font-bold mb-3">People Out Now</h3>
          <div className="space-y-2">
            {SAMPLE_USERS.map((user) => (
              <div key={user.name} className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <span className="text-2xl">{user.status}</span>
                <div className="flex-1">
                  <p className="font-medium text-gray-900">{user.name}</p>
                  <p className="text-sm text-gray-500">{user.vibe}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div>
          <h3 className="font-bold mb-3">Venues in Darwin</h3>
          <div className="space-y-2">
            {DARWIN_BARS.map((bar) => (
              <div key={bar.name} className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <span className="text-2xl">{bar.emoji}</span>
                <div className="flex-1">
                  <p className="font-medium text-gray-900">{bar.name}</p>
                  <p className="text-xs text-gray-500">{bar.distance} • {bar.status}</p>
                </div>
                <p className="font-bold text-amber-600">{bar.rating}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function renderScreen(screenId: string) {
  switch (screenId) {
    case 'onboarding-1':
      return <OnboardingSlide1 />;
    case 'onboarding-2':
      return <OnboardingSlide2 />;
    case 'onboarding-3':
      return <OnboardingSlide3 />;
    case 'signup':
      return <SignUpScreen />;
    case 'verify':
      return <VerifyScreen />;
    case 'name':
      return <NameSetupScreen />;
    case 'birthday':
      return <BirthdaySetupScreen />;
    case 'location-perm':
      return <PermissionScreen icon={MapPin} title="Share Location" description="We'll use your location to find people and venues nearby." />;
    case 'contacts-perm':
      return <PermissionScreen icon={User} title="Access Contacts" description="Help you find friends already using Swarm." />;
    case 'notify-perm':
      return <PermissionScreen icon={Bell} title="Enable Notifications" description="Get notified when friends are nearby." />;
    case 'profile-1':
      return <ProfileSetupStep1 />;
    case 'profile-2':
      return <ProfileSetupStep2 />;
    case 'profile-3':
      return <ProfileSetupStep3 />;
    case 'profile-4':
      return <ProfileSetupStep4 />;
    case 'main-dashboard':
      return <MainDashboard />;
    default:
      return null;
  }
}

export default function FullWalkthrough() {
  const [currentStep, setCurrentStep] = useState(0);
  const currentScreen = WALKTHROUGH_SCREENS[currentStep];

  const handleNext = () => {
    if (currentStep < WALKTHROUGH_SCREENS.length - 1) {
      setCurrentStep(currentStep + 1);
    }
  };

  const handlePrev = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const handleJumpTo = (index: number) => {
    setCurrentStep(index);
  };

  return (
    <div className="h-screen flex flex-col bg-gray-50">
      <div className="flex-1 flex overflow-hidden">
        <div className="flex-1 flex flex-col items-center justify-center px-12 py-8">
          <div className="w-full max-w-sm h-full flex flex-col bg-black rounded-3xl shadow-2xl overflow-hidden border-8 border-black">
            <div className="flex-1 bg-white overflow-hidden flex flex-col">
              {renderScreen(currentScreen.id)}
            </div>
          </div>
        </div>

        <div className="w-72 flex flex-col bg-white border-l border-gray-200 overflow-hidden">
          <div className="p-4 border-b border-gray-200">
            <h2 className="font-bold text-gray-900 mb-1">{currentScreen.title}</h2>
            <p className="text-sm text-gray-600">{currentScreen.description}</p>
            <p className="text-xs text-gray-500 mt-2">Step {currentStep + 1} of {WALKTHROUGH_SCREENS.length}</p>
          </div>

          <div className="flex-1 overflow-y-auto p-4 space-y-2">
            {WALKTHROUGH_SCREENS.map((screen, index) => (
              <button
                key={screen.id}
                onClick={() => handleJumpTo(index)}
                className={`w-full text-left px-3 py-2 rounded-lg text-sm transition-colors ${
                  index === currentStep
                    ? 'bg-emerald-100 text-emerald-900 font-medium'
                    : 'hover:bg-gray-100 text-gray-700'
                }`}
              >
                <div className="font-medium">{screen.title}</div>
                <div className="text-xs opacity-70">{screen.description}</div>
              </button>
            ))}
          </div>

          <div className="p-4 border-t border-gray-200 space-y-2">
            <div className="flex gap-2">
              <button
                onClick={handlePrev}
                disabled={currentStep === 0}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg font-medium disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-200 transition-colors"
              >
                <ChevronLeft className="w-4 h-4" />
                Back
              </button>
              <button
                onClick={handleNext}
                disabled={currentStep === WALKTHROUGH_SCREENS.length - 1}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-emerald-500 text-white rounded-lg font-medium disabled:opacity-50 disabled:cursor-not-allowed hover:bg-emerald-600 transition-colors"
              >
                Next
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
