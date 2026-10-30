import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/jalali.dart';
import '../core/theme.dart';
import '../main.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'widgets/charts.dart';
import 'widgets/glass.dart';
import 'widgets/subjects_manager.dart';
import 'widgets/subjects_sheet.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = context.colors;
    final weekStart = startOfWeek(state.today);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final subjectMinutes = state.subjectMinutesSince(weekStart);
    final weekFocus = state.weekFocus;
    final average = (state.weekFocusTotal / 7).round();

    final legend = <_LegendItem>[
      for (final s in state.subjects)
        if ((subjectMinutes[s.id] ?? 0) > 0)
          _LegendItem(
            name: s.name,
            color: Color(s.color),
            minutes: subjectMinutes[s.id]!,
          ),
      if ((subjectMinutes['none'] ?? 0) > 0)
        _LegendItem(
          name: 'بدون درس',
          color: c.muted,
          minutes: subjectMinutes['none']!,
        ),
    ]..sort((a, b) => b.minutes.compareTo(a.minutes));

    final slices = [
      for (final item in legend.take(5))
        DonutSlice(value: item.minutes, color: item.color),
    ];

    final bestIndex = weekFocus.isEmpty
        ? 0
        : weekFocus.indexOf(weekFocus.reduce((a, b) => a > b ? a : b));
    final bestDay = weekFocus[bestIndex];
    final goalsTotal = state.subjects.fold<int>(
      0,
      (sum, s) => sum + s.weeklyGoalMinutes,
    );
    final goalPercent =
        goalsTotal == 0 ? 0 : ((state.weekFocusTotal / goalsTotal) * 100).round();

    final achievements = <_Achievement>[
      _Achievement(
        label: 'شروع مسیر',
        icon: Icons.rocket_launch_rounded,
        unlocked: state.totalFocusMinutes > 0 || state.completedTasksTotal > 0,
        color: c.primary,
      ),
      _Achievement(
        label: '۳ روز پیوسته',
        icon: Icons.local_fire_department_rounded,
        unlocked: state.streak >= 3,
        color: c.coral,
      ),
      _Achievement(
        label: '۷ روز پیوسته',
        icon: Icons.whatshot_rounded,
        unlocked: state.streak >= 7,
        color: c.amber,
      ),
      _Achievement(
        label: '۱۰ ساعت تمرکز',
        icon: Icons.timer_rounded,
        unlocked: state.totalFocusMinutes >= 600,
        color: c.mint,
      ),
      _Achievement(
        label: '۲۵ ساعت تمرکز',
        icon: Icons.workspace_premium_rounded,
        unlocked: state.totalFocusMinutes >= 1500,
        color: c.blue,
      ),
      _Achievement(
        label: '۵۰ کار انجام‌شده',
        icon: Icons.task_alt_rounded,
        unlocked: state.completedTasksTotal >= 50,
        color: c.pink,
      ),
    ];

    int levelOf(DateTime day) {
      final key = dateKey(day);
      final score = state.focusMinutesOn(key) + state.tasksDoneOn(key) * 10;
      if (score == 0) return 0;
      if (score < 15) return 1;
      if (score < 35) return 2;
      if (score < 60) return 3;
      return 4;
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 150),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('آمار و پیشرفت',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 3),
                    Text(
                      '${jalaliShort(weekStart)} تا ${jalaliShort(weekEnd)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Pill(
                label: '٪${faDigits(goalPercent)} از هدف هفته',
                icon: Icons.flag_rounded,
                color: c.primarySoft,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _SummaryCard(
                label: 'تمرکز این هفته',
                value: faDigits(state.weekFocusTotal),
                unit: 'دقیقه',
                icon: Icons.timer_outlined,
                color: c.primary,
              ),
              const SizedBox(width: 10),
              _SummaryCard(
                label: 'کارهای انجام‌شده',
                value: faDigits(state.weekTasksDone),
                unit: 'کار',
                icon: Icons.task_alt_rounded,
                color: c.mint,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryCard(
                label: 'روزهای پیوسته',
                value: faDigits(state.streak),
                unit: 'روز',
                icon: Icons.local_fire_department_rounded,
                color: c.coral,
              ),
              const SizedBox(width: 10),
              _SummaryCard(
                label: 'میانگین روزانه',
                value: faDigits(average),
                unit: 'دقیقه',
                icon: Icons.insights_rounded,
                color: c.amber,
              ),
            ],
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'تمرکز در هفته',
            icon: Icons.bar_chart_rounded,
            action: '${faDigits(state.weekFocusTotal)} دقیقه',
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
            child: Column(
              children: [
                WeeklyBars(
                  values: weekFocus,
                  labels: [
                    for (final d in state.weekDays)
                      Jalali.weekDaysShort[Jalali.weekIndex(d)],
                  ],
                  highlightIndex: Jalali.weekIndex(state.today),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, size: 14, color: c.amber),
                    const SizedBox(width: 6),
                    Text(
                      bestDay == 0
                          ? 'هنوز تمرکزی ثبت نشده'
                          : 'بهترین روز: ${Jalali.dayName(state.weekDays[bestIndex])} با ${prettyMinutes(bestDay)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'نقشهٔ فعالیت',
            icon: Icons.grid_view_rounded,
            action: '۶ هفتهٔ گذشته',
          ),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Heatmap(
                  end: state.today,
                  weeks: 6,
                  levelOf: levelOf,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('کم',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(fontSize: 9.5)),
                    const SizedBox(width: 6),
                    for (var i = 0; i < 4; i++) ...[
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            c.primary.withValues(alpha: 0.25),
                            c.mint,
                            i / 3,
                          ),
                          borderRadius: BorderRadius.circular(3.5),
                        ),
                      ),
                    ],
                    const SizedBox(width: 5),
                    Text('زیاد',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(fontSize: 9.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'درس‌ها',
            icon: Icons.menu_book_rounded,
            action: 'مدیریت',
            onAction: () => openSubjectsManager(context),
          ),
          if (legend.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded,
                      color: c.primarySoft, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('این هفته تمرکزی ثبت نشده',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 3),
                        Text(
                          'یک جلسهٔ تمرکز شروع کن تا نمودار درس‌ها شکل بگیرد.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  DonutChart(
                    slices: slices,
                    size: 132,
                    stroke: 15,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          clockMinutes(state.weekFocusTotal),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'ساعت',
                          style: TextStyle(fontSize: 9.5, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        for (final item in legend.take(4))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: c.text,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                                Text(
                                  prettyMinutes(item.minutes),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: c.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: state.subjects.isEmpty
                ? Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded, color: c.muted),
                      const SizedBox(width: 8),
                      Text('درسی اضافه نکرده‌ای',
                          style: Theme.of(context).textTheme.bodySmall),
                      const Spacer(),
                      Pill(
                        label: 'افزودن درس',
                        color: c.primarySoft,
                        onTap: () => openSubjectEditor(context),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      for (var i = 0; i < state.subjects.length; i++) ...[
                        _SubjectGoalRow(
                          subject: state.subjects[i],
                          minutes: subjectMinutes[state.subjects[i].id] ?? 0,
                          onTap: () => openSubjectEditor(
                            context,
                            subject: state.subjects[i],
                          ),
                        ),
                        if (i != state.subjects.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: c.border, height: 1),
                          ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 26),
          const SectionHeader(
            title: 'دستاوردها',
            icon: Icons.military_tech_rounded,
          ),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - 16) / 3;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in achievements)
                      SizedBox(
                        width: tileWidth,
                        child: _AchievementTile(achievement: a),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _InsightCard(
            text: _insight(state, goalPercent, weekFocus),
          ),
        ],
      ),
    );
  }

  String _insight(AppState state, int goalPercent, List<int> weekFocus) {
    if (state.weekFocusTotal == 0) {
      return 'این هفته هنوز جلسهٔ تمرکزی ثبت نکرده‌ای. با یک جلسهٔ ۲۵ دقیقه‌ای شروع کن؛ کوچک‌ترین قدم هم حساب می‌شود.';
    }
    if (goalPercent >= 100) {
      return 'عالی! به هدف هفتگی درس‌هایت رسیده‌ای. حالا می‌توانی هدف را کمی بالاتر ببری.';
    }
    if (state.streak >= 3) {
      return '${faDigits(state.streak)} روز پیوسته در حال پیشرفتی. ثبات، مهم‌ترین راز موفقیت در درس خواندن است.';
    }
    if (weekFocus.any((v) => v == 0)) {
      return 'در این هفته روزهای بدون تمرکز هم داشته‌ای. برای فردا فقط یک جلسهٔ کوتاه برنامه‌ریزی کن.';
    }
    return 'مسیرت درست است؛ برای رسیدن به هدف هفته حدود ${faDigits((100 - goalPercent).clamp(0, 100))} درصد دیگر باقی مانده.';
  }
}

