/// Deterministic money maths. The AI only reads amounts; every rupee
/// decision is made here.
library;

const notes = [500, 200, 100, 50, 20, 10];
const coins = [5, 2, 1];
const allDenominations = [...notes, ...coins];

class PayPlan {
  final int price;
  final List<int> hand; // notes to hand over, largest first
  int get paid => hand.fold(0, (a, b) => a + b);
  int get change => paid - price;
  const PayPlan(this.price, this.hand);
}

/// "Next rupee up": round the price up to the next ₹10 and pay that with
/// as few notes as possible. ₹47 -> [50], change ₹3.
PayPlan nextRupeeUp(int price) {
  if (price <= 0) throw ArgumentError.value(price, 'price', 'must be > 0');
  final target = ((price + 9) ~/ 10) * 10;
  return PayPlan(price, breakDown(target, notes));
}

/// Greedy split of [amount] into [denoms]. Exact for Indian denominations.
List<int> breakDown(int amount, [List<int> denoms = allDenominations]) {
  final out = <int>[];
  var left = amount;
  for (final d in denoms) {
    while (left >= d) {
      out.add(d);
      left -= d;
    }
  }
  return out;
}

enum ChangeStatus { correct, tooLittle, tooMuch }

class ChangeResult {
  final ChangeStatus status;
  final int expected;
  final int received;
  int get difference => (expected - received).abs();
  const ChangeResult(this.status, this.expected, this.received);
}

ChangeResult checkChange({
  required int price,
  required int paid,
  required List<int> received,
}) {
  final expected = paid - price;
  final got = received.fold(0, (a, b) => a + b);
  final status = got == expected
      ? ChangeStatus.correct
      : got < expected
          ? ChangeStatus.tooLittle
          : ChangeStatus.tooMuch;
  return ChangeResult(status, expected, got);
}
