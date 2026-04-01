import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/services/crypto_topup_service.dart';
import 'package:ewallet/services/stripe_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/money_formatter.dart';
import 'package:ewallet/utils/wallet_support.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AddMoneyView extends StatefulWidget {
  const AddMoneyView({super.key});

  @override
  State<AddMoneyView> createState() => _AddMoneyViewState();
}

class _AddMoneyViewState extends State<AddMoneyView> {
  final TextEditingController _amountController = TextEditingController();
  final StripeService _stripeService = StripeService();
  final CryptoTopupService _cryptoTopupService = CryptoTopupService();
  bool _isProcessing = false;
  String? _pendingSessionId;
  bool _isCryptoProcessing = false;
  CryptoTopupSession? _cryptoSession;

  @override
  void initState() {
    super.initState();
    _restorePendingSession();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _restorePendingSession() async {
    final sessionId = Uri.base.queryParameters['session_id']?.trim() ?? '';
    if (sessionId.isNotEmpty) {
      await StripeService.savePendingSessionId(sessionId);
      if (mounted) {
        setState(() => _pendingSessionId = sessionId);
      }
      return;
    }

    final storedSessionId = await StripeService.getPendingSessionId();
    if (storedSessionId != null && mounted) {
      setState(() => _pendingSessionId = storedSessionId);
    }

    final pendingCryptoSession = await _cryptoTopupService.getPendingSession();
    if (pendingCryptoSession != null && mounted) {
      setState(() => _cryptoSession = pendingCryptoSession);
      await _confirmCryptoTopup(depositId: pendingCryptoSession.depositId, silent: true);
    }
  }

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
        Get.snackbar('error'.tr, 'stripe_backend_missing'.tr);
        return;
      }

      final walletId = await _getOrCreateWalletId();
      final session = await _stripeService.createCheckoutSession(
        amount: amount,
        currency: 'usd',
        email: email,
        walletId: walletId,
      );
      setState(() => _pendingSessionId = session.sessionId);
      await StripeService.savePendingSessionId(session.sessionId);
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

      if (result.credited ||
          result.message.toLowerCase().contains('already credited')) {
        await StripeService.clearPendingSessionId();
        setState(() => _pendingSessionId = null);
      }
      Get.snackbar(
        result.credited ? 'topup_success'.tr : 'topup_pending'.tr,
        result.credited ? 'wallet_credited_successfully'.tr : result.message,
      );
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

  Future<void> _startCryptoTopup() async {
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

    setState(() => _isCryptoProcessing = true);
    try {
      final walletId = await _getOrCreateWalletId();
      final session = await _cryptoTopupService.createCryptoTopup(
        amount: amount,
        email: email,
        walletId: walletId,
      );
      await _cryptoTopupService.savePendingSession(session);
      if (!mounted) return;
      setState(() => _cryptoSession = session);
      Get.snackbar('crypto_method'.tr, 'crypto_payment_created'.tr);
    } catch (e) {
      Get.snackbar(
        'topup_failed'.tr,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isCryptoProcessing = false);
      }
    }
  }

  Future<void> _confirmCryptoTopup({
    String? depositId,
    bool silent = false,
  }) async {
    final targetDepositId = depositId ?? _cryptoSession?.depositId;
    if (targetDepositId == null || targetDepositId.isEmpty) {
      if (!silent) {
        Get.snackbar('error'.tr, 'missing_crypto_deposit'.tr);
      }
      return;
    }

    setState(() => _isCryptoProcessing = true);
    try {
      final result = await _cryptoTopupService.confirmCryptoTopup(
        depositId: targetDepositId,
      );
      if (result.credited) {
        await _cryptoTopupService.clearPendingDepositId();
        if (!mounted) return;
        setState(() => _cryptoSession = null);
      }
      if (!silent) {
        Get.snackbar(
          result.credited ? 'topup_success'.tr : 'topup_pending'.tr,
          result.credited ? 'wallet_credited_successfully'.tr : result.message,
        );
      }
    } catch (e) {
      if (!silent) {
        Get.snackbar(
          'topup_failed'.tr,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCryptoProcessing = false);
      }
    }
  }

  Widget _methodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String fee,
    required String speed,
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
            '${'fee'.tr}: $fee',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '${'speed'.tr}: $speed',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 14),
          CustomButton(
            title: 'continue_text'.tr,
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
      appBar: customAppbar(context: context, title: 'add_money'.tr, arrorw: true),
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
                        'choose_add_money_method'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'add_money_intro'.tr,
                        style: TextStyle(
                          color: Colors.white.withAlpha(190),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      CustomField(
                        title: 'amount_to_add'.tr,
                        keybard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        controller: _amountController,
                        prefixIcon: Icons.attach_money_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _methodCard(
                  icon: Icons.credit_card_rounded,
                  title: 'card_method'.tr,
                  subtitle: 'card_method_subtitle'.tr,
                  fee: '5.5% + \$0.30',
                  speed: 'instant'.tr,
                  onTap: _isProcessing ? () {} : _openStripePaymentLink,
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
                          ontap: _isProcessing ? null : _confirmTopUp,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _methodCard(
                  icon: Icons.currency_bitcoin_rounded,
                  title: 'crypto_method'.tr,
                  subtitle: 'crypto_add_money_subtitle'.tr,
                  fee: '3%',
                  speed: 'instant'.tr,
                  color: Appcolor.secondary,
                  onTap: _isCryptoProcessing ? () {} : _startCryptoTopup,
                ),
                if (_cryptoSession != null) ...[
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'crypto_send_exact_title'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          '${'crypto_wallet_address'.tr}: ${_cryptoSession!.depositWalletAddress}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          '${'crypto_amount_to_send'.tr}: ${MoneyFormatter.fixed6(_cryptoSession!.amountToSend)} ${_cryptoSession!.tokenSymbol}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          '${'crypto_you_receive'.tr}: ${MoneyFormatter.fixed2(_cryptoSession!.netAmount)} USD',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          '${'crypto_network'.tr}: ${_cryptoSession!.blockchain}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'crypto_send_exact_body'.tr,
                          style: TextStyle(
                            color: Colors.white.withAlpha(190),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          title: _isCryptoProcessing
                              ? 'please_wait'.tr
                              : 'i_sent_crypto'.tr,
                          bgColor: Appcolor.secondary,
                          ontap: _isCryptoProcessing ? null : _confirmCryptoTopup,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _methodCard(
                  icon: Icons.support_agent_rounded,
                  title: 'wish_method'.tr,
                  subtitle: 'wish_add_money_subtitle'.tr,
                  fee: '3%',
                  speed: 'two_three_business_hours'.tr,
                  color: const Color(0xffE08A2E),
                  onTap: () => WalletSupport.openSupportContactDialog(
                    title: 'wish_method'.tr,
                    message: 'wish_add_money_contact'.tr,
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
