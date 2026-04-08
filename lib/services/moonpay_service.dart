import 'dart:convert';
import 'dart:math';

import 'package:ewallet/services/api_service.dart';
import 'package:ewallet/utils/money_formatter.dart';
import 'package:http/http.dart' as http;

class MoonPayVerifyResult {
  final bool success;
  final bool credited;
  final bool pending;
  final bool failed;
  final String transactionId;
  final String status;
  final String message;
  final double amountFiat;
  final double amountCrypto;
  final double feeAmount;
  final double netAmount;

  const MoonPayVerifyResult({
    required this.success,
    required this.credited,
    required this.pending,
    required this.failed,
    required this.transactionId,
    required this.status,
    required this.message,
    required this.amountFiat,
    required this.amountCrypto,
    required this.feeAmount,
    required this.netAmount,
  });
}

class MoonPayService {
  static const apiKey = String.fromEnvironment(
    'MOONPAY_API_KEY',
    defaultValue: '',
  );
  static const environment = String.fromEnvironment(
    'MOONPAY_ENVIRONMENT',
    defaultValue: 'sandbox',
  );
  static const defaultCurrencyCode = String.fromEnvironment(
    'MOONPAY_DEFAULT_CURRENCY_CODE',
    defaultValue: 'usdc',
  );
  static const defaultBaseCurrencyCode = String.fromEnvironment(
    'MOONPAY_BASE_CURRENCY_CODE',
    defaultValue: 'usd',
  );
  static const theme = String.fromEnvironment(
    'MOONPAY_THEME',
    defaultValue: 'dark',
  );
  static const redirectUrl = String.fromEnvironment(
    'MOONPAY_REDIRECT_URL',
    defaultValue: 'https://www.infinity-sharing.money/success?provider=moonpay',
  );
  static const platformWalletAddress = String.fromEnvironment(
    'MOONPAY_PLATFORM_WALLET_ADDRESS',
    defaultValue: '0x7c01Fc5c0B9655492d8D75F36BDFb036a73dc20D',
  );

  static const Set<String> _unsupportedCountries = {
    'Afghanistan',
    'American Samoa',
    'Bangladesh',
    'Barbados',
    'Burkina Faso',
    'China',
    'Cuba',
    'Guinea-Bissau',
    'Haiti',
    'Iran',
    'Iraq',
    'Jamaica',
    'Japan',
    'Kosovo',
    'Lebanon',
    'Libya',
    'Macao SAR, China',
    'Madagascar',
    'Malaysia',
    'Mongolia',
    'Morocco',
    'Myanmar',
    'Nicaragua',
    'Nigeria',
    'Korea, North',
    'Oman',
    'Pakistan',
    'Palestine',
    'Panama',
    'Russia',
    'Senegal',
    'Somalia',
    'South Sudan',
    'Syrian Arab Republic',
    'Tajikistan',
    'Timor-Leste',
    'The Democratic Republic Of The Congo',
    'Uganda',
    'Ukraine',
    'United States Virgin Islands',
    'Venezuela',
    'Western Sahara',
    'Yemen',
    'Zimbabwe',
    'Hungary',
  };

  bool get isConfigured =>
      apiKey.trim().isNotEmpty && platformWalletAddress.trim().isNotEmpty;

  bool isCountrySupported(String? country) {
    final normalized = (country ?? '').trim();
    if (normalized.isEmpty) return false;
    return !_unsupportedCountries.contains(normalized);
  }

  double calculateFee(double amount) {
    return _money((amount * 0.055) + 0.30);
  }

  double calculateNet(double amount) {
    return _money(max(0, amount - calculateFee(amount)));
  }

  double _money(num value) {
    return (value * 100).roundToDouble() / 100;
  }

  String _buildExternalTransactionId({
    required String userId,
    required String email,
    required String walletId,
  }) {
    final payload = jsonEncode({
      'userId': userId,
      'email': email,
      'walletId': walletId,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    return 'ctx_${base64UrlEncode(utf8.encode(payload))}';
  }

  Uri buildBuyUri({
    required double amount,
    required String userId,
    required String userEmail,
    required String walletId,
  }) {
    if (!isConfigured) {
      throw Exception(
        'Missing MoonPay configuration. Add MOONPAY_API_KEY and MOONPAY_PLATFORM_WALLET_ADDRESS.',
      );
    }

    final host = environment.trim().toLowerCase() == 'production'
        ? 'buy.moonpay.com'
        : 'buy-sandbox.moonpay.com';

    final externalTransactionId = _buildExternalTransactionId(
      userId: userId,
      email: userEmail,
      walletId: walletId,
    );

    final params = <String, String>{
      'apiKey': apiKey,
      'baseCurrencyCode': defaultBaseCurrencyCode,
      'baseCurrencyAmount': MoneyFormatter.fixed2(amount),
      'defaultCurrencyCode': defaultCurrencyCode,
      'paymentMethod': 'credit_debit_card',
      'theme': theme,
      'walletAddress': platformWalletAddress,
      'email': userEmail,
      'externalCustomerId': userId,
      'externalTransactionId': externalTransactionId,
      'redirectURL': redirectUrl,
      'metadata[userId]': userId,
      'metadata[walletId]': walletId,
    };

    return Uri.https(host, '/', params);
  }

  Future<Uri> createSignedBuyUri({
    required double amount,
    required String userId,
    required String userEmail,
    required String walletId,
  }) async {
    final unsignedUrl = buildBuyUri(
      amount: amount,
      userId: userId,
      userEmail: userEmail,
      walletId: walletId,
    );
    final token = await ApiService.getIdToken();
    final response = await http.post(
      ApiService.uri('/moonpay/sign-url'),
      headers: {
        ...ApiService.getAuthHeaders(),
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'url': unsignedUrl.toString(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'moonpay-sign-url failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = ApiService.decodeJsonObject(
      endpoint: 'moonpay-sign-url',
      response: response,
    );
    final signedUrl = data['signedUrl']?.toString().trim() ?? '';
    if (signedUrl.isEmpty) {
      throw Exception('MoonPay sign-url response is missing signedUrl');
    }

    return Uri.parse(signedUrl);
  }

  Future<MoonPayVerifyResult> verifyTransaction({
    required String transactionId,
  }) async {
    final token = await ApiService.getIdToken();
    final response = await http.get(
      ApiService.uri(
        '/moonpay/verify',
        queryParameters: {
          'transactionId': transactionId,
        },
      ),
      headers: {
        ...ApiService.getAuthHeaders(includeContentType: false),
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'moonpay-verify failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = ApiService.decodeJsonObject(
      endpoint: 'moonpay-verify',
      response: response,
    );
    return MoonPayVerifyResult(
      success: data['success'] == true,
      credited: data['credited'] == true,
      pending: data['pending'] == true,
      failed: data['failed'] == true,
      transactionId: data['transactionId']?.toString() ?? transactionId,
      status: data['status']?.toString() ?? '',
      message: data['message']?.toString() ?? 'MoonPay status received',
      amountFiat: (data['amountFiat'] as num?)?.toDouble() ?? 0,
      amountCrypto: (data['amountCrypto'] as num?)?.toDouble() ?? 0,
      feeAmount: (data['feeAmount'] as num?)?.toDouble() ?? 0,
      netAmount: (data['netAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
