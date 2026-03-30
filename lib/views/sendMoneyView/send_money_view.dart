import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/services/wallet_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/views/successView/success_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SendMoneyView extends StatefulWidget {
  const SendMoneyView({super.key});

  @override
  State<SendMoneyView> createState() => _SendMoneyViewState();
}

class _SendMoneyViewState extends State<SendMoneyView> {
  final TextEditingController walletIdController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final WalletService _walletService = WalletService();
  bool _isSending = false;

  @override
  void dispose() {
    walletIdController.dispose();
    amountController.dispose();
    super.dispose();
  }

  String _sanitizeWalletIdFromQr(String raw) {
    final data = raw.trim();
    final lower = data.toLowerCase();
    if (lower.startsWith('upay://wallet/')) {
      return data.substring('upay://wallet/'.length).trim();
    }

    final uri = Uri.tryParse(data);
    if (uri != null &&
        uri.scheme.toLowerCase() == 'upay' &&
        uri.host.toLowerCase() == 'wallet') {
      final pathValue = uri.path.replaceFirst('/', '').trim();
      if (pathValue.isNotEmpty) {
        return pathValue;
      }
    }

    return data;
  }

  Future<void> _scanQr() async {
    final scanned = await Get.to<String>(() => const WalletQrScannerView());
    if (scanned == null || scanned.trim().isEmpty) {
      return;
    }

    final walletId = _sanitizeWalletIdFromQr(scanned);
    setState(() {
      walletIdController.text = walletId;
    });
  }

  Future<void> _transferMoney() async {
    final amount = int.tryParse(amountController.text);
    final receiverWalletId = walletIdController.text.trim();

    if (amount == null || amount <= 0) {
      Get.snackbar('invalid_amount'.tr, 'enter_valid_amount'.tr);
      return;
    }

    if (receiverWalletId.isEmpty) {
      Get.snackbar('error'.tr, 'wallet_id_or_qr'.tr);
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final result = await _walletService.transfer(
        receiverWalletId: receiverWalletId,
        amount: amount,
      );

      Get.offAll(
        () => SuccessView(
          amountSend: amount,
          receiverWalletId: result['receiverWalletId']?.toString() ?? '',
        ),
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar('transfer_failed'.tr, message.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: customAppbar(
        context: context,
        arrorw: true,
        title: 'send_money'.tr,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('user')
                    .doc(user?.email)
                    .snapshots(),
                builder: (context, snapshot) {
                  final availableBalance =
                      snapshot.data?.data()?['Balance'] ?? 0;
                  final senderWalletId =
                      snapshot.data?.data()?['WalletId']?.toString() ?? '';

                  return GlassContainer(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        CustomField(
                          title: 'wallet_id_or_qr'.tr,
                          controller: walletIdController,
                          prefixIcon: Icons.qr_code_rounded,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                title: 'scan_qr'.tr,
                                bgColor: Appcolor.secondary,
                                ontap: _scanQr,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        CustomField(
                          title: 'enter_amount'.tr,
                          prefixIcon: Icons.attach_money_outlined,
                          keybard: TextInputType.number,
                          controller: amountController,
                          focusColor: Appcolor.secondary,
                          borderColor: Appcolor.secondary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${'wallet_id'.tr}: $senderWalletId',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${'available_balance'.tr}: $availableBalance',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              CustomButton(
                title: _isSending ? 'sending'.tr : 'send'.tr,
                bgColor: Appcolor.secondary,
                ontap: _isSending ? null : _transferMoney,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WalletQrScannerView extends StatefulWidget {
  const WalletQrScannerView({super.key});

  @override
  State<WalletQrScannerView> createState() => _WalletQrScannerViewState();
}

class _WalletQrScannerViewState extends State<WalletQrScannerView> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppbar(
        context: context,
        arrorw: true,
        title: 'scan_qr'.tr,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final value = barcodes.first.rawValue;
              if (value == null || value.trim().isEmpty) {
                return;
              }

              _handled = true;
              Get.back(result: value);
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'camera_scan_hint'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
