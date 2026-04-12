import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'neon_service.dart';
import 'session_state.dart';

class SignalService {
  static String get _baseUrl => NeonService.baseUrl;

  /// Fetch all visible, non-expired signals from the DB.
  static Future<List<CampusSignal>> loadSignals() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/signals'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['signals'] as List)
            .map((s) => CampusSignal.fromJson(s as Map<String, dynamic>))
            .where((s) => !s.isExpired)
            .toList();
      }
    } catch (e) {
      print('SignalService loadSignals error: $e');
    }
    return [];
  }

  /// Persist a newly dropped signal to the DB.
  static Future<bool> createSignal(CampusSignal signal) async {
    try {
      final body = signal.toJson();
      body['created_by'] = SessionState.currentUserEmail;
      final response = await http.post(
        Uri.parse('$_baseUrl/signals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('SignalService createSignal error: $e');
    }
    return false;
  }

  /// Mark a signal as invisible (expired or user-removed).
  static Future<void> hideSignal(String id) async {
    try {
      await http.patch(Uri.parse('$_baseUrl/signals/$id'));
    } catch (e) {
      print('SignalService hideSignal error: $e');
    }
  }
}
