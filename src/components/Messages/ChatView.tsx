import { useState, useRef, useEffect } from 'react';
import { ArrowLeft, Send, User, MoreVertical, Phone, Video, Sparkles, Music, Gift, X, MessageCircle, Trash2, Trash } from 'lucide-react';
export interface ChatRecipient {
  id: string;
  name: string;
  avatar_url: string | null;
  tonightStatus?: 'going_out' | 'maybe' | 'staying_in' | null;
}

export interface ChatSwarm {
  id: string;
  name: string;
  title?: string;
  venueName?: string;
  memberCount?: number;
  vibe_tags?: string[];
  [key: string]: any;
}

export interface ChatMember {
  id: string;
  name: string;
  avatar_url?: string | null;
}
import { SendMusicModal } from '../Music/SendMusicModal';
import { MusicShareCard } from '../Music/MusicShareCard';
import { VirtualItemsModal } from '../VirtualItems/VirtualItemsModal';
import { GiftCard } from '../VirtualItems/GiftCard';
import type { VirtualItem } from '../../data/virtualItems';
import type { Song } from '../../services/musicService';
import { messagesService } from '../../services/messagesService';
import { giftsService } from '../../services/giftsService';
import { musicSharingService } from '../../services/musicSharingService';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../contexts/ToastContext';
import { markConversationAsRead } from '../../services/messagesService';

interface Message {
  id: string;
  senderId: string;
  senderName: string;
  senderAvatar?: string;
  text?: string;
  timestamp: Date;
  isMe: boolean;
  type?: 'text' | 'gift' | 'music';
  gift?: {
    item: VirtualItem;
    message?: string;
    status: 'sent' | 'viewed' | 'reacted';
    reaction?: string;
  };
  music?: {
    song: Song;
    message?: string;
    status: 'sent' | 'played' | 'saved';
  };
}

interface ChatViewProps {
  isOpen: boolean;
  onClose: () => void;
  chatType: 'direct' | 'swarm';
  recipient?: ChatRecipient;
  swarm?: ChatSwarm;
  members?: ChatMember[];
}

