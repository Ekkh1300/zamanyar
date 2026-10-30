import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/jalali.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.subject,
    required this.onToggle,
    this.onTap,
    this.showDate = false,
  });

  final TaskItem task;
  final Subject? subject;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final bool showDate;

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.high:
        return const Color(0xFFFF7091);
      case TaskPriority.medium:
        return const Color(0xFFFFC15E);
      case TaskPriority.low:
        return const Color(0xFF2FE3B4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final subjectColor =
        subject == null ? c.muted : Color(subject!.color);
    final done = task.done;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: done ? 0.62 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: c.isDark ? 0.72 : 1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: done ? c.border : c.border.withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CheckButton(
                done: done,
                color: subjectColor,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onToggle();
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                            decorationColor: c.muted,
                            color: done ? c.muted : c.text,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (subject != null)
                          _Meta(
                            icon: Icons.circle,
                            iconSize: 8,
                            color: subjectColor,
                            label: subject!.name,
                          ),
                        if (showDate)
                          _Meta(
                            icon: Icons.calendar_today_rounded,
                            iconSize: 11,
                            color: c.muted,
                            label: friendlyDate(fromKey(task.dateKey)),
                          ),
                        if (task.time != null)
                          _Meta(
                            icon: Icons.schedule_rounded,
                            iconSize: 12,
                            color: c.muted,
                            label: faDigits(task.time!),
                          ),
                        _Meta(
                          icon: Icons.timelapse_rounded,
                          iconSize: 12,
                          color: c.muted,
                          label: '${faDigits(task.durationMinutes)} دقیقه',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _priorityColor,
                      _priorityColor.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final double iconSize;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: context.colors.muted,
          ),
        ),
      ],
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    required this.done,
    required this.color,
    required this.onTap,
  });

  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: done
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.65)])
              : null,
          border: Border.all(
            color: done ? Colors.transparent : c.muted.withValues(alpha: 0.6),
            width: 1.6,
          ),
          boxShadow: done
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: AnimatedScale(
          scale: done ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
