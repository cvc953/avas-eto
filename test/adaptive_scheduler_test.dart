import 'package:avas_eto/models/completion_behavior_event.dart';
import 'package:avas_eto/services/adaptive_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

CompletionBehaviorEvent buildEvent({
  required String id,
  required DateTime completedAt,
  required DateTime dueAt,
}) {
  return CompletionBehaviorEvent.fromTask(
    taskId: id,
    completedAt: completedAt,
    dueAt: dueAt,
  );
}

void main() {
  test('preferred windows favor recent matching weekday patterns', () {
    final scheduler = AdaptiveScheduler();
    final now = DateTime(2026, 3, 12, 9, 0);
    final events = [
      buildEvent(
        id: '1',
        completedAt: DateTime(2026, 3, 5, 8, 30),
        dueAt: DateTime(2026, 3, 5, 12, 0),
      ),
      buildEvent(
        id: '2',
        completedAt: DateTime(2026, 3, 10, 9, 15),
        dueAt: DateTime(2026, 3, 10, 12, 0),
      ),
      buildEvent(
        id: '3',
        completedAt: DateTime(2026, 3, 11, 19, 0),
        dueAt: DateTime(2026, 3, 11, 22, 0),
      ),
      buildEvent(
        id: '4',
        completedAt: DateTime(2026, 3, 12, 20, 0),
        dueAt: DateTime(2026, 3, 12, 23, 0),
      ),
    ];

    final windows = scheduler.preferredWindowsFor(
      events: events,
      referenceNow: now,
      weekday: 4,
    );

    expect(windows.length, 2);
    expect(windows.first.startHour, anyOf(8, 20));
    expect(windows.last.startHour, anyOf(8, 18, 20));
  });

  test('alignReminder moves reminder to next preferred productive window', () {
    final scheduler = AdaptiveScheduler();
    final now = DateTime(2026, 3, 12, 9, 0);
    final events = [
      buildEvent(
        id: '1',
        completedAt: DateTime(2026, 3, 5, 8, 30),
        dueAt: DateTime(2026, 3, 5, 12, 0),
      ),
      buildEvent(
        id: '2',
        completedAt: DateTime(2026, 3, 12, 19, 30),
        dueAt: DateTime(2026, 3, 12, 22, 0),
      ),
    ];

    final aligned = scheduler.alignReminder(
      scheduled: DateTime(2026, 3, 13, 14, 0),
      due: DateTime(2026, 3, 14, 12, 0),
      events: events,
      referenceNow: now,
    );

    expect(aligned.hour, anyOf(8, 18));
    expect(aligned.isAfter(DateTime(2026, 3, 13, 14, 0)), isTrue);
    expect(aligned.isBefore(DateTime(2026, 3, 14, 12, 1)), isTrue);
  });

  test(
    'adjustedLeadHours moves reminders earlier when user completes late',
    () {
      final scheduler = AdaptiveScheduler();
      final now = DateTime(2026, 3, 12, 9, 0);
      final lateEvents = [
        buildEvent(
          id: '1',
          completedAt: DateTime(2026, 3, 10, 15, 0),
          dueAt: DateTime(2026, 3, 10, 9, 0),
        ),
        buildEvent(
          id: '2',
          completedAt: DateTime(2026, 3, 11, 13, 0),
          dueAt: DateTime(2026, 3, 11, 9, 0),
        ),
      ];

      final adjusted = scheduler.adjustedLeadHours(
        events: lateEvents,
        baseLeadHours: 24,
        referenceNow: now,
      );

      expect(adjusted, 30);
    },
  );
}
