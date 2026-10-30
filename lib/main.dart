import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'state/app_state.dart';
import 'state/focus_timer.dart';
import 'ui/shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final state = AppState();
  await state.load();

  runApp(ZamanYarApp(state: state));
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
      assert(scope != null, 'AppScope was not found in the widget tree');
      return scope!.notifier!;
    }
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree');
    return scope!.notifier!;
  }
}

class TimerScope extends InheritedNotifier<FocusTimer> {
  const TimerScope({
    super.key,
    required FocusTimer timer,
    required super.child,
  }) : super(notifier: timer);

  static FocusTimer of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final scope = context.dependOnInheritedWidgetOfExactType<TimerScope>();
      assert(scope != null, 'TimerScope was not found in the widget tree');
      return scope!.notifier!;
    }
    final scope = context.getInheritedWidgetOfExactType<TimerScope>();
    assert(scope != null, 'TimerScope was not found in the widget tree');
    return scope!.notifier!;
  }
}

class ZamanYarApp extends StatefulWidget {
  const ZamanYarApp({super.key, required this.state});

  final AppState state;

  @override
  State<ZamanYarApp> createState() => _ZamanYarAppState();
}

class _ZamanYarAppState extends State<ZamanYarApp> {
  late final FocusTimer _focusTimer = FocusTimer(
    onSessionComplete: (minutes, subjectId) {
      widget.state.logFocus(minutes: minutes, subjectId: subjectId);
      widget.state.celebration.value++;
    },
  );

  @override
  void dispose() {
    _focusTimer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final mode = widget.state.themeMode;
        final isDark = mode == ThemeMode.dark ||
            (mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);

        return AppScope(
          state: widget.state,
          child: TimerScope(
            timer: _focusTimer,
            child: MaterialApp(
              title: 'زمان‌یار',
              debugShowCheckedModeBanner: false,
              locale: const Locale('fa'),
              supportedLocales: const [Locale('fa'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.build(Brightness.light),
              darkTheme: AppTheme.build(Brightness.dark),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              builder: (context, child) {
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness:
                        isDark ? Brightness.light : Brightness.dark,
                    statusBarBrightness:
                        isDark ? Brightness.dark : Brightness.light,
                    systemNavigationBarColor: Colors.transparent,
                    systemNavigationBarIconBrightness:
                        isDark ? Brightness.light : Brightness.dark,
                    systemNavigationBarContrastEnforced: false,
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              home: const Shell(),
            ),
          ),
        );
      },
    );
  }
}
