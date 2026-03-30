import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/custom_button.dart';
import 'package:ewallet/globals/custom_field.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/services/wallet_service.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:ewallet/utils/money_formatter.dart';
import 'package:ewallet/views/successView/success_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AmountView extends StatefulWidget {
  final String amoutViewTitle;
  final Map<String, dynamic>? receiverData;
  final Map<String, dynamic>? senderData;

  const AmountView({
    super.key,
    this.receiverData,
    this.senderData,
    required this.amoutViewTitle,
  });

  @override
  State<AmountView> createState() => _AmountViewState();
}

class _AmountViewState extends State<AmountView> {
  final TextEditingController amountController = TextEditingController();
  final WalletService _walletService = WalletService();
  bool _isSending = false;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<void> _transferMoney() async {
    final amount = MoneyFormatter.parseAmount(amountController.text);
    if (amount <= 0) {
      Get.snackbar("Invalid Amount", "Enter a valid amount greater than 0");
      return;
    }

    final receiverWalletId = widget.receiverData?["WalletId"] as String?;
    if (receiverWalletId == null || receiverWalletId.isEmpty) {
      Get.snackbar("Error", "Receiver data is invalid");
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _walletService.transfer(
        receiverWalletId: receiverWalletId,
        amount: amount,
      );

      Get.offAll(
        () => SuccessView(
          amountSend: amount,
          receiverWalletId: receiverWalletId,
        ),
      );
    } catch (e) {
      Get.snackbar(
          "Transfer Failed", e.toString().replaceFirst("Exception: ", ""));
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
    final availableBalance = widget.senderData?["Balance"] ?? 0;
    final receiverWalletId = widget.receiverData?["WalletId"]?.toString() ?? "";
    final receiverInitial =
        receiverWalletId.isNotEmpty ? receiverWalletId[0] : "?";

    return Scaffold(
      appBar: customAppbar(
        context: context,
        arrorw: true,
        title: widget.amoutViewTitle,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "To: ",
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      leading: CircleAvatar(
                        radius: 25,
                        child: Text(receiverInitial),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.receiverData?["Full Name"] ?? "",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            receiverWalletId,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15.00),
                    CustomField(
                      title: "Enter Amount",
                      prefixIcon: Icons.attach_money_outlined,
                      keybard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      controller: amountController,
                      focusColor: Appcolor.secondary,
                      borderColor: Appcolor.secondary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Available Balance: \$${MoneyFormatter.fixed2(availableBalance)}",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    )
                  ],
                ),
              ),
              CustomButton(
                title: _isSending ? "Sending..." : "Send",
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