class _LegendItem {
  const _LegendItem({
    required this.name,
    required this.color,
    required this.minutes,
  });

  final String name;
  final Color color;
  final int minutes;
}

class _Achievement {
  const _Achievement({
    required this.label,
    required this.icon,
    required this.unlocked,
    required this.color,
  });

  final String label;
  final IconData icon;
  final bool unlocked;
  final Color color;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Text(unit, style: TextStyle(fontSize: 10, color: c.muted)),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectGoalRow extends StatelessWidget {
  const _SubjectGoalRow({
    required this.subject,
    required this.minutes,
    required this.onTap,
  });

  final Subject subject;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = Color(subject.color);
    final ratio = subject.weeklyGoalMinutes == 0
        ? 0.0
        : (minutes / subject.weeklyGoalMinutes).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.menu_book_rounded, size: 17, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${faDigits(minutes)} / ${faDigits(subject.weeklyGoalMinutes)} د',
                style: TextStyle(fontSize: 10.5, color: c.muted),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_left_rounded, size: 16, color: c.muted),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: c.surfaceAlt,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final _Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = achievement;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: a.unlocked ? a.color.withValues(alpha: 0.10) : c.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: a.unlocked
              ? a.color.withValues(alpha: 0.35)
              : c.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: a.unlocked
                  ? LinearGradient(
                      colors: [a.color, a.color.withValues(alpha: 0.6)],
                    )
                  : null,
              color: a.unlocked ? null : c.border,
            ),
            child: Icon(
              a.unlocked ? a.icon : Icons.lock_rounded,
              size: 18,
              color: a.unlocked ? Colors.white : c.muted.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            a.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 9.5,
              height: 1.4,
              fontWeight: a.unlocked ? FontWeight.w700 : FontWeight.w500,
              color: a.unlocked ? c.text : c.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 22,
      gradient: [
        c.mint.withValues(alpha: 0.10),
        c.primary.withValues(alpha: 0.06),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.mint.withValues(alpha: 0.16),
            ),
            child: Icon(Icons.auto_awesome_rounded, size: 17, color: c.mint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'پیشنهاد زمانیار',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: c.mint,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
