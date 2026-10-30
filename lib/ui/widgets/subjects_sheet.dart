import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/jalali.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../state/app_state.dart';
import '../../models/models.dart';
import 'glass.dart';

Future<bool> openSubjectEditor(BuildContext context, {Subject? subject}) async {
  final result = await showAppSheet<bool>(
    context,
    SubjectEditorSheet(subject: subject),
  );
  return result ?? false;
}

class SubjectEditorSheet extends StatefulWidget {
  const SubjectEditorSheet({super.key, this.subject});

  final Subject? subject;

  @override
  State<SubjectEditorSheet> createState() => _SubjectEditorSheetState();
}

class _SubjectEditorSheetState extends State<SubjectEditorSheet> {
  late final AppState _state = AppScope.of(context, listen: false);
  late final TextEditingController _name =
      TextEditingController(text: widget.subject?.name ?? '');
  late int _color =
      widget.subject?.color ?? AppColors.subjectPalette.first.toARGB32();
  late int _goal = widget.subject?.weeklyGoalMinutes ?? 180;

  bool get _isEditing => widget.subject != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      HapticFeedback.vibrate();
      return;
    }
    final subject = Subject(
      id: widget.subject?.id ?? newId(),
      name: name,
      color: _color,
      weeklyGoalMinutes: _goal,
    );
    if (_isEditing) {
      _state.updateSubject(subject);
    } else {
      _state.addSubject(subject);
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف درس؟'),
        content: const Text(
          'کارهای مربوط به این درس حذف نمی‌شوند، اما بدون درس می‌شوند.',
        ),
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
      _state.deleteSubject(widget.subject!.id);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = Color(_color);

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
                  color: color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.menu_book_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'ویرایش درس' : 'درس جدید',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'هدف هفتگی تعیین کن تا پیشرفتت را ببینی',
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
                    child:
                        Icon(Icons.delete_outline_rounded, color: c.coral, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            autofocus: !_isEditing,
            maxLength: 30,
            decoration: const InputDecoration(
              hintText: 'نام درس، مثلاً: ریاضی',
              counterText: '',
              prefixIcon: Icon(Icons.edit_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'رنگ درس',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: c.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final swatch in AppColors.subjectPalette)
                GestureDetector(
                  onTap: () => setState(() => _color = swatch.toARGB32()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == swatch.toARGB32()
                            ? c.text
                            : Colors.transparent,
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: swatch.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _color == swatch.toARGB32()
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                'هدف هفتگی',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: c.muted, fontSize: 12.5),
              ),
              const Spacer(),
              Pill(label: prettyMinutes(_goal), color: color),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in [60, 120, 180, 240, 300, 420])
                GestureDetector(
                  onTap: () => setState(() => _goal = minutes),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _goal == minutes
                          ? color.withValues(alpha: 0.18)
                          : c.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _goal == minutes
                            ? color.withValues(alpha: 0.65)
                            : c.border,
                      ),
                    ),
                    child: Text(
                      '${faDigits(minutes ~/ 60)} ساعت',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _goal == minutes ? color : c.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: _isEditing ? 'ذخیره تغییرات' : 'افزودن درس',
            icon: Icons.check_rounded,
            gradient: [color, Color.lerp(color, Colors.white, 0.25)!],
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
