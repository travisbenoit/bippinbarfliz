import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ReportTargetType { user, message, venue, swarm }

class ReportContentSheet extends StatefulWidget {
  final ReportTargetType targetType;
  final String? targetUserId;
  final String? venueId;
  final String? targetLabel;

  const ReportContentSheet({
    super.key,
    required this.targetType,
    this.targetUserId,
    this.venueId,
    this.targetLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required ReportTargetType targetType,
    String? targetUserId,
    String? venueId,
    String? targetLabel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportContentSheet(
        targetType: targetType,
        targetUserId: targetUserId,
        venueId: venueId,
        targetLabel: targetLabel,
      ),
    );
  }

  @override
  State<ReportContentSheet> createState() => _ReportContentSheetState();
}

class _ReportContentSheetState extends State<ReportContentSheet> {
  static const _reasons = [
    ('spam', 'Spam or fake account'),
    ('harassment', 'Harassment or bullying'),
    ('hate_speech', 'Hate speech'),
    ('sexual_content', 'Sexual or inappropriate content'),
    ('violence', 'Threats or violence'),
    ('underage', 'User appears to be underage'),
    ('impersonation', 'Impersonation'),
    ('safety', 'Safety concern'),
    ('other', 'Other'),
  ];

  static const _venueReasonMap = {
    'spam': 'spam',
    'harassment': 'inappropriate',
    'hate_speech': 'inappropriate',
    'sexual_content': 'inappropriate',
    'violence': 'safety_concern',
    'safety': 'safety_concern',
    'underage': 'safety_concern',
    'impersonation': 'incorrect_info',
    'other': 'other',
  };

  String? _selectedReason;
  final _detailsController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() => _submitting = true);

    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      setState(() => _submitting = false);
      return;
    }

    try {
      if (widget.targetType == ReportTargetType.venue) {
        await supabase.from('venue_reports').insert({
          'venue_id': widget.venueId,
          'reporter_id': currentUser.id,
          'report_type': _venueReasonMap[_selectedReason] ?? 'other',
          'description': _detailsController.text.trim().isNotEmpty
              ? _detailsController.text.trim()
              : _reasons.firstWhere((r) => r.$1 == _selectedReason).$2,
        });
      } else {
        final context = widget.targetType == ReportTargetType.message
            ? 'dm'
            : widget.targetType == ReportTargetType.swarm
                ? 'swarm'
                : 'profile';
        await supabase.from('reports').insert({
          'reporter_user_id': currentUser.id,
          'reported_user_id': widget.targetUserId,
          'context': context,
          'reason': _selectedReason,
          'details': _detailsController.text.trim(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks for reporting. We review within 24 hours.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit report. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.targetType == ReportTargetType.venue
        ? 'this venue'
        : widget.targetLabel != null
            ? widget.targetLabel!
            : 'this content';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_outlined, color: Colors.red, size: 22),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Report $label',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a reason. We review every report within 24 hours.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Reason list
            ..._reasons.map((r) {
              final selected = _selectedReason == r.$1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedReason = r.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: selected ? Colors.red[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? Colors.red[300]! : Colors.grey[200]!,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.$2,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: selected ? Colors.red[700] : Colors.black87,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: selected ? Colors.red[300] : Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // Details
            Text('Additional details (optional)',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 6),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'What happened?',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedReason != null && !_submitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red[200],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  _submitting ? 'Submitting...' : 'Submit Report',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
