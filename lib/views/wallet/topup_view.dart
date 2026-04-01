import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/money_formatter.dart';
import 'package:ewallet/views/wallet/add_money_view.dart';
import 'package:ewallet/views/wallet/cash_out_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TopUpView extends StatefulWidget {
  const TopUpView({super.key});

  @override
  State<TopUpView> createState() => _TopUpViewState();
}

class _TopUpViewState extends State<TopUpView> {
  String _generateWalletId() {
    final rand = Random();
    final digits = List.generate(10, (_) => rand.nextInt(10)).join();
    return 'W$digits';
  }

  Future<String?> _getOrCreateWalletId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return null;

    final ref = FirebaseFirestore.instance.collection('user').doc(user!.email);
    final snap = await ref.get();
    final existing = snap.data()?['WalletId']?.toString().trim() ?? '';
    if (existing.isNotEmpty) return existing;

    final walletId = _generateWalletId();
    await ref.set({'WalletId': walletId}, SetOptions(merge: true));
    return walletId;
  }

  Future<void> _showMyQr(String walletId) async {
    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, minWidth: 280),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            decoration: BoxDecoration(
              color: Appcolor.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Appcolor.glassBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'receive_by_qr'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: QrImageView(
                      data: 'upay://wallet/$walletId',
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${'wallet_id'.tr}: $walletId',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: Text('close'.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withAlpha(10),
            border: Border.all(color: Appcolor.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (color ?? Appcolor.primary).withAlpha(32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color ?? Appcolor.accent),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text('please_login_again'.tr)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'wallet'.tr,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('user')
                      .doc(user.email)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data();
                    final balance = data?['Balance'] ?? 0;
                    final walletId = data?['WalletId']?.toString() ?? '';

                    return GlassContainer(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'wallet_card'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '\$${MoneyFormatter.fixed2(balance)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${'wallet_id'.tr}: $walletId',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomButton(
                            title: 'show_my_qr'.tr,
                            bgColor: Appcolor.secondary,
                            ontap: () async {
                              final ensured = walletId.isNotEmpty
                                  ? walletId
                                  : await _getOrCreateWalletId();
                              if (ensured == null || ensured.isEmpty) {
                                Get.snackbar(
                                  'error'.tr,
                                  'please_login_again'.tr,
                                );
                                return;
                              }
                              await _showMyQr(ensured);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _quickAction(
                      title: 'add_money'.tr,
                      subtitle: 'add_money_wallet_short'.tr,
                      icon: Icons.add_card_rounded,
                      onTap: () => Get.to(() => const AddMoneyView()),
                    ),
                    const SizedBox(width: 12),
                    _quickAction(
                      title: 'cash_out'.tr,
                      subtitle: 'cash_out_wallet_short'.tr,
                      icon: Icons.local_atm_rounded,
                      color: Appcolor.secondary,
                      onTap: () => Get.to(() => const CashOutView()),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'wallet_notes_title'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'wallet_notes_body'.tr,
                        style: TextStyle(
                          color: Colors.white.withAlpha(190),
                          height: 1.5,
                        ),
                      ),
                    ],
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
