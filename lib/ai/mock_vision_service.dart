import 'dart:typed_data';

import 'vision_service.dart';

/// Scripted readings for the demo (Anu's day) and for running without a key.
class MockVisionService implements VisionService {
  int _board = 0, _change = 0;

  @override
  String get name => 'Demo mode (no AI key)';

  Future<void> _think() => Future.delayed(const Duration(milliseconds: 600));

  @override
  Future<AmountReading> readAmount(Uint8List image) async {
    await _think();
    return const AmountReading(35, 0.95);
  }

  /// First check: shopkeeper gives ₹2 short. Then correct change.
  @override
  Future<CurrencyReading> readCurrency(Uint8List image) async {
    await _think();
    return (_change++ % 2 == 0)
        ? const CurrencyReading([2, 1], 0.93)
        : const CurrencyReading([5], 0.93);
  }

  /// First board is the wrong bus, second is right.
  @override
  Future<BoardReading> readBusBoard(Uint8List image) async {
    await _think();
    return (_board++ % 2 == 0)
        ? const BoardReading(['പാലാ', 'Pala', 'ഈരാറ്റുപേട്ട'], 0.9)
        : const BoardReading(['കോട്ടയം', 'Kottayam', 'വഴി ഏറ്റുമാനൂർ'], 0.9);
  }

  @override
  Future<ItemReading> checkItem(Uint8List image,
      {required String item, required String targetState}) async {
    await _think();
    return const ItemReading(true, 0.92);
  }
}
