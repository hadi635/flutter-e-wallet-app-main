import 'dart:convert';

import 'package:ewallet/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CryptoTopupSession {
  final String depositId;
  final String depositWalletAddress;
  final String tokenMint;
  final String tokenSymbol;
  final String blockchain;
  final double amountToSend;
  final double requestedAmount;
  final double feeAmount;
  final double netAmount;
  final double usdRate;
  final String status;

  const CryptoTopupSession({
    required this.depositId,
    required this.depositWalletAddress,
    required this.tokenMint,
    required this.tokenSymbol,
    required this.blockchain,
    required this.amountToSend,
    required this.requestedAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.usdRate,
    required this.status,
  });
}

class CryptoTopupResult {
  final bool success;
  final bool credited;
  final String status;
  final String message;
  final String signature;

  const CryptoTopupResult({
    required this.success,
    required this.credited,
    required this.status,
    required this.message,
    required this.signature,
  });
}

class CryptoTopupService {
  static const String _pendingDepositIdKey = 'crypto_pending_deposit_id';
  static const String _pendingDepositJsonKey = 'crypto_pending_deposit_json';

  Future<void> savePendingSession(CryptoTopupSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingDepositIdKey, session.depositId);
    await prefs.setString(_pendingDepositJsonKey, jsonEncode({
      'depositId': session.depositId,
      'depositWalletAddress': session.depositWalletAddress,
      'tokenMint': session.tokenMint,
      'tokenSymbol': session.tokenSymbol,
      'blockchain': session.blockchain,
      'amountToSend': session.amountToSend,
      'requestedAmount': session.requestedAmount,
      'feeAmount': session.feeAmount,
      'netAmount': session.netAmount,
      'usdRate': session.usdRate,
      'status': session.status,
    }));
  }

  Future<String?> getPendingDepositId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_pendingDepositIdKey)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<CryptoTopupSession?> getPendingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingDepositJsonKey)?.trim();
    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return CryptoTopupSession(
        depositId: data['depositId']?.toString() ?? '',
        depositWalletAddress: data['depositWalletAddress']?.toString() ?? '',
        tokenMint: data['tokenMint']?.toString() ?? '',
        tokenSymbol: data['tokenSymbol']?.toString() ?? 'USDC',
        blockchain: data['blockchain']?.toString() ?? 'Solana',
        amountToSend: (data['amountToSend'] as num?)?.toDouble() ?? 0,
        requestedAmount: (data['requestedAmount'] as num?)?.toDouble() ?? 0,
        feeAmount: (data['feeAmount'] as num?)?.toDouble() ?? 0,
        netAmount: (data['netAmount'] as num?)?.toDouble() ?? 0,
        usdRate: (data['usdRate'] as num?)?.toDouble() ?? 1,
        status: data['status']?.toString() ?? 'pending',
      );
    } catch (_) {
      await clearPendingDepositId();
      return null;
    }
  }

  Future<void> clearPendingDepositId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingDepositIdKey);
    await prefs.remove(_pendingDepositJsonKey);
  }

  Future<CryptoTopupSession> createCryptoTopup({
    required double amount,
    required String email,
    String? walletId,
  }) async {
    final uri = ApiService.uri('/create-crypto-topup');
    final token = await ApiService.getIdToken();
    final response = await http.post(
      uri,
      headers: {
        ...ApiService.getAuthHeaders(),
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'email': email,
        'walletId': walletId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'create-crypto-topup failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = ApiService.decodeJsonObject(
      endpoint: 'create-crypto-topup',
      response: response,
    );

    return CryptoTopupSession(
      depositId: data['depositId']?.toString() ?? '',
      depositWalletAddress: data['depositWalletAddress']?.toString() ?? '',
      tokenMint: data['tokenMint']?.toString() ?? '',
      tokenSymbol: data['tokenSymbol']?.toString() ?? 'USDC',
      blockchain: data['blockchain']?.toString() ?? 'Solana',
      amountToSend: (data['amountToSend'] as num?)?.toDouble() ?? 0,
      requestedAmount: (data['requestedAmount'] as num?)?.toDouble() ?? 0,
      feeAmount: (data['feeAmount'] as num?)?.toDouble() ?? 0,
      netAmount: (data['netAmount'] as num?)?.toDouble() ?? 0,
      usdRate: (data['estimatedUsdRate'] as num?)?.toDouble() ?? 1,
      status: data['status']?.toString() ?? 'pending',
    );
  }

  Future<CryptoTopupResult> confirmCryptoTopup({
    required String depositId,
  }) async {
    final uri = ApiService.uri('/confirm-crypto-topup');
    final token = await ApiService.getIdToken();
    final response = await http.post(
      uri,
      headers: {
        ...ApiService.getAuthHeaders(),
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'depositId': depositId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'confirm-crypto-topup failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = ApiService.decodeJsonObject(
      endpoint: 'confirm-crypto-topup',
      response: response,
    );

    return CryptoTopupResult(
      success: data['success'] == true,
      credited: data['credited'] == true,
      status: data['status']?.toString() ?? 'pending',
      message: data['message']?.toString() ?? 'Crypto top-up status received',
      signature: data['signature']?.toString() ?? '',
    );
  }
}
