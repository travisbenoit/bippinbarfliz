import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';

class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isUnread;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isUnread,
  });
}

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return [];

  final response = await supabase
      .from('messages')
      .select('''
        id,
        dm_user_a,
        dm_user_b,
        sender_user_id,
        body,
        created_at,
        read_at
      ''')
      .eq('conversation_type', 'dm')
      .or('dm_user_a.eq.${currentUser.id},dm_user_b.eq.${currentUser.id}')
      .order('created_at', ascending: false);

  final messages = response as List;
  final conversationMap = <String, Map<String, dynamic>>{};

  for (final msg in messages) {
    final otherUserId = msg['dm_user_a'] == currentUser.id
        ? msg['dm_user_b']
        : msg['dm_user_a'];

    if (!conversationMap.containsKey(otherUserId)) {
      conversationMap[otherUserId] = msg;
    }
  }

  final conversations = <Conversation>[];
  for (final entry in conversationMap.entries) {
    final otherUserId = entry.key;
    final msg = entry.value;

    final userResponse = await supabase
        .from('users')
        .select('name, avatar_url')
        .eq('id', otherUserId)
        .maybeSingle();

    conversations.add(Conversation(
      id: msg['id'],
      otherUserId: otherUserId,
      otherUserName: userResponse?['name'] ?? 'Unknown User',
      otherUserAvatar: userResponse?['avatar_url'],
      lastMessage: msg['body'] ?? '',
      lastMessageTime: DateTime.parse(msg['created_at']),
      isUnread: msg['read_at'] == null && msg['sender_user_id'] != currentUser.id,
    ));
  }

  conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
  return conversations;
});

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(AppStrings.messagesTitle)),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: conversationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFE91E63)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('${t(AppStrings.error)}: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(conversationsProvider),
                child: Text(t(AppStrings.retry)),
              ),
            ],
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 40,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t(AppStrings.messagesNoMsgYet),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(AppStrings.messagesStartConvo),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(conversationsProvider);
            },
            color: const Color(0xFFE91E63),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return _ConversationTile(conversation: conv);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFFE91E63).withOpacity(0.1),
        backgroundImage: conversation.otherUserAvatar != null
            ? NetworkImage(conversation.otherUserAvatar!)
            : null,
        child: conversation.otherUserAvatar == null
            ? const Icon(Icons.person, color: Color(0xFFE91E63))
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.otherUserName,
              style: TextStyle(
                fontWeight: conversation.isUnread
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
          Text(
            timeago.format(conversation.lastMessageTime, locale: 'en_short'),
            style: TextStyle(
              fontSize: 12,
              color: conversation.isUnread
                  ? const Color(0xFFE91E63)
                  : Colors.grey[500],
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: conversation.isUnread ? Colors.black87 : Colors.grey[600],
                fontWeight: conversation.isUnread
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ),
          if (conversation.isUnread)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFE91E63),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () => context.push('/chat/${conversation.otherUserId}'),
    );
  }
}
