import 'dart:async';
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
import 'package:ewallet/utils/web_url_state.dart';
import 'package:ewallet/utils/wallet_support.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AddMoneyView extends StatefulWidget {
  const AddMoneyView({super.key});

  @override
  State<AddMoneyView> createState() => _AddMoneyViewState();
}

class _AddMoneyViewState extends State<AddMoneyView> {
  static const String _cardMethod = 'card';
  static const String _cryptoMethod = 'crypto';

  final TextEditingController _amountController = TextEditingController();
  final StripeService _stripeService = StripeService();
  final CryptoTopupService _cryptoTopupService = CryptoTopupService();
  bool _isProcessing = false;
  String? _pendingSessionId;
  bool _isCryptoProcessing = false;
  CryptoTopupSession? _cryptoSession;
  String? _selectedMethod;
  Timer? _stripePollTimer;
  Timer? _cryptoPollTimer;

  @override
  void initState() {
    super.initState();
    _restorePendingSession();
  }

  @override
  void dispose() {
    _stripePollTimer?.cancel();
    _cryptoPollTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _restorePendingSession() async {
    final sessionId =
        resolveWebUrlState().queryParameters['session_id']?.trim() ?? '';
    if (sessionId.isNotEmpty) {
      await StripeService.savePendingSessionId(sessionId);
      if (mounted) {
        setState(() {
          _pendingSessionId = sessionId;
          _selectedMethod = _cardMethod;
        });
      }
      return;
    }

    final storedSessionId = await StripeService.getPendingSessionId();
    if (storedSessionId != null && mounted) {
      setState(() => _pendingSessionId = storedSessionId);
      _startStripePolling();
    }

    final pendingCryptoSession = await _cryptoTopupService.getPendingSession();
    if (pendingCryptoSession != null && mounted) {
      setState(() => _cryptoSession = pendingCryptoSession);
      _startCryptoPolling();
      await _confirmCryptoTopup(depositId: pendingCryptoSession.depositId, silent: true);
    }
  }

  void _startStripePolling() {
    _stripePollTimer?.cancel();
    final sessionId = _pendingSessionId;
    if (sessionId == null || sessionId.isEmpty) return;

    _stripePollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!mounted || _pendingSessionId == null || _isProcessing) return;
      await _confirmTopUp(silent: true);
    });
  }

  void _stopStripePolling() {
    _stripePollTimer?.cancel();
    _stripePollTimer = null;
  }

  void _startCryptoPolling() {
    _cryptoPollTimer?.cancel();
    final depositId = _cryptoSession?.depositId;
    if (depositId == null || depositId.isEmpty) return;

    _cryptoPollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!mounted || _cryptoSession == null || _isCryptoProcessing) return;
      await _confirmCryptoTopup(silent: true);
    });
  }

  void _stopCryptoPolling() {
    _cryptoPollTimer?.cancel();
    _cryptoPollTimer = null;
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
      _startStripePolling();
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

  Future<void> _handleCardMethodTap() async {
    setState(() => _selectedMethod = _cardMethod);
    if (_pendingSessionId != null && _pendingSessionId!.isNotEmpty) {
      return;
    }
    await _openStripePaymentLink();
  }

  Future<void> _confirmTopUp({bool silent = false}) async {
    final sessionId = _pendingSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      if (!silent) {
        Get.snackbar('error'.tr, 'missing_session_id'.tr);
      }
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final result = await _stripeService.confirmTopUp(sessionId: sessionId);
      if (!result.success) {
        if (!silent) {
          Get.snackbar('topup_failed'.tr, result.message);
        }
        return;
      }

      if (result.credited ||
          result.message.toLowerCase().contains('already credited')) {
        await StripeService.clearPendingSessionId();
        _stopStripePolling();
        setState(() => _pendingSessionId = null);
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
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _startCryptoTopup() async {
    setState(() => _selectedMethod = _cryptoMethod);
    await _openCryptoRequestDialog();
  }

  Future<void> _copyText(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    Get.snackbar('success'.tr, message);
  }

  Future<void> _showCryptoInstructionsDialog(CryptoTopupSession session) async {
    await Get.dialog(
      AlertDialog(
        backgroundColor: Appcolor.background,
        title: Text(
          'crypto_send_exact_title'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'crypto_dialog_steps'.tr,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${'crypto_wallet_address'.tr}:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  session.depositWalletAddress,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                CustomButton(
                  title: 'copy_wallet_address'.tr,
                  bgColor: Appcolor.secondary,
                  ontap: () => _copyText(
                    session.depositWalletAddress,
                    'wallet_address_copied'.tr,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${'crypto_amount_to_send'.tr}:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  '${MoneyFormatter.fixed6(session.amountToSend)} ${session.tokenSymbol}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                CustomButton(
                  title: 'copy_crypto_amount'.tr,
                  bgColor: Appcolor.secondary,
                  ontap: () => _copyText(
                    MoneyFormatter.fixed6(session.amountToSend),
                    'crypto_amount_copied'.tr,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${'your_sending_wallet'.tr}: ${session.senderWalletAddress}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  '${'crypto_you_receive'.tr}: ${MoneyFormatter.fixed2(session.netAmount)} USD',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _openCryptoRequestDialog() async {
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

    final senderWalletController = TextEditingController(
      text: _cryptoSession?.senderWalletAddress ?? '',
    );

    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(18),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'crypto_method'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'crypto_request_intro'.tr,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomField(
                    title: 'your_sending_wallet'.tr,
                    controller: senderWalletController,
                    prefixIcon: Icons.account_balance_wallet_rounded,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${'amount_to_add'.tr}: ${MoneyFormatter.fixed2(amount)} USD',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'crypto_request_note'.tr,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isCryptoProcessing ? null : () => Get.back(),
                          child: Text('close'.tr),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          title: _isCryptoProcessing
                              ? 'please_wait'.tr
                              : 'create_crypto_request'.tr,
                          bgColor: Appcolor.secondary,
                          ontap: _isCryptoProcessing
                              ? null
                              : () async {
                                  final senderWalletAddress =
                                      senderWalletController.text.trim();
                                  if (senderWalletAddress.isEmpty) {
                                    Get.snackbar(
                                      'error'.tr,
                                      'sender_wallet_required'.tr,
                                    );
                                    return;
                                  }

                                  setDialogState(() {});
                                  setState(() => _isCryptoProcessing = true);
                                  try {
                                    final walletId = await _getOrCreateWalletId();
                                    final session =
                                        await _cryptoTopupService.createCryptoTopup(
                                      amount: amount,
                                      email: email,
                                      walletId: walletId,
                                      senderWalletAddress: senderWalletAddress,
                                    );
                                    await _cryptoTopupService
                                        .savePendingSession(session);
                                    if (!mounted) return;
                                    setState(() => _cryptoSession = session);
                                    _startCryptoPolling();
                                    Get.back();
                                    await _showCryptoInstructionsDialog(session);
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
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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
        _stopCryptoPolling();
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
                  onTap: _isProcessing ? () {} : _handleCardMethodTap,
                ),
                if (_selectedMethod == _cardMethod &&
                    StripeService.hasBackend &&
                    _pendingSessionId != null) ...[
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
                        'payment_auto_checking'.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Appcolor.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'payment_waiting_credit'.tr,
                              style: TextStyle(
                                color: Colors.white.withAlpha(190),
                              ),
                            ),
                          ),
                        ],
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
                if (_selectedMethod == _cryptoMethod &&
                    _cryptoSession != null) ...[
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
                          '${'your_sending_wallet'.tr}: ${_cryptoSession!.senderWalletAddress}',
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
                          '${'crypto_rate_applied'.tr}: ${MoneyFormatter.fixed2(_cryptoSession!.usdRate)}',
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
                        Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Appcolor.accent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'crypto_waiting_credit'.tr,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(190),
                                ),
                              ),
                            ),
                          ],
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
