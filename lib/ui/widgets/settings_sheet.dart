import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../main.dart';
import '../../state/app_state.dart';
import 'glass.dart';

Future<void> openSettings(BuildContext context) {
  return showAppSheet<void>(context, const SettingsSheet());
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late final AppState _state = AppScope.of(context, listen: false);
  late final TextEditingController _name =
      TextEditingController(text: _state.name);
  late double _goal = _state.dailyGoalMinutes.toDouble();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('پاک کردن همهٔ دادهٔ‌ها؟'),
        content: const Text(
          'همهٔ کارها، درس‌ها و جلسه‌های تمرکز حذف می‌شوند. این کار قابل بازگشت نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('پاک کن', style: TextStyle(color: ctx.colors.coral)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _state.clearAllData();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
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
                    colors: [c.primary, c.pink],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تنظیمات',
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text('زمان‌یار را برای خودت تنظیم کن',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          _Label('نام تو'),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            decoration: InputDecoration(
              hintText: 'مثلاً: سارا',
              prefixIcon: Icon(Icons.person_rounded, size: 20, color: c.muted),
            ),
            onChanged: (v) => _state.setName(v),
          ),
          const SizedBox(height: 22),
          _Label('ظاهر'),
          const SizedBox(height: 8),
          Row(
            children: [
              _ThemeChoice(
                label: 'تیره',
                icon: Icons.dark_mode_rounded,
                selected: _state.themeMode == ThemeMode.dark,
                onTap: () =>
                    setState(() => _state.setThemeMode(ThemeMode.dark)),
              ),
              const SizedBox(width: 8),
              _ThemeChoice(
                label: 'روشن',
                icon: Icons.light_mode_rounded,
                selected: _state.themeMode == ThemeMode.light,
                onTap: () =>
                    setState(() => _state.setThemeMode(ThemeMode.light)),
              ),
              const SizedBox(width: 8),
              _ThemeChoice(
                label: 'سیستم',
                icon: Icons.auto_mode_rounded,
                selected: _state.themeMode == ThemeMode.system,
                onTap: () =>
                    setState(() => _state.setThemeMode(ThemeMode.system)),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _Label('هدف تمرکز روزانه'),
              const Spacer(),
              Pill(
                label: prettyMinutes(_goal.round()),
                color: c.primarySoft,
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: c.primary,
              inactiveTrackColor: c.surfaceAlt,
              thumbColor: Colors.white,
              overlayColor: c.primary.withValues(alpha: 0.16),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: _goal.clamp(30, 360),
              min: 30,
              max: 360,
              divisions: 22,
              onChanged: (v) => setState(() => _goal = v),
              onChangeEnd: (v) => _state.setDailyGoal(v.round()),
            ),
          ),
          const SizedBox(height: 10),
          _Label('دربارهٔ برنامه'),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            radius: 20,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [c.primary, c.mint]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('زمان‌یار',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            'نسخهٔ ۱.۰.۰ • برنامه‌ریز درس و تمرکز',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: c.border, height: 1),
                const SizedBox(height: 12),
                Text(
                  'همهٔ داده‌ها فقط روی همین گوشی ذخیره می‌شوند و به اینترنت نیازی نیست.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _confirmReset,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: c.coral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.coral.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep_rounded, size: 18, color: c.coral),
                  const SizedBox(width: 8),
                  Text(
                    'پاک کردن همهٔ داده‌ها',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.coral,
                    ),
                  ),
                ],
              ),
            ),
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
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(color: context.colors.muted, fontSize: 12.5),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? c.primary.withValues(alpha: 0.16) : c.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? c.primary.withValues(alpha: 0.6) : c.border,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? c.primarySoft : c.muted),
              const SizedBox(height: 6),
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
      ),
    );
  }
}
