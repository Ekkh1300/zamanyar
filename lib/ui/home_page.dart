import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/jalali.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import 'widgets/charts.dart';
import 'widgets/glass.dart';
import 'widgets/subjects_manager.dart';
import 'widgets/task_editor.dart';
import 'widgets/task_tile.dart';
import 'widgets/settings_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = context.colors;
    final now = DateTime.now();
    final today = state.today;
    final goal = state.dailyGoalMinutes;
    final focus = state.todayFocus;
    final progress = goal == 0 ? 0.0 : (focus / goal).clamp(0.0, 1.0);
    final percent = goal == 0 ? 0 : ((focus / goal) * 100).round();

    final todayTasks = state.todayTasks;
    final pending = todayTasks.where((t) => !t.done).take(3).toList();
    final preview = pending.isNotEmpty
        ? pending
        : todayTasks.where((t) => t.done).take(3).toList();
    final greeting = greetingFor(now.hour);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 150),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => openSettings(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [c.primary, c.pink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      state.name.isEmpty
                          ? 'ز'
                          : state.name.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting${state.name.isEmpty ? '' : '، ${state.name}'}',
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      jalaliLong(now),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StreakChip(streak: state.streak),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => openSettings(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.surface.withValues(alpha: c.isDark ? 0.7 : 1),
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border),
                  ),
                  child: Icon(Icons.settings_rounded, size: 19, color: c.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _FocusHero(
            focusMinutes: focus,
            goal: goal,
            progress: progress,
            percent: percent,
            sessions: state.sessionsOn(todayKey()),
            tasksDone: state.todayDoneTasks,
            tasksTotal: todayTasks.length,
            onStart: () {
              onOpenTab(2);
            },
            onOpenPlan: () => onOpenTab(1),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                icon: Icons.local_fire_department_rounded,
                color: c.coral,
                value: faDigits(state.streak),
                label: 'روز پیوسته',
              ),
              const SizedBox(width: 10),
              _MiniStat(
                icon: Icons.check_circle_rounded,
                color: c.mint,
                value:
                    '${faDigits(state.todayDoneTasks)}/${faDigits(todayTasks.length)}',
                label: 'کارهای امروز',
              ),
              const SizedBox(width: 10),
              _MiniStat(
                icon: Icons.timelapse_rounded,
                color: c.amber,
                value: faDigits(state.weekFocusTotal),
                label: 'دقیقه این هفته',
              ),
            ],
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'برنامهٔ امروز',
            icon: Icons.wb_sunny_rounded,
            action: 'همهٔ کارها',
            onAction: () => onOpenTab(1),
          ),
          if (preview.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded,
                      color: c.primarySoft, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    'امروز کاری ثبت نشده',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'یک کار کوچک اضافه کن و شروع کن.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  Pill(
                    label: 'افزودن کار',
                    icon: Icons.add_rounded,
                    color: c.primarySoft,
                    onTap: () => openTaskEditor(context),
                  ),
                ],
              ),
            )
          else
            ...preview.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TaskTile(
                  task: task,
                  subject: state.subjectById(task.subjectId),
                  onToggle: () => state.toggleTask(task.id),
                  onTap: () => openTaskEditor(context, task: task),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'شروع سریع',
            icon: Icons.bolt_rounded,
            action: 'درس‌ها',
            onAction: () => openSubjectsManager(context),
          ),
          if (state.subjects.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        Icon(Icons.menu_book_rounded, color: c.primarySoft),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('هر درسی که می‌خواهی اضافه کن',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 3),
                        Text(
                          'ریاضی، زبان، فیزیک… با رنگ و هدف هفتگی.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pill(
                    label: 'درس جدید',
                    icon: Icons.add_rounded,
                    color: c.primarySoft,
                    onTap: () => openSubjectsManager(context),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: state.subjects.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final subject = state.subjects[index];
                  final minutes = state
                          .subjectMinutesSince(startOfWeek(today))[subject.id] ??
                      0;
                  return _SubjectQuickCard(
                    subject: subject,
                    minutes: minutes,
                    onTap: () {
                      TimerScope.of(context, listen: false)
                          .setSubject(subject.id);
                      onOpenTab(2);
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'این هفته',
            icon: Icons.calendar_month_rounded,
            action: 'آمار کامل',
            onAction: () => onOpenTab(3),
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '${faDigits(state.weekFocusTotal)} دقیقه تمرکز',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    Text(
                      '${faDigits(state.weekTasksDone)} کار انجام‌شده',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: _WeekCell(
                          day: state.weekDays[i],
                          minutes: state.focusMinutesOn(
                            dateKey(state.weekDays[i]),
                          ),
                          isToday: state.weekDays[i] == today,
                          onTap: () => onOpenTab(3),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _QuoteCard(quote: quoteOfToday(now)),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.amber.withValues(alpha: 0.18),
            c.coral.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 16, color: c.amber),
          const SizedBox(width: 3),
          Text(
            faDigits(streak),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.amber,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            'روز',
            style: TextStyle(fontSize: 10, color: c.amber.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _FocusHero extends StatelessWidget {
  const _FocusHero({
    required this.focusMinutes,
    required this.goal,
    required this.progress,
    required this.percent,
    required this.sessions,
    required this.tasksDone,
    required this.tasksTotal,
    required this.onStart,
    required this.onOpenPlan,
  });

  final int focusMinutes;
  final int goal;
  final double progress;
  final int percent;
  final int sessions;
  final int tasksDone;
  final int tasksTotal;
  final VoidCallback onStart;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF4A35C9), Color(0xFF7C5CFF), Color(0xFF5B7BFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EF6).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -70,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF9CFFD9),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'تمرکز امروز',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          clockMinutes(focusMinutes),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'از هدف ${faDigits(goal)} دقیقه‌ای',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.68),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _HeroPill(
                              icon: Icons.check_circle_rounded,
                              label:
                                  '${faDigits(tasksDone)}/${faDigits(tasksTotal)} کار',
                            ),
                            const SizedBox(width: 8),
                            _HeroPill(
                              icon: Icons.bolt_rounded,
                              label: '${faDigits(sessions)} جلسه',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ProgressRing(
                    progress: progress,
                    size: 104,
                    stroke: 10,
                    colors: const [Colors.white, Color(0xFF7CFFD4)],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '٪${faDigits(percent)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'هدف',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GradientButton(
                      label: 'شروع تمرکز',
                      icon: Icons.play_arrow_rounded,
                      height: 46,
                      gradient: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.88),
                      ],
                      textColor: const Color(0xFF3D2C9E),
                      onPressed: onStart,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: onOpenPlan,
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.format_list_bulleted_rounded,
                                size: 17, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'برنامه',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectQuickCard extends StatelessWidget {
  const _SubjectQuickCard({
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
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              color.withValues(alpha: c.isDark ? 0.22 : 0.14),
              c.surface.withValues(alpha: c.isDark ? 0.6 : 1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.menu_book_rounded, size: 16, color: color),
            ),
            const Spacer(),
            Text(
              subject.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 4,
                backgroundColor: c.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${faDigits(minutes)} از ${faDigits(subject.weeklyGoalMinutes)} د',
              style: TextStyle(fontSize: 9, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCell extends StatelessWidget {
  const _WeekCell({
    required this.day,
    required this.minutes,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final int minutes;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = minutes > 0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            Jalali.weekDaysShort[Jalali.weekIndex(day)],
            style: TextStyle(
              fontSize: 10,
              color: isToday ? c.primarySoft : c.muted,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isToday
                  ? LinearGradient(colors: [c.primary, c.primarySoft])
                  : null,
              color: isToday
                  ? null
                  : active
                      ? c.mint.withValues(alpha: 0.14)
                      : c.surfaceAlt,
              border: Border.all(
                color: isToday
                    ? Colors.transparent
                    : active
                        ? c.mint.withValues(alpha: 0.35)
                        : c.border,
              ),
            ),
            child: Center(
              child: Text(
                faDigits(Jalali.fromDateTime(day).day),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isToday
                      ? Colors.white
                      : active
                          ? c.mint
                          : c.muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: minutes > 0 ? c.mint : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      radius: 22,
      gradient: [
        c.primary.withValues(alpha: 0.10),
        c.mint.withValues(alpha: 0.05),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primary.withValues(alpha: 0.16),
            ),
            child: Icon(Icons.format_quote_rounded, size: 18, color: c.primarySoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'انگیزهٔ امروز',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: c.primarySoft,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  quote,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12.5, height: 1.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
