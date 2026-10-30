import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/jalali.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  static const _storageKey = 'zamanyar_state_v1';

  String name = '';
  ThemeMode themeMode = ThemeMode.dark;
  int dailyGoalMinutes = 120;
  List<Subject> subjects = [];
  List<TaskItem> tasks = [];
  List<FocusSession> sessions = [];
  bool loaded = false;

  /// Bumped whenever something worth celebrating happens.
  final ValueNotifier<int> celebration = ValueNotifier<int>(0);

  DateTime get today => dateOnly(DateTime.now());

  List<DateTime> get weekDays => List.generate(
        7,
        (i) => startOfWeek(today).add(Duration(days: i)),
      );

  Subject? subjectById(String? id) {
    if (id == null) return null;
    for (final s in subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        _hydrate(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _seed();
      }
    } else {
      _seed();
      await _persist();
    }
    loaded = true;
    notifyListeners();
  }

  void _hydrate(Map<String, dynamic> json) {
    name = json['name'] as String? ?? '';
    themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == json['theme'],
      orElse: () => ThemeMode.dark,
    );
    dailyGoalMinutes = json['goal'] as int? ?? 120;
    subjects = (json['subjects'] as List<dynamic>? ?? [])
        .map((e) => Subject.fromJson(e as Map<String, dynamic>))
        .toList();
    tasks = (json['tasks'] as List<dynamic>? ?? [])
        .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
        .toList();
    sessions = (json['sessions'] as List<dynamic>? ?? [])
        .map((e) => FocusSession.fromJson(e as Map<String, dynamic>))
        .toList();
    if (subjects.isEmpty) _seedSubjects();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'theme': themeMode.name,
        'goal': dailyGoalMinutes,
        'subjects': subjects.map((s) => s.toJson()).toList(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(toJson()));
  }

  void _changed() {
    _persist();
    notifyListeners();
  }

  void _seedSubjects() {
    subjects = [
      const Subject(
        id: 'sub-math',
        name: 'ریاضی',
        color: 0xFF7C6CFF,
        weeklyGoalMinutes: 300,
      ),
      const Subject(
        id: 'sub-physics',
        name: 'فیزیک',
        color: 0xFF5AA9FF,
        weeklyGoalMinutes: 240,
      ),
      const Subject(
        id: 'sub-english',
        name: 'زبان انگلیسی',
        color: 0xFF2FE3B4,
        weeklyGoalMinutes: 180,
      ),
    ];
  }

  void _seed() {
    name = '';
    _seedSubjects();
    final t = today;
    tasks = [
      TaskItem(
        id: newId(),
        title: 'حل ۲۰ تست مشتق',
        subjectId: 'sub-math',
        dateKey: dateKey(t),
        time: '17:30',
        durationMinutes: 45,
        priority: TaskPriority.high,
        createdAt: DateTime.now(),
      ),
      TaskItem(
        id: newId(),
        title: 'مرور لغات درس چهارم',
        subjectId: 'sub-english',
        dateKey: dateKey(t),
        time: '21:00',
        durationMinutes: 20,
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
      ),
      TaskItem(
        id: newId(),
        title: 'خلاصه‌نویسی فصل دوم فیزیک',
        subjectId: 'sub-physics',
        dateKey: dateKey(t.add(const Duration(days: 1))),
        durationMinutes: 40,
        priority: TaskPriority.low,
        createdAt: DateTime.now(),
      ),
    ];
    sessions = [
      for (final s in [(3, 45, 'sub-math'), (2, 30, 'sub-english'), (1, 25, 'sub-physics'), (1, 20, 'sub-math'), (5, 40, 'sub-english')])
        FocusSession(
          id: newId(),
          dateKey: dateKey(t.subtract(Duration(days: s.$1))),
          minutes: s.$2,
          endedAt: t
              .subtract(Duration(days: s.$1))
              .add(const Duration(hours: 19)),
          subjectId: s.$3,
        ),
    ];
  }

  // ---------------------------------------------------------------- queries

  List<TaskItem> tasksOn(String key) {
    final list = tasks.where((t) => t.dateKey == key).toList();
    list.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      final at = a.time ?? '99:99';
      final bt = b.time ?? '99:99';
      final byTime = at.compareTo(bt);
      if (byTime != 0) return byTime;
      return (a.createdAt ?? DateTime.now())
          .compareTo(b.createdAt ?? DateTime.now());
    });
    return list;
  }

  List<TaskItem> get todayTasks => tasksOn(todayKey());

  List<TaskItem> get upcomingTasks {
    final now = DateTime.now();
    final key = todayKey();
    final current = '${two(now.hour)}:${two(now.minute)}';
    return tasks
        .where((t) =>
            !t.done &&
            (t.dateKey == key ? (t.time == null || t.time!.compareTo(current) >= 0) : true) &&
            t.dateKey.compareTo(key) >= 0)
        .toList()
      ..sort((a, b) {
        final byDate = a.dateKey.compareTo(b.dateKey);
        if (byDate != 0) return byDate;
        return (a.time ?? '99:99').compareTo(b.time ?? '99:99');
      });
  }

  TaskItem? get nextTask {
    final list = upcomingTasks;
    return list.isEmpty ? null : list.first;
  }

  int focusMinutesOn(String key) => sessions
      .where((s) => s.dateKey == key)
      .fold(0, (sum, s) => sum + s.minutes);

  int sessionsOn(String key) =>
      sessions.where((s) => s.dateKey == key).length;

  int tasksDoneOn(String key) => tasks
      .where((t) =>
          t.done &&
          t.completedAt != null &&
          dateKey(t.completedAt!) == key)
      .length;

  bool _activeOn(DateTime d) {
    final key = dateKey(d);
    return focusMinutesOn(key) > 0 || tasksDoneOn(key) > 0;
  }

  int get streak {
    var cursor = today;
    if (!_activeOn(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (_activeOn(cursor) && count < 3650) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  int get todayFocus => focusMinutesOn(todayKey());

  int get todayPlanned => todayTasks.fold(0, (s, t) => s + t.durationMinutes);

  int get todayDoneTasks => todayTasks.where((t) => t.done).length;

  List<int> get weekFocus => weekDays
      .map((d) => focusMinutesOn(dateKey(d)))
      .toList(growable: false);

  int get weekFocusTotal => weekFocus.fold(0, (a, b) => a + b);

  int get weekTasksDone => weekDays
      .map((d) => tasksDoneOn(dateKey(d)))
      .fold(0, (a, b) => a + b);

  int get totalFocusMinutes =>
      sessions.fold(0, (sum, s) => sum + s.minutes);

  int get completedTasksTotal => tasks.where((t) => t.done).length;

  Map<String, int> subjectMinutesSince(DateTime from) {
    final result = <String, int>{};
    for (final s in sessions) {
      if (fromKey(s.dateKey).isBefore(dateOnly(from))) continue;
      final key = s.subjectId ?? 'none';
      result[key] = (result[key] ?? 0) + s.minutes;
    }
    return result;
  }

  // ---------------------------------------------------------------- mutations

  void addTask(TaskItem task) {
    tasks.add(task);
    _changed();
  }

  void updateTask(TaskItem task) {
    final i = tasks.indexWhere((t) => t.id == task.id);
    if (i == -1) return;
    tasks[i] = task;
    _changed();
  }

  void toggleTask(String id) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    final task = tasks[i];
    final nowDone = !task.done;
    tasks[i] = task.copyWith(
      done: nowDone,
      completedAt: nowDone ? DateTime.now() : null,
    );
    _persist();
    if (nowDone && todayTasks.isNotEmpty && todayTasks.every((t) => t.done)) {
      celebration.value++;
    }
    notifyListeners();
  }

  void deleteTask(String id) {
    tasks.removeWhere((t) => t.id == id);
    _changed();
  }

  void moveTaskToDate(String id, String key) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    tasks[i] = tasks[i].copyWith(dateKey: key);
    _changed();
  }

  void addSubject(Subject subject) {
    subjects.add(subject);
    _changed();
  }

  void updateSubject(Subject subject) {
    final i = subjects.indexWhere((s) => s.id == subject.id);
    if (i == -1) return;
    subjects[i] = subject;
    _changed();
  }

  void deleteSubject(String id) {
    subjects.removeWhere((s) => s.id == id);
    for (var i = 0; i < tasks.length; i++) {
      if (tasks[i].subjectId == id) {
        tasks[i] = tasks[i].copyWith(subjectId: null);
      }
    }
    _changed();
  }

  void logFocus({required int minutes, String? subjectId}) {
    sessions.add(
      FocusSession(
        id: newId(),
        dateKey: todayKey(),
        minutes: minutes,
        endedAt: DateTime.now(),
        subjectId: subjectId,
      ),
    );
    _changed();
  }

  void setName(String value) {
    name = value.trim();
    _changed();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _changed();
  }

  void setDailyGoal(int minutes) {
    dailyGoalMinutes = minutes;
    _changed();
  }

  void clearAllData() {
    final keepName = name;
    final keepTheme = themeMode;
    final keepGoal = dailyGoalMinutes;
    _seed();
    name = keepName;
    themeMode = keepTheme;
    dailyGoalMinutes = keepGoal;
    _changed();
  }
}
