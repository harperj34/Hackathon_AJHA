import 'dart:convert';
import 'package:http/http.dart' as http;

class NeonService {
  
  static const String _apiUrl = 'https://ep-morning-frog-aney0u45-pooler.c-6.us-east-1.aws.neon.tech/sql';
  static const String _apiKey = 'napi_eqdgwjwusvhl8wcqj2h7h9zws900e19s276m7q7h1dzq1z9rmxzlpay2typ19jzl';

  static Future<Map<String, dynamic>> _query(
    String sql, [
    List<dynamic> params = const [],
  ]) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({'query': sql, 'params': params}),
    );
    return jsonDecode(response.body);
  }

  // returning user -> true return
  static Future<bool> emailExists(String email) async {
    final result = await _query(
      'SELECT id FROM users WHERE email = \$1',
      [email],
    );
    final rows = result['rows'] as List;
    return rows.isNotEmpty;
  }

  // new user
  static Future<bool> createUser(String email) async {
    try {
      await _query(
        'INSERT INTO users (email) VALUES (\$1)',
        [email],
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}