import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/services/wallet_request_service.dart';
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
  String _methodLabel(String? method) {
    switch (method) {
      case 'wish':
        return 'request_method_wish'.tr;
      case 'card':
        return 'request_method_card'.tr;
      case 'crypto':
        return 'request_method_crypto'.tr;
      case 'agent':
        return 'request_method_agent'.tr;
      default:
        return method ?? 'unknown'.tr;
    }
  }

  String _kindLabel(String? kind) {
    switch (kind) {
      case 'add_money':
        return 'request_kind_add_money'.tr;
      case 'cash_out':
        return 'request_kind_cash_out'.tr;
      default:
        return kind ?? 'unknown'.tr;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'request_status_pending'.tr;
      case 'confirmed':
        return 'request_status_confirmed'.tr;
      case 'rejected':
        return 'request_status_rejected'.tr;
      default:
        return status ?? 'unknown'.tr;
    }
  }

  Future<String?> _getOrCreateWalletId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return null;

    final ref = FirebaseFirestore.instance.collection('user').doc(user!.email);
    final snap = await ref.get();
    final existing = snap.data()?['WalletId']?.toString().trim() ?? '';
    if (existing.isNotEmpty) return existing;

    final rand = Random();
    final walletId = 'W${List.generate(10, (_) => rand.nextInt(10)).join()}';
    await ref.set({'WalletId': walletId}, SetOptions(merge: true));
    return walletId;
  }

  Future<void> _showMyQr(String walletId) async {
    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(18),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: 'upay://wallet/$walletId',
                  backgroundColor: Colors.white,
                  size: 220,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${'wallet_id'.tr}: $walletId',
                style: const TextStyle(color: Colors.white),
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
      return Scaffold(body: Center(child: Text('please_login_again'.tr)));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('user')
                .doc(user.email)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() ?? {};
              final balance = data['Balance'] ?? 0;
              final walletId = data['WalletId']?.toString() ?? '';

              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _walletCard(balance: balance, walletId: walletId),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 720;
                      final addMoneyCard = _actionCard(
                        title: 'add_money'.tr,
                        subtitle: 'wallet_add_money_summary'.tr,
                        icon: Icons.add_card_rounded,
                        color: Appcolor.primary,
                        onTap: () => Get.to(() => const AddMoneyView()),
                      );
                      final cashOutCard = _actionCard(
                        title: 'cash_out'.tr,
                        subtitle: 'wallet_cash_out_summary'.tr,
                        icon: Icons.local_atm_rounded,
                        color: Appcolor.secondary,
                        onTap: () => Get.to(() => const CashOutView()),
                      );

                      if (compact) {
                        return Column(
                          children: [
                            addMoneyCard,
                            const SizedBox(height: 12),
                            cashOutCard,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: addMoneyCard),
                          const SizedBox(width: 12),
                          Expanded(child: cashOutCard),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'receive_money'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'receive_money_body'.tr,
                          style: TextStyle(
                            color: Colors.white.withAlpha(190),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        CustomButton(
                          title: 'show_my_qr'.tr,
                          bgColor: Appcolor.secondary,
                          ontap: () async {
                            final ensured = walletId.isNotEmpty
                                ? walletId
                                : await _getOrCreateWalletId();
                            if (ensured != null && ensured.isNotEmpty) {
                              await _showMyQr(ensured);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection(WalletRequestService.requestsCollection)
                        .where('email', isEqualTo: user.email)
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, requestSnapshot) {
                      final requestDocs = requestSnapshot.data?.docs ?? [];
                      if (requestDocs.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return GlassContainer(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'pending_operations'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...requestDocs.take(5).map((doc) {
                              final item = doc.data();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${_kindLabel(item['kind']?.toString())} • ${_methodLabel(item['method']?.toString())} • ${_statusLabel(item['status']?.toString())}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '\$${MoneyFormatter.fixed2(item['netAmount'] ?? item['requestedAmount'] ?? 0)}',
                                      style: const TextStyle(
                                        color: Appcolor.accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _walletCard({required dynamic balance, required String walletId}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xffFFC145), Color(0xffD88A19), Color(0xff111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'wallet_card_brand'.tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'wallet_card_teaser'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(28),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'coming_soon'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Appcolor.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(185),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
