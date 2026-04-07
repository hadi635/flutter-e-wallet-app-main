import 'package:ewallet/utils/money_formatter.dart';

class MoonPayService {
  static const String apiKey = String.fromEnvironment(
    'MOONPAY_API_KEY',
    defaultValue: '',
  );
  static const String environment = String.fromEnvironment(
    'MOONPAY_ENVIRONMENT',
    defaultValue: 'sandbox',
  );
  static const String defaultCurrencyCode = String.fromEnvironment(
    'MOONPAY_DEFAULT_CURRENCY_CODE',
    defaultValue: 'usdc_sol',
  );
  static const String defaultBaseCurrencyCode = String.fromEnvironment(
    'MOONPAY_BASE_CURRENCY_CODE',
    defaultValue: 'usd',
  );
  static const String theme = String.fromEnvironment(
    'MOONPAY_THEME',
    defaultValue: 'dark',
  );
  static const String redirectUrl = String.fromEnvironment(
    'MOONPAY_REDIRECT_URL',
    defaultValue: '',
  );

  static const Set<String> _unsupportedCountries = {
    'Afghanistan',
    'American Samoa',
    'Bangladesh',
    'Barbados',
    'Burkina Faso',
    'China',
    'Cuba',
    'Guinea-Bissau',
    'Haiti',
    'Iran',
    'Iraq',
    'Jamaica',
    'Japan',
    'Kosovo',
    'Lebanon',
    'Libya',
    'Macao SAR, China',
    'Madagascar',
    'Malaysia',
    'Mongolia',
    'Morocco',
    'Myanmar',
    'Nicaragua',
    'Nigeria',
    'Korea, North',
    'Oman',
    'Pakistan',
    'Palestine',
    'Panama',
    'Russia',
    'Senegal',
    'Somalia',
    'South Sudan',
    'Syrian Arab Republic',
    'Tajikistan',
    'Timor-Leste',
    'The Democratic Republic Of The Congo',
    'Uganda',
    'Ukraine',
    'United States Virgin Islands',
    'Venezuela',
    'Western Sahara',
    'Yemen',
    'Zimbabwe',
    'Hungary',
  };

  bool get isConfigured => apiKey.trim().isNotEmpty;

  bool isCountrySupported(String? country) {
    final normalized = (country ?? '').trim();
    if (normalized.isEmpty) return false;
    return !_unsupportedCountries.contains(normalized);
  }

  Uri buildBuyUri({
    required double amount,
  }) {
    if (!isConfigured) {
      throw Exception(
        'Missing MOONPAY_API_KEY. Add --dart-define=MOONPAY_API_KEY=pk_test_...',
      );
    }

    final host = environment.trim().toLowerCase() == 'production'
        ? 'buy.moonpay.com'
        : 'buy-sandbox.moonpay.com';

    final params = <String, String>{
      'apiKey': apiKey,
      'baseCurrencyCode': defaultBaseCurrencyCode,
      'baseCurrencyAmount': MoneyFormatter.fixed2(amount),
      'defaultCurrencyCode': defaultCurrencyCode,
      'paymentMethod': 'credit_debit_card',
      'theme': theme,
    };

    final normalizedRedirect = redirectUrl.trim();
    if (normalizedRedirect.isNotEmpty) {
      params['redirectURL'] = normalizedRedirect;
    }

    return Uri.https(host, '/', params);
  }
}
