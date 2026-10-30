import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Lightweight confetti burst drawn with a single painter — no assets,
/// no dependencies.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.trigger,
    required this.child,
  });

  final ValueListenable<int> trigger;
  final Widget child;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  List<_Particle> _particles = const [];
  int _lastTrigger = 0;

  @override
  void initState() {
    super.initState();
    _lastTrigger = widget.trigger.value;
    widget.trigger.addListener(_onTrigger);
  }

  @override
  void didUpdateWidget(covariant CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      oldWidget.trigger.removeListener(_onTrigger);
      widget.trigger.addListener(_onTrigger);
      _lastTrigger = widget.trigger.value;
    }
  }

  void _onTrigger() {
    if (widget.trigger.value == _lastTrigger) return;
    _lastTrigger = widget.trigger.value;
    _burst();
  }

  void _burst() {
    final colors = AppColors.subjectPalette;
    final random = math.Random(DateTime.now().millisecondsSinceEpoch);
    _particles = List.generate(64, (i) {
      final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 1.7;
      final speed = 260 + random.nextDouble() * 720;
      return _Particle(
        angle: angle,
        speed: speed,
        color: colors[random.nextInt(colors.length)],
        size: 4 + random.nextDouble() * 7,
        spin: (random.nextDouble() - 0.5) * 12,
        isCircle: random.nextBool(),
        delay: random.nextDouble() * 0.15,
      );
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_onTrigger);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, _) {
              if (!_controller.isAnimating) return const SizedBox.shrink();
              return CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  t: _controller.value,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.spin,
    required this.isCircle,
    required this.delay,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double spin;
  final bool isCircle;
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.t});

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.34);
    final gravity = 1000.0;

    for (final p in particles) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final eased = 1 - math.pow(1 - local, 2.2);
      final distance = p.speed * eased;
      final x = origin.dx + math.cos(p.angle) * distance;
      final y = origin.dy +
          math.sin(p.angle) * distance +
          gravity * local * local * 0.35;
      final alpha = (1 - local * local).clamp(0.0, 1.0);
      if (alpha <= 0.02) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * local);
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.6,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.t != t || old.particles != particles;
}
