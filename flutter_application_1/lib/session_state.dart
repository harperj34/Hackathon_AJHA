import 'models.dart';

/// Holds ephemeral session data that resets on app restart.
class SessionState {
  // IDs of events the user has tapped "Going" on this session
  static final Set<String> goingEventIds = {};

  // Events the user created this session (for Activity tab display)
  static final List<CampusEvent> myCreatedEvents = [];

  // The logged-in user's email (set on login)
  static String currentUserEmail = '';

  static bool isGoing(String eventId) => goingEventIds.contains(eventId);

  static void setGoing(String eventId, bool going) {
    if (going) {
      goingEventIds.add(eventId);
    } else {
      goingEventIds.remove(eventId);
    }
  }

  static void addCreatedEvent(CampusEvent event) {
    myCreatedEvents.removeWhere((e) => e.id == event.id);
    myCreatedEvents.add(event);
  }

  static void clear() {
    goingEventIds.clear();
    myCreatedEvents.clear();
    currentUserEmail = '';
  }
}