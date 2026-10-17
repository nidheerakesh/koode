import 'package:flutter_test/flutter_test.dart';
import 'package:koode/core/confidence.dart';
import 'package:koode/core/money_logic.dart';
import 'package:koode/core/route_match.dart';

void main() {
  group('nextRupeeUp', () {
    test('₹47 -> one ₹50, ₹3 back', () {
      final p = nextRupeeUp(47);
      expect(p.hand, [50]);
      expect(p.change, 3);
    });
    test('₹230 -> 200 + 20 + 10', () {
      expect(nextRupeeUp(230).hand, [200, 20, 10]);
    });
    test('always pays enough, change under ₹10, ₹1..2000', () {
      for (var i = 1; i <= 2000; i++) {
        final p = nextRupeeUp(i);
        expect(p.paid >= i, isTrue);
        expect(p.change, inInclusiveRange(0, 9));
        expect(p.hand.every(notes.contains), isTrue);
      }
    });
  });

  group('checkChange', () {
    test('correct', () {
      final r = checkChange(price: 47, paid: 50, received: [2, 1]);
      expect(r.status, ChangeStatus.correct);
    });
    test('too little', () {
      final r = checkChange(price: 35, paid: 50, received: [10]);
      expect(r.status, ChangeStatus.tooLittle);
      expect(r.difference, 5);
    });
  });

  group('route match', () {
    const ktm = ['Kottayam', 'കോട്ടയം', 'KTM'];
    test('exact Malayalam', () => expect(isMyBus(['കോട്ടയം'], ktm), isTrue));
    test('board with via', () =>
        expect(isMyBus(['KOTTAYAM via Ettumanoor'], ktm), isTrue));
    test('spelling variant', () => expect(isMyBus(['Kotayam'], ktm), isTrue));
    test('other place', () => expect(isMyBus(['Pala', 'പാലാ'], ktm), isFalse));
  });

  group('confidence gate', () {
    test('low confidence is unsure', () {
      expect(gate(positive: true, confidence: 0.5), Verdict.unsure);
    });
    test('safety bar is stricter', () {
      expect(gate(positive: true, confidence: 0.8, threshold: safetyThreshold),
          Verdict.unsure);
      expect(gate(positive: true, confidence: 0.9, threshold: safetyThreshold),
          Verdict.yes);
    });
  });
}
