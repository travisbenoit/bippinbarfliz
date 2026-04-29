import { useNavigate } from 'react-router-dom';
import { ChevronLeft } from 'lucide-react';

export default function TermsOfService() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-[#FFF5F0]">
      <div className="sticky top-0 z-10 bg-white border-b border-gray-100 px-4 py-4 flex items-center gap-3">
        <button onClick={() => navigate(-1)} className="p-2 hover:bg-gray-100 rounded-full">
          <ChevronLeft className="w-5 h-5" />
        </button>
        <h1 className="text-lg font-bold text-gray-900">Terms of Service</h1>
      </div>

      <div className="max-w-2xl mx-auto px-6 py-8 space-y-6 text-gray-700 text-sm leading-relaxed">
        <p className="text-xs text-gray-400">Last updated: March 10, 2026</p>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">1. Acceptance of Terms</h2>
          <p>By creating an account and using Barfliz, you agree to these Terms of Service. If you do not agree, do not use the app.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">2. Eligibility</h2>
          <p>You must be at least 18 years of age to use Barfliz. By using the app, you represent and warrant that you are 18 or older. We reserve the right to terminate accounts of users found to be under 18.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">3. Your Account</h2>
          <p>You are responsible for maintaining the security of your account and all activity under it. Your phone number is used for verification and must be valid. You may not share your account with others.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">4. Acceptable Use and Zero Tolerance</h2>
          <p>Barfliz has <span className="font-semibold text-gray-900">zero tolerance for objectionable content or abusive users</span>. Reports are reviewed within 24 hours. Users who violate these terms are banned without warning and may be reported to law enforcement when appropriate.</p>
          <p>You agree not to:</p>
          <ul className="list-disc pl-5 space-y-1">
            <li>Harass, threaten, bully, or abuse other users</li>
            <li>Post illegal, harmful, hateful, sexually explicit, or otherwise objectionable content</li>
            <li>Impersonate another person or entity</li>
            <li>Use the app while driving or in a way that endangers yourself or others</li>
            <li>Attempt to bypass security measures or reverse-engineer the app</li>
            <li>Use automated tools to scrape or collect data</li>
            <li>Share the location of other users without their consent</li>
            <li>Create accounts if you are under the legal drinking age in your country</li>
          </ul>
          <p>You can report any user, message, swarm, or venue from inside the app at any time. You can block any user from your profile or theirs. Blocked users will no longer be able to see your profile, send you messages, or appear in your discovery feeds.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">5. Responsible Drinking</h2>
          <p>Barfliz is a social platform that operates in nightlife environments. We strongly encourage responsible alcohol consumption. Never drink and drive. Use the built-in safe arrival features. Barfliz is not responsible for the actions of users while intoxicated.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">6. Virtual Items and Lush Coins</h2>
          <p>Virtual gifts and Lush Coins are in-app items with no real monetary value and are non-refundable. They cannot be exchanged for real money. Barfliz reserves the right to modify, discontinue, or adjust the virtual economy at any time.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">7. User Content</h2>
          <p>You retain ownership of content you post. By posting, you grant Barfliz a non-exclusive license to use, display, and distribute that content within the app. You are solely responsible for the content you post. Moments and Room messages are ephemeral and expire automatically.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">8. Payments</h2>
          <p>Barfliz integrates with third-party payment providers (Venmo, Beem It). Payment transactions are governed by those providers' terms. Barfliz does not process or hold funds and is not responsible for payment disputes.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">9. Termination</h2>
          <p>We may suspend or terminate your account at any time for violations of these Terms. You may delete your account at any time from Settings → Safety & Security → Delete Account.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">10. Limitation of Liability</h2>
          <p>Barfliz is provided "as is" without warranty of any kind. We are not liable for damages arising from your use of the app, interactions with other users, or events at venues listed in the app. Use your own judgment and stay safe.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">11. Changes to Terms</h2>
          <p>We may update these Terms from time to time. Continued use of Barfliz after changes constitutes acceptance of the updated Terms.</p>
        </section>

        <section className="space-y-3">
          <h2 className="text-base font-bold text-gray-900">12. Contact</h2>
          <p>Questions about these Terms? Email us at <span className="text-[#E91E63] font-medium">legal@barfliz.com</span></p>
        </section>
      </div>
    </div>
  );
}
