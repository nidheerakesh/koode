import 'dart:typed_data';

/// What the AI read from a photo. Readings only, never decisions.
class AmountReading {
  final int? amount;
  final double confidence;
  const AmountReading(this.amount, this.confidence);
}

class CurrencyReading {
  /// Denominations seen, e.g. [2, 1] for a ₹2 and a ₹1 coin.
  final List<int> items;
  final double confidence;
  const CurrencyReading(this.items, this.confidence);
}

class BoardReading {
  final List<String> placeNames;
  final double confidence;
  const BoardReading(this.placeNames, this.confidence);
}

class ItemReading {
  /// true = in the safe state the caregiver asked for (gas off, door locked).
  final bool? inTargetState;
  final double confidence;
  const ItemReading(this.inTargetState, this.confidence);
}

abstract class VisionService {
  String get name;
  Future<AmountReading> readAmount(Uint8List image);
  Future<CurrencyReading> readCurrency(Uint8List image);
  Future<BoardReading> readBusBoard(Uint8List image);
  Future<ItemReading> checkItem(Uint8List image,
      {required String item, required String targetState});
}
