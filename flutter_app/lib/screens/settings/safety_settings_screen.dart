import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../extensions/localization_extension.dart';
import '../../utils/app_error.dart';
import '../../widgets/app_loader.dart';

class SafetySettingsScreen extends ConsumerStatefulWidget {
  const SafetySettingsScreen({super.key});

  @override
  ConsumerState<SafetySettingsScreen> createState() =>
      _SafetySettingsScreenState();
}

class _SafetySettingsScreenState
    extends ConsumerState<SafetySettingsScreen> {
  static const _brandColor = Color(0xFFE91E63);

  final _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _ghostMode = false;
  String _privacyMode = 'public';
  List<_BlockedUser> _blockedUsers = [];
  bool _savingGhost = false;
  bool _savingPrivacy = false;
  bool _requestingDeletion = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadSettings() async {
    setState(() => _loading = true);

    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Load ghost mode + privacy mode
      final profile = await _supabase
          .from('users')
          .select('ghost_mode, privacy_mode')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        _ghostMode = profile['ghost_mode'] as bool? ?? false;
        _privacyMode = profile['privacy_mode'] as String? ?? 'public';
      }

      // Load block list
      final blocks = await _supabase
          .from('user_blocks')
          .select('id, blocked_id')
          .eq('blocker_id', user.id);

      final blockedUsers = await Future.wait(
        (blocks as List).map((row) async {
          try {
            final blocked = await _supabase
                .from('users')
                .select('id, name, avatar_url')
                .eq('id', row['blocked_id'] as String)
                .maybeSingle();
            if (blocked == null) return null;
            return _BlockedUser(
              blockId: row['id'] as String,
              userId: blocked['id'] as String,
              name: blocked['name'] as String? ?? 'Unknown',
              avatarUrl: blocked['avatar_url'] as String?,
            );
          } catch (_) {
            return null;
          }
        }),
      );

      if (mounted) {
        setState(() {
          _blockedUsers = blockedUsers.whereType<_BlockedUser>().toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showErrorSnackBar(context, e, tag: 'SafetySettings.load');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _toggleGhostMode(bool value) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _ghostMode = value;
      _savingGhost = true;
    });
    try {
      await _supabase
          .from('users')
          .update({'ghost_mode': value}).eq('id', user.id);
    } catch (e) {
      if (mounted) {
        setState(() => _ghostMode = !value);
        showErrorSnackBar(context, e, tag: 'SafetySettings.ghostMode');
      }
    } finally {
      if (mounted) setState(() => _savingGhost = false);
    }
  }

  Future<void> _setPrivacyMode(String mode) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final previous = _privacyMode;
    setState(() {
      _privacyMode = mode;
      _savingPrivacy = true;
    });

    try {
      await _supabase
          .from('users')
          .update({'privacy_mode': mode}).eq('id', user.id);
    } catch (e) {
      if (mounted) {
        setState(() => _privacyMode = previous);
        showErrorSnackBar(context, e, tag: 'SafetySettings.privacyMode');
      }
    } finally {
      if (mounted) setState(() => _savingPrivacy = false);
    }
  }

  Future<void> _unblock(_BlockedUser blocked) async {
    final unblockMsg = '${blocked.name} ${context.tr(AppStrings.safetyUnblockedUser)}';

    try {
      await _supabase
          .from('user_blocks')
          .delete()
          .eq('id', blocked.blockId);

      if (mounted) {
        setState(() =>
            _blockedUsers.removeWhere((b) => b.blockId == blocked.blockId));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(unblockMsg)));
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e, tag: 'SafetySettings.unblock');
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final title = context.tr(AppStrings.safetyDeleteConfirmTitle);
    final message = context.tr(AppStrings.safetyDeleteConfirmMsg);
    final cancelLabel = context.tr(AppStrings.cancel);
    final deleteLabel = context.tr(AppStrings.safetyDeleteMyAccount);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(deleteLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _requestAccountDeletion();
  }

  Future<void> _requestAccountDeletion() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _requestingDeletion = true);
    final successMsg = context.tr(AppStrings.safetyDeletionRequested);

    try {
      await _supabase.from('account_deletion_requests').insert({
        'user_id': user.id,
        'requested_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(successMsg),
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e, tag: 'SafetySettings.deletionRequest');
    } finally {
      if (mounted) setState(() => _requestingDeletion = false);
    }
  }

  void _requestDataExport() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.tr(AppStrings.safetyDataExportSoon)),
      duration: const Duration(seconds: 4),
    ));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.watch(tProvider);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr(AppStrings.safetyTitle),
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.shield_outlined, color: _brandColor),
          ),
        ],
      ),
      body: _loading
          ? const AppFullLoader(color: _brandColor)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPrivacySection(),
                const SizedBox(height: 16),
                _buildBlockListSection(),
                const SizedBox(height: 16),
                _buildAccountSection(),
                const SizedBox(height: 16),
                _buildDataSection(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Privacy section
  // ---------------------------------------------------------------------------

  Widget _buildPrivacySection() {
    return _SectionCard(
      title: context.tr(AppStrings.safetyPrivacy),
      icon: Icons.lock_outline,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(AppStrings.safetyGhostModeTitle),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(AppStrings.safetyGhostHideSub),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _savingGhost
                ? const AppButtonLoader(color: _brandColor, size: 24)
                : Switch(
                    value: _ghostMode,
                    onChanged: _toggleGhostMode,
                    activeThumbColor: _brandColor,
                  ),
          ],
        ),

        const Divider(height: 28),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.tr(AppStrings.safetyProfileVisibility),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_savingPrivacy)
                  const AppButtonLoader(color: _brandColor, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            _buildPrivacyOption(
              value: 'public',
              label: context.tr(AppStrings.safetyPublicLabel),
              description: context.tr(AppStrings.safetyPublicDesc),
              icon: Icons.public,
            ),
            const SizedBox(height: 8),
            _buildPrivacyOption(
              value: 'friends_only',
              label: context.tr(AppStrings.safetyFriendsOnlyLabel),
              description: context.tr(AppStrings.safetyFriendsOnlyDesc),
              icon: Icons.people_outline,
            ),
            const SizedBox(height: 8),
            _buildPrivacyOption(
              value: 'private',
              label: context.tr(AppStrings.safetyPrivateLabel),
              description: context.tr(AppStrings.safetyPrivateDesc),
              icon: Icons.lock_outline,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrivacyOption({
    required String value,
    required String label,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _privacyMode == value;

    return GestureDetector(
      onTap: () => _setPrivacyMode(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _brandColor.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _brandColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? _brandColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? _brandColor : null,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: _brandColor, size: 20),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Block list section
  // ---------------------------------------------------------------------------

  Widget _buildBlockListSection() {
    return _SectionCard(
      title: context.tr(AppStrings.safetyBlockedUsersTitle),
      icon: Icons.block,
      children: [
        if (_blockedUsers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                context.tr(AppStrings.safetyNoBlocked),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          )
        else
          ..._blockedUsers.map((blocked) => _BlockedUserTile(
                blockedUser: blocked,
                onUnblock: () => _unblock(blocked),
              )),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Account section
  // ---------------------------------------------------------------------------

  Widget _buildAccountSection() {
    return _SectionCard(
      title: context.tr(AppStrings.safetyAccount),
      icon: Icons.manage_accounts_outlined,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_forever_outlined,
                color: Colors.red, size: 20),
          ),
          title: Text(
            context.tr(AppStrings.safetyDeleteAccount),
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            context.tr(AppStrings.safetyDeleteAccountSub),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: _requestingDeletion
              ? const AppButtonLoader(color: Colors.red, size: 20)
              : const Icon(Icons.arrow_forward_ios,
                  size: 14),
          onTap: _requestingDeletion ? null : _showDeleteAccountDialog,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Data section
  // ---------------------------------------------------------------------------

  Widget _buildDataSection() {
    return _SectionCard(
      title: context.tr(AppStrings.safetyYourData),
      icon: Icons.storage_outlined,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _brandColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.download_outlined,
                color: _brandColor, size: 20),
          ),
          title: Text(
            context.tr(AppStrings.safetyDownloadData),
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15),
          ),
          subtitle: Text(
            context.tr(AppStrings.safetyDownloadDataSub),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.arrow_forward_ios,
              size: 14),
          onTap: _requestDataExport,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _BlockedUser {
  final String blockId;
  final String userId;
  final String name;
  final String? avatarUrl;

  const _BlockedUser({
    required this.blockId,
    required this.userId,
    required this.name,
    this.avatarUrl,
  });
}

class _BlockedUserTile extends StatelessWidget {
  final _BlockedUser blockedUser;
  final VoidCallback onUnblock;

  const _BlockedUserTile({
    required this.blockedUser,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final initial = blockedUser.name.isNotEmpty
        ? blockedUser.name[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                const Color(0xFFE91E63).withValues(alpha: 0.1),
            backgroundImage: blockedUser.avatarUrl != null
                ? NetworkImage(blockedUser.avatarUrl!)
                : null,
            child: blockedUser.avatarUrl == null
                ? Text(
                    initial,
                    style: const TextStyle(
                        color: Color(0xFFE91E63),
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              blockedUser.name,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ),
          OutlinedButton(
            onPressed: onUnblock,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(context.tr(AppStrings.blockedUnblock), style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFE91E63)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
