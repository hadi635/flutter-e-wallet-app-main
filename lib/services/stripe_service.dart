import 'dart:convert';

import 'package:ewallet/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StripeCheckoutSessionResult {
  final String checkoutUrl;
  final String sessionId;

  const StripeCheckoutSessionResult({
    required this.checkoutUrl,
    required this.sessionId,
  });
}

class StripeTopUpResult {
  final bool success;
  final bool credited;
  final String message;

  const StripeTopUpResult({
    required this.success,
    required this.credited,
    required this.message,
  });
}

class StripeService {
  static const String backendBaseUrl = ApiService.baseUrl;
  static const String _pendingSessionIdKey = 'stripe_pending_session_id';

  static bool get hasBackend => backendBaseUrl.trim().isNotEmpty;

  static Future<void> init() async {
    return;
  }

  static Future<void> savePendingSessionId(String sessionId) async {
    final value = sessionId.trim();
    if (value.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingSessionIdKey, value);
  }

  static Future<String?> getPendingSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_pendingSessionIdKey)?.trim();
    if (sessionId == null || sessionId.isEmpty) {
      return null;
    }
    return sessionId;
  }

  static Future<void> clearPendingSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSessionIdKey);
  }

  Map<String, dynamic> _decodeJsonResponse({
    required String endpoint,
    required http.Response response,
  }) {
    return ApiService.decodeJsonObject(endpoint: endpoint, response: response);
  }

  Future<StripeCheckoutSessionResult> createCheckoutSession({
    required double amount,
    required String currency,
    required String email,
    String? walletId,
  }) async {
    if (!hasBackend) {
      throw Exception(
        'Missing API_BASE_URL. Provide --dart-define=API_BASE_URL=https://www.infinity-sharing.money/api',
      );
    }

    final uri = ApiService.uri('/create-checkout-session');
    final token = await ApiService.getIdToken();
    final headers = {
      ...ApiService.getAuthHeaders(),
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        'email': email,
        'walletId': walletId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'create-checkout-session failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = _decodeJsonResponse(
      endpoint: 'create-checkout-session',
      response: response,
    );
    final checkoutUrl = data['checkoutUrl']?.toString() ?? '';
    final sessionId = data['sessionId']?.toString() ?? '';

    if (checkoutUrl.isEmpty || sessionId.isEmpty) {
      throw Exception('Backend did not return checkoutUrl/sessionId');
    }

    return StripeCheckoutSessionResult(
      checkoutUrl: checkoutUrl,
      sessionId: sessionId,
    );
  }

  Future<StripeTopUpResult> confirmTopUp({
    required String sessionId,
  }) async {
    if (!hasBackend) {
      throw Exception(
        'Missing API_BASE_URL. Provide --dart-define=API_BASE_URL=https://www.infinity-sharing.money/api',
      );
    }

    final uri = ApiService.uri('/confirm-topup');
    final token = await ApiService.getIdToken();
    final headers = {
      ...ApiService.getAuthHeaders(),
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'sessionId': sessionId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'confirm-topup failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = _decodeJsonResponse(
      endpoint: 'confirm-topup',
      response: response,
    );
    return StripeTopUpResult(
      success: data['success'] == true,
      credited: data['credited'] == true,
      message: data['message']?.toString() ??
          data['error']?.toString() ??
          'Top-up result received',
    );
  }
}
