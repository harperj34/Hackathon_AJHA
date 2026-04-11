import 'dart:convert';
import 'package:http/http.dart' as http;

class NeonService {
  // This points to our local Node.js server
  static const String _baseUrl = 'http://localhost:3000';

  //returning user
  static Future<bool> emailExists(String email) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/user/$email'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exists'] == true;
    }
    throw Exception('Failed to check email');
  }

  //new user creation
  static Future<bool> createUser(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception('Failed to create user');
  }
}