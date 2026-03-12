import '../models/completion_behavior_event.dart';

class AdaptiveTimeWindow {
  final int startHour;
  final int endHour;
  final double score;

  const AdaptiveTimeWindow({
    required this.startHour,
    required this.endHour,
    required this.score,
  });
}

class AdaptiveScheduler {
  static const Duration historyRetention = Duration(days: 30);

  List<AdaptiveTimeWindow> preferredWindowsFor({
    required List<CompletionBehaviorEvent> events,
    required DateTime referenceNow,
    int? weekday,
  }) {
    if (events.isEmpty) return const [];

    final scores = <int, double>{};
    for (final event in events) {
      final ageInDays = referenceNow.difference(event.completedAt).inDays;
      if (ageInDays < 0 || ageInDays > historyRetention.inDays) continue;

      final windowStart = (event.hourOfDay ~/ 2) * 2;
      final recencyWeight = 1 + ((historyRetention.inDays - ageInDays) / 30);
      final weekdayWeight =
          weekday == null
              ? 1.0
              : (event.dayOfWeek == weekday ? 1.8 : 0.7);
      scores.update(
        windowStart,
        (value) => value + (recencyWeight * weekdayWeight),
        ifAbsent: () => recencyWeight * weekdayWeight,
      );
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ranked.take(2).map((entry) {
      return AdaptiveTimeWindow(
        startHour: entry.key,
        endHour: entry.key + 2,
        score: entry.value,
      );
    }).toList(growable: false);
  }

  DateTime alignReminder({
    required DateTime scheduled,
    required DateTime due,
    required List<CompletionBehaviorEvent> events,
    required DateTime referenceNow,
  }) {
    final preferredWindows = preferredWindowsFor(
      events: events,
      referenceNow: referenceNow,
      weekday: scheduled.weekday,
    );
    if (preferredWindows.isEmpty) return scheduled;

    DateTime? bestCandidate;
    for (final window in preferredWindows) {
      final candidate = _nextOccurrenceWithinWindow(
        scheduled: scheduled,
        due: due,
        window: window,
      );
      if (candidate == null) continue;
      if (bestCandidate == null || candidate.isBefore(bestCandidate)) {
        bestCandidate = candidate;
      }
    }

    return bestCandidate ?? scheduled;
  }

  int adjustedLeadHours({
    required List<CompletionBehaviorEvent> events,
    required int baseLeadHours,
    required DateTime referenceNow,
  }) {
    if (events.isEmpty) return baseLeadHours;

    final recent =
        events.where((event) {
          final ageInDays = referenceNow.difference(event.completedAt).inDays;
          return ageInDays >= 0 && ageInDays <= historyRetention.inDays;
        }).toList(growable: false);
    if (recent.isEmpty) return baseLeadHours;

    final averageHoursFromDeadline =
        recent
            .map((event) => event.hoursFromDeadline)
            .reduce((a, b) => a + b) /
        recent.length;

    if (averageHoursFromDeadline < -6) {
      return baseLeadHours + 12;
    }
    if (averageHoursFromDeadline < 0) {
      return baseLeadHours + 6;
    }
    if (averageHoursFromDeadline > 24) {
      return baseLeadHours > 12 ? baseLeadHours - 12 : baseLeadHours;
    }
    return baseLeadHours;
  }

  DateTime? _nextOccurrenceWithinWindow({
    required DateTime scheduled,
    required DateTime due,
    required AdaptiveTimeWindow window,
  }) {
    for (var offsetDays = 0; offsetDays <= 7; offsetDays++) {
      final day = DateTime(
        scheduled.year,
        scheduled.month,
        scheduled.day + offsetDays,
      );
      final candidate = DateTime(
        day.year,
        day.month,
        day.day,
        window.startHour,
      );
      if (candidate.isBefore(scheduled)) continue;
      if (candidate.isAfter(due)) return null;
      return candidate;
    }
    return null;
  }
}