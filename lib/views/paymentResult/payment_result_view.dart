import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/glass_container.dart';
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
  bool _processing = false;
  bool _credited = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _confirmFromSessionIfNeeded();
  }

  Future<void> _confirmFromSessionIfNeeded() async {
    if (!widget.success) return;

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
        _message = result.message;
      });

      if (result.credited ||
          result.message.toLowerCase().contains('already credited')) {
        await StripeService.clearPendingSessionId();
      }
    } catch (e) {
      setState(() {
        _credited = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.success;
    final topMessage = _processing
        ? 'please_wait'.tr
        : (isSuccess
            ? (_credited
                ? 'wallet_credited_successfully'.tr
                : (_message.isNotEmpty
                    ? _message
                    : 'payment_opened_return_confirm'.tr))
            : 'topup_failed'.tr);

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
                  Icon(
                    isSuccess
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                    color: isSuccess ? Appcolor.accent : Colors.redAccent,
                    size: 66,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isSuccess ? 'topup_success'.tr : 'topup_failed'.tr,
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
