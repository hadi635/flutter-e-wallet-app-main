import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/services/wallet_request_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/money_formatter.dart';
import 'package:ewallet/utils/wallet_support.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CashOutView extends StatefulWidget {
  const CashOutView({super.key});

  @override
  State<CashOutView> createState() => _CashOutViewState();
}

class _CashOutViewState extends State<CashOutView> {
  static const _cardMethod = 'card';
  static const _agentMethod = 'agent';
  static const _cryptoMethod = 'crypto';
  static const _wishMethod = 'wish';

  final _amountController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _agentPhoneController = TextEditingController();
  final _agentLocationController = TextEditingController();
  final _cryptoWalletController = TextEditingController();
  final _noteController = TextEditingController();
  final _requestService = WalletRequestService();

  String _selectedMethod = _cardMethod;
  bool _busy = false;
  String? _lastRequestId;

  double get _amount => MoneyFormatter.parseAmount(_amountController.text);

  String _methodLabel(String? method) {
    switch (method) {
      case _cardMethod:
        return 'request_method_card'.tr;
      case _agentMethod:
        return 'request_method_agent'.tr;
      case _cryptoMethod:
        return 'request_method_crypto'.tr;
      case _wishMethod:
        return 'request_method_wish'.tr;
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

  @override
  void dispose() {
    _amountController.dispose();
    _cardNameController.dispose();
    _agentPhoneController.dispose();
    _agentLocationController.dispose();
    _cryptoWalletController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(String method) async {
    if (_amount <= 0) {
      Get.snackbar('invalid_amount'.tr, 'enter_valid_amount'.tr);
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await _requestService.createCashOutRequest(
        method: method,
        amount: _amount,
        note: _noteController.text.trim(),
        contactPhone: _agentPhoneController.text.trim(),
        preferredLocation: _agentLocationController.text.trim(),
        walletAddress: _cryptoWalletController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _lastRequestId = result['requestId']?.toString());
      Get.snackbar('success'.tr, 'cashout_pending_saved'.tr);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;
    return Scaffold(
      appBar:
          customAppbar(context: context, title: 'cash_out'.tr, arrorw: true),
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
                    'cash_out_title_new'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'cash_out_overview'.tr,
                    style: TextStyle(
                      color: Colors.white.withAlpha(190),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomField(
                    title: 'withdraw_amount'.tr,
                    controller: _amountController,
                    keybard:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.attach_money_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _methodTile(
              method: _cardMethod,
              icon: Icons.credit_card_rounded,
              color: const Color(0xff5BC0EB),
              title: 'cashout_card_title'.tr,
              subtitle: 'cashout_card_subtitle'.tr,
              speed: 'cashout_card_speed'.tr,
            ),
            const SizedBox(height: 12),
            _methodTile(
              method: _agentMethod,
              icon: Icons.storefront_rounded,
              color: Appcolor.secondary,
              title: 'cashout_agent_title'.tr,
              subtitle: 'cashout_agent_subtitle'.tr,
              speed: 'cashout_agent_speed'.tr,
            ),
            const SizedBox(height: 12),
            _methodTile(
              method: _cryptoMethod,
              icon: Icons.currency_bitcoin_rounded,
              color: const Color(0xff66BB6A),
              title: 'cashout_crypto_title'.tr,
              subtitle: 'cashout_crypto_subtitle'.tr,
              speed: 'cashout_crypto_speed'.tr,
            ),
            const SizedBox(height: 12),
            _methodTile(
              method: _wishMethod,
              icon: Icons.phone_rounded,
              color: const Color(0xffE08A2E),
              title: 'cashout_wish_title'.tr,
              subtitle: 'cashout_wish_subtitle'.tr,
              speed: 'cashout_wish_speed'.tr,
            ),
            const SizedBox(height: 16),
            if (_selectedMethod == _cardMethod) _cardPanel(),
            if (_selectedMethod == _agentMethod) _agentPanel(),
            if (_selectedMethod == _cryptoMethod) _cryptoPanel(),
            if (_selectedMethod == _wishMethod) _wishPanel(),
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
                    .where('kind', isEqualTo: 'cash_out')
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
                          'recent_cashout_requests'.tr,
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
                                    '${_methodLabel(data['method']?.toString())} • ${_statusLabel(data['status']?.toString())}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Text(
                                  '\$${MoneyFormatter.fixed2(data['requestedAmount'] ?? 0)}',
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Appcolor.glassBorder),
                    ),
                    child: Text(
                      '${'speed'.tr}: $speed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

  Widget _cardPanel() {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cashout_card_panel_title'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'cashout_card_panel_body'.tr,
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          CustomField(
            title: 'card_holder_name'.tr,
            controller: _cardNameController,
          ),
          const SizedBox(height: 12),
          CustomField(
            title: 'payment_note'.tr,
            controller: _noteController,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          CustomButton(
            title: _busy ? 'please_wait'.tr : 'save_pending_card_withdrawal'.tr,
            bgColor: const Color(0xff5BC0EB),
            ontap: _busy ? null : () => _submit(_cardMethod),
          ),
        ],
      ),
    );
  }

  Widget _agentPanel() {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cashout_agent_panel_title'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'cashout_agent_panel_body'.tr,
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          CustomField(
            title: 'contact_phone'.tr,
            controller: _agentPhoneController,
          ),
          const SizedBox(height: 12),
          CustomField(
            title: 'preferred_location'.tr,
            controller: _agentLocationController,
          ),
          const SizedBox(height: 12),
          CustomField(
            title: 'payment_note'.tr,
            controller: _noteController,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          CustomButton(
            title: _busy ? 'please_wait'.tr : 'save_pending_agent_cashout'.tr,
            bgColor: Appcolor.secondary,
            ontap: _busy ? null : () => _submit(_agentMethod),
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
            'cashout_crypto_panel_title'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'cashout_crypto_panel_body'.tr,
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          CustomField(
            title: 'wallet_address_field'.tr,
            controller: _cryptoWalletController,
          ),
          const SizedBox(height: 12),
          CustomField(
            title: 'payment_note'.tr,
            controller: _noteController,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          CustomButton(
            title: _busy ? 'please_wait'.tr : 'save_pending_crypto_cashout'.tr,
            bgColor: const Color(0xff66BB6A),
            ontap: _busy ? null : () => _submit(_cryptoMethod),
          ),
        ],
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
            'cashout_wish_panel_title'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'cashout_wish_panel_body'.trParams(
              {'number': WalletSupport.contactNumber},
            ),
            style: TextStyle(
              color: Colors.white.withAlpha(190),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          CustomButton(
            title: 'contact_wish_support'.tr,
            bgColor: const Color(0xffE08A2E),
            ontap: () => WalletSupport.openSupportContactDialog(
              title: 'cashout_wish_title'.tr,
              message: 'cashout_wish_contact_message'.tr,
            ),
          ),
        ],
      ),
    );
  }
}
