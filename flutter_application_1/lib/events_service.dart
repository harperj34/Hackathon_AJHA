import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'neon_service.dart'; // reuse _baseUrl pattern

class EventsService {
  static String get _baseUrl => NeonService.baseUrl; // we'll expose this below

  // Recorded when the app first loads events: used to calculate expiry
  static DateTime? _appStartTime;

  // In-memory cache of all events fetched this session
  static List<CampusEvent> _allEvents = [];

  //fetch all events from DB and record start time
  static Future<List<CampusEvent>> loadEvents() async {
    _appStartTime = DateTime.now();
    try {
      final response = await http.get(Uri.parse('$_baseUrl/events'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['events'] as List)
            .map((e) => CampusEvent.fromJson(e as Map<String, dynamic>))
            .toList();
        _allEvents = list;
        return _activeEvents;
      }
    } catch (e) {
      print('EventsService error: $e');
    }
    return [];
  }

  // returns only events that haven't expired yet this session
  static List<CampusEvent> get _activeEvents {
    if (_appStartTime == null) return _allEvents;
    final elapsed = DateTime.now().difference(_appStartTime!).inMinutes;
    return _allEvents
        .where((e) => elapsed < e.durationMinutes)
        .toList();
  }


  static List<CampusEvent> get currentEvents => _activeEvents;


  static Future<bool> createEvent(CampusEvent event) async {
    //also add to in-memory list immediately
    _allEvents.add(event);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(event.toJson()),
      );
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('EventsService createEvent error: $e');
    }
    return false;
  }
}