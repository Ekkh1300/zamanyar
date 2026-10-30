import 'package:flutter/material.dart';

import '../../core/jalali.dart';
import '../../core/theme.dart';
import 'glass.dart';

/// A compact Jalali (Solar Hijri) month picker rendered in a bottom sheet.
Future<DateTime?> showJalaliDatePicker(
  BuildContext context, {
  DateTime? initial,
}) {
  return showAppSheet<DateTime>(
    context,
    _JalaliPicker(initial: initial ?? DateTime.now()),
  );
}

class _JalaliPicker extends StatefulWidget {
  const _JalaliPicker({required this.initial});

  final DateTime initial;

  @override
  State<_JalaliPicker> createState() => _JalaliPickerState();
}

class _JalaliPickerState extends State<_JalaliPicker> {
  late JalaliDate _visible = Jalali.fromDateTime(widget.initial);
  late DateTime _selected = dateOnly(widget.initial);

  void _shift(int delta) {
    setState(() {
      var m = _visible.month + delta;
      var y = _visible.year;
      if (m < 1) {
        m = 12;
        y -= 1;
      } else if (m > 12) {
        m = 1;
        y += 1;
      }
      _visible = JalaliDate(y, m, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final first = jalaliToDateTime(_visible.year, _visible.month, 1);
    final days = daysInJalaliMonth(_visible.year, _visible.month);
    final leading = Jalali.weekIndex(first);
    final today = dateOnly(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _NavArrow(icon: Icons.chevron_right_rounded, onTap: () => _shift(-1)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${Jalali.monthName(_visible.month)} ${faDigits(_visible.year)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'روز موردنظر را انتخاب کن',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _NavArrow(icon: Icons.chevron_left_rounded, onTap: () => _shift(1)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final w in Jalali.weekDaysShort)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: c.muted,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leading + days,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox.shrink();
              final dayNumber = index - leading + 1;
              final date =
                  jalaliToDateTime(_visible.year, _visible.month, dayNumber);
              final isSelected = dateOnly(date) == _selected;
              final isToday = dateOnly(date) == today;

              return GestureDetector(
                onTap: () {
                  setState(() => _selected = date);
                  Navigator.of(context).pop(date);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? LinearGradient(colors: [c.primary, c.primarySoft])
                        : null,
                    border: isToday && !isSelected
                        ? Border.all(color: c.primary.withValues(alpha: 0.7), width: 1.4)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: c.primary.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      faDigits(dayNumber),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? Colors.white : c.text,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selected == today ? 'امروز انتخاب شده' : friendlyDate(_selected),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (_selected != today)
                TextButton.icon(
                  onPressed: () {
                    final now = dateOnly(DateTime.now());
                    setState(() {
                      _selected = now;
                      _visible = Jalali.fromDateTime(now);
                    });
                    Navigator.of(context).pop(now);
                  },
                  icon: Icon(Icons.today_rounded, size: 15, color: c.primarySoft),
                  label: Text(
                    'برو به امروز',
                    style: TextStyle(color: c.primarySoft, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          shape: BoxShape.circle,
          border: Border.all(color: c.border),
        ),
        child: Icon(icon, size: 22, color: c.text),
      ),
    );
  }
}
