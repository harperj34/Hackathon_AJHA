import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';

class NeonService {
  static String get baseUrl {
    if (kIsWeb) {
      final base = Uri.base;
      // Local dev: the Flutter web dev server is not the Express server
      if (base.host == 'localhost' || base.host == '127.0.0.1') {
        return 'http://localhost:3000';
      }
      // Production (Vercel): use same-origin /api (serverless functions)
      final port = (base.hasPort && base.port != 80 && base.port != 443)
          ? ':${base.port}'
          : '';
      return '${base.scheme}://${base.host}$port/api';
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
  final encodedEmail = Uri.encodeComponent(email);

  final response = await http.get(
    Uri.parse('$baseUrl/user/$encodedEmail'),
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
