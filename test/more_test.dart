import 'package:flutter_test/flutter_test.dart';
import 'package:koode/core/spoken_amount.dart';
import 'package:koode/features/travel/get_off_screen.dart';

void main() {
  group('spoken amount', () {
    test('digits', () => expect(parseSpokenAmount('47 രൂപ'), 47));
    test('Malayalam digits', () => expect(parseSpokenAmount('൪൭'), 47));
    test('Malayalam words', () {
      expect(parseSpokenAmount('മുപ്പത്തിയഞ്ച് രൂപ'), 35);
      expect(parseSpokenAmount('അമ്പത് രൂപ'), 50);
      expect(parseSpokenAmount('പത്ത്'), 10);
      expect(parseSpokenAmount('നാല്പത്'), 40);
      expect(parseSpokenAmount('നാല്പത്തിയേഴ്'), 47);
      expect(parseSpokenAmount('നാല്'), 4);
    });
    test('English words', () {
      expect(parseSpokenAmount('forty seven rupees'), 47);
      expect(parseSpokenAmount('two hundred'), 200);
    });
    test('nothing', () => expect(parseSpokenAmount('hello'), isNull));
  });

  group('stop phase', () {
    test('far', () => expect(stopPhase(2000, 2000), StopPhase.riding));
    test('next', () => expect(stopPhase(400, 400), StopPhase.next));
    test('arrived', () => expect(stopPhase(50, 50), StopPhase.arrived));
    test('passed', () => expect(stopPhase(300, 100), StopPhase.passed));
  });
}
