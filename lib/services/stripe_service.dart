import 'dart:convert';

import 'package:http/http.dart' as http;

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
  static const String backendBaseUrl =
      String.fromEnvironment('STRIPE_BACKEND_URL', defaultValue: '');

  static bool get hasBackend => backendBaseUrl.trim().isNotEmpty;

  static Future<void> init() async {
    return;
  }

  Future<StripeCheckoutSessionResult> createCheckoutSession({
    required double amount,
    required String currency,
    required String email,
    String? walletId,
  }) async {
    if (!hasBackend) {
      throw Exception(
        'Missing STRIPE_BACKEND_URL. Provide --dart-define=STRIPE_BACKEND_URL=http://localhost:4242',
      );
    }

    final uri = Uri.parse('$backendBaseUrl/create-checkout-session');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
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

    final data = jsonDecode(response.body) as Map<String, dynamic>;
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
        'Missing STRIPE_BACKEND_URL. Provide --dart-define=STRIPE_BACKEND_URL=http://localhost:4242',
      );
    }

    final uri = Uri.parse('$backendBaseUrl/confirm-topup');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionId': sessionId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'confirm-topup failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return StripeTopUpResult(
      success: data['success'] == true,
      credited: data['credited'] == true,
      message: data['message']?.toString() ?? 'Top-up result received',
    );
  }
}
