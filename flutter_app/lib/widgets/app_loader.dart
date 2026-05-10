import 'dart:math' as math;
import 'package:flutter/material.dart';

const _kBrandPink = Color(0xFFE91E63);

/// Spinning gradient-arc loader that uses the brand pink by default.
class AppLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const AppLoader({super.key, this.size = 44, this.color});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? _kBrandPink;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _ArcPainter(_ctrl.value, color),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double t;
  final Color color;

  _ArcPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final strokeW = size.width * 0.09;
    final radius = (size.width - strokeW) / 2;
    final center = Offset(cx, cy);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    // Sweeping arc (270°)
    const sweep = math.pi * 1.5;
    final start = 2 * math.pi * t - math.pi / 2;

    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: sweep,
        colors: [color.withValues(alpha: 0.0), color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, start, sweep, false, arcPaint);

    // Glowing tip dot
    final tipX = cx + radius * math.cos(start + sweep);
    final tipY = cy + radius * math.sin(start + sweep);
    final tip = Offset(tipX, tipY);

    canvas.drawCircle(
      tip,
      strokeW * 0.9,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeW * 0.8),
    );
    canvas.drawCircle(tip, strokeW * 0.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.t != t;
}

/// Drop-in for `Center(child: CircularProgressIndicator(color: ...))`.
class AppFullLoader extends StatelessWidget {
  final Color? color;
  const AppFullLoader({super.key, this.color});

  @override
  Widget build(BuildContext context) =>
      Center(child: AppLoader(color: color));
}

/// Tiny inline loader for inside buttons / list rows.
/// Drop-in for the `SizedBox(width:20, height:20, child: CircularProgressIndicator(...))` pattern.
class AppButtonLoader extends StatelessWidget {
  final Color color;
  final double size;
  const AppButtonLoader({super.key, this.color = Colors.white, this.size = 20});

  @override
  Widget build(BuildContext context) => AppLoader(size: size, color: color);
}
