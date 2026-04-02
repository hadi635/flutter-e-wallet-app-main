import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTranslations extends Translations {
  static const Map<String, String> _english = {
    'app_name': 'Infinity E-wallet',
    'login': 'Login',
    'create_account': 'Create Account',
    'create_new_account': 'Create New Account',
    'already_have_account': 'Already Have an Account?',
    'email_address': 'Email Address',
    'password': 'Password',
    're_enter_password': 'Re-enter Password',
    'fields_cant_be_empty': "Fields can't be empty",
    'passwords_do_not_match': 'Passwords do not match',
    'welcome_subtitle':
        'Send money using wallet ID and QR, and top up your wallet securely.',
    'home': 'Home',
    'wallet': 'Wallet',
    'settings': 'Settings',
    'hello': 'Hello',
    'available_balance': 'Available Balance',
    'send_money': 'Send Money',
    'cash_out': 'Cash Out',
    'recent_activity': 'Recent Activity',
    'see_all': 'See All',
    'no_transactions_yet': 'No transactions yet',
    'activity': 'Activity',
    'to_wallet_id': 'To Wallet ID',
    'wallet_id': 'Wallet ID',
    'wallet_id_or_qr': 'Wallet ID / QR',
    'scan_qr': 'Scan QR',
    'open_scanner': 'Open Scanner',
    'generate_qr': 'Generate QR',
    'receive_money': 'Receive Money',
    'receive_by_qr': 'Receive By QR',
    'show_my_qr': 'Show My QR',
    'enter_amount': 'Enter Amount',
    'amount_to_add': 'Amount to add',
    'send': 'Send',
    'sending': 'Sending...',
    'invalid_amount': 'Invalid Amount',
    'enter_valid_amount': 'Enter a valid amount greater than 0',
    'transfer_failed': 'Transfer Failed',
    'success': 'Success',
    'done': 'Done',
    'sent_to_wallet': 'Sent to wallet ID',
    'from_your_wallet': 'from your wallet.',
    'complete_setup': 'Complete Setup',
    'enter_full_name': 'Enter Your Full Name',
    'enter_nid_name': 'Enter Your NID Name',
    'enter_phone_number': 'Enter Your Phone Number',
    'save_details': 'Save Details',
    'search_by_wallet_id': 'Search by Wallet ID...',
    'user_not_found': 'Wallet not found',
    'logout': 'Logout',
    'logout_success': 'Successfully Logout',
    'policy_privacy': 'Policy & Privacy',
    'history': 'History',
    'profile': 'Profile',
    'language': 'Language',
    'english': 'English',
    'arabic': 'Arabic',
    'cash_out_help': 'Cash out support number',
    'contact_cash_out': 'Contact Cash Out',
    'wallet_card': 'INFINITY E-WALLET CARD',
    'card_details': 'Card details',
    'please_wait': 'Please wait...',
    'go_stripe': 'Go to Stripe Checkout',
    'missing_payment_link':
        'Missing STRIPE_PAYMENT_LINK. Add --dart-define=STRIPE_PAYMENT_LINK=https://buy.stripe.com/...',
    'payment_opened_manual_credit':
        'Payment page opened. Wallet credit is manual in this mode.',
    'payment_opened_return_confirm':
        'Payment page opened. After payment, return and tap Confirm Top-up.',
    'payment_link_label': 'Stripe Payment Link',
    'confirm_topup': 'Confirm Top-up',
    'missing_session_id': 'Missing checkout session id',
    'pay_add_money': 'Pay & Add Money',
    'security_note':
        'Security note: Stripe keys never go in app code except publishable key. Payment and balance credit are verified by backend.',
    'backend': 'Backend',
    'not_configured': 'Not configured',
    'privacy_content':
        'Your data is used only for wallet operations, transaction history, and account security.',
    'error': 'Error',
    'congratulations': 'Congratulations!',
    'signup_success': 'Successfully Sign Up',
    'login_success': 'Successfully Login',
    'weak_password': 'The password provided is too weak.',
    'email_used': 'The account already exists for that email.',
    'account_creation_failed': 'Account Creation Failed',
    'login_failed': 'Login Failed',
    'user_not_found_email': 'No user found for that email.',
    'wrong_password': 'Wrong password provided for that user.',
    'auth_error': 'Auth Error',
    'please_login_again': 'Please log in again.',
    'card_required': 'Card Required',
    'complete_card_details': 'Please complete card details.',
    'topup': 'Top-up',
    'topup_success': 'Top-up Success',
    'wallet_credited_new_balance': 'Wallet credited. New balance:',
    'wallet_credited_successfully': 'Wallet credited successfully.',
    'topup_pending': 'Top-up Pending',
    'topup_failed': 'Top-up Failed',
    'web_stripe_note':
        'Web uses Stripe-hosted checkout page for secure card entry.',
    'unknown': 'Unknown',
    'insufficient_balance': 'Insufficient balance',
    'cannot_transfer_self': 'Cannot transfer to yourself',
    'sender_or_receiver_not_found': 'Sender or receiver not found',
    'amount_must_be_greater': 'Amount must be greater than 0',
    'invalid_qr': 'Invalid QR Code',
    'camera_scan_hint': 'Scan receiver wallet QR code',
    'close': 'Close',
    'upload_profile_failed': 'Unable to upload profile picture',
    'remember_me': 'Remember me on this browser',
    'add_money': 'Add Money',
    'choose_add_money_method': 'Choose how you want to add money',
    'add_money_intro':
        'Pick the funding method that fits you. Card payments open Stripe instantly, crypto uses Solana USDC deposit instructions with automatic wallet credit, and Wish Money or TapTap Send is handled by a third party.',
    'card_method': 'Credit Card / Mastercard / Apple Pay',
    'card_method_subtitle':
        'Instant funding through Stripe checkout with secure card processing.',
    'crypto_method': 'Crypto',
    'crypto_add_money_subtitle':
        'Instant USDC funding on Solana with automatic wallet credit after payment arrives.',
    'wish_method': 'Wish Money / TapTap Send',
    'wish_add_money_subtitle':
        'Handled by a third party. Processing normally takes 2 to 3 business hours.',
    'wish_add_money_contact':
        'To add money with Wish Money or TapTap Send, contact the third-party support number and share your request.',
    'fee': 'Fee',
    'speed': 'Speed',
    'instant': 'Instant',
    'continue_text': 'Continue',
    'two_three_business_hours': '2 to 3 business hours',
    'stripe_backend_missing':
        'Missing API_BASE_URL. Set --dart-define=API_BASE_URL=https://www.infinity-sharing.money/api',
    'crypto_coming_soon':
        'Crypto cash out setup is still pending.',
    'missing_crypto_deposit': 'Missing crypto deposit request.',
    'crypto_send_exact_title': 'Send the exact crypto amount',
    'crypto_request_intro':
        'Enter the wallet you will send from. We use that wallet plus the exact amount to match your pending deposit safely.',
    'crypto_request_note':
        'After you create the request, copy our wallet address and the exact USDC amount. Send only from the wallet you entered here.',
    'create_crypto_request': 'Create Crypto Request',
    'sender_wallet_required': 'Your sending wallet address is required.',
    'your_sending_wallet': 'Your sending wallet',
    'crypto_wallet_address': 'Deposit wallet',
    'crypto_amount_to_send': 'Exact amount to send',
    'crypto_you_receive': 'Wallet credit after fee',
    'crypto_rate_applied': 'USD rate applied now',
    'crypto_network': 'Network',
    'crypto_send_exact_body':
        'Send exactly this USDC amount on Solana to the wallet above. After the transfer is confirmed on-chain, tap the button below to refresh and the app will credit your wallet balance automatically.',
    'i_sent_crypto': 'I sent the crypto',
    'crypto_dialog_steps':
        '1. Copy our wallet address.\n2. Copy the exact USDC amount.\n3. Send from the wallet you entered.\n4. Leave the request pending until the transfer is detected and your wallet is credited automatically.',
    'copy_wallet_address': 'Copy Wallet Address',
    'wallet_address_copied': 'Wallet address copied.',
    'copy_crypto_amount': 'Copy Crypto Amount',
    'crypto_amount_copied': 'Crypto amount copied.',
    'payment_auto_checking': 'Payment opened. The app is checking status automatically.',
    'payment_waiting_credit': 'Waiting for Stripe payment confirmation and wallet credit.',
    'crypto_waiting_credit': 'Waiting for Solana payment confirmation and automatic wallet credit.',
    'cash_out_intro_title': 'Cash out options',
    'cash_out_intro':
        'Choose the way you want to cash out. Local cash out is handled by trusted third parties under country rules.',
    'agent_cash_out': 'Our agents',
    'agent_cash_out_subtitle':
        'Third-party agent support will guide you through the available local cash-out steps.',
    'agent_cash_out_contact':
        'Contact our third-party agents on the support number to receive cash-out instructions.',
    'crypto_cash_out_subtitle':
        'Crypto cash out is handled by third-party support through the contact number.',
    'crypto_cash_out_contact':
        'Contact the support number to complete crypto cash out through the third party.',
    'wish_cash_out': 'Wish Money',
    'wish_cash_out_subtitle':
        'Third-party cash out through Wish Money support.',
    'wish_cash_out_contact':
        'Contact the support number to complete Wish Money cash out with the third party.',
    'third_party_speed': 'Handled by third party',
    'support_number': 'Support number',
    'contact_now': 'Contact now',
    'fees_table': 'Fees Table',
    'no_fee_banner':
        'NO FEES FROM WALLET TO WALLET\nNO FEES ON CASH OUT\nNO HIDDEN FEES',
    'fees_intro':
        'The only fees apply when you add money to the wallet. Wallet transfers and cash out do not have app fees.',
    'add_money_fees': 'Add money fees',
    'support_chat': 'AI Support Chat',
    'ask_support_hint': 'Ask about fees, add money, cash out, or security',
    'wallet_notes_title': 'Wallet information',
    'wallet_notes_body':
        'Use your wallet ID or QR to receive balance. Add money and cash out each have their own page, so the wallet screen stays focused on balance and receiving.',
    'add_money_wallet_short': 'Card, crypto, or Wish Money funding',
    'cash_out_wallet_short': 'Agent, crypto, or Wish Money cash out',
    'date_of_birth': 'Date of Birth',
    'average_monthly_transactions': 'Average Monthly Transactions',
    'data_secure_note': 'Your data is secure and used for account protection.',
    'must_be_18': 'You must be at least 18 years old.',
    'profile_image_required': 'Profile image is required.',
    'wallet_policy_text':
        'Infinity is an e-wallet service. Your balance is maintained inside the wallet as a stable and real balance available for your use, including cash out whenever supported. Local cash-out fulfillment may be handled by regulated third parties according to the laws of the country where the service is used. Infinity operates as a UK registered company and provides an unlimited wallet experience for supported customers.',
    'security_reassurance': 'Everything is secure.',
    'settings_security_text':
        'We protect account data, wallet balances, and transaction records. Third-party cash-out partners operate under local country rules, while your balance remains available in the wallet.',
    'profile_updated': 'Profile updated successfully',
  };

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': _english,
        'ar_IQ': _english,
      };
}

class LanguageController extends GetxController {
  final Rx<Locale> _locale = const Locale('en', 'US').obs;

  Locale get locale => _locale.value;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_language') ?? 'en';
    _locale.value =
        code == 'ar' ? const Locale('ar', 'IQ') : const Locale('en', 'US');
  }

  Future<void> changeLanguage(String code) async {
    final locale =
        code == 'ar' ? const Locale('ar', 'IQ') : const Locale('en', 'US');
    _locale.value = locale;
    Get.updateLocale(locale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
  }
}
