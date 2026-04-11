import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum EventCategory { food, events, study, deals, social, myki }

class EventCategoryInfo {
  final String label;
  final IconData icon;
  final Color color;

  const EventCategoryInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}

final Map<EventCategory, EventCategoryInfo> categoryInfo = {
  EventCategory.food: const EventCategoryInfo(
    label: 'Food',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFFF9F43),
  ),
  EventCategory.events: const EventCategoryInfo(
    label: 'Events',
    icon: Icons.celebration_rounded,
    color: Color(0xFF6C63FF),
  ),
  EventCategory.study: const EventCategoryInfo(
    label: 'Study Spot',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF00B894),
  ),
  EventCategory.deals: const EventCategoryInfo(
    label: 'Deals',
    icon: Icons.local_offer_rounded,
    color: Color(0xFFFFC107),
  ),
  EventCategory.social: const EventCategoryInfo(
    label: 'Social',
    icon: Icons.emoji_people_rounded,
    color: Color(0xFFFF7AD9),
  ),
  EventCategory.myki: const EventCategoryInfo(
    label: 'Myki Inspectors',
    icon: Icons.security_rounded,
    color: Color(0xFFEF5350),
  ),
};

class CampusEvent {
  final String id;
  final String title;
  final String subtitle;
  final String location;
  final String time;
  final String imageUrl;
  final EventCategory category;
  final LatLng position;
  final int attendees;

  const CampusEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.time,
    required this.imageUrl,
    required this.category,
    required this.position,
    this.attendees = 0,
  });
}

class StudySpot {
  final String id;
  final String title;
  final String location;
  final LatLng position;

  StudySpot({
    required this.id,
    required this.title,
    required this.location,
    required this.position,
  });
}

// Returns "Today, H:MM AM/PM" for a time [minutesFromNow] minutes in the future.
String _todayPlusMinutes(int minutesFromNow) {
  final t = DateTime.now().add(Duration(minutes: minutesFromNow));
  final isPm = t.hour >= 12;
  final displayHour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minuteStr = t.minute.toString().padLeft(2, '0');
  return 'Today, $displayHour:$minuteStr ${isPm ? 'PM' : 'AM'}';
}

