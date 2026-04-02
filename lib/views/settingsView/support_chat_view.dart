import 'package:ewallet/globals/custom_appbar.dart';
import 'package:ewallet/globals/glass_container.dart';
import 'package:ewallet/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SupportChatView extends StatefulWidget {
  const SupportChatView({super.key});

  @override
  State<SupportChatView> createState() => _SupportChatViewState();
}

class _SupportChatViewState extends State<SupportChatView> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Hello. I am Infinity support. Ask about add money, cash out, fees, wallet ID, or profile security.',
      isUser: false,
    ),
  ];

  final List<String> _faqPrompts = const [
    'How do I add money?',
    'How do I cash out?',
    'What are the fees?',
    'Is my data secure?',
    'How do wallet transfers work?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendPrompt([String? preset]) {
    final input = (preset ?? _controller.text).trim();
    if (input.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: input, isUser: true));
      _messages.add(_ChatMessage(text: _buildReply(input), isUser: false));
      _controller.clear();
    });
  }

  String _buildReply(String input) {
    final q = input.toLowerCase();

    if (q.contains('add') || q.contains('top') || q.contains('deposit')) {
      return 'Use Add Money to fund the wallet by card, crypto, or Wish Money / TapTap Send. Card payments open Stripe instantly. Crypto uses Solana USDC deposit instructions and credits the wallet after the payment arrives. Wish Money / TapTap Send is handled by a third party and usually takes 2 to 3 business hours.';
    }
    if (q.contains('cash') || q.contains('withdraw')) {
      return 'Cash out is available through our agents, crypto, and Wish Money. Agent and Wish Money cash out are handled by third parties through the support number shown in the app. Crypto cash out is kept ready for the next task.';
    }
    if (q.contains('fee') || q.contains('cost') || q.contains('charge')) {
      return 'Wallet to wallet transfers have no fee. Cash out has no app fee. Add money fees are 3% for Wish Money, 3% for crypto, and 5.5% plus \$0.30 for card, Visa, Mastercard, and Apple Pay.';
    }
    if (q.contains('secure') ||
        q.contains('privacy') ||
        q.contains('safe') ||
        q.contains('data')) {
      return 'Your account data is stored for wallet operations, identity details, transaction activity, and account protection. The policy in signup and profile explains that the wallet balance remains stable and available for cash out, with local cash-out fulfillment handled by third parties under country rules.';
    }
    if (q.contains('wallet') || q.contains('transfer') || q.contains('send')) {
      return 'You can send balance directly by wallet ID inside the app. Wallet-to-wallet transfers are fee-free, and the wallet page also gives you your wallet ID and QR code for receiving money.';
    }
    if (q.contains('profile') || q.contains('signup') || q.contains('sign up')) {
      return 'Signup and profile editing collect name, date of birth, email, password, image, and average monthly transactions. Users must be at least 18 years old before continuing.';
    }

    return 'I can help with add money, cash out, fees, wallet transfers, signup, profile details, and privacy information. Try one of the FAQ buttons or ask a short question.';
  }

  Widget _bubble(_ChatMessage message) {
    final align =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isUser
        ? Appcolor.primary.withAlpha(180)
        : Colors.white.withAlpha(18);

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Appcolor.glassBorder),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white, height: 1.45),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppbar(context: context, title: 'support_chat'.tr, arrorw: true),
      body: Container(
        decoration: const BoxDecoration(gradient: Appcolor.appGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _faqPrompts
                      .map(
                        (prompt) => ActionChip(
                          backgroundColor: Colors.white.withAlpha(20),
                          side: const BorderSide(color: Appcolor.glassBorder),
                          label: Text(
                            prompt,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onPressed: () => _sendPrompt(prompt),
                        ),
                      )
                      .toList(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(14),
                    child: ListView(
                      children: _messages.map(_bubble).toList(),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: GlassContainer(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'ask_support_hint'.tr,
                            hintStyle: TextStyle(
                              color: Colors.white.withAlpha(150),
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendPrompt(),
                        ),
                      ),
                      IconButton(
                        onPressed: _sendPrompt,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Appcolor.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({
    required this.text,
    required this.isUser,
  });
}
