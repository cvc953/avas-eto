class CompletionBehaviorEvent {
  final String id;
  final String taskId;
  final DateTime completedAt;
  final DateTime dueAt;
  final int dayOfWeek;
  final int hourOfDay;
  final int hoursFromDeadline;

  CompletionBehaviorEvent({
    required this.id,
    required this.taskId,
    required this.completedAt,
    required this.dueAt,
    required this.dayOfWeek,
    required this.hourOfDay,
    required this.hoursFromDeadline,
  });

  factory CompletionBehaviorEvent.fromTask({
    required String taskId,
    required DateTime completedAt,
    required DateTime dueAt,
  }) {
    return CompletionBehaviorEvent(
      id: '${taskId}_${completedAt.millisecondsSinceEpoch}',
      taskId: taskId,
      completedAt: completedAt,
      dueAt: dueAt,
      dayOfWeek: completedAt.weekday,
      hourOfDay: completedAt.hour,
      hoursFromDeadline: dueAt.difference(completedAt).inHours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'completedAt': completedAt.toIso8601String(),
      'dueAt': dueAt.toIso8601String(),
      'dayOfWeek': dayOfWeek,
      'hourOfDay': hourOfDay,
      'hoursFromDeadline': hoursFromDeadline,
    };
  }

  factory CompletionBehaviorEvent.fromMap(Map<String, dynamic> map) {
    return CompletionBehaviorEvent(
      id: map['id'] as String,
      taskId: map['taskId'] as String,
      completedAt: DateTime.parse(map['completedAt'] as String),
      dueAt: DateTime.parse(map['dueAt'] as String),
      dayOfWeek: (map['dayOfWeek'] as num).toInt(),
      hourOfDay: (map['hourOfDay'] as num).toInt(),
      hoursFromDeadline: (map['hoursFromDeadline'] as num).toInt(),
    );
  }
}