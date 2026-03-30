import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/services/stripe_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/money_formatter.dart';
import 'package:ewallet/views/sendMoneyView/send_money_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TopUpView extends StatefulWidget {
  const TopUpView({super.key});

  @override
  State<TopUpView> createState() => _TopUpViewState();
}

class _TopUpViewState extends State<TopUpView> {
  static const String cashOutNumber = '+964 78 75 84 48 84';

  final TextEditingController _amountController = TextEditingController();
  final StripeService _stripeService = StripeService();
  bool _isProcessing = false;
  String? _pendingSessionId;

  @override
  void initState() {
    super.initState();
    final sessionId = Uri.base.queryParameters['session_id'];
    if (sessionId != null && sessionId.trim().isNotEmpty) {
      _pendingSessionId = sessionId.trim();
    }
  }

  String _generateWalletId() {
    final rand = Random();
    final digits = List.generate(10, (_) => rand.nextInt(10)).join();
    return 'W$digits';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
          constraints: const BoxConstraints(
            maxWidth: 360,
            minWidth: 280,
          ),
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

  Future<void> _callCashOutNumber() async {
    final normalized = cashOutNumber.replaceAll(' ', '');
    final uri = Uri.parse('tel:$normalized');
    final launched = await launchUrl(uri);
    if (!launched) {
      Get.snackbar('error'.tr, cashOutNumber);
    }
  }

  Future<void> _openStripePaymentLink() async {
    final amount = MoneyFormatter.parseAmount(_amountController.text);
    if (amount <= 0) {
      Get.snackbar('invalid_amount'.tr, 'enter_valid_amount'.tr);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null) {
      Get.snackbar('auth_error'.tr, 'please_login_again'.tr);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      if (!StripeService.hasBackend) {
        Get.snackbar(
          'error'.tr,
          'Missing STRIPE_BACKEND_URL. Set --dart-define=STRIPE_BACKEND_URL=https://your-backend-url',
        );
        return;
      }

      final walletId = await _getOrCreateWalletId();

      final session = await _stripeService.createCheckoutSession(
        amount: amount,
        currency: 'usd',
        email: email,
        walletId: walletId,
      );
      setState(() {
        _pendingSessionId = session.sessionId;
      });
      final uri = Uri.parse(session.checkoutUrl);
      final launched = await launchUrl(uri, webOnlyWindowName: '_self');
      if (!launched) {
        throw Exception('Unable to open Stripe checkout');
      }
      Get.snackbar('topup_pending'.tr, 'payment_opened_return_confirm'.tr);
    } catch (e) {
      Get.snackbar(
        'topup_failed'.tr,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _confirmTopUp() async {
    final sessionId = _pendingSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      Get.snackbar('error'.tr, 'missing_session_id'.tr);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final result = await _stripeService.confirmTopUp(sessionId: sessionId);
      if (!result.success) {
        Get.snackbar('topup_failed'.tr, result.message);
        return;
      }

      if (result.credited) {
        setState(() {
          _pendingSessionId = null;
        });
        Get.snackbar('topup_success'.tr, 'wallet_credited_successfully'.tr);
      } else {
        Get.snackbar('topup_pending'.tr, result.message);
      }
    } catch (e) {
      Get.snackbar(
        'topup_failed'.tr,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  title: 'generate_qr'.tr,
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
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomButton(
                                  title: 'scan_qr'.tr,
                                  ontap: () => Get.to(
                                    () => const SendMoneyView(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
                GlassContainer(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      CustomField(
                        title: 'amount_to_add'.tr,
                        keybard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        controller: _amountController,
                        prefixIcon: Icons.attach_money_outlined,
                      ),
                      const SizedBox(height: 14),
                      CustomButton(
                        title:
                            _isProcessing ? 'please_wait'.tr : 'go_stripe'.tr,
                        bgColor: Appcolor.primary,
                        ontap: _isProcessing ? null : _openStripePaymentLink,
                      ),
                    ],
                  ),
                ),
                if (StripeService.hasBackend && _pendingSessionId != null) ...[
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'topup_pending'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'payment_opened_return_confirm'.tr,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          title: _isProcessing
                              ? 'please_wait'.tr
                              : 'confirm_topup'.tr,
                          bgColor: Appcolor.primary,
                          ontap: _isProcessing ? null : _confirmTopUp,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                GlassContainer(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'cash_out'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${'cash_out_help'.tr}: $cashOutNumber',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        title: 'contact_cash_out'.tr,
                        bgColor: Appcolor.secondary,
                        ontap: _callCashOutNumber,
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
