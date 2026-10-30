import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/jalali.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../models/models.dart';
import 'glass.dart';
import 'subjects_sheet.dart';

Future<void> openSubjectsManager(BuildContext context) {
  return showAppSheet<void>(context, const SubjectsManagerSheet());
}

/// Full list of subjects with weekly goals, plus the entry point for
/// adding any subject the user wants.
class SubjectsManagerSheet extends StatelessWidget {
  const SubjectsManagerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = AppScope.of(context);
    final weekMinutes =
        state.subjectMinutesSince(startOfWeek(DateTime.now()));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [c.primary, c.mint]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('درس‌ها',
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(
                      'هر درسی که می‌خواهی اضافه کن؛ رنگ و هدف هفتگی هم دارد',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GradientButton(
            label: 'افزودن درس جدید',
            icon: Icons.add_rounded,
            onPressed: () => openSubjectEditor(context),
          ),
          const SizedBox(height: 18),
          if (state.subjects.isEmpty)
            EmptyState(
              icon: Icons.menu_book_rounded,
              title: 'هنوز درسی اضافه نکرده‌ای',
              subtitle:
                  'ریاضی، زبان، فیزیک، برنامه‌نویسی… هر درسی که می‌خواهی بساز.',
              action: 'افزودن درس',
              onAction: () => openSubjectEditor(context),
            )
          else ...[
            Text(
              '${faDigits(state.subjects.length)} درس',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: c.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            for (final subject in state.subjects)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SubjectCard(
                  subject: subject,
                  weekMinutes: weekMinutes[subject.id] ?? 0,
                  onTap: () => openSubjectEditor(context, subject: subject),
                ),
              ),
          ],
          const SizedBox(height: 6),
          Text(
            'با لمس هر درس می‌توانی نام، رنگ و هدف هفتگی‌اش را عوض کنی یا حذفش کنی.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.weekMinutes,
    required this.onTap,
  });

  final Subject subject;
  final int weekMinutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = Color(subject.color);
    final goal = subject.weeklyGoalMinutes <= 0
        ? 1
        : subject.weeklyGoalMinutes;
    final progress = (weekMinutes / goal).clamp(0.0, 1.0);

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.menu_book_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'هدف هفتگی ${prettyMinutes(subject.weeklyGoalMinutes)} • این هفته ${prettyMinutes(weekMinutes)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: c.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_left_rounded, color: c.muted, size: 20),
        ],
      ),
    );
  }
}
