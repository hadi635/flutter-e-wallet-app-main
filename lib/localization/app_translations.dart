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
    'go_moonpay': 'Go to MoonPay',
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
    'availability': 'Availability',
    'speed': 'Speed',
    'instant': 'Instant',
    'continue_text': 'Continue',
    'two_three_business_hours': '2 to 3 business hours',
    'stripe_backend_missing':
        'Missing API_BASE_URL. Set --dart-define=API_BASE_URL=https://www.infinity-sharing.money/api',
    'crypto_coming_soon': 'Crypto cash out setup is still pending.',
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
    'payment_auto_checking':
        'Payment opened. The app is checking status automatically.',
    'payment_waiting_credit':
        'Waiting for Stripe payment confirmation and wallet credit.',
    'crypto_waiting_credit':
        'Waiting for Solana payment confirmation and automatic wallet credit.',
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
    'reset_password': 'Reset Password',
    'reset_password_sent': 'Password reset email sent.',
    'enter_email_for_reset': 'Enter your email address first.',
    'change_password': 'Change Password',
    'current_password': 'Current Password',
    'new_password': 'New Password',
    'confirm_new_password': 'Confirm New Password',
    'password_changed_successfully': 'Password changed successfully.',
    'recent_login_required':
        'For security, please log in again before changing your password.',
    'weak_new_password': 'The new password is too weak.',
    'wallet_id_preview': 'Wallet ID Preview',
    'no_wallet_id_yet': 'Not assigned yet',
    'profile_photo_optional': 'Profile photo is optional.',
    'image_too_large': 'Image is too large. Please choose a smaller file.',
    'uploading': 'Uploading...',
    'password_reset_failed': 'Unable to send password reset email.',
    'password_change_failed': 'Unable to change password.',
    'about': 'About',
    'services': 'Services',
    'contact': 'Contact',
    'privacy': 'Privacy',
    'terms': 'Terms',
    'admin': 'Admin',
    'welcome_badge': 'Unlimited Wallet Access',
    'welcome_title': 'Move money with one clean wallet flow.',
    'welcome_tagline': 'No Limit NO Saving for your data',
    'welcome_description':
        'Create your account, receive balance by wallet ID or QR, add money with the right method for your case, and keep manual requests visible until they are confirmed.',
    'welcome_stat_one': 'Wallet to wallet',
    'welcome_stat_two': 'Crypto instant',
    'welcome_stat_three': 'Manual review tracking',
    'welcome_cta_title': 'Start with a simpler wallet setup',
    'welcome_cta_body':
        'Open your account, unlock the first Wish Money promotion, and manage every wallet operation from one place.',
    'add_money_overview':
        'Choose the funding method that fits your case. Crypto is instant, Wish Money is a pending manual request, and card top-up stays pending until approval.',
    'wish_promo_title': 'Wish Promotion',
    'wish_promo_body':
        'Your first Wish Money add money request has 0% fee. After that, Wish Money uses a 1% fee.',
    'wish_method_title': 'Wish Money',
    'wish_method_subtitle_free':
        'Fast manual funding with no fee on the first payment.',
    'wish_method_subtitle_paid':
        'Fast manual funding with a low 1% fee after the first payment.',
    'wish_fee_free': '0% first payment',
    'wish_fee_paid': '1%',
    'wish_speed': 'Pending until admin confirms',
    'crypto_method_title': 'Crypto',
    'crypto_method_subtitle_new':
        'Instant USDC funding on Solana with automatic wallet credit after confirmation.',
    'crypto_fee_value': '2.5%',
    'crypto_speed_value': 'Instant',
    'card_method_title_new': 'Visa / Mastercard',
    'card_method_subtitle_new':
        'Manual review before wallet credit for users who can wait.',
    'card_fee_value': '5.5% + \$0.30',
    'card_speed_value': '1 to 3 business days',
    'wish_pending_title': 'Wish Money Pending Payment',
    'wish_pending_body':
        'Send the payment to @number. The request stays pending until admin confirms the received amount minus the fee.',
    'requested_amount': 'Requested amount',
    'wallet_credit_label': 'Wallet credit',
    'sender_full_name': 'Sender full name',
    'sender_phone': 'Sender phone',
    'wish_transfer_reference': 'Wish transfer reference',
    'payment_note': 'Note',
    'save_pending_request': 'Save Pending Request',
    'wish_pending_saved':
        'Wish request saved. Send the payment to the support number and wait for admin confirmation.',
    'crypto_panel_title': 'Crypto Instant Funding',
    'crypto_panel_body':
        'Create a Solana USDC request. The wallet credits automatically after the blockchain payment is confirmed.',
    'card_pending_title': 'Card Pending Payment Review',
    'card_pending_body':
        'Pay through Stripe. After payment, the top-up stays pending until admin confirmation within 1 to 3 business days.',
    'card_provider_stripe': 'Stripe',
    'card_provider_stripe_body':
        'Direct wallet top-up flow with backend confirmation.',
    'card_provider_moonpay': 'MoonPay',
    'card_provider_moonpay_body':
        'Hosted card crypto checkout for supported countries.',
    'moonpay_country_required':
        'Complete your profile country to check MoonPay availability.',
    'moonpay_country_not_supported':
        'MoonPay is not available for your selected country.',
    'moonpay_country_unavailable_short': 'Unavailable here',
    'moonpay_supported_country': 'Available in this country.',
    'moonpay_panel_body':
        'MoonPay opens its hosted checkout in your browser. Availability and fees depend on MoonPay region support and payment method.',
    'moonpay_opened': 'MoonPay opened in your browser.',
    'moonpay_result_pending':
        'MoonPay returned a pending transaction status. Finish the flow on MoonPay.',
    'moonpay_result_opened':
        'MoonPay transaction @id opened successfully. Follow MoonPay to complete the purchase.',
    'card_holder_name': 'Card holder name',
    'card_reference': 'Card reference or last 4 digits',
    'save_pending_card_request': 'Save Pending Card Request',
    'card_pending_saved':
        'Card request saved. Balance stays pending until admin confirms it in 1 to 3 business days.',
    'stripe_card_pending_message':
        'Card payment received. Your top-up is pending admin confirmation for 1 to 3 business days.',
    'pending_request_saved': 'Pending request saved',
    'recent_add_money_requests': 'Your recent add money requests',
    'cash_out_title_new': 'Cash Out Options',
    'cash_out_overview':
        'Choose how you want to withdraw. Card requests take 1 to 3 business days, agent and crypto requests take 1 business day, and Wish Money stays contact-based.',
    'withdraw_amount': 'Amount to withdraw',
    'cashout_card_title': 'Card',
    'cashout_card_subtitle':
        'Pending card withdrawal handled with manual review.',
    'cashout_card_speed': '1 to 3 business days',
    'cashout_agent_title': 'Agent',
    'cashout_agent_subtitle':
        'Pending request routed to the nearest available third-party point.',
    'cashout_agent_speed': '1 business day',
    'cashout_crypto_title': 'Crypto',
    'cashout_crypto_subtitle':
        'Pending crypto withdrawal sent after manual handling.',
    'cashout_crypto_speed': '1 business day',
    'cashout_wish_title': 'Wish Money',
    'cashout_wish_subtitle':
        'Wish Money cash out is handled through direct contact.',
    'cashout_wish_speed': 'Contact us',
    'cashout_card_panel_title': 'Card Withdrawal Request',
    'cashout_card_panel_body':
        'This request stays pending until manual confirmation within 1 to 3 business days.',
    'save_pending_card_withdrawal': 'Save Pending Card Withdrawal',
    'cashout_agent_panel_title': 'Agent Cash Out Request',
    'cashout_agent_panel_body':
        'Add your contact number and preferred nearby location so the admin can route your request.',
    'contact_phone': 'Contact phone',
    'preferred_location': 'Preferred nearby location',
    'save_pending_agent_cashout': 'Save Pending Agent Cash Out',
    'cashout_crypto_panel_title': 'Crypto Cash Out Request',
    'cashout_crypto_panel_body':
        'This request stays pending until it is manually handled within one business day.',
    'wallet_address_field': 'Wallet address',
    'save_pending_crypto_cashout': 'Save Pending Crypto Cash Out',
    'cashout_wish_panel_title': 'Wish Money Contact Flow',
    'cashout_wish_panel_body':
        'Wish Money cash out is handled by third party. Contact @number to proceed.',
    'contact_wish_support': 'Contact Wish Money Support',
    'cashout_wish_contact_message':
        'Contact the support number below for Wish Money cash out.',
    'cashout_pending_saved': 'Cash out request saved as pending.',
    'recent_cashout_requests': 'Your recent cash out requests',
    'coming_soon': 'Coming Soon',
    'wallet_card_brand': 'INFINITY WALLET',
    'wallet_card_teaser': 'Coming Soon Physical and Virtual Visa Card',
    'wallet_add_money_summary':
        'Crypto instant, Wish pending, card pending review',
    'wallet_cash_out_summary':
        'Card, agent, or crypto requests with pending handling',
    'receive_money_body':
        'Use your wallet ID or QR to receive wallet-to-wallet transfers instantly.',
    'pending_operations': 'Pending operations',
    'request_kind_add_money': 'Add money',
    'request_kind_cash_out': 'Cash out',
    'request_status_pending': 'Pending',
    'request_status_confirmed': 'Confirmed',
    'request_status_rejected': 'Rejected',
    'request_method_wish': 'Wish Money',
    'request_method_card': 'Visa / Mastercard',
    'request_method_crypto': 'Crypto',
    'request_method_agent': 'Agent',
  };

  static const Map<String, String> _arabic = {
    'app_name': 'محفظة إنفينيتي الإلكترونية',
    'login': 'تسجيل الدخول',
    'create_account': 'إنشاء حساب',
    'create_new_account': 'إنشاء حساب جديد',
    'already_have_account': 'لديك حساب بالفعل؟',
    'email_address': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    're_enter_password': 'أعد إدخال كلمة المرور',
    'fields_cant_be_empty': 'لا يمكن أن تكون الحقول فارغة',
    'passwords_do_not_match': 'كلمتا المرور غير متطابقتين',
    'welcome_subtitle':
        'أرسل الأموال باستخدام رقم المحفظة ورمز QR واشحن محفظتك بأمان.',
    'home': 'الرئيسية',
    'wallet': 'المحفظة',
    'settings': 'الإعدادات',
    'hello': 'مرحبًا',
    'available_balance': 'الرصيد المتاح',
    'send_money': 'إرسال الأموال',
    'cash_out': 'سحب الأموال',
    'recent_activity': 'النشاط الأخير',
    'see_all': 'عرض الكل',
    'no_transactions_yet': 'لا توجد معاملات حتى الآن',
    'activity': 'النشاط',
    'to_wallet_id': 'إلى رقم المحفظة',
    'wallet_id': 'رقم المحفظة',
    'wallet_id_or_qr': 'رقم المحفظة / QR',
    'scan_qr': 'مسح QR',
    'open_scanner': 'فتح الماسح',
    'generate_qr': 'إنشاء QR',
    'receive_money': 'استلام الأموال',
    'receive_by_qr': 'الاستلام عبر QR',
    'show_my_qr': 'عرض QR الخاص بي',
    'enter_amount': 'أدخل المبلغ',
    'amount_to_add': 'المبلغ المراد إضافته',
    'send': 'إرسال',
    'sending': 'جارٍ الإرسال...',
    'invalid_amount': 'مبلغ غير صالح',
    'enter_valid_amount': 'أدخل مبلغًا صالحًا أكبر من 0',
    'transfer_failed': 'فشل التحويل',
    'success': 'نجاح',
    'done': 'تم',
    'sent_to_wallet': 'تم الإرسال إلى رقم المحفظة',
    'from_your_wallet': 'من محفظتك.',
    'complete_setup': 'أكمل الإعداد',
    'enter_full_name': 'أدخل اسمك الكامل',
    'enter_nid_name': 'أدخل اسم الهوية',
    'enter_phone_number': 'أدخل رقم الهاتف',
    'save_details': 'حفظ التفاصيل',
    'search_by_wallet_id': 'ابحث برقم المحفظة...',
    'user_not_found': 'المحفظة غير موجودة',
    'logout': 'تسجيل الخروج',
    'logout_success': 'تم تسجيل الخروج بنجاح',
    'policy_privacy': 'السياسة والخصوصية',
    'history': 'السجل',
    'profile': 'الملف الشخصي',
    'language': 'اللغة',
    'english': 'الإنجليزية',
    'arabic': 'العربية',
    'cash_out_help': 'رقم دعم سحب الأموال',
    'contact_cash_out': 'التواصل مع السحب',
    'wallet_card': 'بطاقة محفظة إنفينيتي الإلكترونية',
    'card_details': 'تفاصيل البطاقة',
    'please_wait': 'يرجى الانتظار...',
    'go_stripe': 'الانتقال إلى Stripe Checkout',
    'go_moonpay': 'الانتقال إلى MoonPay',
    'missing_payment_link':
        'رابط STRIPE_PAYMENT_LINK مفقود. أضف --dart-define=STRIPE_PAYMENT_LINK=https://buy.stripe.com/...',
    'payment_opened_manual_credit':
        'تم فتح صفحة الدفع. إضافة الرصيد يدوية في هذا الوضع.',
    'payment_opened_return_confirm':
        'تم فتح صفحة الدفع. بعد الدفع ارجع واضغط تأكيد الشحن.',
    'payment_link_label': 'رابط دفع Stripe',
    'confirm_topup': 'تأكيد الشحن',
    'missing_session_id': 'معرّف جلسة الدفع مفقود',
    'pay_add_money': 'ادفع وأضف أموالاً',
    'security_note':
        'ملاحظة أمنية: مفاتيح Stripe السرية لا توضع في التطبيق. الدفع وإضافة الرصيد يتم التحقق منهما من خلال الخادم.',
    'backend': 'الخادم',
    'not_configured': 'غير مهيأ',
    'privacy_content':
        'تُستخدم بياناتك فقط لعمليات المحفظة وسجل المعاملات وأمان الحساب.',
    'error': 'خطأ',
    'congratulations': 'تهانينا!',
    'signup_success': 'تم إنشاء الحساب بنجاح',
    'login_success': 'تم تسجيل الدخول بنجاح',
    'weak_password': 'كلمة المرور المقدمة ضعيفة جدًا.',
    'email_used': 'يوجد حساب بالفعل لهذا البريد الإلكتروني.',
    'account_creation_failed': 'فشل إنشاء الحساب',
    'login_failed': 'فشل تسجيل الدخول',
    'user_not_found_email': 'لم يتم العثور على مستخدم لهذا البريد الإلكتروني.',
    'wrong_password': 'كلمة المرور غير صحيحة لهذا المستخدم.',
    'auth_error': 'خطأ في المصادقة',
    'please_login_again': 'يرجى تسجيل الدخول مرة أخرى.',
    'card_required': 'البطاقة مطلوبة',
    'complete_card_details': 'يرجى إكمال تفاصيل البطاقة.',
    'topup': 'شحن',
    'topup_success': 'نجح الشحن',
    'wallet_credited_new_balance': 'تمت إضافة الرصيد. الرصيد الجديد:',
    'wallet_credited_successfully': 'تمت إضافة الرصيد بنجاح.',
    'topup_pending': 'الشحن قيد الانتظار',
    'topup_failed': 'فشل الشحن',
    'web_stripe_note':
        'في الويب يتم استخدام صفحة Stripe المستضافة لإدخال البطاقة بشكل آمن.',
    'unknown': 'غير معروف',
    'insufficient_balance': 'الرصيد غير كافٍ',
    'cannot_transfer_self': 'لا يمكنك التحويل إلى نفسك',
    'sender_or_receiver_not_found': 'لم يتم العثور على المرسل أو المستلم',
    'amount_must_be_greater': 'يجب أن يكون المبلغ أكبر من 0',
    'invalid_qr': 'رمز QR غير صالح',
    'camera_scan_hint': 'امسح رمز QR الخاص بالمستلم',
    'close': 'إغلاق',
    'upload_profile_failed': 'تعذر رفع صورة الملف الشخصي',
    'remember_me': 'تذكرني على هذا المتصفح',
    'add_money': 'إضافة أموال',
    'choose_add_money_method': 'اختر طريقة إضافة الأموال',
    'add_money_intro':
        'اختر وسيلة التمويل المناسبة لك. البطاقة تفتح Stripe فورًا، والعملات الرقمية تستخدم إيداع USDC على Solana مع إضافة تلقائية، وWish Money أو TapTap Send تتم عبر طرف ثالث.',
    'card_method': 'بطاقة ائتمان / ماستركارد / Apple Pay',
    'card_method_subtitle': 'تمويل فوري عبر Stripe مع معالجة آمنة للبطاقة.',
    'crypto_method': 'عملات رقمية',
    'crypto_add_money_subtitle':
        'تمويل فوري بعملة USDC على Solana مع إضافة تلقائية بعد وصول التحويل.',
    'wish_method': 'Wish Money / TapTap Send',
    'wish_add_money_subtitle':
        'تتم عبر طرف ثالث. تستغرق المعالجة عادة من 2 إلى 3 ساعات عمل.',
    'wish_add_money_contact':
        'لإضافة الأموال عبر Wish Money أو TapTap Send، تواصل مع رقم دعم الطرف الثالث وشارك طلبك.',
    'fee': 'الرسوم',
    'availability': 'التوفر',
    'speed': 'السرعة',
    'instant': 'فوري',
    'continue_text': 'متابعة',
    'two_three_business_hours': '2 إلى 3 ساعات عمل',
    'stripe_backend_missing':
        'API_BASE_URL مفقود. استخدم --dart-define=API_BASE_URL=https://www.infinity-sharing.money/api',
    'crypto_coming_soon': 'إعداد سحب العملات الرقمية ما زال قيد التجهيز.',
    'missing_crypto_deposit': 'طلب إيداع العملات الرقمية مفقود.',
    'crypto_send_exact_title': 'أرسل مبلغ العملات الرقمية المحدد بالضبط',
    'crypto_request_intro':
        'أدخل المحفظة التي سترسل منها. نستخدم هذه المحفظة مع المبلغ المحدد لمطابقة الإيداع المعلق بأمان.',
    'crypto_request_note':
        'بعد إنشاء الطلب، انسخ عنوان محفظتنا ومبلغ USDC المحدد بالضبط. أرسل فقط من المحفظة التي أدخلتها هنا.',
    'create_crypto_request': 'إنشاء طلب عملات رقمية',
    'sender_wallet_required': 'عنوان محفظة الإرسال مطلوب.',
    'your_sending_wallet': 'محفظة الإرسال الخاصة بك',
    'crypto_wallet_address': 'عنوان الإيداع',
    'crypto_amount_to_send': 'المبلغ المحدد للإرسال',
    'crypto_you_receive': 'رصيد المحفظة بعد الرسوم',
    'crypto_rate_applied': 'سعر الدولار المطبق الآن',
    'crypto_network': 'الشبكة',
    'crypto_send_exact_body':
        'أرسل هذا المبلغ من USDC بالضبط على شبكة Solana إلى المحفظة أعلاه. بعد تأكيد التحويل على الشبكة، اضغط الزر أدناه للتحديث وسيتم إضافة الرصيد تلقائيًا.',
    'i_sent_crypto': 'لقد أرسلت العملات الرقمية',
    'crypto_dialog_steps':
        '1. انسخ عنوان محفظتنا.\n2. انسخ مبلغ USDC المحدد.\n3. أرسل من المحفظة التي أدخلتها.\n4. اترك الطلب معلقًا حتى يتم اكتشاف التحويل وإضافة الرصيد تلقائيًا.',
    'copy_wallet_address': 'نسخ عنوان المحفظة',
    'wallet_address_copied': 'تم نسخ عنوان المحفظة.',
    'copy_crypto_amount': 'نسخ مبلغ العملات الرقمية',
    'crypto_amount_copied': 'تم نسخ مبلغ العملات الرقمية.',
    'payment_auto_checking':
        'تم فتح صفحة الدفع. التطبيق يتحقق من الحالة تلقائيًا.',
    'payment_waiting_credit': 'بانتظار تأكيد دفع Stripe وإضافة الرصيد.',
    'crypto_waiting_credit':
        'بانتظار تأكيد الدفع على Solana وإضافة الرصيد تلقائيًا.',
    'cash_out_intro_title': 'خيارات سحب الأموال',
    'cash_out_intro':
        'اختر الطريقة التي تريد سحب الأموال بها. السحب المحلي يتم عبر أطراف ثالثة موثوقة وفق قوانين البلد.',
    'agent_cash_out': 'وكلاؤنا',
    'agent_cash_out_subtitle':
        'دعم الوكلاء من الأطراف الثالثة سيوجهك خلال خطوات السحب المحلية المتاحة.',
    'agent_cash_out_contact':
        'تواصل مع وكلائنا من الأطراف الثالثة على رقم الدعم للحصول على تعليمات السحب.',
    'crypto_cash_out_subtitle':
        'سحب العملات الرقمية يتم عبر دعم الطرف الثالث من خلال رقم التواصل.',
    'crypto_cash_out_contact':
        'تواصل مع رقم الدعم لإكمال سحب العملات الرقمية عبر الطرف الثالث.',
    'wish_cash_out': 'Wish Money',
    'wish_cash_out_subtitle': 'سحب الأموال عبر دعم Wish Money كطرف ثالث.',
    'wish_cash_out_contact':
        'تواصل مع رقم الدعم لإكمال سحب Wish Money مع الطرف الثالث.',
    'third_party_speed': 'تتم عبر طرف ثالث',
    'support_number': 'رقم الدعم',
    'contact_now': 'تواصل الآن',
    'fees_table': 'جدول الرسوم',
    'no_fee_banner':
        'لا توجد رسوم من محفظة إلى محفظة\nلا توجد رسوم على السحب\nلا توجد رسوم مخفية',
    'fees_intro':
        'الرسوم الوحيدة تطبق عند إضافة الأموال إلى المحفظة. التحويلات والسحب لا توجد عليهما رسوم من التطبيق.',
    'add_money_fees': 'رسوم إضافة الأموال',
    'support_chat': 'دردشة الدعم الذكية',
    'ask_support_hint': 'اسأل عن الرسوم أو إضافة الأموال أو السحب أو الأمان',
    'wallet_notes_title': 'معلومات المحفظة',
    'wallet_notes_body':
        'استخدم رقم المحفظة أو QR لاستلام الرصيد. إضافة الأموال والسحب لكل منهما صفحة خاصة، لتبقى صفحة المحفظة مركزة على الرصيد والاستلام.',
    'add_money_wallet_short': 'تمويل بالبطاقة أو العملات الرقمية أو Wish Money',
    'cash_out_wallet_short': 'سحب عبر الوكيل أو العملات الرقمية أو Wish Money',
    'date_of_birth': 'تاريخ الميلاد',
    'average_monthly_transactions': 'متوسط المعاملات الشهرية',
    'data_secure_note': 'بياناتك آمنة وتستخدم لحماية الحساب.',
    'must_be_18': 'يجب أن يكون عمرك 18 سنة على الأقل.',
    'profile_image_required': 'صورة الملف الشخصي مطلوبة.',
    'wallet_policy_text':
        'إنفينيتي خدمة محفظة إلكترونية. يتم الاحتفاظ برصيدك داخل المحفظة كرصيد ثابت وحقيقي متاح لاستخدامك، بما في ذلك السحب عند توفره. قد يتم تنفيذ السحب المحلي عبر أطراف ثالثة منظمة وفقًا لقوانين البلد المستخدم فيه الخدمة. تعمل إنفينيتي كشركة مسجلة في المملكة المتحدة وتوفر تجربة محفظة غير محدودة للعملاء المؤهلين.',
    'security_reassurance': 'كل شيء آمن.',
    'settings_security_text':
        'نحمي بيانات الحساب وأرصدة المحفظة وسجلات المعاملات. شركاء السحب من الأطراف الثالثة يعملون وفق قوانين البلد، بينما يبقى رصيدك متاحًا داخل المحفظة.',
    'profile_updated': 'تم تحديث الملف الشخصي بنجاح',
    'reset_password': 'إعادة تعيين كلمة المرور',
    'reset_password_sent': 'تم إرسال رسالة إعادة تعيين كلمة المرور.',
    'enter_email_for_reset': 'أدخل بريدك الإلكتروني أولاً.',
    'change_password': 'تغيير كلمة المرور',
    'current_password': 'كلمة المرور الحالية',
    'new_password': 'كلمة المرور الجديدة',
    'confirm_new_password': 'تأكيد كلمة المرور الجديدة',
    'password_changed_successfully': 'تم تغيير كلمة المرور بنجاح.',
    'recent_login_required':
        'لأسباب أمنية، يرجى تسجيل الدخول مرة أخرى قبل تغيير كلمة المرور.',
    'weak_new_password': 'كلمة المرور الجديدة ضعيفة جدًا.',
    'wallet_id_preview': 'معاينة رقم المحفظة',
    'no_wallet_id_yet': 'لم يتم تعيينه بعد',
    'profile_photo_optional': 'صورة الملف الشخصي اختيارية.',
    'image_too_large': 'الصورة كبيرة جدًا. يرجى اختيار ملف أصغر.',
    'uploading': 'جارٍ الرفع...',
    'password_reset_failed': 'تعذر إرسال رسالة إعادة تعيين كلمة المرور.',
    'password_change_failed': 'تعذر تغيير كلمة المرور.',
    'about': 'حول',
    'services': 'الخدمات',
    'contact': 'اتصل بنا',
    'privacy': 'الخصوصية',
    'terms': 'الشروط',
    'admin': 'المشرف',
    'welcome_badge': 'وصول غير محدود للمحفظة',
    'welcome_title': 'حرّك أموالك عبر محفظة واحدة بتجربة واضحة.',
    'welcome_tagline': 'No Limit NO Saving for your data',
    'welcome_description':
        'أنشئ حسابك، واستقبل الرصيد عبر رقم المحفظة أو رمز QR، وأرسل طلبات الإضافة أو السحب مع متابعة واضحة حتى يتم تأكيدها.',
    'welcome_stat_one': 'تحويل من محفظة إلى محفظة',
    'welcome_stat_two': 'عملات رقمية فورية',
    'welcome_stat_three': 'متابعة للطلبات اليدوية',
    'welcome_cta_title': 'ابدأ بمحفظة أبسط',
    'welcome_cta_body':
        'افتح حسابك، واحصل على عرض Wish Money لأول مرة، وأدر كل عمليات محفظتك من مكان واحد.',
    'add_money_overview':
        'اختر طريقة الإضافة المناسبة لك. العملات الرقمية فورية، وWish Money طلب يدوي معلق، والبطاقة تبقى معلقة حتى الموافقة.',
    'wish_promo_title': 'عرض Wish',
    'wish_promo_body':
        'أول طلب إضافة أموال عبر Wish Money بدون رسوم 0%. بعد ذلك تصبح الرسوم 1%.',
    'wish_method_title': 'Wish Money',
    'wish_method_subtitle_free': 'إضافة يدوية سريعة بدون رسوم في أول دفعة.',
    'wish_method_subtitle_paid':
        'إضافة يدوية سريعة مع رسوم منخفضة 1% بعد أول دفعة.',
    'wish_fee_free': '0% لأول دفعة',
    'wish_fee_paid': '1%',
    'wish_speed': 'معلق حتى تأكيد المشرف',
    'crypto_method_title': 'العملات الرقمية',
    'crypto_method_subtitle_new':
        'إضافة USDC فورية على شبكة Solana مع شحن تلقائي بعد التأكيد.',
    'crypto_fee_value': '2.5%',
    'crypto_speed_value': 'فوري',
    'card_method_title_new': 'Visa / Mastercard',
    'card_method_subtitle_new':
        'مراجعة يدوية قبل إضافة الرصيد للمستخدمين الذين يمكنهم الانتظار.',
    'card_fee_value': '5.5% + \$0.30',
    'card_speed_value': 'من 1 إلى 3 أيام عمل',
    'wish_pending_title': 'دفع Wish Money المعلق',
    'wish_pending_body':
        'أرسل الدفعة إلى @number. يبقى الطلب معلقًا حتى يؤكد المشرف المبلغ المستلم بعد خصم الرسوم.',
    'requested_amount': 'المبلغ المطلوب',
    'wallet_credit_label': 'الرصيد الذي سيضاف',
    'sender_full_name': 'اسم المرسل الكامل',
    'sender_phone': 'هاتف المرسل',
    'wish_transfer_reference': 'مرجع تحويل Wish',
    'payment_note': 'ملاحظة',
    'save_pending_request': 'حفظ الطلب المعلق',
    'wish_pending_saved':
        'تم حفظ طلب Wish. أرسل الدفعة إلى رقم الدعم وانتظر تأكيد المشرف.',
    'crypto_panel_title': 'إضافة فورية بالعملات الرقمية',
    'crypto_panel_body':
        'أنشئ طلب USDC على Solana. تتم إضافة الرصيد تلقائيًا بعد تأكيد التحويل على الشبكة.',
    'card_pending_title': 'مراجعة دفع البطاقة المعلقة',
    'card_pending_body':
        'ادفع عبر Stripe. بعد الدفع يبقى طلب الإضافة معلقًا حتى تأكيد المشرف خلال 1 إلى 3 أيام عمل.',
    'card_provider_stripe': 'Stripe',
    'card_provider_stripe_body':
        'إضافة مباشرة إلى المحفظة مع تأكيد من الخادم.',
    'card_provider_moonpay': 'MoonPay',
    'card_provider_moonpay_body':
        'شراء عملات رقمية بالبطاقة عبر صفحة مستضافة في البلدان المدعومة.',
    'moonpay_country_required':
        'أكمل حقل البلد في ملفك الشخصي للتحقق من توفر MoonPay.',
    'moonpay_country_not_supported':
        'MoonPay غير متاح للبلد المحدد في حسابك.',
    'moonpay_country_unavailable_short': 'غير متاح هنا',
    'moonpay_supported_country': 'متاح في هذا البلد.',
    'moonpay_panel_body':
        'يفتح MoonPay صفحة دفع مستضافة داخل المتصفح. التوفر والرسوم يعتمدان على البلد وطريقة الدفع لدى MoonPay.',
    'moonpay_opened': 'تم فتح MoonPay في المتصفح.',
    'moonpay_result_pending':
        'أعاد MoonPay حالة معاملة قيد الانتظار. أكمل المتابعة داخل MoonPay.',
    'moonpay_result_opened':
        'تم فتح معاملة MoonPay رقم @id بنجاح. تابع داخل MoonPay لإكمال الشراء.',
    'card_holder_name': 'اسم حامل البطاقة',
    'card_reference': 'مرجع البطاقة أو آخر 4 أرقام',
    'save_pending_card_request': 'حفظ طلب البطاقة المعلق',
    'card_pending_saved':
        'تم حفظ طلب البطاقة. الرصيد يبقى معلقًا حتى يؤكده المشرف خلال 1 إلى 3 أيام عمل.',
    'stripe_card_pending_message':
        'تم استلام دفعة البطاقة. طلب الإضافة الآن قيد الانتظار حتى تأكيد المشرف خلال 1 إلى 3 أيام عمل.',
    'pending_request_saved': 'تم حفظ الطلب المعلق',
    'recent_add_money_requests': 'أحدث طلبات إضافة الأموال',
    'cash_out_title_new': 'خيارات سحب الأموال',
    'cash_out_overview':
        'اختر طريقة السحب المناسبة. طلبات البطاقة تستغرق من 1 إلى 3 أيام عمل، وطلبات الوكيل والعملات الرقمية يوم عمل واحد، وWish Money عبر التواصل المباشر.',
    'withdraw_amount': 'المبلغ المراد سحبه',
    'cashout_card_title': 'البطاقة',
    'cashout_card_subtitle': 'طلب سحب بالبطاقة مع مراجعة يدوية.',
    'cashout_card_speed': 'من 1 إلى 3 أيام عمل',
    'cashout_agent_title': 'الوكيل',
    'cashout_agent_subtitle':
        'طلب معلق يتم توجيهه إلى أقرب نقطة طرف ثالث متاحة.',
    'cashout_agent_speed': 'يوم عمل واحد',
    'cashout_crypto_title': 'العملات الرقمية',
    'cashout_crypto_subtitle':
        'طلب سحب بالعملات الرقمية يتم تنفيذه بعد المعالجة اليدوية.',
    'cashout_crypto_speed': 'يوم عمل واحد',
    'cashout_wish_title': 'Wish Money',
    'cashout_wish_subtitle': 'سحب Wish Money يتم عبر التواصل المباشر.',
    'cashout_wish_speed': 'تواصل معنا',
    'cashout_card_panel_title': 'طلب سحب إلى البطاقة',
    'cashout_card_panel_body':
        'يبقى هذا الطلب معلقًا حتى التأكيد اليدوي خلال 1 إلى 3 أيام عمل.',
    'save_pending_card_withdrawal': 'حفظ طلب سحب البطاقة',
    'cashout_agent_panel_title': 'طلب سحب عبر وكيل',
    'cashout_agent_panel_body':
        'أضف رقم التواصل والموقع القريب المفضل حتى يتم توجيه طلبك بشكل صحيح.',
    'contact_phone': 'رقم التواصل',
    'preferred_location': 'الموقع القريب المفضل',
    'save_pending_agent_cashout': 'حفظ طلب سحب الوكيل',
    'cashout_crypto_panel_title': 'طلب سحب العملات الرقمية',
    'cashout_crypto_panel_body':
        'يبقى هذا الطلب معلقًا حتى تتم معالجته يدويًا خلال يوم عمل واحد.',
    'wallet_address_field': 'عنوان المحفظة',
    'save_pending_crypto_cashout': 'حفظ طلب سحب العملات الرقمية',
    'cashout_wish_panel_title': 'مسار التواصل لـ Wish Money',
    'cashout_wish_panel_body':
        'سحب Wish Money يتم عبر طرف ثالث. تواصل مع @number للمتابعة.',
    'contact_wish_support': 'التواصل مع دعم Wish Money',
    'cashout_wish_contact_message':
        'تواصل مع رقم الدعم أدناه لإتمام سحب Wish Money.',
    'cashout_pending_saved': 'تم حفظ طلب السحب كمعلق.',
    'recent_cashout_requests': 'أحدث طلبات السحب',
    'coming_soon': 'قريبًا',
    'wallet_card_brand': 'INFINITY WALLET',
    'wallet_card_teaser': 'قريبًا بطاقة Visa فعلية وافتراضية',
    'wallet_add_money_summary':
        'العملات الرقمية فورية، وWish معلقة، والبطاقة بانتظار المراجعة',
    'wallet_cash_out_summary':
        'طلبات البطاقة أو الوكيل أو العملات الرقمية مع متابعة معلقة',
    'receive_money_body':
        'استخدم رقم محفظتك أو رمز QR لاستلام التحويلات من محفظة إلى محفظة بشكل فوري.',
    'pending_operations': 'العمليات المعلقة',
    'request_kind_add_money': 'إضافة أموال',
    'request_kind_cash_out': 'سحب أموال',
    'request_status_pending': 'قيد الانتظار',
    'request_status_confirmed': 'مؤكد',
    'request_status_rejected': 'مرفوض',
    'request_method_wish': 'Wish Money',
    'request_method_card': 'Visa / Mastercard',
    'request_method_crypto': 'العملات الرقمية',
    'request_method_agent': 'الوكيل',
  };

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': _english,
        'ar_IQ': _arabic,
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
