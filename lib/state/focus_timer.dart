import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum FocusMode { focus, rest }

class FocusTimer extends ChangeNotifier {
  FocusTimer({required this.onSessionComplete});

  final void Function(int minutes, String? subjectId) onSessionComplete;

  static const presets = <int>[15, 25, 45, 60];

  int selectedMinutes = 25;
  int breakMinutes = 5;
  FocusMode mode = FocusMode.focus;
  String? subjectId;
  int totalSeconds = 25 * 60;
  int remainingSeconds = 25 * 60;
  bool running = false;

  Timer? _timer;
  DateTime? _lastTick;
  double _fractionalSeconds = 0;

  double get progress {
    if (totalSeconds == 0) return 0;
    return (1 - remainingSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  bool get isFocus => mode == FocusMode.focus;

  void setSubject(String? id) {
    subjectId = id;
    notifyListeners();
  }

  void setPreset(int minutes) {
    if (running) return;
    selectedMinutes = minutes;
    // Picking a length while resting starts a new focus session instead of
    // keeping the break mode with a focus-sized duration.
    mode = FocusMode.focus;
    _fractionalSeconds = 0;
    totalSeconds = minutes * 60;
    remainingSeconds = totalSeconds;
    notifyListeners();
  }

  void toggle() => running ? pause() : start();

  void start() {
    if (running) return;
    if (remainingSeconds <= 0) reset();
    running = true;
    _lastTick = DateTime.now();
    _fractionalSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void pause() {
    if (!running) return;
    running = false;
    _timer?.cancel();
    notifyListeners();
  }

  void reset() {
    running = false;
    _timer?.cancel();
    _fractionalSeconds = 0;
    totalSeconds = (isFocus ? selectedMinutes : breakMinutes) * 60;
    remainingSeconds = totalSeconds;
    notifyListeners();
  }

  void skip() {
    running = false;
    _timer?.cancel();
    _fractionalSeconds = 0;
    if (isFocus) {
      _enterRest();
    } else {
      _enterFocus();
    }
  }

  void _tick() {
    final now = DateTime.now();
    final deltaMs = now.difference(_lastTick ?? now).inMilliseconds;
    _lastTick = now;
    _fractionalSeconds += deltaMs / 1000;
    final whole = _fractionalSeconds.floor();
    if (whole <= 0) return;
    _fractionalSeconds -= whole;
    final next = remainingSeconds - whole;
    if (next <= 0) {
      remainingSeconds = 0;
      _finish();
    } else {
      remainingSeconds = next;
      notifyListeners();
    }
  }

  void _finish() {
    running = false;
    _timer?.cancel();
    if (isFocus) {
      final minutes = selectedMinutes;
      final subject = subjectId;
      HapticFeedback.heavyImpact();
      _enterRest();
      onSessionComplete(minutes, subject);
    } else {
      HapticFeedback.mediumImpact();
      _enterFocus();
    }
    notifyListeners();
  }

  void _enterRest() {
    mode = FocusMode.rest;
    totalSeconds = breakMinutes * 60;
    remainingSeconds = totalSeconds;
  }

  void _enterFocus() {
    mode = FocusMode.focus;
    totalSeconds = selectedMinutes * 60;
    remainingSeconds = totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
