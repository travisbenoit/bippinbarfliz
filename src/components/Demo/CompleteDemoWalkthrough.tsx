import { useState } from 'react';
import {
  User, MapPin, Users, MessageSquare, Calendar, Gift,
  CreditCard, Settings, ChevronRight, X, Play, Pause,
  Phone, Camera, Bell, Navigation, Wine, Clock,
  Heart, Music, Share2, TrendingUp, Shield
} from 'lucide-react';

interface DemoStep {
  id: number;
  title: string;
  description: string;
  screen: 'auth' | 'onboarding' | 'permissions' | 'home' | 'map' | 'friends' | 'messages' | 'swarms' | 'profile' | 'payments' | 'gifts' | 'tonight';
  features: string[];
  mockImage?: string;
}

const demoSteps: DemoStep[] = [
  {
    id: 1,
    title: 'Sign Up & Authentication',
    description: 'Users start by creating an account with phone verification for security',
    screen: 'auth',
    features: [
      'Phone number verification via Twilio SMS',
      'Secure OTP code validation',
      'Age gate (21+ verification)',
      'Terms of service acceptance'
    ]
  },
  {
    id: 2,
    title: 'Profile Setup',
    description: 'New users create their profile with personal details',
    screen: 'onboarding',
    features: [
      'Name and birthday setup',
      'Profile photo upload',
      'Drink preferences selection',
      'Vibe tags (e.g., "Dance Floor", "Dive Bars", "Rooftop")',
      'Home city selection'
    ]
  },
  {
    id: 3,
    title: 'Permissions Request',
    description: 'Essential permissions for core features',
    screen: 'permissions',
    features: [
      'Location services (for nearby venues)',
      'Push notifications (for messages & alerts)',
      'Contacts access (for finding friends)',
      'Radar geofencing setup'
    ]
  },
  {
    id: 4,
    title: 'Home Dashboard',
    description: 'Main hub showing tonight status and friend activity',
    screen: 'home',
    features: [
      'Set "Tonight Status" (Staying In / Going Out Soon / Out Now)',
      'See friends who are out tonight',
      'Tonight Feed with friend locations',
      'DD Mode toggle (Designated Driver)',
      'Weather card with conditions',
      'Quick actions: Create Swarm, Check In, Message'
    ]
  },
  {
    id: 5,
    title: 'Interactive Map',
    description: 'Discover venues and see where friends are',
    screen: 'map',
    features: [
      '682+ venues (Darwin, South Florida)',
      'Real-time friend locations on map',
      'Venue filters (Bars, Clubs, Lounges, Breweries)',
      'Search venues by name',
      'Radius control (adjust search area)',
      'Tap venue for details: hours, address, crowd size',
      'Google Places integration for photos & ratings'
    ]
  },
  {
    id: 6,
    title: 'Tonight Status & Social Feed',
    description: 'See who is out and where they are',
    screen: 'tonight',
    features: [
      'Friends marked "Out Now" with live locations',
      'Friends "Going Out Soon" list',
      'Current venue display for each friend',
      'DD badges for designated drivers',
      'Vibe tags visible',
      'One-tap to message or view profile'
    ]
  },
  {
    id: 7,
    title: 'Friends & Connections',
    description: 'Build your social network',
    screen: 'friends',
    features: [
      'Send/accept friend requests',
      'Search users by name or username',
      'Import contacts to find friends',
      'View friend profiles',
      'Block/unblock users',
      'Friend activity history'
    ]
  },
  {
    id: 8,
    title: 'Messaging',
    description: 'Direct messaging with friends',
    screen: 'messages',
    features: [
      'One-on-one conversations',
      'Real-time message delivery',
      'Read receipts',
      'Share location in messages',
      'Share music (Spotify integration)',
      'Send virtual gifts & drinks',
      'Emoji reactions to messages'
    ]
  },
  {
    id: 9,
    title: 'Swarms (Group Plans)',
    description: 'Organize group outings',
    screen: 'swarms',
    features: [
      'Create swarm with name, date, time',
      'Invite multiple friends',
      'Set meeting venue',
      'RSVP tracking (Going, Maybe, Invited)',
      'Group chat in swarm',
      'Share swarm details',
      'Date filter for upcoming swarms'
    ]
  },
  {
    id: 10,
    title: 'Payments & Splitting',
    description: 'Send money and split bills',
    screen: 'payments',
    features: [
      'Link Venmo/PayPal/Cash App',
      'Send payment to friends',
      'Request payment',
      'Group bill splitting',
      'Payment history',
      'QR code for receiving payments'
    ]
  },
  {
    id: 11,
    title: 'Virtual Gifts',
    description: 'Send fun virtual items to friends',
    screen: 'gifts',
    features: [
      'Gift catalog: drinks, shots, champagne',
      'Send gifts with messages',
      'Gift inbox to receive items',
      'Gift history tracking',
      'Fun animations on receive'
    ]
  },
  {
    id: 12,
    title: 'Profile & Settings',
    description: 'Manage account and preferences',
    screen: 'profile',
    features: [
      'Edit profile details',
      'Change avatar',
      'Update drink preferences',
      'Privacy settings (ghost mode)',
      'Notification preferences',
      'Payment provider settings',
      'Safety features (safe arrival, emergency contacts)',
      'Language selection (i18n ready)',
      'Help center & support'
    ]
  }
];

