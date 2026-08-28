class CardNumberPolicy {
  CardNumberPolicy._();

  static const String asciiDigits = '0123456789';

  static String toAsciiDigits(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static int? parseAsciiInteger(String value) {
    final normalized = toAsciiDigits(value.trim());
    if (normalized.isEmpty || !RegExp(r'^\d+$').hasMatch(normalized)) {
      return null;
    }
    return int.tryParse(normalized);
  }

  static bool isAsciiDigitsOnly(String value) {
    return value.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(value);
  }
}
