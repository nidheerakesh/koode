import 'package:flutter/material.dart';

/// Calm colours, big type, big targets.
class K {
  static const bg = Color(0xFFF7F4EE);
  static const ink = Color(0xFF1F2A30);
  static const teal = Color(0xFF2E7D74);
  static const yes = Color(0xFF2E8B57);
  static const no = Color(0xFFC0392B);
  static const unsure = Color(0xFFB7791F);
  static const money = Color(0xFF4F7CAC);
  static const travel = Color(0xFF7A5BA6);
  static const home = Color(0xFFC0703A);
  static const safety = Color(0xFFB84A62);
}

ThemeData koodeTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: K.teal, surface: K.bg),
    scaffoldBackgroundColor: K.bg,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: K.ink, displayColor: K.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: K.bg,
      foregroundColor: K.ink,
      centerTitle: true,
      titleTextStyle: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: K.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(72),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
  );
}
