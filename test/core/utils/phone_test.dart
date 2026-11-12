import 'package:click_sos/core/utils/phone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toE164 adds +55 to Brazilian numbers and keeps international ones', () {
    expect(toE164('(11) 90000-0001'), '+5511900000001');
    expect(toE164('55 11 90000-0001'), '+5511900000001');
    expect(toE164('+1 415 555 0100'), '+14155550100');
  });

  test('isValidPhone rejects empty or too short numbers', () {
    expect(isValidPhone('(11) 90000-0001'), isTrue);
    expect(isValidPhone(''), isFalse);
    expect(isValidPhone('123'), isFalse);
  });
}
