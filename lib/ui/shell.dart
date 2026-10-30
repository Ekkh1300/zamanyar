import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../main.dart';
import 'focus_page.dart';
import 'home_page.dart';
import 'stats_page.dart';
import 'tasks_page.dart';
import 'widgets/celebration.dart';
import 'widgets/glass.dart';
import 'widgets/task_editor.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _quickAdd() async {
    final saved = await openTaskEditor(context);
    if (saved && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('کار جدید به برنامه اضافه شد'),
            duration: Duration(milliseconds: 1600),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return CelebrationOverlay(
      trigger: state.celebration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: AuroraBackground(
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            children: [
              HomePage(onOpenTab: _go),
              const TasksPage(),
              const FocusPage(),
              const StatsPage(),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Transform.translate(
          offset: const Offset(0, 10),
          child: _AddFab(onTap: _quickAdd),
        ),
        bottomNavigationBar: _GlassNav(
          index: _index,
          onTap: _go,
        ),
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  const _AddFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.primary, c.primarySoft],
          ),
          border: Border.all(
            color: c.bg.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

class _GlassNav extends StatelessWidget {
  const _GlassNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    const items = <(IconData, String)>[
      (Icons.space_dashboard_rounded, 'خانه'),
      (Icons.checklist_rounded, 'کارها'),
      (Icons.center_focus_strong_rounded, 'تمرکز'),
      (Icons.insights_rounded, 'آمار'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottom + 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: c.nav.withValues(alpha: c.isDark ? 0.82 : 0.9),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: c.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.08),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i == 2) const SizedBox(width: 72),
                  Expanded(
                    child: _NavItem(
                      icon: items[i].$1,
                      label: items[i].$2,
                      selected: index == i,
                      showRunningDot: i == 2,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.showRunningDot,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool showRunningDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? c.primary.withValues(alpha: 0.28)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected ? c.primarySoft : c.muted,
                ),
                if (showRunningDot)
                  const PositionedDirectional(
                    top: -1,
                    end: -3,
                    child: _RunningDot(),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? c.primarySoft : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunningDot extends StatelessWidget {
  const _RunningDot();

  @override
  Widget build(BuildContext context) {
    final timer = TimerScope.of(context);
    final c = context.colors;
    if (!timer.running) return const SizedBox.shrink();
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: timer.isFocus ? c.mint : c.blue,
        shape: BoxShape.circle,
        border: Border.all(color: c.nav, width: 1.5),
      ),
    );
  }
}
