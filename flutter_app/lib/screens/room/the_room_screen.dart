import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/analytics_service.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../extensions/localization_extension.dart';
import '../../utils/app_error.dart';
import '../../widgets/app_loader.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class _RoomMessage {
  final String id;
  final String userId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final String? userName;

  _RoomMessage({
    required this.id,
    required this.userId,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.userName,
  });
}

class _PresenceUser {
  final String userId;
  final String name;
  final String? avatarUrl;
  final String? tonightStatus;

  _PresenceUser({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.tonightStatus,
  });
}

class _WallPhoto {
  final String id;
  final String? photoUrl;
  final String? caption;
  final int likesCount;
  final DateTime createdAt;

  _WallPhoto({
    required this.id,
    this.photoUrl,
    this.caption,
    required this.likesCount,
    required this.createdAt,
  });
}

class _VibePoll {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, dynamic> votes;

  _VibePoll({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
  });
}

class _Moment {
  final String id;
  final String content;
  final String type;
  final DateTime createdAt;

  _Moment({
    required this.id,
    required this.content,
    required this.type,
    required this.createdAt,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TheRoomScreen extends ConsumerStatefulWidget {
  final String venueId;
  final String? venueName;

  const TheRoomScreen({
    super.key,
    required this.venueId,
    this.venueName,
  });

  @override
  ConsumerState<TheRoomScreen> createState() => _TheRoomScreenState();
}

class _TheRoomScreenState extends ConsumerState<TheRoomScreen>
    with SingleTickerProviderStateMixin {
  static const _brandColor = Color(0xFFE91E63);

  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  // Chat state
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  List<_RoomMessage> _messages = [];
  bool _chatLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _chatSub;

  // Who's here state
  List<_PresenceUser> _presenceUsers = [];
  bool _presenceLoading = true;
  bool _checkingIn = false;

  // Photo wall state
  List<_WallPhoto> _wallPhotos = [];
  bool _photosLoading = true;

  // Vibe state
  _VibePoll? _currentPoll;
  bool _vibeLoading = true;
  String? _selectedPollOption;
  bool _submittingVote = false;
  final _momentController = TextEditingController();
  bool _postingMoment = false;
  List<_Moment> _moments = [];

  int get _peopleCount => _presenceUsers.length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        switch (_tabController.index) {
          case 1:
            _loadPresence();
          case 2:
            _loadWallPhotos();
          case 3:
            _loadVibe();
        }
      }
    });
    _loadChat();
    _loadPresence();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    _momentController.dispose();
    _chatSub?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  void _loadChat() {
    setState(() => _chatLoading = true);

    final stream = _supabase
        .from('venue_room_messages')
        .stream(primaryKey: ['id']).eq('venue_id', widget.venueId);

    _chatSub = stream.listen((data) async {
      final msgs = await Future.wait(data.map((row) async {
        String? userName;
        try {
          final user = await _supabase
              .from('users')
              .select('name')
              .eq('id', row['user_id'] as String)
              .maybeSingle();
          userName = user?['name'] as String?;
        } catch (_) {}

        return _RoomMessage(
          id: row['id'] as String,
          userId: row['user_id'] as String,
          content: row['content'] as String? ?? '',
          messageType: row['message_type'] as String? ?? 'text',
          createdAt: DateTime.parse(row['created_at'] as String),
          userName: userName,
        );
      }));

      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (mounted) {
        setState(() {
          _messages = msgs;
          _chatLoading = false;
        });
        _scrollToBottom();
      }
    }, onError: (_) {
      if (mounted) setState(() => _chatLoading = false);
    });
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
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('venue_room_messages').insert({
        'venue_id': widget.venueId,
        'user_id': user.id,
        'content': text,
        'message_type': 'text',
      });
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e, tag: 'Room.sendMessage');
    }
  }

  // ---------------------------------------------------------------------------
  // Presence
  // ---------------------------------------------------------------------------

  Future<void> _loadPresence() async {
    if (mounted) setState(() => _presenceLoading = true);

    try {
      final cutoff =
          DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String();

      final rows = await _supabase
          .from('venue_room_presence')
          .select('user_id')
          .eq('venue_id', widget.venueId)
          .gt('last_seen_at', cutoff);

      final users = await Future.wait(
        (rows as List).map((row) async {
          try {
            final user = await _supabase
                .from('users')
                .select('id, name, avatar_url, tonight_status')
                .eq('id', row['user_id'] as String)
                .maybeSingle();
            if (user == null) return null;
            return _PresenceUser(
              userId: user['id'] as String,
              name: user['name'] as String? ?? 'Anonymous',
              avatarUrl: user['avatar_url'] as String?,
              tonightStatus: user['tonight_status'] as String?,
            );
          } catch (_) {
            return null;
          }
        }),
      );

      if (mounted) {
        setState(() {
          _presenceUsers = users.whereType<_PresenceUser>().toList();
          _presenceLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _presenceLoading = false);
    }
  }

  Future<void> _checkIn() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _checkingIn = true);
    final messenger = ScaffoldMessenger.of(context);
    final successMsg = context.tr(AppStrings.roomCheckedIn);
    try {
      final now = DateTime.now().toIso8601String();

      await _supabase.from('venue_room_presence').upsert({
        'venue_id': widget.venueId,
        'user_id': user.id,
        'joined_at': now,
        'last_seen_at': now,
      }, onConflict: 'venue_id,user_id');

      await _supabase.from('user_venue_presence').upsert({
        'user_id': user.id,
        'venue_id': widget.venueId,
        'checked_in_at': now,
        'status': 'checked_in',
      }, onConflict: 'user_id,venue_id');

      await AnalyticsService.instance.venueCheckedIn(
        venueId: widget.venueId,
        venueName: widget.venueName ?? 'Unknown',
      );

      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(successMsg)));
        await _loadPresence();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e, tag: 'Room.checkIn');
      }
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Photo Wall
  // ---------------------------------------------------------------------------

  Future<void> _loadWallPhotos() async {
    if (mounted) setState(() => _photosLoading = true);

    try {
      final rows = await _supabase
          .from('venue_wall_photos')
          .select()
          .eq('venue_id', widget.venueId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _wallPhotos = (rows as List).map((row) {
            return _WallPhoto(
              id: row['id'] as String,
              photoUrl: row['photo_url'] as String?,
              caption: row['caption'] as String?,
              likesCount: row['likes_count'] as int? ?? 0,
              createdAt: DateTime.parse(row['created_at'] as String),
            );
          }).toList();
          _photosLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _photosLoading = false);
    }
  }

  Future<void> _addPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final msg = context.tr(AppStrings.roomPhotoComingSoon);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (mounted) {
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ---------------------------------------------------------------------------
  // Vibe
  // ---------------------------------------------------------------------------

  Future<void> _loadVibe() async {
    if (mounted) setState(() => _vibeLoading = true);

    try {
      final pollRows = await _supabase
          .from('venue_room_vibe_polls')
          .select()
          .eq('venue_id', widget.venueId)
          .order('created_at', ascending: false)
          .limit(1);

      _VibePoll? poll;
      if ((pollRows as List).isNotEmpty) {
        final row = pollRows.first;
        final options = (row['options'] as List?)?.cast<String>() ?? [];
        final votes = (row['votes'] as Map<String, dynamic>?) ?? {};
        poll = _VibePoll(
          id: row['id'] as String,
          question: row['question'] as String? ?? '',
          options: options,
          votes: votes,
        );
      }

      final momentRows = await _supabase
          .from('venue_room_moments')
          .select()
          .eq('venue_id', widget.venueId)
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _currentPoll = poll;
          _moments = (momentRows as List).map((row) {
            return _Moment(
              id: row['id'] as String,
              content: row['content'] as String? ?? '',
              type: row['type'] as String? ?? 'text',
              createdAt: DateTime.parse(row['created_at'] as String),
            );
          }).toList();
          _vibeLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _vibeLoading = false);
    }
  }

  Future<void> _submitVote() async {
    if (_currentPoll == null || _selectedPollOption == null) return;
    setState(() => _submittingVote = true);
    final messenger = ScaffoldMessenger.of(context);
    final successMsg = context.tr(AppStrings.roomVoteSuccess);

    try {
      final votes = Map<String, dynamic>.from(_currentPoll!.votes);
      final current = votes[_selectedPollOption!] as int? ?? 0;
      votes[_selectedPollOption!] = current + 1;

      await _supabase
          .from('venue_room_vibe_polls')
          .update({'votes': votes}).eq('id', _currentPoll!.id);

      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(successMsg)));
        await _loadVibe();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e, tag: 'Room.submitVote');
      }
    } finally {
      if (mounted) setState(() => _submittingVote = false);
    }
  }

  Future<void> _postMoment() async {
    final text = _momentController.text.trim();
    if (text.isEmpty) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _postingMoment = true);
    try {
      await _supabase.from('venue_room_moments').insert({
        'venue_id': widget.venueId,
        'user_id': user.id,
        'content': text,
        'type': 'text',
      });
      _momentController.clear();
      await _loadVibe();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e, tag: 'Room.postMoment');
    } finally {
      if (mounted) setState(() => _postingMoment = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.venueName ?? t(AppStrings.roomTheRoomDefault),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_peopleCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, size: 14, color: _brandColor),
                  const SizedBox(width: 4),
                  Text(
                    '$_peopleCount',
                    style: const TextStyle(
                      color: _brandColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _brandColor,
          labelColor: _brandColor,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: t(AppStrings.roomChatTab)),
            Tab(text: t(AppStrings.roomWhosHereTab)),
            Tab(text: t(AppStrings.roomPhotoWallTab)),
            Tab(text: t(AppStrings.roomVibeTab)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(),
          _buildPresenceTab(),
          _buildPhotoWallTab(),
          _buildVibeTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chat tab
  // ---------------------------------------------------------------------------

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(child: _buildMessageList()),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_chatLoading) {
      return const AppFullLoader(color: _brandColor);
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _brandColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 36,
                color: _brandColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(AppStrings.roomNoMessages),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(AppStrings.roomBeFirstSay),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe =
            msg.userId == (_supabase.auth.currentUser?.id ?? '');
        return _MessageBubble(message: msg, isMe: isMe);
      },
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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
                controller: _chatController,
                decoration: InputDecoration(
                  hintText: context.tr(AppStrings.roomSaySomething),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Presence tab
  // ---------------------------------------------------------------------------

  Widget _buildPresenceTab() {
    return Column(
      children: [
        // Header with count + button
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people, size: 16, color: _brandColor),
                    const SizedBox(width: 6),
                    Text(
                      '$_peopleCount ${context.tr(AppStrings.roomHereNow)}',
                      style: const TextStyle(
                        color: _brandColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _checkingIn ? null : _checkIn,
                icon: _checkingIn
                    ? const AppButtonLoader(size: 14)
                    : const Icon(Icons.location_on, size: 16),
                label: Text(context.tr(AppStrings.roomIAmHere)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _presenceLoading
            ? const AppFullLoader(color: _brandColor)
            : _presenceUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_off_outlined, size: 48),
                        const SizedBox(height: 12),
                        Text(context.tr(AppStrings.roomNoOneCheckedIn),
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(context.tr(AppStrings.roomBeFirst),
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPresence,
                    color: _brandColor,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _presenceUsers.length,
                      itemBuilder: (context, index) {
                        return _UserCard(user: _presenceUsers[index]);
                      },
                    ),
                  )),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Photo wall tab
  // ---------------------------------------------------------------------------

  Widget _buildPhotoWallTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhoto,
        backgroundColor: _brandColor,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
      body: _photosLoading
          ? const AppFullLoader(color: _brandColor)
          : _wallPhotos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _brandColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_library_outlined,
                            size: 36, color: _brandColor),
                      ),
                      const SizedBox(height: 16),
                      Text(context.tr(AppStrings.roomNoPhotos),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(context.tr(AppStrings.roomAddFirstPhoto),
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWallPhotos,
                  color: _brandColor,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _wallPhotos.length,
                    itemBuilder: (context, index) {
                      return _PhotoCard(photo: _wallPhotos[index]);
                    },
                  ),
                ),
    );
  }

  // ---------------------------------------------------------------------------
  // Vibe tab
  // ---------------------------------------------------------------------------

  static const _vibeTagsList = [
    'Happy Hour',
    'Dance Party',
    'Live Music',
    'Craft Beer',
    'Sports',
    'Karaoke',
    'Chill Vibes',
    'Rooftop',
    'Late Night',
    'Wine Down',
  ];

  Widget _buildVibeTab() {
    if (_vibeLoading) {
      return const AppFullLoader(color: _brandColor);
    }

    return RefreshIndicator(
      onRefresh: _loadVibe,
      color: _brandColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Poll card
          if (_currentPoll != null) ...[
            _buildPollCard(),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  context.tr(AppStrings.roomNoActivePoll),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Vibe tags row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(AppStrings.roomPopularVibes),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _vibeTagsList.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _brandColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _brandColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                            fontSize: 12,
                            color: _brandColor,
                            fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Add moment
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(AppStrings.roomShareMomentTitle),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _momentController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: context.tr(AppStrings.roomWhatHappening),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _postingMoment ? null : _postMoment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _postingMoment
                        ? const AppButtonLoader(size: 16)
                        : Text(context.tr(AppStrings.roomPostMoment)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recent moments
          if (_moments.isNotEmpty) ...[
            Text(
              context.tr(AppStrings.roomRecentMoments),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ..._moments.map((m) => _MomentCard(moment: m)),
          ],
        ],
      ),
    );
  }

  Widget _buildPollCard() {
    final poll = _currentPoll!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(context.tr(AppStrings.roomPollLabel),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _brandColor)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  poll.question,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: poll.options.map((opt) {
              final isSelected = _selectedPollOption == opt;
              final voteCount = poll.votes[opt] as int? ?? 0;
              return GestureDetector(
                onTap: () => setState(() => _selectedPollOption = opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _brandColor
                        : _brandColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? _brandColor
                          : _brandColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$opt ($voteCount)',
                    style: TextStyle(
                      color: isSelected ? Colors.white : _brandColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (_selectedPollOption == null || _submittingVote)
                      ? null
                      : _submitVote,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _submittingVote
                  ? const AppButtonLoader(size: 16)
                  : Text(context.tr(AppStrings.roomSubmitVote)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final _RoomMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFE91E63);
    final initial =
        message.userName?.isNotEmpty == true ? message.userName![0] : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: brandColor.withValues(alpha: 0.15),
              child: Text(
                initial.toUpperCase(),
                style: const TextStyle(
                    color: brandColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)])
                    : null,
                color: isMe ? null : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && message.userName != null) ...[
                    Text(
                      message.userName!,
                      style: const TextStyle(
                          color: brandColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : null,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _fmtTime(message.createdAt),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 10,
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

  String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _UserCard extends StatelessWidget {
  final _PresenceUser user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFE91E63);
    final initial =
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    Color statusColor;
    String statusLabel;
    switch (user.tonightStatus) {
      case 'out_now':
        statusColor = Colors.green;
        statusLabel = context.tr(AppStrings.roomOutNow);
      case 'going_out_soon':
        statusColor = Colors.orange;
        statusLabel = context.tr(AppStrings.roomGoingOutSoon);
      default:
        statusColor = Colors.grey;
        statusLabel = context.tr(AppStrings.roomStayingIn);
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: brandColor.withValues(alpha: 0.1),
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    initial,
                    style: const TextStyle(
                        color: brandColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            user.name,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final _WallPhoto photo;

  const _PhotoCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFE91E63);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          photo.photoUrl != null && photo.photoUrl!.isNotEmpty
              ? Image.network(
                  photo.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                )
              : Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image_outlined, size: 40),
                ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      photo.caption ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.favorite,
                      size: 12, color: brandColor),
                  const SizedBox(width: 3),
                  Text(
                    '${photo.likesCount}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  final _Moment moment;

  const _MomentCard({required this.moment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt,
                size: 20, color: Color(0xFFE91E63)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moment.content,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmtRelative(moment.createdAt, context),
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtRelative(DateTime t, BuildContext context) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return context.tr(AppStrings.roomJustNow);
    if (diff.inMinutes < 60) return '${diff.inMinutes}${context.tr(AppStrings.roomMinAgo)}';
    if (diff.inHours < 24) return '${diff.inHours}${context.tr(AppStrings.roomHourAgo)}';
    return '${diff.inDays}${context.tr(AppStrings.roomDayAgo)}';
  }
}
