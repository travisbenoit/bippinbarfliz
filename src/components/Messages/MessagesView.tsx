import { useState, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { Search, MessageCircle, User, Sparkles, SquarePen as PenSquare } from 'lucide-react';
import ChatView from './ChatView';
import NewChatModal from './NewChatModal';
import { ErrorBoundary } from '../ErrorBoundary';
import { messagesService } from '../../services/messagesService';
import { supabase } from '../../lib/supabase';
import { useToast } from '../../contexts/ToastContext';

interface Conversation {
  id: string;
  type: 'direct' | 'swarm';
  name: string;
  avatar_url: string | null;
  lastMessage: string;
  lastMessageTime: string;
  unread: boolean;
  userId?: string;
  swarmId?: string;
  memberCount?: number;
}

interface SwarmWithLastMessage {
  id: string;
  title: string;
  vibe_tags: string[];
  status: string;
  lastMessage?: string;
  lastMessageTime?: string;
  memberCount?: number;
}

function formatTimeAgo(date: Date): string {
  const now = new Date();
  const diff = now.getTime() - date.getTime();
  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);

  if (minutes < 1) return 'now';
  if (minutes < 60) return `${minutes}m`;
  if (hours < 24) return `${hours}h`;
  return `${days}d`;
}

export default function MessagesView() {
  const { showError } = useToast();
  const location = useLocation();
  const [searchQuery, setSearchQuery] = useState('');
  const [activeChat, setActiveChat] = useState<Conversation | null>(null);
  const [directChatUser, setDirectChatUser] = useState<{ id: string; name: string; avatar_url: string | null } | null>(null);
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [swarmConversations, setSwarmConversations] = useState<Conversation[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const [newChatOpen, setNewChatOpen] = useState(false);

  useEffect(() => {
    loadConversations();
  }, []);

  useEffect(() => {
    const state = location.state as { openDmWith?: string; dmUserName?: string; dmUserAvatar?: string | null; openSwarmChat?: string; swarmName?: string } | null;
    if (state?.openDmWith) {
      setDirectChatUser({
        id: state.openDmWith,
        name: state.dmUserName || 'User',
        avatar_url: state.dmUserAvatar ?? null,
      });
      window.history.replaceState({}, '');
    }
    if (state?.openSwarmChat) {
      const swarmId = state.openSwarmChat;
      const swarmName = state.swarmName || 'Swarm';
      const existing = swarmConversations.find(s => s.swarmId === swarmId);
      setActiveChat(existing ?? {
        id: swarmId,
        type: 'swarm',
        name: swarmName,
        avatar_url: null,
        lastMessage: '',
        lastMessageTime: '',
        unread: false,
        swarmId,
      });
      window.history.replaceState({}, '');
    }
  }, [location.state, swarmConversations]);

  useEffect(() => {
    const subscription = messagesService.subscribeToAllMessages(() => {
      loadConversations();
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const loadConversations = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;
      setCurrentUserId(user.id);

      const [dmConversations, swarmData] = await Promise.all([
        messagesService.getDMConversations(),
        loadSwarmConversations(user.id),
      ]);

      const formattedDMs: Conversation[] = dmConversations.map((msg: any) => {
        const otherId = msg.otherUserId;
        const isUnread = msg.read_at === null && msg.sender_user_id !== user.id;

        return {
          id: `dm-${otherId}`,
          type: 'direct' as const,
          name: msg.otherUser?.name || 'Unknown User',
          avatar_url: msg.otherUser?.avatar_url || null,
          lastMessage: msg.body || '',
          lastMessageTime: formatTimeAgo(new Date(msg.created_at)),
          unread: isUnread,
          userId: otherId,
          tonightStatus: msg.otherUser?.tonight_status || null,
        };
      });

      setConversations(formattedDMs);
      setSwarmConversations(swarmData);
    } catch (err) {
      console.error('Error loading conversations:', err);
      showError('Could not load conversations. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const loadSwarmConversations = async (userId: string): Promise<Conversation[]> => {
    try {
      const { data: memberRows } = await supabase
        .from('swarm_members')
        .select('swarm_id')
        .eq('user_id', userId);

      if (!memberRows || memberRows.length === 0) return [];

      const swarmIds = memberRows.map((r) => r.swarm_id);

      const [{ data: swarms }, { data: allMembers }, { data: lastMessages }] = await Promise.all([
        supabase
          .from('swarms')
          .select('id, title, vibe_tags, status')
          .in('id', swarmIds)
          .eq('status', 'active'),
        supabase
          .from('swarm_members')
          .select('swarm_id')
          .in('swarm_id', swarmIds),
        supabase
          .from('messages')
          .select('swarm_id, body, created_at, sender_user_id, read_at')
          .eq('conversation_type', 'swarm')
          .in('swarm_id', swarmIds)
          .is('deleted_at', null)
          .order('created_at', { ascending: false }),
      ]);

      if (!swarms || swarms.length === 0) return [];

      const memberCountMap = new Map<string, number>();
      (allMembers || []).forEach((m) => {
        memberCountMap.set(m.swarm_id, (memberCountMap.get(m.swarm_id) || 0) + 1);
      });

      const lastMsgMap = new Map<string, typeof lastMessages extends (infer T)[] | null ? T : never>();
      (lastMessages || []).forEach((msg) => {
        if (msg.swarm_id && !lastMsgMap.has(msg.swarm_id)) {
          lastMsgMap.set(msg.swarm_id, msg);
        }
      });

      return swarms.map((swarm) => {
        const lastMsg = lastMsgMap.get(swarm.id);
        const isUnread = lastMsg
          ? lastMsg.read_at === null && lastMsg.sender_user_id !== userId
          : false;

        return {
          id: `swarm-${swarm.id}`,
          type: 'swarm' as const,
          name: swarm.title,
          avatar_url: null,
          lastMessage: lastMsg?.body || 'No messages yet',
          lastMessageTime: lastMsg ? formatTimeAgo(new Date(lastMsg.created_at)) : '',
          unread: isUnread,
          swarmId: swarm.id,
          memberCount: memberCountMap.get(swarm.id) || 0,
        };
      });
    } catch (err) {
      console.error('Error loading swarm conversations:', err);
      return [];
    }
  };

  const allConversations = [...swarmConversations, ...conversations];

  const filtered = allConversations.filter((conv) =>
    conv.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredSwarms = filtered.filter(c => c.type === 'swarm');
  const filteredDMs = filtered.filter(c => c.type === 'direct');

  const getChatRecipient = () => {
    if (activeChat?.type === 'direct' && activeChat.userId) {
      const dbUser = conversations.find(c => c.userId === activeChat.userId);
      if (dbUser) {
        const status = (dbUser as any).tonightStatus;
        const mapped = status === 'out_now' ? 'going_out' : status === 'going_out_soon' ? 'maybe' : 'staying_in';
        return {
          id: activeChat.userId,
          name: dbUser.name,
          avatar_url: dbUser.avatar_url,
          tonightStatus: mapped as 'going_out' | 'maybe' | 'staying_in',
        };
      }
    }
    return undefined;
  };

  const getChatSwarm = () => {
    if (activeChat?.type === 'swarm' && activeChat.swarmId) {
      const swarmConv = swarmConversations.find(s => s.swarmId === activeChat.swarmId);
      if (swarmConv) {
        return {
          id: swarmConv.swarmId!,
          name: swarmConv.name,
          title: swarmConv.name,
          venueName: '',
          memberCount: swarmConv.memberCount || 0,
          vibe_tags: [],
          description: null,
          venue_id: null,
          host_id: '',
          start_time: '',
          end_time: null,
          max_attendees: swarmConv.memberCount || 0,
          status: 'active' as const,
          is_public: true,
          created_at: '',
          updated_at: '',
        };
      }
    }
    return undefined;
  };

  return (
    <div className="h-full flex flex-col bg-[#FFF5F0]">
      <div className="bg-white shadow-sm p-5 space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Messages</h1>
          <button
            onClick={() => setNewChatOpen(true)}
            className="flex items-center gap-2 px-4 py-2 bg-[#E91E63] text-white rounded-xl text-sm font-semibold hover:bg-[#C2185B] active:scale-95 transition-all shadow-md shadow-[#E91E63]/20"
          >
            <PenSquare size={16} />
            New Chat
          </button>
        </div>
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
          <input
            type="text"
            placeholder="Search conversations..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-11 pr-4 py-3 bg-gray-100 rounded-xl border border-gray-200 focus:border-[#E91E63] focus:ring-2 focus:ring-[#E91E63]/20 outline-none transition-all text-gray-900 placeholder:text-gray-400"
          />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto">
        {loading ? (
          <div className="flex items-center justify-center h-full p-8">
            <div className="text-center space-y-4">
              <div className="w-12 h-12 border-4 border-[#E91E63]/30 border-t-[#E91E63] rounded-full animate-spin mx-auto" />
              <p className="text-gray-500">Loading conversations...</p>
            </div>
          </div>
        ) : filtered.length === 0 ? (
          <div className="flex items-center justify-center h-full p-8">
            <div className="text-center space-y-5">
              <div className="w-20 h-20 rounded-full bg-[#E91E63]/10 flex items-center justify-center mx-auto">
                <MessageCircle size={40} className="text-[#E91E63]/40" />
              </div>
              <div>
                <p className="text-xl font-bold text-gray-900">
                  {searchQuery ? 'No conversations match' : 'No messages yet'}
                </p>
                <p className="text-gray-500 mt-2">
                  {searchQuery
                    ? 'Try a different search'
                    : 'Start a conversation with a friend or join a swarm!'}
                </p>
              </div>
              {!searchQuery && (
                <button
                  onClick={() => setNewChatOpen(true)}
                  className="inline-flex items-center gap-2 px-6 py-3 bg-[#E91E63] text-white rounded-xl font-semibold hover:bg-[#C2185B] transition-colors shadow-lg shadow-[#E91E63]/20"
                >
                  <PenSquare size={18} />
                  Start a Conversation
                </button>
              )}
            </div>
          </div>
        ) : (
          <div>
            {filteredSwarms.length > 0 && (
              <div>
                <div className="px-5 py-3 bg-gray-50">
                  <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wider flex items-center gap-2">
                    <Sparkles className="w-3.5 h-3.5" />
                    Swarm Chats
                  </h2>
                </div>
                <div className="divide-y divide-gray-100 bg-white">
                  {filteredSwarms.map((conv) => (
                    <button
                      key={conv.id}
                      onClick={() => setActiveChat(conv)}
                      className="w-full p-4 flex items-center gap-3 hover:bg-gray-50 transition-colors"
                    >
                      <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[#E91E63] to-[#FF6B6B] flex items-center justify-center flex-shrink-0 shadow-md">
                        <Sparkles className="w-6 h-6 text-white" />
                      </div>
                      <div className="flex-1 text-left min-w-0">
                        <div className="flex items-center justify-between mb-1">
                          <h3 className="font-semibold text-gray-900 truncate">{conv.name}</h3>
                          <span className={`text-xs ml-2 ${conv.unread ? 'text-[#E91E63]' : 'text-gray-400'}`}>
                            {conv.lastMessageTime}
                          </span>
                        </div>
                        <p className={`text-sm truncate ${conv.unread ? 'text-gray-700' : 'text-gray-500'}`}>
                          {conv.lastMessage}
                        </p>
                        <p className="text-xs text-gray-400 mt-0.5">{conv.memberCount} members</p>
                      </div>
                      {conv.unread && (
                        <div className="w-2.5 h-2.5 bg-[#E91E63] rounded-full flex-shrink-0" />
                      )}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {filteredDMs.length > 0 && (
              <div>
                <div className="px-5 py-3 bg-gray-50">
                  <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wider flex items-center gap-2">
                    <User className="w-3.5 h-3.5" />
                    Direct Messages
                  </h2>
                </div>
                <div className="divide-y divide-gray-100 bg-white">
                  {filteredDMs.map((conv) => (
                    <button
                      key={conv.id}
                      onClick={() => setActiveChat(conv)}
                      className="w-full p-4 flex items-center gap-3 hover:bg-gray-50 transition-colors"
                    >
                      <div className="w-14 h-14 rounded-full overflow-hidden flex-shrink-0 border-2 border-gray-200">
                        {conv.avatar_url ? (
                          <img src={conv.avatar_url} alt={conv.name} className="w-full h-full object-cover" />
                        ) : (
                          <div className="w-full h-full bg-gradient-to-br from-pink-200 to-orange-200 flex items-center justify-center">
                            <User className="w-6 h-6 text-[#E91E63]" />
                          </div>
                        )}
                      </div>
                      <div className="flex-1 text-left min-w-0">
                        <div className="flex items-center justify-between mb-1">
                          <h3 className="font-semibold text-gray-900 truncate">{conv.name}</h3>
                          <span className={`text-xs ml-2 ${conv.unread ? 'text-[#E91E63]' : 'text-gray-400'}`}>
                            {conv.lastMessageTime}
                          </span>
                        </div>
                        <p className={`text-sm truncate ${conv.unread ? 'text-gray-700' : 'text-gray-500'}`}>
                          {conv.lastMessage}
                        </p>
                      </div>
                      {conv.unread && (
                        <div className="w-2.5 h-2.5 bg-[#E91E63] rounded-full flex-shrink-0" />
                      )}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      <ErrorBoundary fallbackLabel="Chat failed to load">
        <ChatView
          isOpen={!!activeChat || !!directChatUser}
          onClose={() => {
            setActiveChat(null);
            setDirectChatUser(null);
            loadConversations();
          }}
          chatType={activeChat?.type || 'direct'}
          recipient={directChatUser ? {
            id: directChatUser.id,
            name: directChatUser.name,
            avatar_url: directChatUser.avatar_url,
          } : getChatRecipient()}
          swarm={getChatSwarm()}
          members={[]}
        />
      </ErrorBoundary>

      <NewChatModal
        isOpen={newChatOpen}
        onClose={() => setNewChatOpen(false)}
        onStartChat={(user) => {
          setDirectChatUser(user);
          setNewChatOpen(false);
        }}
      />
    </div>
  );
}
