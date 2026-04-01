import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.infinity-sharing.money/api',
  );

  static Future<String?> getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  static Uri uri(String path, {Map<String, String>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath')
        .replace(queryParameters: queryParameters);
  }

  static Map<String, dynamic> decodeJsonObject({
    required String endpoint,
    required http.Response response,
  }) {
    final body = response.body;
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    final looksLikeHtml =
        body.trimLeft().startsWith('<!DOCTYPE') || body.trimLeft().startsWith('<html');

    if (!contentType.contains('application/json') || looksLikeHtml) {
      debugPrint(
        'API error [$endpoint]: expected JSON but got content-type="$contentType". '
        'Body preview: ${body.length > 300 ? '${body.substring(0, 300)}...' : body}',
      );
      throw Exception('Invalid response from $endpoint: expected JSON');
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Response JSON is not an object');
      }
      return decoded;
    } on FormatException catch (e) {
      debugPrint('API JSON parse error [$endpoint]: $e');
      throw Exception('Invalid JSON from $endpoint');
    }
  }

  // Helper for auth POST
  static Map<String, String> getAuthHeaders({bool includeContentType = true}) {
    final headers = <String, String>{};
    if (includeContentType) headers['Content-Type'] = 'application/json';
    return headers;
  }
}
