import '../../models.dart';

/// Pure business logic for event state detection, countdown computation,
/// time parsing, and formatting. All methods are stateless and side-effect-free.
class EventService {
  EventService._();

  /// Returns true when [event] is currently happening (live).
  static bool isEventLive(CampusEvent event) {
    if (event.time == 'Now') return true;
    if (!event.time.startsWith('Today')) return false;
    try {
      final timePart = event.time.replaceFirst('Today, ', '');
      final parts = timePart.split(' ');
      final hhmm = parts[0].split(':');
      var hour = int.parse(hhmm[0]);
      final minute = int.parse(hhmm[1]);
      final isPm = parts[1].toUpperCase() == 'PM';
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      final now = DateTime.now();
      final eventTime = DateTime(now.year, now.month, now.day, hour, minute);
      final diff = now.difference(eventTime);
      return diff.inMinutes >= 0 && diff.inMinutes < 90;
    } catch (_) {
      return false;
    }
  }

  /// Returns remaining duration until [event] starts if it is within 12 hours.
  /// Returns null for 'Now' events or events more than 12 hours away.
  static Duration? getCountdown(CampusEvent event) {
    if (event.time == 'Now') return null;
    final now = DateTime.now();
    try {
      DateTime? eventDt;
      if (event.time.startsWith('Today, ')) {
        final timePart = event.time.replaceFirst('Today, ', '');
        eventDt = parseTimePartToday(timePart, now);
      } else if (event.time.startsWith('Tomorrow, ')) {
        final timePart = event.time.replaceFirst('Tomorrow, ', '');
        final base = parseTimePartToday(timePart, now);
        if (base != null) eventDt = base.add(const Duration(days: 1));
      } else {
        final comma = event.time.indexOf(', ');
        if (comma >= 0) {
          final timePart = event.time.substring(comma + 2);
          final base = parseTimePartToday(timePart, now);
          if (base != null && base.isAfter(now)) eventDt = base;
        }
      }
      if (eventDt == null) return null;
      final diff = eventDt.difference(now);
      if (diff.inSeconds <= 0) return null;
      if (diff.inHours >= 12) return null;
      return diff;
    } catch (_) {
      return null;
    }
  }

  /// Parses an 'H:MM AM/PM' time string into a [DateTime] on [base]'s date.
  static DateTime? parseTimePartToday(String timePart, DateTime base) {
    try {
      final parts = timePart.trim().split(' ');
      final hhmm = parts[0].split(':');
      var hour = int.parse(hhmm[0]);
      final minute = int.parse(hhmm[1]);
      final isPm = parts[1].toUpperCase() == 'PM';
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return DateTime(base.year, base.month, base.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Formats a countdown [Duration] like '2h 15m' or '45m'.
  static String formatCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '< 1m';
  }
}