export function CompleteDemoWalkthrough() {
  const [currentStep, setCurrentStep] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [showDemo, setShowDemo] = useState(true);

  const currentDemo = demoSteps[currentStep];

  const nextStep = () => {
    if (currentStep < demoSteps.length - 1) {
      setCurrentStep(currentStep + 1);
    } else {
      setCurrentStep(0);
    }
  };

  const prevStep = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
    }
  };

  const getScreenPreview = (screen: DemoStep['screen']) => {
    switch (screen) {
      case 'auth':
        return (
          <div className="bg-gradient-to-br from-pink-50 to-rose-50 p-8 rounded-2xl">
            <div className="max-w-sm mx-auto bg-white rounded-3xl shadow-2xl p-8">
              <div className="text-center mb-8">
                <div className="w-20 h-20 bg-gradient-to-br from-rose-500 to-pink-600 rounded-3xl mx-auto mb-4 flex items-center justify-center">
                  <Wine className="w-10 h-10 text-white" />
                </div>
                <h2 className="text-3xl font-bold text-gray-900 mb-2">Barfliz</h2>
                <p className="text-gray-500">Find your crew, explore the night</p>
              </div>
              <div className="space-y-4">
                <div className="relative">
                  <Phone className="absolute left-4 top-3.5 w-5 h-5 text-gray-400" />
                  <input
                    type="tel"
                    placeholder="+1 (555) 123-4567"
                    className="w-full pl-12 pr-4 py-3.5 border-2 border-gray-200 rounded-xl font-medium"
                    disabled
                  />
                </div>
                <button className="w-full bg-gradient-to-r from-rose-500 to-pink-600 text-white font-bold py-4 rounded-xl shadow-lg">
                  Send Verification Code
                </button>
                <p className="text-xs text-center text-gray-400">Must be 21+ to use Barfliz</p>
              </div>
            </div>
          </div>
        );

      case 'onboarding':
        return (
          <div className="bg-gradient-to-br from-blue-50 to-indigo-50 p-8 rounded-2xl">
            <div className="max-w-sm mx-auto bg-white rounded-3xl shadow-2xl p-8">
              <div className="text-center mb-6">
                <div className="relative w-24 h-24 mx-auto mb-4">
                  <div className="w-24 h-24 bg-gradient-to-br from-gray-200 to-gray-300 rounded-full flex items-center justify-center">
                    <Camera className="w-10 h-10 text-gray-500" />
                  </div>
                  <div className="absolute bottom-0 right-0 w-8 h-8 bg-rose-500 rounded-full flex items-center justify-center shadow-lg">
                    <span className="text-white text-xl">+</span>
                  </div>
                </div>
                <h3 className="text-2xl font-bold text-gray-900 mb-2">Create Your Profile</h3>
              </div>
              <div className="space-y-4">
                <input placeholder="Your name" className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl" disabled />
                <input type="date" className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl" disabled />
                <div className="grid grid-cols-3 gap-2">
                  <div className="px-3 py-2 bg-rose-100 text-rose-700 rounded-lg text-xs font-bold text-center">Dance Floor</div>
                  <div className="px-3 py-2 bg-gray-100 text-gray-600 rounded-lg text-xs font-bold text-center">Rooftop</div>
                  <div className="px-3 py-2 bg-gray-100 text-gray-600 rounded-lg text-xs font-bold text-center">Dive Bars</div>
                </div>
              </div>
            </div>
          </div>
        );

      case 'permissions':
        return (
          <div className="bg-gradient-to-br from-purple-50 to-pink-50 p-8 rounded-2xl">
            <div className="max-w-sm mx-auto bg-white rounded-3xl shadow-2xl p-8">
              <h3 className="text-2xl font-bold text-gray-900 mb-6 text-center">Enable Features</h3>
              <div className="space-y-4">
                {[
                  { icon: Navigation, title: 'Location', desc: 'Find venues nearby', color: 'blue' },
                  { icon: Bell, title: 'Notifications', desc: 'Get friend updates', color: 'rose' },
                  { icon: Users, title: 'Contacts', desc: 'Find your friends', color: 'green' }
                ].map((item, i) => (
                  <div key={i} className="flex items-center gap-4 p-4 border-2 border-gray-200 rounded-xl">
                    <div className={`w-12 h-12 bg-${item.color}-100 rounded-xl flex items-center justify-center`}>
                      <item.icon className={`w-6 h-6 text-${item.color}-600`} />
                    </div>
                    <div className="flex-1">
                      <p className="font-bold text-gray-900">{item.title}</p>
                      <p className="text-xs text-gray-500">{item.desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        );

      case 'home':
        return (
          <div className="bg-gray-50 p-8 rounded-2xl">
            <div className="max-w-sm mx-auto bg-white rounded-3xl shadow-2xl overflow-hidden">
              <div className="bg-gradient-to-r from-rose-500 to-pink-600 p-6 text-white">
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-2xl font-bold">Tonight</h2>
                  <div className="flex gap-2">
                    <Bell className="w-6 h-6" />
                    <Settings className="w-6 h-6" />
                  </div>
                </div>
                <div className="bg-white/20 backdrop-blur rounded-2xl p-4">
                  <p className="text-sm opacity-90 mb-2">What are you up to?</p>
                  <div className="flex gap-2">
                    <button className="flex-1 bg-white text-rose-600 font-bold py-2 rounded-xl text-sm">Out Now</button>
                    <button className="flex-1 bg-white/30 text-white font-bold py-2 rounded-xl text-sm">Going Soon</button>
                  </div>
                </div>
              </div>
              <div className="p-6 space-y-4">
                <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                  <div className="w-10 h-10 bg-gradient-to-br from-rose-400 to-pink-500 rounded-full" />
                  <div className="flex-1">
                    <p className="font-bold text-sm">Sarah Martinez</p>
                    <p className="text-xs text-emerald-600 font-semibold">Out now at The Deck</p>
                  </div>
                  <MessageSquare className="w-5 h-5 text-gray-400" />
                </div>
                <div className="grid grid-cols-3 gap-3">
                  <button className="p-4 bg-rose-50 rounded-xl text-center">
                    <Users className="w-6 h-6 text-rose-600 mx-auto mb-1" />
                    <p className="text-xs font-bold text-gray-700">Swarm</p>
                  </button>
                  <button className="p-4 bg-blue-50 rounded-xl text-center">
                    <MapPin className="w-6 h-6 text-blue-600 mx-auto mb-1" />
                    <p className="text-xs font-bold text-gray-700">Map</p>
                  </button>
                  <button className="p-4 bg-purple-50 rounded-xl text-center">
                    <Gift className="w-6 h-6 text-purple-600 mx-auto mb-1" />
                    <p className="text-xs font-bold text-gray-700">Gifts</p>
                  </button>
                </div>
              </div>
            </div>
          </div>
        );

      case 'map':
        return (
          <div className="bg-gradient-to-br from-blue-100 to-green-100 p-8 rounded-2xl">
            <div className="max-w-sm mx-auto bg-white rounded-3xl shadow-2xl overflow-hidden">
              <div className="relative h-96 bg-gradient-to-br from-blue-200 to-green-200 p-4">
                <div className="absolute top-4 left-4 right-4 flex gap-2">
                  <input
                    placeholder="Search venues..."
                    className="flex-1 px-4 py-2.5 rounded-xl shadow-lg border-0 font-medium"
                    disabled
                  />
                  <button className="w-12 h-12 bg-white rounded-xl shadow-lg flex items-center justify-center">
                    <Navigation className="w-5 h-5 text-rose-600" />
                  </button>
                </div>
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="space-y-4">
                    <div className="w-10 h-10 bg-rose-500 rounded-full shadow-lg border-4 border-white animate-pulse" />
                    <div className="w-8 h-8 bg-blue-500 rounded-full shadow-lg border-4 border-white absolute top-20 left-12" />
                    <div className="w-8 h-8 bg-amber-500 rounded-full shadow-lg border-4 border-white absolute bottom-24 right-16" />
                  </div>
                </div>
                <div className="absolute bottom-4 left-4 bg-white rounded-xl shadow-lg p-3 max-w-xs">
                  <div className="flex items-start gap-3">
                    <div className="w-12 h-12 bg-gradient-to-br from-rose-400 to-pink-500 rounded-lg flex items-center justify-center">
                      <Wine className="w-6 h-6 text-white" />
                    </div>
                    <div className="flex-1">
                      <h4 className="font-bold text-gray-900">The Deck</h4>
                      <p className="text-xs text-gray-500">Rooftop Bar • 0.3mi</p>
                      <div className="flex items-center gap-2 mt-1">
                        <div className="flex items-center gap-1">
                          <Users className="w-3.5 h-3.5 text-emerald-600" />
                          <span className="text-xs font-bold text-emerald-600">12 people</span>
                        </div>
                        <span className="text-xs text-gray-400">• Open until 2am</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div className="p-4 flex gap-2 overflow-x-auto">
                <button className="px-4 py-2 bg-rose-500 text-white rounded-full text-xs font-bold whitespace-nowrap">All</button>
                <button className="px-4 py-2 bg-gray-100 text-gray-600 rounded-full text-xs font-bold whitespace-nowrap">Bars</button>
                <button className="px-4 py-2 bg-gray-100 text-gray-600 rounded-full text-xs font-bold whitespace-nowrap">Clubs</button>
                <button className="px-4 py-2 bg-gray-100 text-gray-600 rounded-full text-xs font-bold whitespace-nowrap">Lounges</button>
              </div>
            </div>
          </div>
        );

      case 'messages':
        return (
          <div className="bg-gray-50 p-8 rounded-2xl">
            <div className="max-w-sm mx-auto bg-white rounded-3xl shadow-2xl overflow-hidden">
              <div className="bg-gradient-to-r from-blue-500 to-purple-600 p-6 text-white">
                <h2 className="text-2xl font-bold">Messages</h2>
              </div>
              <div className="divide-y">
                {[
                  { name: 'Sarah Martinez', msg: 'See you at The Deck!', time: '2m', unread: 2 },
                  { name: 'Mike Chen', msg: 'Want to grab drinks?', time: '15m', unread: 0 },
                  { name: 'Friday Night Crew', msg: 'Alex: Count me in!', time: '1h', unread: 5 }
                ].map((chat, i) => (
                  <div key={i} className="p-4 flex items-center gap-3 hover:bg-gray-50">
                    <div className="relative">
                      <div className="w-12 h-12 bg-gradient-to-br from-rose-400 to-pink-500 rounded-full" />
                      {chat.unread > 0 && (
                        <div className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 rounded-full flex items-center justify-center">
                          <span className="text-white text-xs font-bold">{chat.unread}</span>
                        </div>
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-1">
                        <p className="font-bold text-gray-900">{chat.name}</p>
                        <span className="text-xs text-gray-400">{chat.time}</span>
                      </div>
                      <p className="text-sm text-gray-500 truncate">{chat.msg}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        );

      case 'swarms':
        return (
          <div className="bg-gradient-to-br from-purple-50 to-pink-50 p-8 rounded-2xl">
            <div className="max-w-sm mx-auto bg-white rounded-3xl shadow-2xl overflow-hidden">
              <div className="bg-gradient-to-r from-purple-500 to-pink-600 p-6 text-white">
                <div className="flex items-center justify-between">
                  <h2 className="text-2xl font-bold">Swarms</h2>
                  <button className="w-10 h-10 bg-white/20 backdrop-blur rounded-full flex items-center justify-center">
                    <span className="text-2xl">+</span>
                  </button>
                </div>
              </div>
              <div className="p-6 space-y-4">
                <div className="bg-gradient-to-br from-purple-50 to-pink-50 rounded-2xl p-4 border-2 border-purple-200">
                  <div className="flex items-start justify-between mb-3">
                    <div>
                      <h3 className="font-bold text-gray-900 mb-1">Friday Night Out</h3>
                      <div className="flex items-center gap-2 text-xs text-gray-600">
                        <Clock className="w-3.5 h-3.5" />
                        <span>Tonight at 9:00 PM</span>
                      </div>
                    </div>
                    <span className="px-3 py-1 bg-emerald-100 text-emerald-700 text-xs font-bold rounded-full">Going</span>
                  </div>
                  <div className="flex items-center gap-2 mb-3">
                    <MapPin className="w-4 h-4 text-rose-600" />
                    <span className="text-sm text-gray-700 font-medium">Starting at The Deck</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="flex -space-x-2">
                      {[1,2,3,4].map(i => (
                        <div key={i} className="w-8 h-8 bg-gradient-to-br from-rose-400 to-pink-500 rounded-full border-2 border-white" />
                      ))}
                    </div>
                    <span className="text-xs font-bold text-gray-600">8 going</span>
                  </div>
                </div>
                <div className="bg-gray-50 rounded-2xl p-4">
                  <div className="flex items-start justify-between mb-3">
                    <div>
                      <h3 className="font-bold text-gray-900 mb-1">Saturday Bar Crawl</h3>
                      <div className="flex items-center gap-2 text-xs text-gray-600">
                        <Clock className="w-3.5 h-3.5" />
                        <span>Tomorrow at 8:00 PM</span>
                      </div>
                    </div>
                    <span className="px-3 py-1 bg-amber-100 text-amber-700 text-xs font-bold rounded-full">Maybe</span>
                  </div>
                  <div className="flex -space-x-2">
                    {[1,2,3].map(i => (
                      <div key={i} className="w-8 h-8 bg-gradient-to-br from-blue-400 to-purple-500 rounded-full border-2 border-white" />
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        );

      case 'payments':
        return (
          <div className="bg-gradient-to-br from-green-50 to-emerald-50 p-8 rounded-2xl">
            <div className="max-w-sm mx-auto bg-white rounded-3xl shadow-2xl overflow-hidden">
              <div className="bg-gradient-to-r from-green-500 to-emerald-600 p-6 text-white">
                <h2 className="text-2xl font-bold mb-4">Payments</h2>
                <div className="bg-white/20 backdrop-blur rounded-2xl p-4">
                  <div className="flex items-center gap-3">
                    <CreditCard className="w-8 h-8" />
                    <div>
                      <p className="text-sm opacity-90">Connected</p>
                      <p className="font-bold">Venmo</p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="p-6">
                <div className="grid grid-cols-2 gap-3 mb-6">
                  <button className="p-4 bg-green-50 rounded-xl text-center border-2 border-green-200">
                    <Share2 className="w-6 h-6 text-green-600 mx-auto mb-2" />
                    <p className="text-sm font-bold text-gray-900">Send</p>
                  </button>
                  <button className="p-4 bg-blue-50 rounded-xl text-center border-2 border-blue-200">
                    <TrendingUp className="w-6 h-6 text-blue-600 mx-auto mb-2" />
                    <p className="text-sm font-bold text-gray-900">Request</p>
                  </button>
                </div>
                <div className="space-y-3">
                  <p className="text-xs font-bold text-gray-500 uppercase">Recent Activity</p>
                  {[
                    { name: 'Sarah Martinez', amount: '$12.50', type: 'sent', desc: 'Drinks at The Deck' },
                    { name: 'Mike Chen', amount: '$25.00', type: 'received', desc: 'Uber split' }
                  ].map((tx, i) => (
                    <div key={i} className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                      <div className="w-10 h-10 bg-gradient-to-br from-green-400 to-emerald-500 rounded-full" />
                      <div className="flex-1">
                        <p className="font-bold text-sm">{tx.name}</p>
                        <p className="text-xs text-gray-500">{tx.desc}</p>
                      </div>
                      <div className="text-right">
                        <p className={`font-bold ${tx.type === 'sent' ? 'text-red-600' : 'text-green-600'}`}>
                          {tx.type === 'sent' ? '-' : '+'}{tx.amount}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        );

      case 'gifts':
        return (
          <div className="bg-gradient-to-br from-purple-50 to-pink-50 p-8 rounded-2xl">
            <div className="max-w-sm mx-auto bg-white rounded-3xl shadow-2xl overflow-hidden">
              <div className="bg-gradient-to-r from-purple-500 to-pink-600 p-6 text-white">
                <h2 className="text-2xl font-bold">Virtual Gifts</h2>
              </div>
              <div className="p-6">
                <div className="grid grid-cols-3 gap-4 mb-6">
                  {[
                    { emoji: '🍺', name: 'Beer', price: '$1' },
                    { emoji: '��', name: 'Cocktail', price: '$2' },
                    { emoji: '🥃', name: 'Shot', price: '$1' },
                    { emoji: '🍾', name: 'Champagne', price: '$5' },
                    { emoji: '🍷', name: 'Wine', price: '$3' },
                    { emoji: '🎉', name: 'Party', price: '$2' }
                  ].map((gift, i) => (
                    <button key={i} className="p-4 bg-gradient-to-br from-purple-50 to-pink-50 rounded-xl text-center border-2 border-purple-200 hover:border-purple-400 transition-all">
                      <div className="text-3xl mb-2">{gift.emoji}</div>
                      <p className="text-xs font-bold text-gray-900">{gift.name}</p>
                      <p className="text-xs text-purple-600 font-bold">{gift.price}</p>
                    </button>
                  ))}
                </div>
                <div className="bg-gradient-to-br from-amber-50 to-orange-50 rounded-xl p-4 border-2 border-amber-200">
                  <div className="flex items-center gap-3">
                    <div className="text-3xl">🎁</div>
                    <div className="flex-1">
                      <p className="font-bold text-gray-900">You received a gift!</p>
                      <p className="text-xs text-gray-600">Sarah sent you a cocktail 🍸</p>
                    </div>
                    <Heart className="w-5 h-5 text-rose-500" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        );

      case 'profile':
        return (
          <div className="bg-gray-50 p-8 rounded-2xl">
            <div className="max-w-sm mx-auto bg-white rounded-3xl shadow-2xl overflow-hidden">
              <div className="bg-gradient-to-r from-gray-800 to-gray-900 p-6 text-white text-center">
                <div className="w-24 h-24 bg-gradient-to-br from-rose-400 to-pink-500 rounded-full mx-auto mb-4 border-4 border-white shadow-xl" />
                <h2 className="text-2xl font-bold mb-1">Alex Johnson</h2>
                <p className="text-sm opacity-75">@alexj • Darwin, NT</p>
                <div className="flex justify-center gap-4 mt-4">
                  <div className="text-center">
                    <p className="text-2xl font-bold">47</p>
                    <p className="text-xs opacity-75">Friends</p>
                  </div>
                  <div className="text-center">
                    <p className="text-2xl font-bold">12</p>
                    <p className="text-xs opacity-75">Swarms</p>
                  </div>
                  <div className="text-center">
                    <p className="text-2xl font-bold">8</p>
                    <p className="text-xs opacity-75">Nights Out</p>
                  </div>
                </div>
              </div>
              <div className="p-6 space-y-3">
                {[
                  { icon: Settings, label: 'Account Settings', color: 'gray' },
                  { icon: Shield, label: 'Privacy & Safety', color: 'blue' },
                  { icon: CreditCard, label: 'Payment Methods', color: 'green' },
                  { icon: Bell, label: 'Notifications', color: 'rose' }
                ].map((item, i) => (
                  <button key={i} className="w-full flex items-center gap-3 p-3 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors">
                    <div className={`w-10 h-10 bg-${item.color}-100 rounded-lg flex items-center justify-center`}>
                      <item.icon className={`w-5 h-5 text-${item.color}-600`} />
                    </div>
                    <span className="flex-1 text-left font-semibold text-gray-900">{item.label}</span>
                    <ChevronRight className="w-5 h-5 text-gray-400" />
                  </button>
                ))}
              </div>
            </div>
          </div>
        );

      case 'tonight':
        return (
          <div className="bg-gradient-to-br from-emerald-50 to-teal-50 p-8 rounded-2xl">
            <div className="max-w-sm mx-auto bg-white rounded-3xl shadow-2xl overflow-hidden">
              <div className="bg-gradient-to-r from-emerald-500 to-teal-600 p-6 text-white">
                <h2 className="text-2xl font-bold mb-3">Tonight Status</h2>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-green-300 rounded-full animate-pulse" />
                  <p className="text-sm font-semibold">5 friends are out now</p>
                </div>
              </div>
              <div className="p-6 space-y-4">
                <div>
                  <div className="flex items-center gap-2 mb-3">
                    <div className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
                    <p className="text-xs font-bold text-emerald-700 uppercase">Out Right Now (3)</p>
                  </div>
                  <div className="space-y-2">
                    {[
                      { name: 'Sarah Martinez', venue: 'The Deck', vibe: 'Rooftop' },
                      { name: 'Mike Chen', venue: 'Darwin Sailing Club', vibe: 'Waterfront' },
                      { name: 'Emma Wilson', venue: 'Discovery', vibe: 'Dance' }
                    ].map((friend, i) => (
                      <div key={i} className="flex items-center gap-3 p-3 bg-emerald-50 rounded-xl">
                        <div className="relative">
                          <div className="w-10 h-10 bg-gradient-to-br from-emerald-400 to-teal-500 rounded-full" />
                          <div className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 bg-emerald-500 rounded-full border-2 border-white" />
                        </div>
                        <div className="flex-1">
                          <p className="font-bold text-sm">{friend.name}</p>
                          <div className="flex items-center gap-1 text-xs">
                            <MapPin className="w-3 h-3 text-emerald-600" />
                            <span className="text-emerald-700 font-semibold">{friend.venue}</span>
                          </div>
                        </div>
                        <span className="text-xs bg-white px-2 py-1 rounded-full text-gray-600">{friend.vibe}</span>
                      </div>
                    ))}
                  </div>
                </div>
                <div>
                  <div className="flex items-center gap-2 mb-3">
                    <div className="w-2 h-2 bg-amber-400 rounded-full" />
                    <p className="text-xs font-bold text-amber-700 uppercase">Going Out Soon (2)</p>
                  </div>
                  <div className="space-y-2">
                    {[
                      { name: 'Chris Taylor', time: 'In 30 min' },
                      { name: 'Rachel Kim', time: 'In 1 hour' }
                    ].map((friend, i) => (
                      <div key={i} className="flex items-center gap-3 p-3 bg-amber-50 rounded-xl">
                        <div className="w-10 h-10 bg-gradient-to-br from-amber-400 to-orange-500 rounded-full" />
                        <div className="flex-1">
                          <p className="font-bold text-sm">{friend.name}</p>
                          <p className="text-xs text-amber-600 font-semibold">{friend.time}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        );

      default:
        return null;
    }
  };

  if (!showDemo) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl shadow-2xl max-w-6xl w-full max-h-[90vh] overflow-hidden flex flex-col">
        <div className="bg-gradient-to-r from-rose-500 to-pink-600 p-6 text-white">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-3xl font-bold mb-2">Barfliz Complete Demo</h1>
              <p className="text-sm opacity-90">Full user journey from signup to all features</p>
            </div>
            <button
              onClick={() => setShowDemo(false)}
              className="w-10 h-10 bg-white/20 backdrop-blur rounded-full flex items-center justify-center hover:bg-white/30 transition-colors"
            >
              <X className="w-6 h-6" />
            </button>
          </div>
          <div className="flex items-center gap-4">
            <button
              onClick={() => setIsPlaying(!isPlaying)}
              className="w-12 h-12 bg-white text-rose-600 rounded-full flex items-center justify-center shadow-lg hover:scale-105 transition-transform"
            >
              {isPlaying ? <Pause className="w-6 h-6" /> : <Play className="w-6 h-6 ml-1" />}
            </button>
            <div className="flex-1">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-semibold">Step {currentStep + 1} of {demoSteps.length}</span>
                <span className="text-sm opacity-75">{Math.round(((currentStep + 1) / demoSteps.length) * 100)}% Complete</span>
              </div>
              <div className="w-full bg-white/20 rounded-full h-2">
                <div
                  className="bg-white rounded-full h-2 transition-all duration-300"
                  style={{ width: `${((currentStep + 1) / demoSteps.length) * 100}%` }}
                />
              </div>
            </div>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto">
          <div className="grid md:grid-cols-2 gap-6 p-6">
            <div>
              <div className="sticky top-0 bg-white pb-4">
                <h2 className="text-2xl font-bold text-gray-900 mb-2">{currentDemo.title}</h2>
                <p className="text-gray-600 mb-4">{currentDemo.description}</p>

                <div className="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-2xl p-4 border-2 border-blue-200">
                  <h3 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
                    <TrendingUp className="w-5 h-5 text-blue-600" />
                    Key Features
                  </h3>
                  <ul className="space-y-2">
                    {currentDemo.features.map((feature, i) => (
                      <li key={i} className="flex items-start gap-2 text-sm text-gray-700">
                        <ChevronRight className="w-4 h-4 text-blue-600 flex-shrink-0 mt-0.5" />
                        <span>{feature}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </div>

            <div>
              {getScreenPreview(currentDemo.screen)}
            </div>
          </div>
        </div>

        <div className="border-t bg-gray-50 p-4 flex items-center justify-between">
          <button
            onClick={prevStep}
            disabled={currentStep === 0}
            className={`px-6 py-3 rounded-xl font-bold flex items-center gap-2 ${
              currentStep === 0
                ? 'bg-gray-200 text-gray-400 cursor-not-allowed'
                : 'bg-white text-gray-900 hover:bg-gray-100 shadow-sm'
            }`}
          >
            Previous
          </button>

          <div className="flex gap-2">
            {demoSteps.map((_, i) => (
              <button
                key={i}
                onClick={() => setCurrentStep(i)}
                className={`w-2.5 h-2.5 rounded-full transition-all ${
                  i === currentStep
                    ? 'bg-rose-500 w-8'
                    : i < currentStep
                    ? 'bg-rose-300'
                    : 'bg-gray-300'
                }`}
              />
            ))}
          </div>

          <button
            onClick={nextStep}
            className="px-6 py-3 bg-gradient-to-r from-rose-500 to-pink-600 text-white rounded-xl font-bold flex items-center gap-2 hover:shadow-lg transition-shadow"
          >
            {currentStep === demoSteps.length - 1 ? 'Start Over' : 'Next'}
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
