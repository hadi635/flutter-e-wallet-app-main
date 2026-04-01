import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/wallet_support.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CashOutView extends StatelessWidget {
  const CashOutView({super.key});

  Widget _methodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String speed,
    required String actionTitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (color ?? Appcolor.primary).withAlpha(32),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color ?? Appcolor.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withAlpha(190),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${'speed'.tr}: $speed',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 14),
          CustomButton(
            title: actionTitle,
            bgColor: color,
            ontap: onTap,
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppbar(context: context, title: 'cash_out'.tr, arrorw: true),
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'cash_out_intro_title'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'cash_out_intro'.tr,
                        style: TextStyle(
                          color: Colors.white.withAlpha(190),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _methodCard(
                  icon: Icons.storefront_rounded,
                  title: 'agent_cash_out'.tr,
                  subtitle: 'agent_cash_out_subtitle'.tr,
                  speed: 'third_party_speed'.tr,
                  actionTitle: 'contact_now'.tr,
                  onTap: () => WalletSupport.openSupportContactDialog(
                    title: 'agent_cash_out'.tr,
                    message: 'agent_cash_out_contact'.tr,
                  ),
                ),
                const SizedBox(height: 12),
                _methodCard(
                  icon: Icons.currency_bitcoin_rounded,
                  title: 'crypto_method'.tr,
                  subtitle: 'crypto_cash_out_subtitle'.tr,
                  speed: 'instant'.tr,
                  actionTitle: 'continue_text'.tr,
                  color: Appcolor.secondary,
                  onTap: () => Get.snackbar(
                    'crypto_method'.tr,
                    'crypto_coming_soon'.tr,
                  ),
                ),
                const SizedBox(height: 12),
                _methodCard(
                  icon: Icons.phone_in_talk_rounded,
                  title: 'wish_cash_out'.tr,
                  subtitle: 'wish_cash_out_subtitle'.tr,
                  speed: 'third_party_speed'.tr,
                  actionTitle: 'contact_now'.tr,
                  color: const Color(0xffE08A2E),
                  onTap: () => WalletSupport.openSupportContactDialog(
                    title: 'wish_cash_out'.tr,
                    message: 'wish_cash_out_contact'.tr,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
