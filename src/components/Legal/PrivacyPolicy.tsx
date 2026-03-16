import { useNavigate } from 'react-router';
import { ChevronLeft } from 'lucide-react';

export default function PrivacyPolicy() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-[#FFF5F0]">
      <div className="sticky top-0 z-10 bg-white border-b border-gray-100 px-4 py-4 flex items-center gap-3">
        <button onClick={() => navigate(-1)} className="p-2 hover:bg-gray-100 rounded-full">
          <ChevronLeft className="w-5 h-5" />
        </button>
        <h1 className="text-lg font-bold text-gray-900">Privacy Policy</h1>
      </div>

      <div className="max-w-2xl mx-auto px-6 py-8 space-y-6 text-gray-700 text-sm leading-relaxed">
        <p className="text-xs text-gray-400">Last updated: March 10, 2026</p>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">1. Information We Collect</h2>
          <p>Barfliz collects information you provide directly to us, including your name, phone number, date of birth, and profile information. We also collect location data when you use the app to enable geofencing and venue discovery features.</p>
          <p>We collect usage data such as check-ins, messages, swarm activity, and interactions with other users to power the social features of the app.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">2. How We Use Your Information</h2>
          <ul className="list-disc pl-5 space-y-1">
            <li>To provide, maintain, and improve the Barfliz service</li>
            <li>To show your location to friends you've connected with (unless Ghost Mode is enabled)</li>
            <li>To send push notifications about friend activity, messages, and swarm invites</li>
            <li>To calculate XP, streaks, and leaderboard rankings</li>
            <li>To enforce community guidelines and prevent abuse</li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">3. Location Data</h2>
          <p>Barfliz uses your device's GPS location to detect when you enter or leave venues (geofencing). Location data is processed in real-time and used to trigger check-ins, notify friends, and surface relevant venues. You can disable location access at any time in your device settings.</p>
          <p>Enabling Ghost Mode prevents your location from being shared with other users.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">4. Sharing of Information</h2>
          <p>We do not sell your personal information to third parties. We may share information with:</p>
          <ul className="list-disc pl-5 space-y-1">
            <li><strong>Other users:</strong> Your name, profile photo, tonight status, and activity is visible to your friends and nearby users per your privacy settings</li>
            <li><strong>Service providers:</strong> We use Supabase (database), Radar.io (geofencing), and Google Places (venue data) to operate the service</li>
            <li><strong>Legal requirements:</strong> We may disclose information if required by law</li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">5. Data Retention</h2>
          <p>Messages in The Room expire after 24 hours. Venue Buzz messages expire after 4 hours. Account data is retained until you delete your account. You can delete your account at any time from Settings → Safety & Security.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">6. Push Notifications</h2>
          <p>With your permission, we send push notifications for messages, friend activity, swarm invites, and gifts. You can manage notification preferences in Settings → Notifications or disable them in your device settings.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">7. Age Requirement</h2>
          <p>Barfliz is intended for users aged 18 and over. We do not knowingly collect information from anyone under 18. If we learn that we have collected information from a person under 18, we will delete it promptly.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">8. Security</h2>
          <p>We use industry-standard encryption and security measures including row-level security on all database tables, HTTPS for all data transmission, and phone verification for account creation.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">9. Your Rights</h2>
          <p>You have the right to access, correct, or delete your personal information. To exercise these rights, contact us at privacy@barfliz.com or use the account deletion feature in-app.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">10. Contact</h2>
          <p>For privacy questions or concerns, email us at <span className="text-[#E91E63] font-medium">privacy@barfliz.com</span></p>
        </section>
      </div>
    </div>
  );
}
