import { useState, useEffect, useRef } from 'react';
import { Send, Trash2, Flag } from 'lucide-react';
import { buzzService, BuzzMessage } from '../../services/buzzService';
import { supabase } from '../../lib/supabase';
import { xpService } from '../../services/xpService';

interface VenueBuzzChatProps {
  venueId: string;
  venueTitle: string;
}

export function VenueBuzzChat({ venueId, venueTitle }: VenueBuzzChatProps) {
  const [messages, setMessages] = useState<BuzzMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const subscriptionRef = useRef<any>(null);

  useEffect(() => {
    const getUser = async () => {
      const { data: session } = await supabase.auth.getSession();
      setCurrentUserId(session?.user?.id || null);
    };
    getUser();
  }, []);

  useEffect(() => {
    const loadMessages = async () => {
      try {
        const data = await buzzService.getBuzzForVenue(venueId);
        setMessages(data);
        setLoading(false);
      } catch (error) {
        console.error('Failed to load buzz messages:', error);
        setLoading(false);
      }
    };

    loadMessages();

    subscriptionRef.current = buzzService.subscribeToVenueBuzz(venueId, (newMsg) => {
      setMessages((prev) => [newMsg, ...prev]);
    });

    return () => {
      subscriptionRef.current?.unsubscribe();
    };
  }, [venueId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || submitting) return;

    setSubmitting(true);
    try {
      await buzzService.postBuzz(venueId, newMessage.trim());
      setNewMessage('');
      if (currentUserId) {
        xpService.updateChallengeProgress(currentUserId, 'buzz_creator', 1).catch(() => null);
      }
    } catch (error) {
      console.error('Failed to post buzz:', error);
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteMessage = async (messageId: string) => {
    try {
      await buzzService.deleteBuzz(messageId);
      setMessages((prev) => prev.filter((m) => m.id !== messageId));
    } catch (error) {
      console.error('Failed to delete message:', error);
    }
  };

  const handleReportMessage = async (messageId: string) => {
    try {
      await buzzService.reportBuzz(messageId);
      setMessages((prev) => prev.filter((m) => m.id !== messageId));
    } catch (error) {
      console.error('Failed to report message:', error);
    }
  };

  return (
    <div className="flex flex-col h-96 bg-white border-t border-gray-200">
      <div className="px-4 py-3 border-b border-gray-100 bg-gradient-to-r from-blue-50 to-transparent">
        <h3 className="font-semibold text-gray-900">💬 The Buzz at {venueTitle}</h3>
        <p className="text-xs text-gray-500 mt-1">Messages expire after 4 hours</p>
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-3 space-y-3">
        {loading ? (
          <div className="flex items-center justify-center h-full">
            <div className="animate-pulse text-gray-400">Loading buzz...</div>
          </div>
        ) : messages.length === 0 ? (
          <div className="flex items-center justify-center h-full text-gray-400 text-sm">
            No buzz yet. Be the first to speak up!
          </div>
        ) : (
          messages.map((msg) => (
            <div
              key={msg.id}
              className="bg-gray-50 rounded-lg p-3 hover:bg-gray-100 transition-colors group"
            >
              <div className="flex items-start justify-between gap-2">
                <div className="flex-1 min-w-0">
                  <p className="text-sm text-gray-700 break-words">{msg.body}</p>
                  <p className="text-xs text-gray-500 mt-1">
                    {new Date(msg.created_at).toLocaleTimeString([], {
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </p>
                </div>
                <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  {msg.user_id === currentUserId && (
                    <button
                      onClick={() => handleDeleteMessage(msg.id)}
                      className="p-1 hover:bg-red-100 rounded transition-colors"
                      title="Delete"
                    >
                      <Trash2 size={14} className="text-red-500" />
                    </button>
                  )}
                  {msg.user_id !== currentUserId && (
                    <button
                      onClick={() => handleReportMessage(msg.id)}
                      className="p-1 hover:bg-red-100 rounded transition-colors"
                      title="Report"
                    >
                      <Flag size={14} className="text-orange-500" />
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))
        )}
        <div ref={messagesEndRef} />
      </div>

      <form onSubmit={handleSendMessage} className="border-t border-gray-200 p-3 bg-gray-50">
        <div className="flex gap-2">
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value.slice(0, 280))}
            placeholder="What's the vibe? (max 280 chars)"
            maxLength={280}
            className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
            disabled={submitting}
          />
          <button
            type="submit"
            disabled={!newMessage.trim() || submitting}
            className="px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <Send size={18} />
          </button>
        </div>
        <p className="text-xs text-gray-500 mt-1">
          {newMessage.length}/280
        </p>
      </form>
    </div>
  );
}
