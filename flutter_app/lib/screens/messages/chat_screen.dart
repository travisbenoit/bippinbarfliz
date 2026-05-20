import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/analytics_service.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../utils/app_error.dart';
import '../../services/notification_sender.dart';
import '../../widgets/app_loader.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String body;
  final DateTime createdAt;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.body,
    required this.createdAt,
    required this.isMe,
  });
}

class ChatScreen extends ConsumerStatefulWidget {
  final String userId;

  const ChatScreen({super.key, required this.userId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _supabase = Supabase.instance.client;

  List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _error;
  bool _isBlocked = false;
  String _otherUserName = 'Chat';
  String? _otherUserAvatar;
  String _myName = '';
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOtherUser() async {
    final currentUser = _supabase.auth.currentUser;
    final (other, me) = await (
      _supabase
          .from('users')
          .select('name, avatar_url')
          .eq('id', widget.userId)
          .maybeSingle(),
      currentUser != null
          ? _supabase
              .from('users')
              .select('name')
              .eq('id', currentUser.id)
              .maybeSingle()
          : Future<Map<String, dynamic>?>.value(null),
    ).wait;

    if (!mounted) return;
    setState(() {
      _otherUserName = (other?['name'] as String?) ?? 'Unknown';
      _otherUserAvatar = other?['avatar_url'] as String?;
      _myName = ((me?['name'] as String?) ?? '').trim();
    });
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      await _loadOtherUser();

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = ref.read(tProvider)(AppStrings.chatNotLoggedIn);
          _loading = false;
        });
        return;
      }

      // Check blocks in either direction
      final blockRows = await _supabase
          .from('user_blocks')
          .select('id')
          .or('and(blocker_id.eq.${currentUser.id},blocked_id.eq.${widget.userId}),and(blocker_id.eq.${widget.userId},blocked_id.eq.${currentUser.id})')
          .limit(1);
      if (mounted) {
        setState(() => _isBlocked = (blockRows as List).isNotEmpty);
      }
      if (_isBlocked) {
        setState(() => _loading = false);
        return;
      }

      final userIds = [currentUser.id, widget.userId]..sort();
      final userA = userIds[0];
      final userB = userIds[1];

      final response = await _supabase
          .from('messages')
          .select('''
            id,
            sender_user_id,
            body,
            created_at
          ''')
          .eq('conversation_type', 'dm')
          .eq('dm_user_a', userA)
          .eq('dm_user_b', userB)
          .order('created_at', ascending: true)
          .limit(100);

      final messages = (response as List).map((msg) {
        return ChatMessage(
          id: msg['id'],
          senderId: msg['sender_user_id'],
          senderName: msg['sender_user_id'] == currentUser.id
              ? ref.read(tProvider)(AppStrings.messagesYou)
              : _otherUserName,
          senderAvatar:
              msg['sender_user_id'] == currentUser.id ? null : _otherUserAvatar,
          body: msg['body'] ?? '',
          createdAt: DateTime.parse(msg['created_at']),
          isMe: msg['sender_user_id'] == currentUser.id,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _messages = messages;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e, stackTrace: st, tag: 'Chat.loadMessages');
          _loading = false;
        });
      }
    }
  }

  void _setupRealtimeSubscription() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    final userIds = [currentUser.id, widget.userId]..sort();
    final userA = userIds[0];
    final userB = userIds[1];

    _supabase
        .channel('chat:$userA:$userB')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newMsg = payload.newRecord;
            if (newMsg['conversation_type'] == 'dm' &&
                newMsg['dm_user_a'] == userA &&
                newMsg['dm_user_b'] == userB) {
              final message = ChatMessage(
                id: newMsg['id'],
                senderId: newMsg['sender_user_id'],
                senderName: newMsg['sender_user_id'] == currentUser.id
                    ? ref.read(tProvider)(AppStrings.messagesYou)
                    : _otherUserName,
                senderAvatar: newMsg['sender_user_id'] == currentUser.id
                    ? null
                    : _otherUserAvatar,
                body: newMsg['body'] ?? '',
                createdAt: DateTime.parse(newMsg['created_at']),
                isMe: newMsg['sender_user_id'] == currentUser.id,
              );

              if (mounted && !_messages.any((m) => m.id == message.id)) {
                setState(() {
                  _messages.add(message);
                });
                _scrollToBottom();
              }
            }
          },
        )
        .subscribe();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      final userIds = [currentUser.id, widget.userId]..sort();

      await _supabase.from('messages').insert({
        'conversation_type': 'dm',
        'dm_user_a': userIds[0],
        'dm_user_b': userIds[1],
        'sender_user_id': currentUser.id,
        'body': text,
      });
      AnalyticsService.instance.messageSent();
      NotificationSender.messageSent(
        toUserId: widget.userId,
        senderName: _myName.isEmpty ? 'Someone' : _myName,
        messagePreview: text.length > 80 ? '${text.substring(0, 80)}…' : text,
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e, tag: 'Chat.sendMessage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE91E63).withOpacity(0.1),
              backgroundImage: _otherUserAvatar != null
                  ? NetworkImage(_otherUserAvatar!)
                  : null,
              child: _otherUserAvatar == null
                  ? const Icon(Icons.person, size: 18, color: Color(0xFFE91E63))
                  : null,
            ),
            const SizedBox(width: 12),
            Text(_otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          if (_isBlocked) _buildBlockedBanner() else _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final t = ref.read(tProvider);
    if (_loading) {
      return const AppFullLoader();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('${t(AppStrings.error)}: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: Text(t(AppStrings.retry)),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
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
              t(AppStrings.chatNoMsgYet),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_otherUserName!',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _MessageBubble(message: message);
      },
    );
  }

  Widget _buildBlockedBanner() {
    final t = ref.read(tProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Text(
              t(AppStrings.chatBlockedBanner),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final t = ref.read(tProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: t(AppStrings.chatTypeMsg),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE91E63).withOpacity(0.1),
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null
                  ? const Icon(Icons.person, size: 16, color: Color(0xFFE91E63))
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isMe
                    ? const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)],
                      )
                    : null,
                color:
                    message.isMe ? null : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isMe ? 20 : 4),
                  bottomRight: Radius.circular(message.isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.body,
                    style: TextStyle(
                      color: message.isMe
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: message.isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
