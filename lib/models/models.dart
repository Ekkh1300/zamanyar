import '../core/jalali.dart';

enum TaskPriority {
  low('کم', 1),
  medium('متوسط', 2),
  high('مهم', 3);

  const TaskPriority(this.label, this.weight);
  final String label;
  final int weight;

  static TaskPriority fromWeight(int? weight) {
    return TaskPriority.values.firstWhere(
      (p) => p.weight == weight,
      orElse: () => TaskPriority.medium,
    );
  }
}

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(100 + (DateTime.now().millisecond % 900))}';

class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.color,
    this.weeklyGoalMinutes = 180,
  });

  final String id;
  final String name;
  final int color;
  final int weeklyGoalMinutes;

  Subject copyWith({String? name, int? color, int? weeklyGoalMinutes}) {
    return Subject(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      weeklyGoalMinutes: weeklyGoalMinutes ?? this.weeklyGoalMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'weeklyGoal': weeklyGoalMinutes,
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'درس',
        color: json['color'] as int? ?? 0xFF7C6CFF,
        weeklyGoalMinutes: json['weeklyGoal'] as int? ?? 180,
      );
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.dateKey,
    this.subjectId,
    this.priority = TaskPriority.medium,
    this.time,
    this.durationMinutes = 30,
    this.done = false,
    this.createdAt,
    this.completedAt,
    this.note = '',
  });

  final String id;
  final String title;
  final String dateKey;
  final String? subjectId;
  final TaskPriority priority;
  final String? time; // "HH:mm" — optional
  final int durationMinutes;
  final bool done;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String note;

  bool get isToday => dateKey == todayKey();

  TaskItem copyWith({
    String? title,
    String? dateKey,
    Object? subjectId = _sentinel,
    TaskPriority? priority,
    Object? time = _sentinel,
    int? durationMinutes,
    bool? done,
    Object? completedAt = _sentinel,
    String? note,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      dateKey: dateKey ?? this.dateKey,
      subjectId: identical(subjectId, _sentinel)
          ? this.subjectId
          : subjectId as String?,
      priority: priority ?? this.priority,
      time: identical(time, _sentinel) ? this.time : time as String?,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      done: done ?? this.done,
      createdAt: createdAt,
      completedAt: identical(completedAt, _sentinel)
          ? this.completedAt
          : completedAt as DateTime?,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': dateKey,
        'subject': subjectId,
        'priority': priority.weight,
        'time': time,
        'duration': durationMinutes,
        'done': done,
        'createdAt': createdAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'note': note,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        dateKey: json['date'] as String? ?? todayKey(),
        subjectId: json['subject'] as String?,
        priority: TaskPriority.fromWeight(json['priority'] as int?),
        time: json['time'] as String?,
        durationMinutes: json['duration'] as int? ?? 30,
        done: json['done'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
        note: json['note'] as String? ?? '',
      );
}

class FocusSession {
  const FocusSession({
    required this.id,
    required this.dateKey,
    required this.minutes,
    required this.endedAt,
    this.subjectId,
  });

  final String id;
  final String dateKey;
  final int minutes;
  final DateTime endedAt;
  final String? subjectId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': dateKey,
        'minutes': minutes,
        'endedAt': endedAt.toIso8601String(),
        'subject': subjectId,
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'] as String,
        dateKey: json['date'] as String? ?? todayKey(),
        minutes: json['minutes'] as int? ?? 0,
        endedAt: DateTime.tryParse(json['endedAt'] as String? ?? '') ??
            DateTime.now(),
        subjectId: json['subject'] as String?,
      );
}

const _sentinel = Object();
