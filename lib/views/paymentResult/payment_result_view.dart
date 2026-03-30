import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/views/splash/splash_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentResultView extends StatelessWidget {
  final bool success;

  const PaymentResultView({super.key, required this.success});

  @override
  Widget build(BuildContext context) {
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
                    success
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                    color: success ? Appcolor.accent : Colors.redAccent,
                    size: 66,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    success ? 'topup_success'.tr : 'topup_failed'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    success
                        ? 'payment_opened_return_confirm'.tr
                        : 'topup_failed'.tr,
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
