class MoneyFormatter {
  static double parseAmount(String raw) {
    final sanitized = raw.trim().replaceAll(',', '.');
    final value = double.tryParse(sanitized);
    if (value == null) return 0;
    return round2(value);
  }

  static double round2(num value) {
    return (value.toDouble() * 100).roundToDouble() / 100;
  }

  static String fixed2(num value) {
    return round2(value).toStringAsFixed(2);
  }

  static String fixed6(num value) {
    return value.toDouble().toStringAsFixed(6);
  }
}
