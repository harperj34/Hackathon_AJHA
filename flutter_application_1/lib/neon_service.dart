import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';

class NeonService {
  static String get baseUrl {
    if (kIsWeb) {
      //in chrome
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2
      return 'http://10.0.2.2:3000';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'http://localhost:3000';
    } else {
      //Windows/Mac/Linux desktop
      return 'http://localhost:3000';
    }
  }

  //returning user
  static Future<bool> emailExists(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$email'),
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
      Uri.parse('$baseUrl/user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception('Failed to create user');
  }
}