import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/services/crypto_topup_service.dart';
import 'package:ewallet/services/moonpay_service.dart';
import 'package:ewallet/services/stripe_service.dart';
import 'package:ewallet/services/wallet_request_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/money_formatter.dart';
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
  static const _wishMethod = 'wish';
  static const _cryptoMethod = 'crypto';
  static const _cardMethod = 'card';
  static const _stripeProvider = 'stripe';
  static const _moonPayProvider = 'moonpay';

  final _amountController = TextEditingController();
  final _wishSenderNameController = TextEditingController();
  final _wishSenderPhoneController = TextEditingController();
  final _wishReferenceController = TextEditingController();
  final _noteController = TextEditingController();
  final _requestService = WalletRequestService();
  final _cryptoTopupService = CryptoTopupService();
  final _stripeService = StripeService();
  final _moonPayService = MoonPayService();

  String _selectedMethod = _wishMethod;
  String _selectedCardProvider = _stripeProvider;
  bool _wishFirstFree = true;
  bool _busyWish = false;
  bool _busyCard = false;
  bool _busyCrypto = false;
  String? _lastRequestId;
  String _country = '';
  CryptoTopupSession? _cryptoSession;
  Timer? _cryptoPollTimer;

  @override
  void initState() {
    super.initState();
    _loadOfferState();
    _restoreCryptoSession();
  }

  @override
  void dispose() {
    _cryptoPollTimer?.cancel();
    _amountController.dispose();
    _wishSenderNameController.dispose();
    _wishSenderPhoneController.dispose();
    _wishReferenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => MoneyFormatter.parseAmount(_amountController.text);
  double get _wishFee => _wishFirstFree ? 0 : _money(_amount * 0.01);
  double get _cardFee => _money((_amount * 0.055) + 0.30);
  double _money(num value) => (value * 100).roundToDouble() / 100;

  String _methodLabel(String? method) {
    switch (method) {
      case _wishMethod:
        return 'request_method_wish'.tr;
      case _cardMethod:
        return 'request_method_card'.tr;
      case _cryptoMethod:
        return 'request_method_crypto'.tr;
      default:
        return method ?? 'unknown'.tr;
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

  Future<void> _loadOfferState() async {
    try {
      final snap = await _requestService.currentUserSnapshot();
      final data = snap.data() ?? {};
      if (!mounted) return;
      setState(() {
        _wishFirstFree =
            ((data['WishAddMoneyCompletedCount'] as num?)?.toInt() ?? 0) == 0;
        _country = (data['Country'] ?? '').toString().trim();
      });
      if (data['WishPromoSeen'] != true) {
        await FirebaseFirestore.instance.collection('user').doc(snap.id).set({
          'WishPromoSeen': true,
        }, SetOptions(merge: true));
        if (!mounted) return;
        _showWishPromo();
      }
    } catch (_) {}
  }

  Future<void> _showWishPromo() async {
    await Get.dialog(
      AlertDialog(
        backgroundColor: Appcolor.background,
        title: Text(
          'wish_promo_title'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'wish_promo_body'.tr,
          style: TextStyle(color: Colors.white.withAlpha(190), height: 1.5),
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

  Future<void> _restoreCryptoSession() async {
    final pending = await _cryptoTopupService.getPendingSession();
    if (pending == null || !mounted) return;
    setState(() => _cryptoSession = pending);
    _startCryptoPolling();
  }

  void _startCryptoPolling() {
    _cryptoPollTimer?.cancel();
    _cryptoPollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (_busyCrypto || _cryptoSession == null || !mounted) return;
      await _confirmCrypto(silent: true);
    });
  }

  Future<String?> _ensureWalletId() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return null;
    final ref = FirebaseFirestore.instance.collection('user').doc(email);
    final snap = await ref.get();
    final current = snap.data()?['WalletId']?.toString().trim() ?? '';
    if (current.isNotEmpty) return current;
    final walletId =
        'W${List.generate(10, (_) => Random().nextInt(10)).join()}';
    await ref.set({'WalletId': walletId}, SetOptions(merge: true));
    return walletId;
  }

  Future<void> _submitWish() async {
    if (_amount <= 0) {
      Get.snackbar('invalid_amount'.tr, 'enter_valid_amount'.tr);
      return;
    }
    setState(() => _busyWish = true);
    try {
      final result = await _requestService.createAddMoneyRequest(
        method: _wishMethod,
        amount: _amount,
        senderName: _wishSenderNameController.text.trim(),
        senderPhone: _wishSenderPhoneController.text.trim(),
        paymentReference: _wishReferenceController.text.trim(),
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _lastRequestId = result['requestId']?.toString());
      Get.snackbar('topup_pending'.tr, 'wish_pending_saved'.tr);
    } catch (e) {
      Get.snackbar(
        'topup_failed'.tr,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _busyWish = false);
    }
  }

  Future<void> _submitCard() async {
    if (_selectedCardProvider == _moonPayProvider) {
      await _submitMoonPay();
      return;
    }

    if (_amount <= 0) {
      Get.snackbar('invalid_amount'.tr, 'enter_valid_amount'.tr);
      return;
    }
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      Get.snackbar('auth_error'.tr, 'please_login_again'.tr);
      return;
    }
    setState(() => _busyCard = true);
    try {
      final walletId = await _ensureWalletId();
      final result = await _stripeService.createCheckoutSession(
        amount: _amount,
        currency: 'usd',
        email: email,
        walletId: walletId,
      );
      await StripeService.savePendingSessionId(result.sessionId);
      final launched = await launchUrl(Uri.parse(result.checkoutUrl));
      if (!launched) {
        throw Exception('Unable to open Stripe checkout.');
      }
      if (!mounted) return;
      Get.snackbar('topup_pending'.tr, 'payment_auto_checking'.tr);
    } catch (e) {
      Get.snackbar(
        'topup_failed'.tr,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _busyCard = false);
    }
  }

  Future<void> _submitMoonPay() async {
    if (_amount <= 0) {
      Get.snackbar('invalid_amount'.tr, 'enter_valid_amount'.tr);
      return;
    }

    if (_country.isEmpty) {
      Get.snackbar('topup_failed'.tr, 'moonpay_country_required'.tr);
      return;
    }

    if (!_moonPayService.isCountrySupported(_country)) {
      Get.snackbar('topup_failed'.tr, 'moonpay_country_not_supported'.tr);
      return;
    }

    setState(() => _busyCard = true);
    try {
      final uri = _moonPayService.buildBuyUri(amount: _amount);
      final launched = await launchUrl(uri);
      if (!launched) {
        throw Exception('Unable to open MoonPay.');
      }
      if (!mounted) return;
      Get.snackbar('topup_pending'.tr, 'moonpay_opened'.tr);
    } catch (e) {
      Get.snackbar(
        'topup_failed'.tr,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _busyCard = false);
    }
  }

  Future<void> _startCrypto() async {
    if (_amount <= 0) {
      Get.snackbar('invalid_amount'.tr, 'enter_valid_amount'.tr);
      return;
    }
    final email = FirebaseAuth.instance.currentUser?.email;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'crypto_request_intro'.tr,
                style: const TextStyle(color: Colors.white, height: 1.5),
              ),
              const SizedBox(height: 12),
              CustomField(
                title: 'your_sending_wallet'.tr,
                controller: senderWalletController,
                prefixIcon: Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(height: 14),
              CustomButton(
                title:
                    _busyCrypto ? 'please_wait'.tr : 'create_crypto_request'.tr,
                bgColor: Appcolor.secondary,
                ontap: _busyCrypto
                    ? null
                    : () async {
                        if (senderWalletController.text.trim().isEmpty) {
                          Get.snackbar('error'.tr, 'sender_wallet_required'.tr);
                          return;
                        }
                        setState(() => _busyCrypto = true);
                        try {
                          final walletId = await _ensureWalletId();
                          final session =
                              await _cryptoTopupService.createCryptoTopup(
                            amount: _amount,
                            email: email,
                            walletId: walletId,
                            senderWalletAddress:
                                senderWalletController.text.trim(),
                          );
                          await _cryptoTopupService.savePendingSession(session);
                          if (!mounted) return;
                          setState(() => _cryptoSession = session);
                          _startCryptoPolling();
                          Get.back();
                        } catch (e) {
                          Get.snackbar(
                            'topup_failed'.tr,
                            e.toString().replaceFirst('Exception: ', ''),
                          );
                        } finally {
                          if (mounted) setState(() => _busyCrypto = false);
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCrypto({bool silent = false}) async {
    final depositId = _cryptoSession?.depositId;
    if (depositId == null || depositId.isEmpty) return;
    setState(() => _busyCrypto = true);
    try {
      final result =
          await _cryptoTopupService.confirmCryptoTopup(depositId: depositId);
      if (result.credited) {
        await _cryptoTopupService.clearPendingDepositId();
        _cryptoPollTimer?.cancel();
        if (mounted) setState(() => _cryptoSession = null);
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
      if (mounted) setState(() => _busyCrypto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;
    return Scaffold(
      appBar:
          customAppbar(context: context, title: 'add_money'.tr, arrorw: true),
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'choose_add_money_method'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'add_money_overview'.tr,
                    style: TextStyle(
                      color: Colors.white.withAlpha(190),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomField(
                    title: 'amount_to_add'.tr,
                    keybard:
                        const TextInputType.numberWithOptions(decimal: true),
                    controller: _amountController,
                    prefixIcon: Icons.attach_money_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _methodTile(
              method: _wishMethod,
              icon: Icons.phone_iphone_rounded,
              color: const Color(0xffE08A2E),
              title: 'wish_method_title'.tr,
              subtitle: _wishFirstFree
                  ? 'wish_method_subtitle_free'.tr
                  : 'wish_method_subtitle_paid'.tr,
              fee: _wishFirstFree ? 'wish_fee_free'.tr : 'wish_fee_paid'.tr,
              speed: 'wish_speed'.tr,
            ),
            const SizedBox(height: 12),
            _methodTile(
              method: _cryptoMethod,
              icon: Icons.currency_bitcoin_rounded,
              color: Appcolor.secondary,
              title: 'crypto_method_title'.tr,
              subtitle: 'crypto_method_subtitle_new'.tr,
              fee: 'crypto_fee_value'.tr,
              speed: 'crypto_speed_value'.tr,
            ),
            const SizedBox(height: 12),
            _methodTile(
              method: _cardMethod,
              icon: Icons.credit_card_rounded,
              color: const Color(0xff5BC0EB),
              title: 'card_method_title_new'.tr,
              subtitle: 'card_method_subtitle_new'.tr,
              fee: 'card_fee_value'.tr,
              speed: 'card_speed_value'.tr,
            ),
            const SizedBox(height: 16),
            if (_selectedMethod == _wishMethod) _wishPanel(),
            if (_selectedMethod == _cryptoMethod) _cryptoPanel(),
            if (_selectedMethod == _cardMethod) _cardPanel(),
            if (_lastRequestId != null) ...[
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${'pending_request_saved'.tr}: $_lastRequestId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (email != null) ...[
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection(WalletRequestService.requestsCollection)
                    .where('email', isEqualTo: email)
                    .where('kind', isEqualTo: 'add_money')
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return const SizedBox.shrink();
                  return GlassContainer(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'recent_add_money_requests'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...docs.take(5).map((doc) {
                          final data = doc.data();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_methodLabel(data['method']?.toString())} - ${_statusLabel(data['status']?.toString())}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Text(
                                  '\$${MoneyFormatter.fixed2(data['netAmount'] ?? 0)}',
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
          ],
        ),
      ),
    );
  }

  Widget _methodTile({
    required String method,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String fee,
    required String speed,
  }) {
    final selected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(22) : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? color : Appcolor.glassBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip('fee'.tr, fee),
                      _infoChip('speed'.tr, speed),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? color : Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _wishPanel() {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'wish_pending_title'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'wish_pending_body'
                .trParams({'number': WalletSupport.contactNumber}),
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _summaryRow(
              'requested_amount'.tr, '\$${MoneyFormatter.fixed2(_amount)}'),
          _summaryRow('fee'.tr, '\$${MoneyFormatter.fixed2(_wishFee)}'),
          _summaryRow(
            'wallet_credit_label'.tr,
            '\$${MoneyFormatter.fixed2(max(0, _amount - _wishFee))}',
          ),
          const SizedBox(height: 14),
          CustomField(
            title: 'sender_full_name'.tr,
            controller: _wishSenderNameController,
          ),
          const SizedBox(height: 12),
          CustomField(
            title: 'sender_phone'.tr,
            controller: _wishSenderPhoneController,
          ),
          const SizedBox(height: 12),
          CustomField(
            title: 'wish_transfer_reference'.tr,
            controller: _wishReferenceController,
          ),
          const SizedBox(height: 12),
          CustomField(
            title: 'payment_note'.tr,
            controller: _noteController,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          CustomButton(
            title: _busyWish ? 'please_wait'.tr : 'save_pending_request'.tr,
            bgColor: const Color(0xffE08A2E),
            ontap: _busyWish ? null : _submitWish,
          ),
        ],
      ),
    );
  }

  Widget _cryptoPanel() {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'crypto_panel_title'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'crypto_panel_body'.tr,
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          CustomButton(
            title: _busyCrypto ? 'please_wait'.tr : 'create_crypto_request'.tr,
            bgColor: Appcolor.secondary,
            ontap: _busyCrypto ? null : _startCrypto,
          ),
          if (_cryptoSession != null) ...[
            const SizedBox(height: 14),
            SelectableText(
              '${'crypto_wallet_address'.tr}: ${_cryptoSession!.depositWalletAddress}\n'
              '${'crypto_amount_to_send'.tr}: ${MoneyFormatter.fixed6(_cryptoSession!.amountToSend)} ${_cryptoSession!.tokenSymbol}\n'
              '${'crypto_you_receive'.tr}: ${MoneyFormatter.fixed2(_cryptoSession!.netAmount)} USD',
              style: const TextStyle(color: Colors.white, height: 1.6),
            ),
            const SizedBox(height: 12),
            CustomButton(
              title: 'copy_wallet_address'.tr,
              bgColor: Appcolor.secondary,
              ontap: () => Clipboard.setData(
                ClipboardData(text: _cryptoSession!.depositWalletAddress),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardPanel() {
    final moonPayAvailable = _moonPayService.isCountrySupported(_country);
    final usingMoonPay = _selectedCardProvider == _moonPayProvider;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'card_pending_title'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'card_pending_body'.tr,
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _providerTile(
                  provider: _stripeProvider,
                  title: 'card_provider_stripe'.tr,
                  subtitle: 'card_provider_stripe_body'.tr,
                  color: const Color(0xff5BC0EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _providerTile(
                  provider: _moonPayProvider,
                  title: 'card_provider_moonpay'.tr,
                  subtitle: moonPayAvailable
                      ? 'card_provider_moonpay_body'.tr
                      : 'moonpay_country_unavailable_short'.tr,
                  color: const Color(0xffF4B860),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _summaryRow(
            'requested_amount'.tr,
            '\$${MoneyFormatter.fixed2(_amount)}',
          ),
          if (!usingMoonPay) ...[
            _summaryRow('fee'.tr, '\$${MoneyFormatter.fixed2(_cardFee)}'),
            _summaryRow(
              'wallet_credit_label'.tr,
              '\$${MoneyFormatter.fixed2(max(0, _amount - _cardFee))}',
            ),
          ] else ...[
            _summaryRow('availability'.tr, _country.isEmpty ? '-' : _country),
            _summaryRow(
              'payment_note'.tr,
              moonPayAvailable
                  ? 'moonpay_supported_country'.tr
                  : 'moonpay_country_not_supported'.tr,
            ),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Appcolor.glassBorder),
            ),
            child: Text(
              usingMoonPay
                  ? 'moonpay_panel_body'.tr
                  : 'card_pending_body'.tr,
              style: TextStyle(
                color: Colors.white.withAlpha(190),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          CustomButton(
            title: _busyCard
                ? 'please_wait'.tr
                : (usingMoonPay ? 'go_moonpay'.tr : 'go_stripe'.tr),
            bgColor: usingMoonPay
                ? const Color(0xffF4B860)
                : const Color(0xff5BC0EB),
            ontap: _busyCard
                ? null
                : (usingMoonPay && !moonPayAvailable ? null : _submitCard),
          ),
        ],
      ),
    );
  }

  Widget _providerTile({
    required String provider,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final selected = _selectedCardProvider == provider;

    return InkWell(
      onTap: () => setState(() => _selectedCardProvider = provider),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(24) : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : Appcolor.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? color : Colors.white54,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withAlpha(190)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Appcolor.glassBorder),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
