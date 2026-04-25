import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';

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
  static const _bgColor = Color(0xFFFFF5F0);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // Avatar upload not implemented yet — local feedback only
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar upload coming soon')),
      );
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_userId == null) return;

    setState(() => _saving = true);

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
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
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: _brandColor),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                        color: _brandColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brandColor))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: 'Basic Info',
                    children: [
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Name',
                        hint: 'Your name',
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _bioCtrl,
                        label: 'Bio',
                        hint: 'Tell people about yourself...',
                        maxLines: 3,
                        maxLength: 200,
                        showCounter: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _homeCityCtrl,
                        label: 'Home City',
                        hint: 'Where are you from?',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _occupationCtrl,
                        label: 'Occupation',
                        hint: 'What do you do?',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Preferences',
                    children: [
                      _buildLookingForDropdown(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Tonight Status',
                    children: [
                      _buildTonightStatusSelector(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Vibe Tags',
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
                    title: 'Favorite Drinks',
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
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save Profile',
                            style: TextStyle(
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
        onTap: _pickAvatar,
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
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
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
              fontWeight: FontWeight.w600,
              color: Colors.black54),
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
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  )
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _brandColor),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: required
              ? (val) {
                  if (val == null || val.trim().isEmpty) {
                    return '$label is required';
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
        const Text(
          'Looking For',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _lookingFor,
          hint: Text(
            'Select an option',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _brandColor),
            ),
            filled: true,
            fillColor: Colors.grey[50],
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
      _StatusOption(TonightStatus.outNow, 'Out Now', Icons.local_bar, Colors.green),
      _StatusOption(TonightStatus.goingOutSoon, 'Going Out Soon', Icons.schedule, Colors.orange),
      _StatusOption(TonightStatus.stayingIn, 'Staying In', Icons.home, Colors.grey),
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
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? opt.color : Colors.grey[300]!,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(opt.icon,
                    size: 16,
                    color: isSelected ? opt.color : Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? opt.color : Colors.grey[600],
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
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : Colors.grey[300]!,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? accentColor : Colors.grey[600],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
