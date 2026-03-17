import { useState, useEffect, useRef, useCallback } from 'react';
import { X, Share2, Download, Twitter, Instagram, Copy, Check, Moon, Loader2 } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';
import { nightRecapService, NightRecapData } from '../../services/nightRecapService';
import NightRecapCard from './NightRecapCard';

interface Props {
  onClose: () => void;
}

export function NightRecapModal({ onClose }: Props) {
  const { user } = useAuth();
  const [recap, setRecap] = useState<NightRecapData | null>(null);
  const [loading, setLoading] = useState(true);
  const [userName, setUserName] = useState('');
  const [shareMode, setShareMode] = useState(false);
  const [copied, setCopied] = useState(false);
  const [sharing, setSharing] = useState(false);
  const [error, setError] = useState(false);
  const cardRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadRecap();
  }, []);

  const loadRecap = async () => {
    if (!user) {
      setLoading(false);
      return;
    }
    try {
      const [recapData, profileData] = await Promise.all([
        nightRecapService.getLastNightRecap(),
        supabase.from('users').select('name').eq('id', user.id).maybeSingle(),
      ]);
      setRecap(recapData);
      setUserName(profileData.data?.name || 'You');
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  };

  const buildShareText = useCallback((): string => {
    if (!recap) return '';
    const lines: string[] = [
      `Last night on Barfliz (${recap.displayDate})`,
      '',
      recap.barsVisited.length > 0
        ? `Bars visited: ${recap.barsVisited.length} (${recap.barsVisited.join(', ')})`
        : 'Bars visited: 0',
      `People met: ${recap.peopleMet}`,
      `Drinks sent: ${recap.drinksSent}`,
    ];
    if (recap.swarmsJoined.length > 0) lines.push(`Swarms joined: ${recap.swarmsJoined.length}`);
    if (recap.xpEarned > 0) lines.push(`XP earned: ${recap.xpEarned}`);
    lines.push('', 'barfliz.app');
    return lines.join('\n');
  }, [recap]);

  const handleCopyText = useCallback(async () => {
    const text = buildShareText();
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      const el = document.createElement('textarea');
      el.value = text;
      document.body.appendChild(el);
      el.select();
      document.execCommand('copy');
      document.body.removeChild(el);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  }, [buildShareText]);

  const handleNativeShare = useCallback(async () => {
    const text = buildShareText();
    if (navigator.share) {
      setSharing(true);
      try {
        await navigator.share({ title: 'My Night Recap \u2014 Barfliz', text });
      } catch {
        // user cancelled
      }
      setSharing(false);
    } else {
      handleCopyText();
    }
  }, [buildShareText, handleCopyText]);

  const handleTwitterShare = useCallback(() => {
    const text = encodeURIComponent(buildShareText());
    window.open(`https://twitter.com/intent/tweet?text=${text}`, '_blank', 'noopener,noreferrer');
  }, [buildShareText]);

  if (loading) {
    return (
      <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 backdrop-blur-sm p-4">
        <div className="bg-[#0f0c29] rounded-3xl w-full max-w-md p-10 flex items-center justify-center">
          <Loader2 className="w-8 h-8 text-[#E91E63] animate-spin" />
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div
        className="fixed inset-0 z-50 flex items-end justify-center bg-black/70 backdrop-blur-sm p-4"
        onClick={(e) => e.target === e.currentTarget && onClose()}
      >
        <div className="bg-[#0f0c29] rounded-3xl w-full max-w-md overflow-hidden shadow-2xl">
          <div className="flex items-center justify-between px-5 pt-5 pb-3">
            <div className="flex items-center gap-2">
              <Moon className="w-5 h-5 text-[#E91E63]" />
              <span className="text-white font-bold text-base">Last Night</span>
            </div>
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center text-white/60 hover:bg-white/20 transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
          <div className="px-5 pb-8 flex flex-col items-center gap-3 py-10">
            <Moon className="w-10 h-10 text-white/20" />
            <p className="text-white/50 text-sm text-center">Could not load your recap. Please try again.</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-black/70 backdrop-blur-sm p-4"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div className="bg-[#0f0c29] rounded-3xl w-full max-w-md overflow-hidden shadow-2xl">
        <div className="flex items-center justify-between px-5 pt-5 pb-3">
          <div className="flex items-center gap-2">
            <Moon className="w-5 h-5 text-[#E91E63]" />
            <span className="text-white font-bold text-base">Last Night</span>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center text-white/60 hover:bg-white/20 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="px-5 pb-2">
          {recap ? (
            <NightRecapCard ref={cardRef} recap={recap} userName={userName} />
          ) : (
            <EmptyRecap />
          )}
        </div>

        {recap && (
          <>
            {!shareMode ? (
              <div className="px-5 pb-6 pt-3 flex gap-3">
                <button
                  onClick={() => setShareMode(true)}
                  className="flex-1 flex items-center justify-center gap-2 bg-gradient-to-r from-[#E91E63] to-[#C2185B] text-white font-semibold rounded-2xl py-3.5 text-sm hover:opacity-90 transition-opacity"
                >
                  <Share2 className="w-4 h-4" />
                  Share Recap
                </button>
              </div>
            ) : (
              <div className="px-5 pb-6 pt-3">
                <p className="text-white/40 text-xs uppercase tracking-widest mb-3">Share to</p>
                <div className="flex gap-2 flex-wrap">
                  <ShareButton
                    icon={<Share2 className="w-4 h-4" />}
                    label={sharing ? 'Sharing\u2026' : 'Share'}
                    onClick={handleNativeShare}
                    primary
                  />
                  <ShareButton
                    icon={<Twitter className="w-4 h-4" />}
                    label="Twitter / X"
                    onClick={handleTwitterShare}
                  />
                  <ShareButton
                    icon={copied ? <Check className="w-4 h-4 text-green-400" /> : <Copy className="w-4 h-4" />}
                    label={copied ? 'Copied!' : 'Copy text'}
                    onClick={handleCopyText}
                  />
                </div>
                <button
                  onClick={() => setShareMode(false)}
                  className="mt-3 text-white/30 text-xs hover:text-white/60 transition-colors"
                >
                  Back
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

function ShareButton({
  icon,
  label,
  onClick,
  primary,
}: {
  icon: React.ReactNode;
  label: string;
  onClick: () => void;
  primary?: boolean;
}) {
  return (
    <button
      onClick={onClick}
      className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium transition-all ${
        primary
          ? 'bg-gradient-to-r from-[#E91E63] to-[#C2185B] text-white'
          : 'bg-white/10 text-white/80 hover:bg-white/20'
      }`}
    >
      {icon}
      {label}
    </button>
  );
}

function EmptyRecap() {
  return (
    <div
      className="rounded-3xl flex flex-col items-center justify-center py-14 gap-3"
      style={{ background: 'linear-gradient(145deg, #0f0c29, #1a1035)' }}
    >
      <Moon className="w-12 h-12 text-white/20" />
      <p className="text-white/50 text-sm text-center px-6">
        No activity found from last night. Head out and use Barfliz to build your recap!
      </p>
    </div>
  );
}
