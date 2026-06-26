// Recall · number formatting. Thousands grouping for the editorial mono/Fraunces
// numerals (XP, lifetime counts) — e.g. 1284 → "1,284". No intl dependency; the
// app is en-only for v1, so a fixed comma group is correct and deterministic.

class RecallNumber {
  const RecallNumber._();

  /// Groups [value] into comma-separated thousands. Negative values keep sign.
  static String grouped(int value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return negative ? '-$buffer' : buffer.toString();
  }
}
