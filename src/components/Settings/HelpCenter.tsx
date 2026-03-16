import { useState } from 'react';
import { useNavigate } from 'react-router';
import { ChevronDown, ChevronUp, Mail, MapPin, Users, MessageCircle, Gift, DollarSign, Shield, Bell, Music, Heart, Navigation } from 'lucide-react';
import PageHeader from '../Layout/PageHeader';

interface FAQItem {
  question: string;
  answer: string;
  icon: any;
}

export default function HelpCenter() {
  const navigate = useNavigate();
  const [expandedIndex, setExpandedIndex] = useState<number | null>(null);

  const faqs: FAQItem[] = [
    {
      icon: MapPin,
      question: 'How does the map work?',
      answer: 'The map shows bars and venues near you in real-time. You can see how many people are at each location, filter by venue type, and adjust your search radius using the slider. Tap any venue to see details, photos, and who\'s there.'
    },
    {
      icon: Users,
      question: 'What are Swarms?',
      answer: 'Swarms are group meetups you can create or join. Set a time, pick a venue, and invite friends or make it public for others to join. You\'ll get notifications when people RSVP, and you can chat with attendees before and during the event.'
    },
    {
      icon: Navigation,
      question: 'How does Tonight Status work?',
      answer: 'Set your Tonight Status to let friends know your plans - "Out Now", "Going Out Soon", or "Staying In". Your status shows on your profile and helps friends find you when they\'re out. You can update it anytime from the home screen.'
    },
    {
      icon: MessageCircle,
      question: 'How do I chat with people?',
      answer: 'You can message friends directly or chat within Swarms. All conversations are private and secure. Read receipts show when messages are seen, and you can share music, send gifts, and react with emojis.'
    },
    {
      icon: Gift,
      question: 'What are virtual gifts?',
      answer: 'Send fun virtual items like drinks, emojis, and special effects to friends. Some gifts are free, while premium gifts can be purchased with Lush Coins. Recipients see gifts in their inbox and can display them on their profile.'
    },
    {
      icon: DollarSign,
      question: 'How do payments work?',
      answer: 'Connect your Venmo (US) or Beem It (Australia) account to easily split bills and send drinks to friends. Your payment handle shows on your profile, making it easy for friends to pay you back. All payments happen securely through the connected app.'
    },
    {
      icon: Heart,
      question: 'What are Cheers and reactions?',
      answer: 'Send Cheers to friends when you see them out, react to their status updates, and celebrate great nights together. Reactions show up in your activity feed and help you stay connected with your crew.'
    },
    {
      icon: Music,
      question: 'Can I share music?',
      answer: 'Yes! Connect your Spotify account to share what you\'re listening to with friends. Send songs directly in messages or post them to your profile. See what friends are jamming to and discover new music together.'
    },
    {
      icon: Bell,
      question: 'What notifications will I get?',
      answer: 'You\'ll receive alerts when friends send messages, invite you to Swarms, send you gifts, or when you enter a venue with an active Swarm. You can customize notification preferences in Settings to control what you see.'
    },
    {
      icon: Shield,
      question: 'How does safety and privacy work?',
      answer: 'Your location is only shared with friends when you\'re active. Ghost Mode hides you completely. Set emergency contacts, use Safe Arrival to let friends know you got home safely, and block users if needed. You control who sees your information.'
    },
    {
      icon: Users,
      question: 'How do I add friends?',
      answer: 'You can add friends by searching for their username, syncing your contacts (with permission), or connecting when you\'re at the same venue. Friend requests must be accepted before you can message or see each other\'s full activity.'
    },
    {
      icon: MapPin,
      question: 'Why don\'t I see any venues?',
      answer: 'Make sure location permissions are enabled. Barfliz currently operates in select cities. If you\'re in an active market but don\'t see venues, try adjusting your search radius or refreshing the map. Some venues may be temporarily inactive.'
    },
    {
      icon: DollarSign,
      question: 'How do I set up payments?',
      answer: 'Go to Settings > Profile > Payment Settings. For US users, link your Venmo account by entering your username. Australian users can link Beem It. Your payment handle will appear on your profile once connected.'
    },
    {
      icon: Navigation,
      question: 'What is geofencing?',
      answer: 'Geofencing automatically detects when you enter or leave a venue. This helps show accurate "people here now" counts and can trigger Swarm notifications. You can view and manage location history in your privacy settings.'
    }
  ];

  const toggleExpand = (index: number) => {
    setExpandedIndex(expandedIndex === index ? null : index);
  };

  return (
    <div className="h-full overflow-y-auto bg-[#FFF5F0] pb-20">
      <PageHeader title="Help Center" onBack={() => navigate('/settings')} />

      <div className="p-4 space-y-4">
        <div className="bg-gradient-to-br from-[#E91E63] to-[#FF6B9D] rounded-2xl p-6 text-white shadow-lg">
          <h2 className="text-2xl font-bold mb-2">How can we help?</h2>
          <p className="text-white/90 text-sm">
            Find answers to common questions or reach out to our team
          </p>
        </div>

        <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wide px-5 py-3 bg-gray-50">
            Frequently Asked Questions
          </h3>
          <div className="divide-y divide-gray-100">
            {faqs.map((faq, index) => {
              const Icon = faq.icon;
              const isExpanded = expandedIndex === index;

              return (
                <div key={index}>
                  <button
                    onClick={() => toggleExpand(index)}
                    className="w-full px-5 py-4 flex items-start gap-3 hover:bg-gray-50 transition-colors text-left"
                  >
                    <div className="w-10 h-10 bg-[#E91E63]/10 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
                      <Icon size={20} className="text-[#E91E63]" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-semibold text-gray-900 pr-2">{faq.question}</p>
                    </div>
                    <div className="flex-shrink-0">
                      {isExpanded ? (
                        <ChevronUp size={20} className="text-gray-400" />
                      ) : (
                        <ChevronDown size={20} className="text-gray-400" />
                      )}
                    </div>
                  </button>
                  {isExpanded && (
                    <div className="px-5 pb-4 pl-[68px] pr-8">
                      <p className="text-sm text-gray-600 leading-relaxed">{faq.answer}</p>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
          <div className="p-6 text-center">
            <div className="w-16 h-16 bg-gradient-to-br from-[#E91E63] to-[#FF6B9D] rounded-full flex items-center justify-center mx-auto mb-4">
              <Mail size={28} className="text-white" />
            </div>
            <h3 className="text-lg font-bold text-gray-900 mb-2">Still need help?</h3>
            <p className="text-sm text-gray-600 mb-4">
              Our support team is here to assist you with any questions or issues.
            </p>
            <a
              href="mailto:hello@barfliz.com"
              className="inline-flex items-center gap-2 px-6 py-3 bg-[#E91E63] text-white rounded-xl font-semibold text-sm hover:bg-[#C2185B] transition-colors shadow-lg shadow-pink-200"
            >
              <Mail size={18} />
              Contact Support
            </a>
            <p className="text-xs text-gray-500 mt-3">hello@barfliz.com</p>
          </div>
        </div>

        <div className="bg-white rounded-2xl shadow-sm p-6">
          <h3 className="text-sm font-semibold text-gray-700 mb-3">Quick Tips</h3>
          <ul className="space-y-2 text-sm text-gray-600">
            <li className="flex items-start gap-2">
              <span className="text-[#E91E63] font-bold">•</span>
              <span>Enable location services for the best experience and accurate venue information</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#E91E63] font-bold">•</span>
              <span>Complete your profile to help friends find and connect with you</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#E91E63] font-bold">•</span>
              <span>Set your Tonight Status to let friends know when you\'re out</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="text-[#E91E63] font-bold">•</span>
              <span>Join or create Swarms to meet new people and plan group outings</span>
            </li>
          </ul>
        </div>

        <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
          <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wide px-5 py-3 bg-gray-50">Legal</h3>
          <div className="divide-y divide-gray-100">
            <button
              onClick={() => navigate('/privacy')}
              className="w-full flex items-center gap-3 px-5 py-4 hover:bg-gray-50 transition-colors text-left"
            >
              <Shield size={18} className="text-[#E91E63] flex-shrink-0" />
              <span className="flex-1 text-sm font-medium text-gray-800">Privacy Policy</span>
              <ChevronDown size={16} className="text-gray-400 -rotate-90" />
            </button>
            <button
              onClick={() => navigate('/terms')}
              className="w-full flex items-center gap-3 px-5 py-4 hover:bg-gray-50 transition-colors text-left"
            >
              <Mail size={18} className="text-[#E91E63] flex-shrink-0" />
              <span className="flex-1 text-sm font-medium text-gray-800">Terms of Service</span>
              <ChevronDown size={16} className="text-gray-400 -rotate-90" />
            </button>
          </div>
        </div>

        <div className="text-center space-y-2 pt-2 pb-4">
          <p className="text-sm text-gray-500">Barfliz v1.3.0</p>
          <p className="text-xs text-gray-400">Making every night out better</p>
        </div>
      </div>
    </div>
  );
}
