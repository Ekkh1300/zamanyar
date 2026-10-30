import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/jalali.dart';
import '../core/theme.dart';
import '../main.dart';
import 'widgets/charts.dart';
import 'widgets/glass.dart';
import 'widgets/task_editor.dart';
import 'widgets/task_tile.dart';

enum _Filter { all, pending, done }

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  DateTime _selected = dateOnly(DateTime.now());
  int _weekOffset = 0;
  _Filter _filter = _Filter.all;

  List<DateTime> get _days {
    final start = startOfWeek(DateTime.now())
        .add(Duration(days: _weekOffset * 7));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  void _shiftWeek(int delta) => setState(() => _weekOffset += delta);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = context.colors;
    final key = dateKey(_selected);
    final all = state.tasksOn(key);
    final tasks = switch (_filter) {
      _Filter.all => all,
      _Filter.pending => all.where((t) => !t.done).toList(),
      _Filter.done => all.where((t) => t.done).toList(),
    };
    final doneCount = all.where((t) => t.done).length;
    final totalMinutes = all.fold<int>(0, (s, t) => s + t.durationMinutes);
    final isToday = key == todayKey();

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
                    Row(
                      children: [
                        Text('کارها',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(width: 8),
                        if (isToday)
                          Pill(
                            label: 'امروز',
                            color: c.mint,
                            fontSize: 10,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${jalaliLong(_selected)} • ${faDigits(all.length)} کار',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final saved = await openTaskEditor(
                    context,
                    dateKey: key,
                  );
                  if (saved && context.mounted) _toast(context, 'به برنامه اضافه شد');
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [c.primary, c.primarySoft]),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: c.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _ArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => _shiftWeek(-1),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    for (final day in _days)
                      Expanded(
                        child: _DayCell(
                          day: day,
                          selected: dateKey(day) == key,
                          isToday: dateKey(day) == todayKey(),
                          taskCount: state.tasksOn(dateKey(day)).length,
                          doneCount: state
                              .tasksOn(dateKey(day))
                              .where((t) => t.done)
                              .length,
                          onTap: () => setState(() => _selected = day),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _ArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _shiftWeek(1),
              ),
            ],
          ),
          if (_weekOffset != 0 || !isToday) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _weekOffset = 0;
                  _selected = dateOnly(DateTime.now());
                }),
                icon: Icon(Icons.today_rounded, size: 15, color: c.primarySoft),
                label: Text(
                  'برگشت به امروز',
                  style: TextStyle(fontSize: 11.5, color: c.primarySoft),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _FilterChip(
                label: 'همه',
                count: all.length,
                selected: _filter == _Filter.all,
                onTap: () => setState(() => _filter = _Filter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'در انتظار',
                count: all.where((t) => !t.done).length,
                selected: _filter == _Filter.pending,
                onTap: () => setState(() => _filter = _Filter.pending),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'انجام‌شده',
                count: doneCount,
                selected: _filter == _Filter.done,
                onTap: () => setState(() => _filter = _Filter.done),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (all.isNotEmpty) ...[
            GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              radius: 20,
              child: Row(
                children: [
                  ProgressRing(
                    progress: all.isEmpty ? 0 : doneCount / all.length,
                    size: 52,
                    stroke: 6,
                    colors: [c.primary, c.mint],
                    trackColor: c.primary.withValues(alpha: 0.34),
                    animate: false,
                    child: Text(
                      '٪${faDigits(all.isEmpty ? 0 : (doneCount / all.length * 100).round())}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doneCount == all.length
                              ? 'همهٔ کارهای این روز انجام شد 🎉'
                              : '${faDigits(all.length - doneCount)} کار باقی مانده',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${faDigits(doneCount)} انجام‌شده از ${faDigits(all.length)} • ${prettyMinutes(totalMinutes)} زمان‌بندی',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (tasks.isEmpty)
            EmptyState(
              icon: _filter == _Filter.done
                  ? Icons.emoji_events_rounded
                  : Icons.event_note_rounded,
              title: switch (_filter) {
                _Filter.all => 'این روز خالی است',
                _Filter.pending => 'کاری در انتظار نیست',
                _Filter.done => 'هنوز کاری انجام نشده',
              },
              subtitle: _filter == _Filter.all
                  ? 'اولین کار این روز را اضافه کن.'
                  : 'فیلتر را تغییر بده یا کار جدید اضافه کن.',
              action: _filter == _Filter.all ? 'افزودن کار' : null,
              onAction: () => openTaskEditor(context, dateKey: key),
            )
          else
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey(task.id),
                  direction: DismissDirection.horizontal,
                  background: const _DeleteBackground(alignEnd: false),
                  secondaryBackground: const _DeleteBackground(alignEnd: true),
                  onDismissed: (_) {
                    HapticFeedback.mediumImpact();
                    state.deleteTask(task.id);
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('«${task.title}» حذف شد'),
                        action: SnackBarAction(
                          label: 'بازگردانی',
                          textColor: c.primarySoft,
                          onPressed: () => state.addTask(task),
                        ),
                      ),
                    );
                  },
                  child: TaskTile(
                    task: task,
                    subject: state.subjectById(task.subjectId),
                    showDate: false,
                    onToggle: () {
                      state.toggleTask(task.id);
                    },
                    onTap: () => openTaskEditor(context, task: task),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.alignEnd});

  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: c.coral.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.coral.withValues(alpha: 0.3)),
      ),
      child: Icon(Icons.delete_outline_rounded, color: c.coral),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 48,
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: c.isDark ? 0.6 : 1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: Icon(icon, size: 18, color: c.muted),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.taskCount,
    required this.doneCount,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final int taskCount;
  final int doneCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final j = Jalali.fromDateTime(day);
    final allDone = taskCount > 0 && doneCount == taskCount;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 72,
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.primary, c.primary.withValues(alpha: 0.75)],
                  )
                : null,
            color: selected ? null : c.surface.withValues(alpha: c.isDark ? 0.55 : 1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : isToday
                      ? c.primary.withValues(alpha: 0.45)
                      : c.border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: c.primary.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Jalali.weekDaysShort[Jalali.weekIndex(day)],
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : c.muted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                faDigits(j.day),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : c.text,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 4.5,
                height: 4.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: taskCount == 0
                      ? Colors.transparent
                      : selected
                          ? Colors.white
                          : allDone
                              ? c.mint
                              : c.amber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.18) : c.surfaceAlt,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? c.primary.withValues(alpha: 0.6) : c.border,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? c.primarySoft : c.muted,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? c.primary.withValues(alpha: 0.25)
                    : c.border,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                faDigits(count),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? c.primarySoft : c.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
