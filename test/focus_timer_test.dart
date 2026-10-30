import 'package:flutter_test/flutter_test.dart';
import 'package:zamanyar/state/focus_timer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('counts down while running', () async {
    final timer = FocusTimer(onSessionComplete: (_, _) {});
    timer.totalSeconds = 60;
    timer.remainingSeconds = 60;

    timer.start();
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(timer.running, isTrue);
    expect(timer.remainingSeconds, lessThan(60));
    timer.dispose();
  });

  test('finishes a focus session and logs it', () async {
    final logged = <int>[];
    final timer = FocusTimer(onSessionComplete: (m, _) => logged.add(m));
    timer.selectedMinutes = 1;
    timer.totalSeconds = 2;
    timer.remainingSeconds = 2;

    timer.start();
    await Future<void>.delayed(const Duration(milliseconds: 2400));

    expect(timer.running, isFalse);
    expect(timer.mode, FocusMode.rest);
    expect(timer.remainingSeconds, timer.breakMinutes * 60);
    expect(logged, [1]);
    timer.dispose();
  });

  test('pause freezes the remaining time', () async {
    final timer = FocusTimer(onSessionComplete: (_, _) {});
    timer.totalSeconds = 60;
    timer.remainingSeconds = 60;

    timer.start();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    timer.pause();
    final frozen = timer.remainingSeconds;

    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(timer.remainingSeconds, frozen);
    expect(frozen, lessThan(60));
    timer.dispose();
  });
}
