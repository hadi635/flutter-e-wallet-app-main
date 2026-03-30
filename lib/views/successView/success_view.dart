import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/money_formatter.dart';
import 'package:ewallet/views/nav/nav_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuccessView extends StatelessWidget {
  final dynamic receiverWalletId;
  final dynamic amountSend;

  const SuccessView({super.key, this.amountSend, this.receiverWalletId});

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
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "success".tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "\$${MoneyFormatter.fixed2(amountSend ?? 0)} USD",
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${'sent_to_wallet'.tr} $receiverWalletId ${'from_your_wallet'.tr}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  CustomButton(
                    title: "done".tr,
                    ontap: () => Get.offAll(NavView()),
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