export default function ChatView({ isOpen, onClose, chatType, recipient, swarm, members = [] }: ChatViewProps) {
  const { showError, showSuccess } = useToast();
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [showMusicModal, setShowMusicModal] = useState(false);
  const [showGiftModal, setShowGiftModal] = useState(false);
  const [showCallModal, setShowCallModal] = useState(false);
  const [showChatMenu, setShowChatMenu] = useState(false);
  const [showDeleteChatConfirm, setShowDeleteChatConfirm] = useState(false);
  const [longPressedMsg, setLongPressedMsg] = useState<string | null>(null);
  const [callType, setCallType] = useState<'audio' | 'video'>('audio');
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const longPressTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (user) setCurrentUserId(user.id);
    });
  }, []);

  const handleCallClick = (type: 'audio' | 'video') => {
    setCallType(type);
    setShowCallModal(true);
  };

  const handleCallOption = (platform: 'whatsapp' | 'messenger' | 'facetime') => {
    if (platform === 'whatsapp') {
      window.open('https://wa.me/', '_blank');
    } else if (platform === 'messenger') {
      window.open('https://m.me/', '_blank');
    } else if (platform === 'facetime') {
      window.open('facetime://', '_blank');
    }
    setShowCallModal(false);
  };

  useEffect(() => {
    if (isOpen) {
      loadMessages();
    }
  }, [isOpen, chatType, recipient?.id, swarm?.id]);

  useEffect(() => {
    if (!isOpen) return;

    let subscription: { unsubscribe: () => void } | null = null;

    const setupSubscription = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      if (chatType === 'direct' && recipient) {
        subscription = messagesService.subscribeToDMMessages(recipient.id, (newMsg) => {
          const formattedMsg: Message = {
            id: newMsg.id,
            senderId: newMsg.sender_user_id,
            senderName: newMsg.sender?.name || 'Unknown',
            senderAvatar: newMsg.sender?.avatar_url || undefined,
            text: newMsg.body || undefined,
            timestamp: new Date(newMsg.created_at),
            isMe: newMsg.sender_user_id === user.id,
            type: 'text',
          };
          setMessages((prev) => {
            if (prev.some((m) => m.id === formattedMsg.id)) return prev;
            return [...prev, formattedMsg];
          });
        });
      } else if (chatType === 'swarm' && swarm) {
        subscription = messagesService.subscribeToSwarmMessages(swarm.id, (newMsg) => {
          const formattedMsg: Message = {
            id: newMsg.id,
            senderId: newMsg.sender_user_id,
            senderName: newMsg.sender?.name || 'Unknown',
            senderAvatar: newMsg.sender?.avatar_url || undefined,
            text: newMsg.body || undefined,
            timestamp: new Date(newMsg.created_at),
            isMe: newMsg.sender_user_id === user.id,
            type: 'text',
          };
          setMessages((prev) => {
            if (prev.some((m) => m.id === formattedMsg.id)) return prev;
            return [...prev, formattedMsg];
          });
        });
      }
    };

    setupSubscription();

    return () => {
      if (subscription) {
        subscription.unsubscribe();
      }
    };
  }, [isOpen, chatType, recipient?.id, swarm?.id]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const loadMessages = async () => {
    try {
      setLoading(true);

      const { data: { user } } = await supabase.auth.getUser();
      let dbMessages = [];

      if (chatType === 'direct' && recipient) {
        dbMessages = await messagesService.getDMMessages(recipient.id);
      } else if (chatType === 'swarm' && swarm) {
        dbMessages = await messagesService.getSwarmMessages(swarm.id);
      }

      const formattedMessages: Message[] = dbMessages
        .filter((msg: any) => {
          if (!user) return true;
          const deletedFor: string[] = msg.deleted_for_user_ids || [];
          const clearedBy: string[] = msg.conversation_cleared_by || [];
          return !deletedFor.includes(user.id) && !clearedBy.includes(user.id);
        })
        .map((msg: any) => ({
          id: msg.id,
          senderId: msg.sender_user_id,
          senderName: msg.sender?.name || 'Unknown',
          senderAvatar: msg.sender?.avatar_url,
          text: msg.body,
          timestamp: new Date(msg.created_at),
          isMe: user ? msg.sender_user_id === user.id : false,
          type: 'text',
        }));

      setMessages(formattedMessages);

      if (chatType === 'direct' && recipient && user) {
        markConversationAsRead(recipient.id, 'dm').catch(() => {});
      } else if (chatType === 'swarm' && swarm && user) {
        markConversationAsRead(swarm.id, 'swarm').catch(() => {});
      }
    } catch (err) {
      console.error('Error loading messages:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSend = async () => {
    if (!newMessage.trim() || sending) return;

    const messageText = newMessage.trim();
    setNewMessage('');
    setSending(true);

    try {
      if (chatType === 'direct' && recipient) {
        await messagesService.sendDMMessage(recipient.id, messageText);
      } else if (chatType === 'swarm' && swarm) {
        await messagesService.sendSwarmMessage(swarm.id, messageText);
      }
    } catch (err) {
      showError(err instanceof Error ? err.message : 'Failed to send message');
      setNewMessage(messageText);
    } finally {
      setSending(false);
    }
  };

  const handleDeleteMessage = async (messageId: string) => {
    setLongPressedMsg(null);
    if (!currentUserId) return;
    try {
      const { error } = await supabase
        .from('messages')
        .update({
          deleted_for_user_ids: supabase.rpc ? undefined : undefined,
        } as any)
        .eq('id', messageId);

      // Use raw SQL approach via rpc or direct array append
      await supabase.rpc('append_to_deleted_for', {
        message_id: messageId,
        user_id: currentUserId,
      }).then(({ error: rpcError }) => {
        if (rpcError) {
          // Fallback: fetch current array, append, update
          return supabase
            .from('messages')
            .select('deleted_for_user_ids')
            .eq('id', messageId)
            .maybeSingle()
            .then(({ data }) => {
              const existing: string[] = data?.deleted_for_user_ids || [];
              if (existing.includes(currentUserId)) return;
              return supabase
                .from('messages')
                .update({ deleted_for_user_ids: [...existing, currentUserId] })
                .eq('id', messageId);
            });
        }
      });

      setMessages((prev) => prev.filter((m) => m.id !== messageId));
      showSuccess('Message deleted.');
    } catch {
      showError('Could not delete message.');
    }
  };

  const handleDeleteChat = async () => {
    setShowDeleteChatConfirm(false);
    setShowChatMenu(false);
    if (!currentUserId) return;
    try {
      let query;
      if (chatType === 'direct' && recipient) {
        query = supabase
          .from('messages')
          .select('id, conversation_cleared_by')
          .or(`and(dm_user_a.eq.${currentUserId},dm_user_b.eq.${recipient.id}),and(dm_user_a.eq.${recipient.id},dm_user_b.eq.${currentUserId})`)
          .eq('conversation_type', 'dm');
      } else if (chatType === 'swarm' && swarm) {
        query = supabase
          .from('messages')
          .select('id, conversation_cleared_by')
          .eq('swarm_id', swarm.id)
          .eq('conversation_type', 'swarm');
      }

      if (!query) return;

      const { data: msgs } = await query;
      if (!msgs || msgs.length === 0) {
        setMessages([]);
        showSuccess('Chat cleared.');
        return;
      }

      const updates = msgs.map((msg: any) => {
        const existing: string[] = msg.conversation_cleared_by || [];
        return supabase
          .from('messages')
          .update({ conversation_cleared_by: existing.includes(currentUserId) ? existing : [...existing, currentUserId] })
          .eq('id', msg.id);
      });

      await Promise.all(updates);
      setMessages([]);
      showSuccess('Chat cleared for you.');
    } catch {
      showError('Could not clear chat.');
    }
  };

  const handleSendGift = async (item: VirtualItem, giftMessage: string) => {
    try {
      if (chatType === 'direct' && recipient) {
        await giftsService.sendGift(recipient.id, item.id, giftMessage, 'direct_message');
      } else if (chatType === 'swarm' && swarm) {
        const { data: swarmMembers } = await supabase
          .from('swarm_members')
          .select('user_id')
          .eq('swarm_id', swarm.id);

        const { data: { user } } = await supabase.auth.getUser();
        const otherMembers = (swarmMembers || []).filter(m => m.user_id !== user?.id);

        await Promise.all(
          otherMembers.map(m =>
            giftsService.sendGift(m.user_id, item.id, giftMessage, 'swarm', swarm.id)
          )
        );
      }
      setShowGiftModal(false);
      showSuccess('Gift sent!');
    } catch (err) {
      showError(err instanceof Error ? err.message : 'Failed to send gift');
    }
  };

  const handleSendMusic = async (song: Song, musicMessage: string) => {
    try {
      if (chatType === 'direct' && recipient) {
        await musicSharingService.shareMusic(
          recipient.id,
          {
            songId: song.id,
            songTitle: song.name,
            artistName: song.artist,
            platform: 'spotify',
            externalUrl: song.url,
            previewUrl: song.preview,
          },
          musicMessage
        );
      } else if (chatType === 'swarm' && swarm) {
        const { data: { user } } = await supabase.auth.getUser();
        if (user) {
          const { data: swarmMembers } = await supabase
            .from('swarm_members')
            .select('user_id')
            .eq('swarm_id', swarm.id);

          const otherMembers = (swarmMembers || []).filter(m => m.user_id !== user.id);

          await Promise.all(
            otherMembers.map(m =>
              musicSharingService.shareMusic(
                m.user_id,
                {
                  songId: song.id,
                  songTitle: song.name,
                  artistName: song.artist,
                  platform: 'spotify',
                  externalUrl: song.url,
                  previewUrl: song.preview,
                },
                musicMessage,
                swarm.id
              )
            )
          );
        }
      }
      setShowMusicModal(false);
      showSuccess('Song shared!');
    } catch (err) {
      showError(err instanceof Error ? err.message : 'Failed to send music');
    }
  };

  // Long press handlers
  const handleTouchStart = (messageId: string) => {
    longPressTimer.current = setTimeout(() => {
      setLongPressedMsg(messageId);
    }, 500);
  };

  const handleTouchEnd = () => {
    if (longPressTimer.current) clearTimeout(longPressTimer.current);
  };

  const formatTime = (date: Date) => date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  if (!isOpen) return null;

  const title = chatType === 'swarm' ? swarm?.name : recipient?.name;
  const subtitle = chatType === 'swarm' ? `${members.length} members` : recipient?.tonightStatus === 'going_out' ? 'Going out tonight' : 'Online';

  return (
    <div className="fixed inset-0 z-[2000] bg-[#FFF5F0] flex flex-col animate-slide-up">
      <div className="bg-white shadow-sm px-4 py-3 flex items-center gap-3">
        <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
          <ArrowLeft className="w-5 h-5 text-gray-700" />
        </button>

        <div className="flex-1 flex items-center gap-3">
          {chatType === 'direct' && recipient ? (
            <div className="w-10 h-10 rounded-full overflow-hidden border-2 border-gray-200">
              {recipient.avatar_url ? (
                <img src={recipient.avatar_url} alt={recipient.name} className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full bg-gradient-to-br from-pink-200 to-orange-200 flex items-center justify-center">
                  <User className="w-5 h-5 text-[#E91E63]" />
                </div>
              )}
            </div>
          ) : (
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#E91E63] to-[#FF6B6B] flex items-center justify-center">
              <Sparkles className="w-5 h-5 text-white" />
            </div>
          )}
          <div className="flex-1 min-w-0">
            <h2 className="font-semibold text-gray-900 truncate">{title}</h2>
            <p className="text-xs text-gray-500">{subtitle}</p>
          </div>
        </div>

        <div className="flex items-center gap-1">
          <button
            onClick={() => handleCallClick('audio')}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
            title="Voice call"
          >
            <Phone className="w-5 h-5 text-gray-600" />
          </button>
          <button
            onClick={() => handleCallClick('video')}
            className="p-2 hover:bg-gray-100 rounded-full transition-colors"
            title="Video call"
          >
            <Video className="w-5 h-5 text-gray-600" />
          </button>
          <div className="relative">
            <button
              onClick={() => setShowChatMenu(!showChatMenu)}
              className="p-2 hover:bg-gray-100 rounded-full transition-colors"
            >
              <MoreVertical className="w-5 h-5 text-gray-400" />
            </button>
            {showChatMenu && (
              <>
                <div className="fixed inset-0 z-10" onClick={() => setShowChatMenu(false)} />
                <div className="absolute right-0 top-10 z-20 bg-white rounded-xl shadow-xl border border-gray-100 py-1 min-w-[170px]">
                  <button
                    onClick={() => { setShowChatMenu(false); setShowDeleteChatConfirm(true); }}
                    className="w-full flex items-center gap-2 px-4 py-2.5 text-sm text-red-600 hover:bg-red-50 transition-colors"
                  >
                    <Trash size={15} className="text-red-400" />
                    Delete conversation
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-3 space-y-2 pb-20">
        {loading && messages.length === 0 ? (
          <div className="flex items-center justify-center h-full">
            <p className="text-gray-400">Loading messages...</p>
          </div>
        ) : messages.length === 0 ? (
          <div className="flex items-center justify-center h-full">
            <p className="text-gray-400">No messages yet. Start a conversation!</p>
          </div>
        ) : (
          messages.map((message, index) => {
          const showAvatar = !message.isMe && (index === 0 || messages[index - 1].isMe);
          const showName = !message.isMe && (index === 0 || messages[index - 1].senderId !== message.senderId);
          const isLongPressed = longPressedMsg === message.id;

          if (message.type === 'gift' && message.gift) {
            return (
              <div key={message.id} className={`flex ${message.isMe ? 'justify-end' : 'justify-start'}`}>
                <GiftCard
                  item={message.gift.item}
                  fromUserName={message.senderName}
                  fromUserAvatar={message.senderAvatar}
                  message={message.gift.message}
                  timestamp={message.timestamp.toISOString()}
                  status={message.gift.status}
                  reaction={message.gift.reaction}
                  isInChat={true}
                />
              </div>
            );
          }

          if (message.type === 'music' && message.music) {
            return (
              <div key={message.id} className={`flex ${message.isMe ? 'justify-end' : 'justify-start'}`}>
                <MusicShareCard
                  song={message.music.song}
                  fromUserName={message.senderName}
                  fromUserAvatar={message.senderAvatar}
                  message={message.music.message}
                  timestamp={message.timestamp.toISOString()}
                  status={message.music.status}
                  isInChat={true}
                />
              </div>
            );
          }

          return (
            <div
              key={message.id}
              className={`flex flex-col ${message.isMe ? 'items-end' : 'items-start'}`}
            >
              {!message.isMe && showName && (
                <p className="text-xs font-semibold text-gray-600 mb-1 pl-2">{message.senderName}</p>
              )}
              <div className={`flex items-end gap-2 ${message.isMe ? 'justify-end' : 'justify-start'} relative`}>
                {!message.isMe && showAvatar && message.senderAvatar ? (
                  <img src={message.senderAvatar} alt="" className="w-8 h-8 rounded-full object-cover" />
                ) : !message.isMe && showAvatar ? (
                  <div className="w-8 h-8 rounded-full bg-gradient-to-br from-pink-200 to-orange-200 flex items-center justify-center">
                    <User className="w-4 h-4 text-[#E91E63]" />
                  </div>
                ) : !message.isMe ? (
                  <div className="w-8" />
                ) : null}

                <div
                  className={`relative group max-w-[80%] px-3 py-2 select-none ${
                    message.isMe
                      ? 'bg-gradient-to-br from-[#E91E63] to-[#FF6B6B] text-white rounded-2xl rounded-br-md shadow-md'
                      : 'bg-white text-gray-900 rounded-2xl rounded-bl-md shadow-sm border border-gray-100'
                  } ${isLongPressed ? 'scale-95 opacity-80' : ''} transition-all`}
                  onTouchStart={() => handleTouchStart(message.id)}
                  onTouchEnd={handleTouchEnd}
                  onTouchCancel={handleTouchEnd}
                  onContextMenu={(e) => { e.preventDefault(); setLongPressedMsg(message.id); }}
                >
                  <p className="text-sm leading-snug break-words">{message.text}</p>
                  <p className={`text-[10px] mt-1 ${message.isMe ? 'text-white/70' : 'text-gray-400'}`}>
                    {formatTime(message.timestamp)}
                  </p>
                  {message.isMe && (
                    <button
                      onClick={() => handleDeleteMessage(message.id)}
                      className="absolute -top-2 -right-2 w-6 h-6 bg-gray-800/80 rounded-full items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity hidden md:flex"
                      title="Delete message"
                    >
                      <X className="w-3 h-3 text-white" />
                    </button>
                  )}
                </div>

                {message.isMe && (
                  <button
                    onClick={() => handleDeleteMessage(message.id)}
                    className="p-1.5 rounded-full hover:bg-red-50 transition-colors opacity-0 group-hover:opacity-100 flex-shrink-0 hidden md:block"
                  >
                    <Trash2 size={14} className="text-gray-300 hover:text-red-400" />
                  </button>
                )}
              </div>

              {isLongPressed && (
                <div
                  className={`mt-1.5 flex items-center gap-1 ${message.isMe ? 'justify-end pr-2' : 'justify-start pl-10'}`}
                >
                  <button
                    onClick={() => handleDeleteMessage(message.id)}
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-red-50 border border-red-200 text-red-600 rounded-full text-xs font-medium hover:bg-red-100 transition-colors shadow-sm"
                  >
                    <Trash2 size={12} />
                    Delete
                  </button>
                  <button
                    onClick={() => setLongPressedMsg(null)}
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-50 border border-gray-200 text-gray-600 rounded-full text-xs font-medium hover:bg-gray-100 transition-colors shadow-sm"
                  >
                    Cancel
                  </button>
                </div>
              )}
            </div>
          );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      <div className="bg-white border-t border-gray-200 p-2 pb-3 safe-area-bottom">
        <div className="flex items-center gap-1.5">
          <button
            onClick={() => setShowGiftModal(true)}
            className="p-2.5 bg-gradient-to-br from-pink-500 to-rose-600 text-white rounded-xl hover:shadow-lg transition-all flex-shrink-0"
            title="Send a gift"
          >
            <Gift className="w-4 h-4" />
          </button>
          <button
            onClick={() => setShowMusicModal(true)}
            className="p-2.5 bg-gradient-to-br from-blue-500 to-blue-700 text-white rounded-xl hover:shadow-lg transition-all flex-shrink-0"
            title="Send a song"
          >
            <Music className="w-4 h-4" />
          </button>
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSend()}
            placeholder="Type a message..."
            className="flex-1 px-3 py-2 bg-gray-100 rounded-xl border border-gray-200 focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all text-sm text-gray-900 placeholder:text-gray-400"
          />
          <button
            onClick={handleSend}
            disabled={!newMessage.trim() || sending}
            className="p-2.5 bg-gradient-to-br from-[#E91E63] to-[#FF6B6B] text-white rounded-xl hover:shadow-lg transition-all disabled:opacity-40 disabled:cursor-not-allowed flex-shrink-0"
          >
            <Send className={`w-4 h-4 ${sending ? 'animate-pulse' : ''}`} />
          </button>
        </div>
      </div>

      {chatType === 'direct' && recipient && (
        <>
          <SendMusicModal
            isOpen={showMusicModal}
            onClose={() => setShowMusicModal(false)}
            recipientId={recipient.id}
            recipientName={recipient.name}
            onSendMusic={handleSendMusic}
          />
          <VirtualItemsModal
            isOpen={showGiftModal}
            onClose={() => setShowGiftModal(false)}
            recipientId={recipient.id}
            recipientName={recipient.name}
            onSend={handleSendGift}
          />
        </>
      )}
      {chatType === 'swarm' && swarm && (
        <>
          <SendMusicModal
            isOpen={showMusicModal}
            onClose={() => setShowMusicModal(false)}
            recipientId={swarm.id}
            recipientName={swarm.name}
            onSendMusic={handleSendMusic}
          />
          <VirtualItemsModal
            isOpen={showGiftModal}
            onClose={() => setShowGiftModal(false)}
            recipientId={swarm.id}
            recipientName={swarm.name}
            onSend={handleSendGift}
          />
        </>
      )}

      {showCallModal && (
        <div className="fixed inset-0 z-[3000] flex items-end justify-center bg-black/50 animate-fade-in" onClick={() => setShowCallModal(false)}>
          <div
            className="w-full max-w-sm bg-white rounded-t-3xl pb-safe overflow-hidden shadow-2xl animate-slide-up"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between px-6 pt-5 pb-3 border-b border-gray-100">
              <div>
                <h3 className="font-bold text-gray-900 text-base">
                  {callType === 'video' ? 'Video Call' : 'Voice Call'}
                </h3>
                <p className="text-sm text-gray-500 mt-0.5">
                  Call {chatType === 'direct' ? recipient?.name : swarm?.name} via
                </p>
              </div>
              <button
                onClick={() => setShowCallModal(false)}
                className="p-2 hover:bg-gray-100 rounded-full transition-colors"
              >
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>

            <div className="p-4 space-y-3">
              <button
                onClick={() => handleCallOption('whatsapp')}
                className="w-full flex items-center gap-4 p-4 rounded-2xl bg-[#25D366]/10 hover:bg-[#25D366]/20 border border-[#25D366]/20 transition-all group"
              >
                <div className="w-12 h-12 rounded-2xl bg-[#25D366] flex items-center justify-center shadow-md group-hover:scale-105 transition-transform">
                  <svg className="w-6 h-6 text-white" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                  </svg>
                </div>
                <div className="text-left">
                  <p className="font-semibold text-gray-900">WhatsApp</p>
                  <p className="text-sm text-gray-500">{callType === 'video' ? 'Video' : 'Voice'} call via WhatsApp</p>
                </div>
              </button>

              <button
                onClick={() => handleCallOption('messenger')}
                className="w-full flex items-center gap-4 p-4 rounded-2xl bg-[#0084FF]/10 hover:bg-[#0084FF]/20 border border-[#0084FF]/20 transition-all group"
              >
                <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#0084FF] to-[#00A3FF] flex items-center justify-center shadow-md group-hover:scale-105 transition-transform">
                  <MessageCircle className="w-6 h-6 text-white" />
                </div>
                <div className="text-left">
                  <p className="font-semibold text-gray-900">Messenger</p>
                  <p className="text-sm text-gray-500">{callType === 'video' ? 'Video' : 'Voice'} call via Facebook Messenger</p>
                </div>
              </button>

              <button
                onClick={() => handleCallOption('facetime')}
                className="w-full flex items-center gap-4 p-4 rounded-2xl bg-[#34C759]/10 hover:bg-[#34C759]/20 border border-[#34C759]/20 transition-all group"
              >
                <div className="w-12 h-12 rounded-2xl bg-[#34C759] flex items-center justify-center shadow-md group-hover:scale-105 transition-transform">
                  <Video className="w-6 h-6 text-white" />
                </div>
                <div className="text-left">
                  <p className="font-semibold text-gray-900">FaceTime</p>
                  <p className="text-sm text-gray-500">{callType === 'video' ? 'Video' : 'Audio'} call via FaceTime (iOS only)</p>
                </div>
              </button>
            </div>

            <div className="px-4 pb-6">
              <p className="text-xs text-center text-gray-400">
                Opens your preferred app to connect with {chatType === 'direct' ? recipient?.name : 'swarm members'}
              </p>
            </div>
          </div>
        </div>
      )}

      {showDeleteChatConfirm && (
        <div className="fixed inset-0 z-[3000] flex items-center justify-center px-4">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setShowDeleteChatConfirm(false)} />
          <div className="relative bg-white rounded-2xl p-6 w-full max-w-sm shadow-2xl">
            <div className="flex items-center gap-3 mb-3">
              <div className="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center flex-shrink-0">
                <Trash size={22} className="text-red-600" />
              </div>
              <div>
                <h3 className="font-bold text-gray-900">Delete conversation?</h3>
                <p className="text-sm text-gray-500">This clears the chat only for you.</p>
              </div>
            </div>
            <p className="text-xs text-gray-400 mb-5">The other participant{chatType === 'swarm' ? 's' : ''} will still see all messages.</p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowDeleteChatConfirm(false)}
                className="flex-1 py-3 rounded-xl border-2 border-gray-200 text-gray-700 font-medium hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleDeleteChat}
                className="flex-1 py-3 rounded-xl bg-red-600 text-white font-medium hover:bg-red-700 transition-colors"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}

      {longPressedMsg && (
        <div
          className="fixed inset-0 z-[2500]"
          onClick={() => setLongPressedMsg(null)}
        />
      )}
    </div>
  );
}
