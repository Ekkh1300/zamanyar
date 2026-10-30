import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/jalali.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'glass.dart';
import 'jalali_picker.dart';
import 'subjects_sheet.dart';

Future<bool> openTaskEditor(
  BuildContext context, {
  TaskItem? task,
  String? dateKey,
}) async {
  final state = AppScope.of(context, listen: false);
  final result = await showAppSheet<bool>(
    context,
    TaskEditorSheet(
      state: state,
      task: task,
      initialDateKey: dateKey ?? todayKey(),
    ),
  );
  return result ?? false;
}

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({
    super.key,
    required this.state,
    this.task,
    required this.initialDateKey,
  });

  final AppState state;
  final TaskItem? task;
  final String initialDateKey;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.task?.title ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.task?.note ?? '');

  late String? _subjectId = widget.task?.subjectId;
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.medium;
  late int _duration = widget.task?.durationMinutes ?? 30;
  late DateTime _date = fromKey(widget.task?.dateKey ?? widget.initialDateKey);
  late TimeOfDay? _time = _parseTime(widget.task?.time);
  String? _error;

  static TimeOfDay? _parseTime(String? value) {
    if (value == null || !value.contains(':')) return null;
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  bool get _isEditing => widget.task != null;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showJalaliDatePicker(context, initial: _date);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _addSubject() async {
    final subject = await openSubjectEditor(context);
    if (subject != null && mounted) setState(() => _subjectId = subject.id);
  }

  String? get _timeString {
    if (_time == null) return null;
    return '${two(_time!.hour)}:${two(_time!.minute)}';
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'یک عنوان برای کار بنویس');
      HapticFeedback.vibrate();
      return;
    }
    final existing = widget.task;
    final task = TaskItem(
      id: existing?.id ?? newId(),
      title: title,
      dateKey: dateKey(_date),
      subjectId: _subjectId,
      priority: _priority,
      time: _timeString,
      durationMinutes: _duration,
      done: existing?.done ?? false,
      createdAt: existing?.createdAt ?? DateTime.now(),
      completedAt: existing?.completedAt,
      note: _note.text.trim(),
    );
    if (existing == null) {
      widget.state.addTask(task);
    } else {
      widget.state.updateTask(task);
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف این کار؟'),
        content: const Text('این کار برای همیشه حذف می‌شود.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: TextStyle(color: ctx.colors.coral)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.state.deleteTask(widget.task!.id);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final subjects = widget.state.subjects;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      c.primary.withValues(alpha: 0.25),
                      c.mint.withValues(alpha: 0.18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: Icon(
                  _isEditing ? Icons.edit_rounded : Icons.add_task_rounded,
                  color: c.primarySoft,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'ویرایش کار' : 'کار جدید',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'برنامه‌ات را دقیق و قابل اجرا بساز',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_isEditing)
                GestureDetector(
                  onTap: _delete,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c.coral.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: c.coral, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _title,
            autofocus: !_isEditing,
            textInputAction: TextInputAction.next,
            maxLength: 80,
            style: Theme.of(context).textTheme.titleMedium,
            decoration: InputDecoration(
              hintText: 'مثلاً: حل تمرین‌های فصل ۳',
              counterText: '',
              errorText: _error,
              prefixIcon: Icon(Icons.task_alt_rounded, color: c.muted, size: 20),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 2,
            minLines: 1,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'یادداشت (اختیاری)',
              prefixIcon: Icon(Icons.notes_rounded, color: c.muted, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          _Label('درس'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SubjectChip(
                label: 'بدون درس',
                color: c.muted,
                selected: _subjectId == null,
                onTap: () => setState(() => _subjectId = null),
              ),
              for (final s in subjects)
                _SubjectChip(
                  label: s.name,
                  color: Color(s.color),
                  selected: _subjectId == s.id,
                  onTap: () => setState(() => _subjectId = s.id),
                ),
              _AddSubjectChip(onTap: _addSubject),
            ],
          ),
          const SizedBox(height: 20),
          _Label('اهمیت'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final p in TaskPriority.values) ...[
                Expanded(
                  child: _PriorityChip(
                    priority: p,
                    selected: _priority == p,
                    onTap: () => setState(() => _priority = p),
                  ),
                ),
                if (p != TaskPriority.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _Label('زمان تقریبی'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in [15, 25, 30, 45, 60, 90])
                _MiniChoice(
                  label: '${faDigits(m)} د',
                  selected: _duration == m,
                  onTap: () => setState(() => _duration = m),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _Label('روز انجام'),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniChoice(
                label: 'امروز',
                selected: dateKey(_date) == todayKey(),
                onTap: () => setState(() => _date = DateTime.now()),
              ),
              const SizedBox(width: 8),
              _MiniChoice(
                label: 'فردا',
                selected: dateKey(_date) ==
                    dateKey(DateTime.now().add(const Duration(days: 1))),
                onTap: () => setState(
                  () => _date = DateTime.now().add(const Duration(days: 1)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_rounded, size: 16, color: c.primarySoft),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            jalaliShort(_date),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Label('ساعت'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 18, color: c.muted),
                        const SizedBox(width: 8),
                        Text(
                          _time == null
                              ? 'بدون ساعت مشخص'
                              : faDigits(_time!.format(context)),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _time == null ? c.muted : c.text,
                          ),
                        ),
                        const Spacer(),
                        if (_time != null)
                          GestureDetector(
                            onTap: () => setState(() => _time = null),
                            child: Icon(Icons.close_rounded,
                                size: 18, color: c.muted),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          GradientButton(
            label: _isEditing ? 'ذخیره تغییرات' : 'افزودن به برنامه',
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: context.colors.muted,
            fontSize: 12.5,
          ),
    );
  }
}

class _MiniChoice extends StatelessWidget {
  const _MiniChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.18) : c.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? c.primary.withValues(alpha: 0.7) : c.border,
          ),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? c.primarySoft : c.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : c.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.65) : c.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
                fontSize: 12.5,
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

class _AddSubjectChip extends StatelessWidget {
  const _AddSubjectChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.primary.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 16, color: c.primarySoft),
            const SizedBox(width: 5),
            Text(
              'درس جدید',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: c.primarySoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final TaskPriority priority;
  final bool selected;
  final VoidCallback onTap;

  Color _color(BuildContext context) {
    switch (priority) {
      case TaskPriority.high:
        return context.colors.coral;
      case TaskPriority.medium:
        return context.colors.amber;
      case TaskPriority.low:
        return context.colors.mint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _color(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : c.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.7) : c.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              priority == TaskPriority.high
                  ? Icons.local_fire_department_rounded
                  : priority == TaskPriority.medium
                      ? Icons.bolt_rounded
                      : Icons.spa_rounded,
              size: 16,
              color: selected ? color : c.muted,
            ),
            const SizedBox(width: 6),
            Text(
              priority.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? c.text : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
