import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = 'first_run_tour_complete_v1';
const _pink = Color(0xFFE91E63);

class _Step {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _Step({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });
}

const _steps = [
  _Step(
    icon: Icons.auto_awesome,
    iconColor: _pink,
    title: 'Set your Tonight Status',
    body:
        "Tap 'Out Now', 'Out Soon', or 'Maybe' on Home so friends know if you're up for it. Set the vibe and pick a venue right from the same screen.",
  ),
  _Step(
    icon: Icons.place,
    iconColor: Color(0xFFFF6B35),
    title: 'See who is out, live',
    body:
        "The Map shows every nearby venue, who's there, and how many people are checked in right now. Tap any pin to see the crowd and join.",
  ),
  _Step(
    icon: Icons.groups,
    iconColor: Color(0xFF9C27B0),
    title: 'Rally your crew with Swarms',
    body:
        'Swarms are 30-second group plans. Pick a venue, set a time, invite friends. Public swarms are discoverable by everyone nearby.',
  ),
  _Step(
    icon: Icons.chat_bubble_outline,
    iconColor: Color(0xFF2196F3),
    title: 'Friends and chat',
    body:
        'Add friends from the map or in person. DM them, share a song, send a virtual gift, or split a tab without leaving the chat.',
  ),
];

class FirstRunTour extends StatefulWidget {
  const FirstRunTour({super.key});

  @override
  State<FirstRunTour> createState() => _FirstRunTourState();
}

class _FirstRunTourState extends State<FirstRunTour> {
  bool _visible = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_storageKey) ?? false;
    if (!done && mounted) setState(() => _visible = true);
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, true);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final step = _steps[_step];
    final isLast = _step == _steps.length - 1;

    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                    child: Row(
                      children: [
                        Text(
                          'Welcome · Step ${_step + 1} of ${_steps.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500],
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: Colors.grey[400]),
                          onPressed: _finish,
                          tooltip: 'Skip tour',
                        ),
                      ],
                    ),
                  ),

                  // Icon + content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: step.iconColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(step.icon, color: step.iconColor, size: 30),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.body,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dots
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_steps.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _step ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _step ? _pink : Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _finish,
                            child: Text(
                              'Skip',
                              style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (isLast) {
                                _finish();
                              } else {
                                setState(() => _step++);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLast ? "Let's go" : 'Next',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                if (!isLast) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 18),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
