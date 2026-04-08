import 'dart:async';

import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/services/moonpay_service.dart';
import 'package:ewallet/services/stripe_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/web_url_state.dart';
import 'package:ewallet/views/splash/splash_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentResultView extends StatefulWidget {
  final bool success;

  const PaymentResultView({super.key, required this.success});

  @override
  State<PaymentResultView> createState() => _PaymentResultViewState();
}

class _PaymentResultViewState extends State<PaymentResultView> {
  final _moonPayService = MoonPayService();

  bool _processing = false;
  bool _credited = false;
  bool _pending = false;
  bool _failed = false;
  String _message = '';
  String _moonPayTransactionId = '';
  Timer? _moonPayPollTimer;

  @override
  void initState() {
    super.initState();
    _confirmFromSessionIfNeeded();
  }

  @override
  void dispose() {
    _moonPayPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmFromSessionIfNeeded() async {
    if (!widget.success) return;

    if (_isMoonPay) {
      await _verifyMoonPay();
      return;
    }

    if (!StripeService.hasBackend) {
      return;
    }

    final querySessionId =
        resolveWebUrlState().queryParameters['session_id']?.trim() ?? '';
    final sessionId = querySessionId.isNotEmpty
        ? querySessionId
        : (await StripeService.getPendingSessionId() ?? '');
    if (sessionId.isEmpty) return;

    if (querySessionId.isNotEmpty) {
      await StripeService.savePendingSessionId(querySessionId);
    }

    setState(() => _processing = true);
    try {
      final result = await StripeService().confirmTopUp(sessionId: sessionId);
      setState(() {
        _credited = result.credited;
        _pending = result.pending;
        _failed = !result.credited && !result.pending;
        _message = result.message;
      });

      if (result.credited || result.pending) {
        await StripeService.clearPendingSessionId();
      }
    } catch (e) {
      setState(() {
        _credited = false;
        _pending = false;
        _failed = true;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  bool get _isMoonPay {
    final provider =
        resolveWebUrlState().queryParameters['provider']?.trim().toLowerCase() ??
            '';
    return provider == 'moonpay';
  }

  Future<void> _verifyMoonPay() async {
    final transactionId =
        resolveWebUrlState().queryParameters['transactionId']?.trim() ?? '';
    if (transactionId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _pending = false;
        _credited = false;
        _message = 'Missing MoonPay transaction id.';
      });
      return;
    }

    _moonPayTransactionId = transactionId;
    _moonPayPollTimer?.cancel();
    await _pollMoonPayTransaction();
  }

  Future<void> _pollMoonPayTransaction() async {
    if (_moonPayTransactionId.isEmpty || !mounted || _processing) return;

    setState(() => _processing = true);
    try {
      final result = await _moonPayService.verifyTransaction(
        transactionId: _moonPayTransactionId,
      );
      if (!mounted) return;

      setState(() {
        _credited = result.credited;
        _pending = result.pending;
        _failed = result.failed;
        _message = result.message;
      });

      if (result.credited || result.failed) {
        _moonPayPollTimer?.cancel();
      } else if (result.pending) {
        _moonPayPollTimer ??=
            Timer.periodic(const Duration(seconds: 5), (_) async {
          await _pollMoonPayTransaction();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _credited = false;
        _pending = false;
        _failed = true;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
      _moonPayPollTimer?.cancel();
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = _pending && !_credited && !_failed;
    final isSuccess = _credited || (widget.success && !_isMoonPay && !_failed);
    final topMessage = _processing
        ? 'please_wait'.tr
        : (_message.isNotEmpty
            ? _message
            : (isPending
                ? (_isMoonPay
                    ? 'moonpay_result_pending'.tr
                    : 'stripe_card_pending_message'.tr)
                : (isSuccess
                    ? 'wallet_credited_successfully'.tr
                    : 'topup_failed'.tr)));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_processing)
                    const SizedBox(
                      width: 66,
                      height: 66,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Appcolor.accent,
                      ),
                    )
                  else
                    Icon(
                      isPending
                          ? Icons.schedule_rounded
                          : (isSuccess
                              ? Icons.check_circle_outline_rounded
                              : Icons.cancel_outlined),
                      color: isPending
                          ? Colors.amberAccent
                          : (isSuccess ? Appcolor.accent : Colors.redAccent),
                      size: 66,
                    ),
                  const SizedBox(height: 10),
                  Text(
                    isPending
                        ? 'topup_pending'.tr
                        : (isSuccess ? 'topup_success'.tr : 'topup_failed'.tr),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (_isMoonPay && _moonPayTransactionId.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SelectableText(
                      'Transaction ID: $_moonPayTransactionId',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(190),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  CustomButton(
                    title: 'done'.tr,
                    ontap: () => Get.offAll(() => const SplashScreenView()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
