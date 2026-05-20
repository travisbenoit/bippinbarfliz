import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../utils/app_error.dart';
import '../../services/notification_sender.dart';
import '../../widgets/app_loader.dart';

const _brandPink = Color(0xFFE91E63);

const _vibeTags = [
  'Bar Crawl', 'Dance Night', 'Chill Vibes', 'Live Music',
  'Rooftop', 'Karaoke', 'Sports Bar', 'Happy Hour',
  'Late Night', 'Wine & Dine', 'Club Night', 'Craft Beer',
];

class CreateSwarmScreen extends ConsumerStatefulWidget {
  const CreateSwarmScreen({super.key});

  @override
  ConsumerState<CreateSwarmScreen> createState() => _CreateSwarmScreenState();
}

class _CreateSwarmScreenState extends ConsumerState<CreateSwarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime? _startTime;
  int _maxAttendees = 10;
  final Set<String> _selectedTags = {};
  bool _submitting = false;

  File? _coverImage;
  bool _uploadingCover = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (picked == null || !mounted) return;
    setState(() => _coverImage = File(picked.path));
  }

  Future<void> _pickStartTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _brandPink),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _brandPink),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(tProvider)(AppStrings.swarmsPickTime))),
      );
      return;
    }

    setState(() => _submitting = true);
    final t = ref.read(tProvider);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Upload cover image if selected
      String? coverImageUrl;
      if (_coverImage != null) {
        setState(() => _uploadingCover = true);
        final ext = _coverImage!.path.split('.').last.toLowerCase();
        final path = 'swarm-covers/${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage.from('swarm-images').upload(path, _coverImage!);
        coverImageUrl = supabase.storage.from('swarm-images').getPublicUrl(path);
        if (mounted) setState(() => _uploadingCover = false);
      }

      final title = _titleCtrl.text.trim();
      final result = await supabase.from('swarms').insert({
        'host_user_id': user.id,
        'title': title,
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'start_time': _startTime!.toIso8601String(),
        'max_size': _maxAttendees,
        'vibe_tags': _selectedTags.toList(),
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      }).select('id').single();

      final swarmId = result['id'] as String;

      // Add the host as the first member so the count is always accurate.
      await supabase.from('swarm_members').insert({
        'swarm_id': swarmId,
        'user_id': user.id,
        'role': 'host',
        'rsvp': 'going',
      });

      final profile = await supabase.from('users').select('name').eq('id', user.id).single();
      final hostName = (profile['name'] as String?)?.trim();
      NotificationSender.swarmCreated(
        swarmId: swarmId,
        swarmTitle: title,
        hostName: (hostName == null || hostName.isEmpty) ? 'Someone' : hostName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(AppStrings.swarmsCreateSuccess)),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e, tag: 'CreateSwarm');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(t(AppStrings.swarmsCreate),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_brandPink, Color(0xFFFF6B6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.groups, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create a Swarm',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t(AppStrings.swarmsCreateNew),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Cover photo (optional) ───────────────────────────────────
              const _SectionLabel('Cover Photo (Optional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _uploadingCover ? null : _pickCoverImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _coverImage != null
                      ? Stack(
                          children: [
                            Image.file(
                              _coverImage!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _coverImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: cs.onSurface.withValues(alpha: 0.15),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 32,
                                  color: cs.onSurface.withValues(alpha: 0.4)),
                              const SizedBox(height: 6),
                              Text(
                                'Add a cover photo',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Swarm name ───────────────────────────────────────────────
              _SectionLabel(t(AppStrings.swarmsNameLabel)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: t(AppStrings.swarmsNameHint),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? t(AppStrings.swarmsNameRequired) : null,
              ),

              const SizedBox(height: 20),

              // ── Description ──────────────────────────────────────────────
              _SectionLabel(t(AppStrings.swarmsDescLabel)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: t(AppStrings.swarmsDescHint),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.notes),
                  ),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 20),

              // ── Start time ───────────────────────────────────────────────
              _SectionLabel(t(AppStrings.swarmsStartTimeLabel)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickStartTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _startTime != null
                          ? _brandPink.withValues(alpha: 0.5)
                          : cs.onSurface.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: _startTime != null ? _brandPink : cs.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: 12),
                      Text(
                        _startTime != null
                            ? DateFormat('EEE, MMM d • h:mm a').format(_startTime!)
                            : t(AppStrings.swarmsPickTime),
                        style: TextStyle(
                          fontSize: 15,
                          color: _startTime != null
                              ? cs.onSurface
                              : cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          color: cs.onSurface.withValues(alpha: 0.4), size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Max attendees ────────────────────────────────────────────
              Row(
                children: [
                  _SectionLabel(t(AppStrings.swarmsMaxAttendeesLabel)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _brandPink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_maxAttendees ${t(AppStrings.swarmsMembers)}',
                      style: const TextStyle(
                          color: _brandPink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _brandPink,
                  thumbColor: _brandPink,
                  inactiveTrackColor: _brandPink.withValues(alpha: 0.2),
                  overlayColor: _brandPink.withValues(alpha: 0.1),
                ),
                child: Slider(
                  value: _maxAttendees.toDouble(),
                  min: 2,
                  max: 50,
                  divisions: 48,
                  onChanged: (v) => setState(() => _maxAttendees = v.round()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('2', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                    Text('50', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Vibe tags ────────────────────────────────────────────────
              _SectionLabel(t(AppStrings.swarmsVibeTagsLabel)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _vibeTags.map((tag) {
                  final selected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () => setState(() {
                      selected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? _brandPink
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? _brandPink
                              : cs.onSurface.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : cs.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // ── Submit ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const AppButtonLoader(size: 18)
                      : const Icon(Icons.rocket_launch_outlined),
                  label: Text(
                    t(AppStrings.swarmsPublish),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandPink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _brandPink.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}
