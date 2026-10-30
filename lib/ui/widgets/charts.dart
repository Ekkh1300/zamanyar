import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/jalali.dart';
import '../../core/theme.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 180,
    this.stroke = 14,
    this.colors,
    this.trackColor,
    this.child,
    this.animate = true,
  });

  final double progress;
  final double size;
  final double stroke;
  final List<Color>? colors;
  final Color? trackColor;
  final Widget? child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final palette = colors ?? [c.primary, c.mint];
    final target = progress.clamp(0.0, 1.0);

    Widget paint(double value) {
      return SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: value,
            stroke: stroke,
            colors: palette,
            track: trackColor ?? c.border,
          ),
          child: Center(child: child),
        ),
      );
    }

    if (!animate) return paint(target);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOutCubic,
      builder: (_, value, _) => paint(value),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.colors,
    required this.track,
  });

  final double progress;
  final double stroke;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (progress <= 0.001) return;

    final sweep = math.pi * 2 * progress;
    final shader = SweepGradient(
      colors: colors,
      startAngle: 0,
      endAngle: math.pi * 2,
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 6
      ..strokeCap = StrokeCap.round
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = colors.first.withValues(alpha: 0.5);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glow);

    final main = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = shader;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, main);

    // Highlight dot at the head of the arc.
    final angle = -math.pi / 2 + sweep;
    final dotCenter = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(dotCenter, math.max(2.2, stroke * 0.18), dot);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.colors != colors ||
      old.track != track ||
      old.stroke != stroke;
}

class WeeklyBars extends StatelessWidget {
  const WeeklyBars({
    super.key,
    required this.values,
    required this.labels,
    this.highlightIndex,
    this.height = 160,
    this.color,
  });

  final List<int> values;
  final List<String> labels;
  final int? highlightIndex;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final labelStyle = Theme.of(context)
        .textTheme
        .labelSmall!
        .copyWith(color: c.muted, fontSize: 10);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, t, _) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _BarsPainter(
            values: values,
            labels: labels,
            progress: t,
            highlightIndex: highlightIndex ?? values.length - 1,
            color: color ?? c.primary,
            softColor: c.mint,
            trackColor: c.surfaceAlt,
            labelStyle: labelStyle,
            textColor: c.text,
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.labels,
    required this.progress,
    required this.highlightIndex,
    required this.color,
    required this.softColor,
    required this.trackColor,
    required this.labelStyle,
    required this.textColor,
  });

  final List<int> values;
  final List<String> labels;
  final double progress;
  final int highlightIndex;
  final Color color;
  final Color softColor;
  final Color trackColor;
  final TextStyle labelStyle;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const labelHeight = 26.0;
    const topPadding = 26.0;
    final chartHeight = size.height - labelHeight - topPadding;
    final slot = size.width / values.length;
    final barWidth = math.min(22.0, slot * 0.44);
    final maxValue = values.fold<int>(1, math.max);

    for (var i = 0; i < values.length; i++) {
      // RTL: first value on the right.
      final centerX = size.width - slot * (i + 0.5);
      final value = values[i];
      final ratio = value / maxValue;
      final barHeight = chartHeight * ratio * progress;
      final isHighlight = i == highlightIndex;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          topPadding + chartHeight - barHeight,
          barWidth,
          math.max(barHeight, value == 0 ? 6 : barHeight).toDouble(),
        ),
        Radius.circular(barWidth / 2),
      );

      final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          topPadding,
          barWidth,
          chartHeight,
        ),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(track, Paint()..color = trackColor.withValues(alpha: 0.55));

      if (value <= 0) {
        final dayTpEmpty = TextPainter(
          text: TextSpan(
            text: labels.length > i ? labels[i] : '',
            style: labelStyle.copyWith(
              color: isHighlight ? textColor : labelStyle.color,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        dayTpEmpty.paint(
          canvas,
          Offset(centerX - dayTpEmpty.width / 2, size.height - labelHeight + 6),
        );
        continue;
      }

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isHighlight
              ? [softColor, color]
              : [
                  color.withValues(alpha: 0.85),
                  color.withValues(alpha: 0.45),
                ],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);

      if (isHighlight) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = color.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }

      if (value > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: faDigits(value),
            style: labelStyle.copyWith(
              color: isHighlight ? textColor : labelStyle.color,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
          textDirection: TextDirection.rtl,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            centerX - tp.width / 2,
            topPadding + chartHeight - barHeight - tp.height - 4,
          ),
        );
      }

      final dayTp = TextPainter(
        text: TextSpan(
          text: labels.length > i ? labels[i] : '',
          style: labelStyle.copyWith(
            color: isHighlight ? textColor : labelStyle.color,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      dayTp.paint(
        canvas,
        Offset(centerX - dayTp.width / 2, size.height - labelHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.progress != progress || old.values != values;
}

class Heatmap extends StatelessWidget {
  const Heatmap({
    super.key,
    required this.end,
    this.weeks = 6,
    required this.levelOf,
  });

  final DateTime end;
  final int weeks;
  final int Function(DateTime day) levelOf;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final start = startOfWeek(end).subtract(Duration(days: (weeks - 1) * 7));
    final columns = <Widget>[];
    for (var w = 0; w < weeks; w++) {
      final children = <Widget>[];
      for (var d = 0; d < 7; d++) {
        final day = start.add(Duration(days: w * 7 + d));
        final level = day.isAfter(end) ? -1 : levelOf(day).clamp(0, 4);
        final future = level < 0;
        final color = future
            ? Colors.transparent
            : level == 0
                ? c.surfaceAlt
                : Color.lerp(
                    c.primary.withValues(alpha: 0.28),
                    c.mint,
                    (level - 1) / 3,
                  )!;
        children.add(
          Container(
            width: 15,
            height: 15,
            margin: const EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4.5),
              border: future ? null : Border.all(color: c.border),
            ),
          ),
        );
      }
      columns.add(Padding(
        padding: const EdgeInsets.only(left: 5),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final label in Jalali.weekDaysShort)
                SizedBox(
                  height: 20,
                  child: Center(
                    child: Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontSize: 9.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: columns,
          ),
        ),
      ],
    );
  }
}

class DonutSlice {
  const DonutSlice({required this.value, required this.color, this.label});

  final int value;
  final Color color;
  final String? label;
}

class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.size = 140,
    this.stroke = 16,
    this.center,
  });

  final List<DonutSlice> slices;
  final double size;
  final double stroke;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = slices.fold<int>(0, (s, e) => s + e.value);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, t, _) => CustomPaint(
          painter: _DonutPainter(
            slices: total == 0 ? [] : slices,
            progress: t,
            stroke: stroke,
            track: c.surfaceAlt,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.progress,
    required this.stroke,
    required this.track,
  });

  final List<DonutSlice> slices;
  final double progress;
  final double stroke;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = slices.fold<int>(0, (s, e) => s + e.value);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);

    if (total == 0) return;
    var start = -math.pi / 2;
    const gap = 0.05;
    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = math.pi * 2 * (slice.value / total) * progress;
      if (sweep > gap) {
        canvas.drawArc(
          rect,
          start + gap / 2,
          sweep - gap,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = slice.color,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.slices != slices;
}
