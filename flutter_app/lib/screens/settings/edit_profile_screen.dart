import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../extensions/localization_extension.dart';
import '../../utils/app_error.dart';
import '../../providers/auth_provider.dart' show currentUserProfileProvider;
import '../../providers/home_providers.dart';
import '../../widgets/app_loader.dart';
import '../../services/permission_service.dart';

class _StatusOption {
  final TonightStatus status;
  final String label;
  final IconData icon;
  final Color color;

  const _StatusOption(this.status, this.label, this.icon, this.color);
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const _brandColor = Color(0xFFE91E63);

  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _homeCityCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();

  // State
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;
  String? _lookingFor;
  TonightStatus _tonightStatus = TonightStatus.stayingIn;
  Set<String> _selectedVibeTags = {};
  Set<String> _selectedDrinks = {};
  String? _userId;

  static const _lookingForOptions = [
    'New Friends',
    'Dating',
    'Networking',
    'Just Drinking',
  ];

  static const _vibeTagOptions = [
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

  static const _drinkOptions = [
    'Beer',
    'Wine',
    'Cocktails',
    'Whiskey',
    'Vodka',
    'Tequila',
    'Non-Alcoholic',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _homeCityCtrl.dispose();
    _occupationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    _userId = user.id;

    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _nameCtrl.text = data['name'] as String? ?? '';
          _bioCtrl.text = data['bio'] as String? ?? '';
          _homeCityCtrl.text = data['home_city'] as String? ?? '';
          _occupationCtrl.text = data['occupation'] as String? ?? '';
          _avatarUrl = data['avatar_url'] as String?;
          _lookingFor = data['looking_for'] as String?;
          _tonightStatus = TonightStatus.fromString(
              data['tonight_status'] as String? ?? 'staying_in');
          _selectedVibeTags = Set<String>.from(
              (data['vibe_tags'] as List<dynamic>?)?.cast<String>() ?? []);
          _selectedDrinks = Set<String>.from(
              (data['favorite_drinks'] as List<dynamic>?)?.cast<String>() ??
                  []);
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showErrorSnackBar(context, e, tag: 'EditProfile.load');
      }
    }
  }

  void _pickAvatar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    if (_userId == null) return;

    final permType = source == ImageSource.camera
        ? AppPermission.camera
        : AppPermission.photos;
    final allowed =
        await PermissionService.instance.request(permType, context);
    if (!allowed || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : 'jpg';
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      // Store under userId/ so RLS path check passes
      final storagePath = '$_userId/avatar.$ext';

      await _supabase.storage.from('avatars').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      // Append cache-buster so Flutter re-fetches the new image
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(storagePath);
      final url = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await _supabase
          .from('users')
          .update({'avatar_url': publicUrl})
          .eq('id', _userId!);

      if (mounted) {
        setState(() => _avatarUrl = url);
        ref.invalidate(homeCurrentUserProfileProvider);
        ref.invalidate(currentUserProfileProvider);
      }
    } catch (e, st) {
      if (mounted) {
        showErrorSnackBar(context, e, stackTrace: st, tag: 'EditProfile.uploadAvatar');
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_userId == null) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final successMsg = ref.read(tProvider)(AppStrings.editProfileSaved);

    try {
      await _supabase.from('users').update({
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'home_city': _homeCityCtrl.text.trim().isEmpty
            ? null
            : _homeCityCtrl.text.trim(),
        'occupation': _occupationCtrl.text.trim().isEmpty
            ? null
            : _occupationCtrl.text.trim(),
        'looking_for': _lookingFor,
        'tonight_status': _tonightStatus.toDbString(),
        'vibe_tags': _selectedVibeTags.toList(),
        'favorite_drinks': _selectedDrinks.toList(),
        if (_avatarUrl != null) 'avatar_url': _avatarUrl,
      }).eq('id', _userId!);

      ref.invalidate(homeCurrentUserProfileProvider);
      ref.invalidate(userStatsProvider);
      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(successMsg)));
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e, tag: 'EditProfile.save');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          t(AppStrings.editProfileTitle),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const AppButtonLoader(color: _brandColor, size: 18)
                : Text(
                    t(AppStrings.editProfileSave),
                    style: const TextStyle(
                        color: _brandColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const AppFullLoader(color: _brandColor)
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: t(AppStrings.editProfileBasicInfo),
                    children: [
                      _buildTextField(
                        controller: _nameCtrl,
                        label: t(AppStrings.editProfileNameLabel),
                        hint: t(AppStrings.editProfileNameHint),
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _bioCtrl,
                        label: t(AppStrings.editProfileBioLabel),
                        hint: t(AppStrings.editProfileBioHintLong),
                        maxLines: 3,
                        maxLength: 200,
                        showCounter: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _homeCityCtrl,
                        label: t(AppStrings.editProfileHomeCityLabel),
                        hint: t(AppStrings.editProfileHomeCityHint),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _occupationCtrl,
                        label: t(AppStrings.editProfileOccupationLabel),
                        hint: t(AppStrings.editProfileOccupationHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: t(AppStrings.editProfilePreferences),
                    children: [
                      _buildLookingForDropdown(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: t(AppStrings.editProfileTonightStatusSection),
                    children: [
                      _buildTonightStatusSelector(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: t(AppStrings.editProfileVibeTags),
                    children: [
                      _buildMultiChips(
                        options: _vibeTagOptions,
                        selected: _selectedVibeTags,
                        onToggle: (tag) {
                          setState(() {
                            if (_selectedVibeTags.contains(tag)) {
                              _selectedVibeTags.remove(tag);
                            } else {
                              _selectedVibeTags.add(tag);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: t(AppStrings.editProfileFavDrinks),
                    children: [
                      _buildMultiChips(
                        options: _drinkOptions,
                        selected: _selectedDrinks,
                        onToggle: (drink) {
                          setState(() {
                            if (_selectedDrinks.contains(drink)) {
                              _selectedDrinks.remove(drink);
                            } else {
                              _selectedDrinks.add(drink);
                            }
                          });
                        },
                        accentColor: Colors.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const AppButtonLoader()
                        : Text(
                            t(AppStrings.editProfileSaveProfile),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section widgets
  // ---------------------------------------------------------------------------

  Widget _buildAvatarSection() {
    final initial =
        _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?';

    return Center(
      child: GestureDetector(
        onTap: _uploadingAvatar ? null : _pickAvatar,
        child: Stack(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _brandColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _brandColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? Image.network(
                        _avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildAvatarFallback(initial),
                      )
                    : _buildAvatarFallback(initial),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: _brandColor,
                  shape: BoxShape.circle,
                ),
                child: _uploadingAvatar
                    ? const Padding(
                        padding: EdgeInsets.all(4),
                        child: AppButtonLoader(size: 18),
                      )
                    : const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String initial) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)]),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
              color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
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
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    bool showCounter = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          buildCounter: showCounter
              ? (context,
                      {required currentLength,
                      required isFocused,
                      required maxLength}) =>
                  Text(
                    '$currentLength/${maxLength ?? 200}',
                    style: const TextStyle(fontSize: 11),
                  )
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _brandColor),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: required
              ? (val) {
                  if (val == null || val.trim().isEmpty) {
                    return '$label ${context.tr(AppStrings.editProfileIsRequired)}';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildLookingForDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(AppStrings.editProfileLookingForLabel),
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _lookingFor,
          hint: Text(
            context.tr(AppStrings.editProfileLookingForHint),
            style: const TextStyle(fontSize: 14),
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _brandColor),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: _lookingForOptions
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (val) => setState(() => _lookingFor = val),
        ),
      ],
    );
  }

  Widget _buildTonightStatusSelector() {
    final options = <_StatusOption>[
      _StatusOption(TonightStatus.outNow, context.tr(AppStrings.editProfileStatusOutNow), Icons.local_bar, Colors.green),
      _StatusOption(TonightStatus.goingOutSoon, context.tr(AppStrings.editProfileStatusGoing), Icons.schedule, Colors.orange),
      _StatusOption(TonightStatus.stayingIn, context.tr(AppStrings.editProfileStatusStaying), Icons.home, Colors.grey),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = _tonightStatus == opt.status;
        return GestureDetector(
          onTap: () => setState(() => _tonightStatus = opt.status),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? opt.color.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? opt.color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(opt.icon,
                    size: 16,
                    color: isSelected ? opt.color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? opt.color : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiChips({
    required List<String> options,
    required Set<String> selected,
    required void Function(String) onToggle,
    Color accentColor = _brandColor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return GestureDetector(
          onTap: () => onToggle(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? accentColor : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
