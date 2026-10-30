import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/jalali.dart';
import '../core/theme.dart';
import '../main.dart';
import '../state/focus_timer.dart';
import 'widgets/charts.dart';
import 'widgets/glass.dart';
import 'widgets/subjects_sheet.dart';

class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final timer = TimerScope.of(context, listen: false);

    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: timer,
        builder: (context, _) {
          final c = context.colors;
          final width = MediaQuery.sizeOf(context).width;
          final ringSize = (width * 0.72).clamp(220.0, 300.0);
          final subject = state.subjectById(timer.subjectId);
          final isFocus = timer.isFocus;
          final running = timer.running;
          final palette = isFocus
              ? [c.primary, c.primarySoft, c.mint]
              : [c.mint, c.blue];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 150),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تمرکز',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 3),
                        Text(
                          'جلسه‌های عمیق، پیشرفت واقعی',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Pill(
                    label: '${faDigits(state.todayFocus)} دقیقه امروز',
                    icon: Icons.bolt_rounded,
                    color: c.amber,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: ringSize,
                        height: ringSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              palette.first.withValues(alpha: 0.14),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      ProgressRing(
                        progress: timer.progress,
                        size: ringSize,
                        stroke: 16,
                        colors: palette,
                        animate: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: palette.first.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: palette.first.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: running
                                          ? palette.last
                                          : c.muted.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isFocus
                                        ? (running
                                            ? 'در حال تمرکز'
                                            : timer.remainingSeconds <
                                                    timer.totalSeconds
                                                ? 'متوقف شده'
                                                : 'آمادهٔ شروع')
                                        : (running
                                            ? 'در حال استراحت'
                                            : 'استراحت کوتاه'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: palette.first,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              clockSeconds(timer.remainingSeconds),
                              style: TextStyle(
                                fontSize: ringSize * 0.2,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                                color: c.text,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subject?.name ?? 'بدون درس',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimerButton(
                    icon: Icons.refresh_rounded,
                    size: 52,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      timer.reset();
                    },
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: timer.toggle,
                    child: Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: palette),
                        boxShadow: [
                          BoxShadow(
                            color: palette.first.withValues(alpha: 0.45),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(
                        running
                            ? Icons.pause_rounded
                            : isFocus
                                ? Icons.play_arrow_rounded
                                : Icons.coffee_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _TimerButton(
                    icon: Icons.skip_next_rounded,
                    size: 52,
                    onTap: timer.skip,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: running ? 0.45 : 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final preset in FocusTimer.presets) ...[
                        _PresetChip(
                          minutes: preset,
                          selected: timer.selectedMinutes == preset,
                          onTap: running
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  timer.setPreset(preset);
                                },
                        ),
                        if (preset != FocusTimer.presets.last)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'درس مورد نظر',
                icon: Icons.menu_book_rounded,
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _SubjectChoice(
                      label: 'بدون درس',
                      color: c.muted,
                      selected: timer.subjectId == null,
                      onTap: () => timer.setSubject(null),
                    ),
                    for (final s in state.subjects) ...[
                      const SizedBox(width: 8),
                      _SubjectChoice(
                        label: s.name,
                        color: Color(s.color),
                        selected: timer.subjectId == s.id,
                        onTap: () => timer.setSubject(s.id),
                      ),
                    ],
                    const SizedBox(width: 8),
                    _SubjectChoice(
                      label: 'درس جدید',
                      color: c.primarySoft,
                      selected: false,
                      onTap: () async {
                        final subject = await openSubjectEditor(context);
                        if (subject != null) timer.setSubject(subject.id);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _TodayCard(
                minutes: state.todayFocus,
                sessions: state.sessionsOn(todayKey()),
                goal: state.dailyGoalMinutes,
              ),
              const SizedBox(height: 14),
              GlassCard(
                padding: const EdgeInsets.all(16),
                radius: 22,
                gradient: [
                  c.amber.withValues(alpha: 0.10),
                  c.primary.withValues(alpha: 0.06),
                ],
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_rounded,
                        size: 18, color: c.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'برای تمرکز بهتر: گوشی را دور بگذار، فقط یک هدف کوچک انتخاب کن و همین ۲۵ دقیقه را کامل کن. استراحت‌ها را هم جدی بگیر.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(height: 1.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  const _TimerButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: c.isDark ? 0.7 : 1),
          shape: BoxShape.circle,
          border: Border.all(color: c.border),
        ),
        child: Icon(icon, size: 24, color: c.muted),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.18) : c.surfaceAlt,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? c.primary.withValues(alpha: 0.6) : c.border,
          ),
        ),
        child: Text(
          '${faDigits(minutes)} دقیقه',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? c.primarySoft : c.muted,
          ),
        ),
      ),
    );
  }
}

class _SubjectChoice extends StatelessWidget {
  const _SubjectChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : c.surfaceAlt,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.6) : c.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? c.text : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.minutes,
    required this.sessions,
    required this.goal,
  });

  final int minutes;
  final int sessions;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ratio = goal == 0 ? 0.0 : (minutes / goal).clamp(0.0, 1.0);
    return GlassCard(
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('تمرکز امروز',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '٪${faDigits((ratio * 100).round())} از هدف',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: c.surfaceAlt,
                valueColor: AlwaysStoppedAnimation(
                  c.isDark ? c.mint : c.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatPill(
                icon: Icons.timer_outlined,
                label: '${faDigits(minutes)} دقیقه',
                color: c.primarySoft,
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.bolt_rounded,
                label: '${faDigits(sessions)} جلسه',
                color: c.amber,
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.flag_rounded,
                label: 'هدف ${faDigits(goal)} د',
                color: c.mint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: c.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