// Sample campus data — using Monash University Clayton campus as example
final List<CampusEvent> sampleEvents = [
  CampusEvent(
    id: '1',
    title: 'BBQ on the Lawn',
    subtitle: 'Engineering Student Society',
    location: 'Campus Green',
    time: 'Today, 12:00 PM',
    imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400',
    category: EventCategory.food,
    position: LatLng(-37.9105, 145.1340),
    attendees: 87,
  ),
  CampusEvent(
    id: '2',
    title: 'Study Jam Session',
    subtitle: 'Academic Support Club',
    location: 'Matheson Library',
    time: 'Today, 2:00 PM',
    imageUrl:
        'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400',
    category: EventCategory.social,
    position: LatLng(-37.9115, 145.1320),
    attendees: 32,
  ),
  CampusEvent(
    id: '3',
    title: 'Dance Club Tryouts',
    subtitle: 'Monash Dance Club',
    location: 'Campus Centre',
    time: 'Today, 4:30 PM',
    imageUrl: 'https://images.unsplash.com/photo-1547153760-18fc86c0bba0?w=400',
    category: EventCategory.events,
    position: LatLng(-37.9125, 145.1315),
    attendees: 56,
  ),
  CampusEvent(
    id: '4',
    title: 'Free Bubble Tea',
    subtitle: 'Asian Society',
    location: 'Sir John Monash Drive',
    time: 'Today, 1:00 PM',
    imageUrl: 'https://images.unsplash.com/photo-1558857563-b371033873b8?w=400',
    category: EventCategory.food,
    position: LatLng(-37.9098, 145.1355),
    attendees: 124,
  ),
  CampusEvent(
    id: '5',
    title: 'Hackathon Kickoff',
    subtitle: 'WIRED Club',
    location: 'Learning & Teaching Building',
    time: 'Fri, 6:00 PM',
    imageUrl:
        'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=400',
    category: EventCategory.events,
    position: LatLng(-37.9135, 145.1310),
    attendees: 200,
  ),
  CampusEvent(
    id: '6',
    title: 'Yoga in the Park',
    subtitle: 'Wellness Society',
    location: 'Jock Marshall Reserve',
    time: 'Tomorrow, 8:00 AM',
    imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400',
    category: EventCategory.social,
    position: LatLng(-37.9080, 145.1370),
    attendees: 43,
  ),
  CampusEvent(
    id: '7',
    title: 'Live Band Night 🎸',
    subtitle: 'Music Club',
    location: 'Wholefoods Cafe',
    time: 'Fri, 7:30 PM',
    imageUrl:
        'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
    category: EventCategory.events,
    position: LatLng(-37.9118, 145.1345),
    attendees: 150,
  ),
  CampusEvent(
    id: '8',
    title: 'Chess Tournament ♟️',
    subtitle: 'Chess Club',
    location: 'Menzies Building',
    time: 'Sat, 10:00 AM',
    imageUrl:
        'https://images.unsplash.com/photo-1529699211952-734e80c4d42b?w=400',
    category: EventCategory.events,
    position: LatLng(-37.9142, 145.1335),
    attendees: 28,
  ),
  CampusEvent(
    id: '9',
    title: 'Free Pizza Giveaway',
    subtitle: 'Student Union',
    location: 'Campus Centre',
    time: _todayPlusMinutes(20),
    imageUrl:
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400',
    category: EventCategory.food,
    position: LatLng(-37.9109, 145.1330),
    attendees: 60,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Public transport layer (PTV-style bus stop data — static placeholders;
// replace with live PTV API calls when API key is available).
// ─────────────────────────────────────────────────────────────────────────────

class BusStop {
  final String id;
  final String name;
  final List<String> routes;
  final String nextArrival;
  final LatLng position;

  const BusStop({
    required this.id,
    required this.name,
    required this.routes,
    required this.nextArrival,
    required this.position,
  });
}

final List<BusStop> sampleBusStops = [
  BusStop(
    id: 'b1',
    name: 'Monash Uni Interchange',
    routes: ['630', '631', '900'],
    nextArrival: '3 min',
    position: LatLng(-37.9108, 145.1292),
  ),
  BusStop(
    id: 'b2',
    name: 'Campus Centre Stop',
    routes: ['631', '732'],
    nextArrival: '7 min',
    position: LatLng(-37.9122, 145.1318),
  ),
  BusStop(
    id: 'b3',
    name: 'Princes Hwy / Research Way',
    routes: ['900', '902'],
    nextArrival: '11 min',
    position: LatLng(-37.9075, 145.1382),
  ),
  BusStop(
    id: 'b4',
    name: 'Wellington Rd / Scenic Blvd',
    routes: ['601'],
    nextArrival: '14 min',
    position: LatLng(-37.9148, 145.1348),
  ),
];

// Persistent study spots (no expiry, no going/not-going state)
List<StudySpot> sampleStudySpots = [
  StudySpot(
    id: 's1',
    title: 'Quiet Study Area',
    location: 'Matheson Library — Level 2',
    position: LatLng(-37.9113, 145.1325),
  ),
  StudySpot(
    id: 's2',
    title: 'Group Study Room',
    location: 'Learning & Teaching Building — G12',
    position: LatLng(-37.9128, 145.1310),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Drop a Signal — ephemeral 30-minute broadcast pins
// ─────────────────────────────────────────────────────────────────────────────

enum SignalCategory {
  freeFood,
  study,
  social,
  studyGroup,
  mykiOfficers,
  fireAlarm,
}

const Map<SignalCategory, _SignalCategoryMeta> signalCategoryMeta = {
  SignalCategory.freeFood: _SignalCategoryMeta(
    label: 'Free Food',
    icon: Icons.fastfood_rounded,
    color: Color(0xFFFF9F43),
  ),
  SignalCategory.study: _SignalCategoryMeta(
    label: 'Study',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF00B894),
  ),
  SignalCategory.social: _SignalCategoryMeta(
    label: 'Social',
    icon: Icons.emoji_people_rounded,
    color: Color(0xFFFF7AD9),
  ),
  SignalCategory.studyGroup: _SignalCategoryMeta(
    label: 'Study Group',
    icon: Icons.groups_rounded,
    color: Color(0xFF3D8BFF),
  ),
  SignalCategory.mykiOfficers: _SignalCategoryMeta(
    label: 'Myki Officers',
    icon: Icons.security_rounded,
    color: Color(0xFFEF5350),
  ),
  SignalCategory.fireAlarm: _SignalCategoryMeta(
    label: 'Fire Alarm',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFFF5722),
  ),
};

class _SignalCategoryMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _SignalCategoryMeta({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class CampusSignal {
  final String id;
  final String message;
  final SignalCategory category;
  final LatLng position;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? imageUrl;
  final String? notes;

  CampusSignal({
    required this.id,
    required this.message,
    required this.category,
    required this.position,
    required this.createdAt,
    required this.expiresAt,
    this.imageUrl,
    this.notes,
  });

  Duration get timeRemaining => expiresAt.difference(DateTime.now());
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get timeAgoLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes == 1) return '1 minute ago';
    return '${diff.inMinutes} minutes ago';
  }
}

/// Live list of active signals — managed by MapTab state.
final List<CampusSignal> activeSignals = [];
