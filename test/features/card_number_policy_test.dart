import 'package:flutter_test/flutter_test.dart';

import 'package:mikrotik_manager/services/card_number_policy.dart';

void main() {
  test('يحوّل الأرقام العربية إلى ASCII', () {
    expect(CardNumberPolicy.toAsciiDigits('١٢٣٤٥'), '12345');
    expect(CardNumberPolicy.toAsciiDigits('۱۲۳۴۵'), '12345');
    expect(CardNumberPolicy.isAsciiDigitsOnly('12345'), isTrue);
    expect(CardNumberPolicy.isAsciiDigitsOnly('١٢٣٤٥'), isFalse);
  });

  test('يقرأ القيم الرقمية بعد التطبيع ويمنع النصوص', () {
    expect(CardNumberPolicy.parseAsciiInteger(' ١٠ '), 10);
    expect(CardNumberPolicy.parseAsciiInteger('10'), 10);
    expect(CardNumberPolicy.parseAsciiInteger('10a'), isNull);
  });
}
