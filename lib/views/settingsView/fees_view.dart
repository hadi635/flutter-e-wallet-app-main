import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeesView extends StatelessWidget {
  const FeesView({super.key});

  Widget _feeRow(String method, String fee) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              method,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            fee,
            style: const TextStyle(
              color: Appcolor.accent,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppbar(context: context, title: 'fees_table'.tr, arrorw: true),
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'no_fee_banner'.tr,
                      style: const TextStyle(
                        color: Appcolor.accent,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'fees_intro'.tr,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'add_money_fees'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _feeRow('Wish Money / TapTap Send', '3%'),
                    const Divider(color: Appcolor.glassBorder, height: 1),
                    _feeRow('Crypto', '3%'),
                    const Divider(color: Appcolor.glassBorder, height: 1),
                    _feeRow('Credit / Visa / Mastercard / Apple Pay', '5.5% + \$0.30'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
