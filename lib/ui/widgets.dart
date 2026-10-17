import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/confidence.dart';
import 'theme.dart';

/// Malayalam first, English underneath.
class Bi extends StatelessWidget {
  final String ml, en;
  final double size;
  final Color? color;
  final TextAlign align;
  const Bi(this.ml, this.en,
      {super.key, this.size = 26, this.color, this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    final c = color ?? K.ink;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(ml,
            textAlign: align,
            style: TextStyle(
                fontSize: size, fontWeight: FontWeight.w700, color: c)),
        Text(en,
            textAlign: align,
            style: TextStyle(fontSize: size * 0.6, color: c.withAlpha(190))),
      ],
    );
  }
}

class BigTile extends StatelessWidget {
  final IconData icon;
  final String ml, en;
  final Color color;
  final VoidCallback onTap;
  const BigTile(
      {super.key,
      required this.icon,
      required this.ml,
      required this.en,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 52, color: Colors.white),
              const SizedBox(height: 8),
              Bi(ml, en, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one big answer: green yes, red no, amber "not sure".
class ResultPanel extends StatelessWidget {
  final Verdict verdict;
  final String ml, en;
  final Widget? extra;
  const ResultPanel(
      {super.key,
      required this.verdict,
      required this.ml,
      required this.en,
      this.extra});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (verdict) {
      Verdict.yes => (K.yes, Icons.check_circle_rounded),
      Verdict.no => (K.no, Icons.cancel_rounded),
      Verdict.unsure => (K.unsure, Icons.help_rounded),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(28)),
      child: Column(children: [
        Icon(icon, size: 96, color: Colors.white),
        const SizedBox(height: 8),
        Bi(ml, en, size: 32, color: Colors.white),
        if (extra != null) ...[const SizedBox(height: 16), extra!],
      ]),
    );
  }
}

/// A simple drawn rupee note or coin. Colours echo the real notes.
class MoneyChip extends StatelessWidget {
  final int value;
  const MoneyChip(this.value, {super.key});

  static const _colors = {
    500: Color(0xFF8E9A8C),
    200: Color(0xFFE3A33B),
    100: Color(0xFF9B8FC2),
    50: Color(0xFF5FB3B3),
    20: Color(0xFFB9C94F),
    10: Color(0xFFB07A4F),
  };

  @override
  Widget build(BuildContext context) {
    final isCoin = value < 10;
    final label = Text('₹$value',
        style: TextStyle(
            fontSize: isCoin ? 22 : 30,
            fontWeight: FontWeight.w800,
            color: K.ink));
    if (isCoin) {
      return Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD9D4C7),
            border: Border.all(color: const Color(0xFF9A9384), width: 3)),
        child: label,
      );
    }
    return Container(
      width: 132,
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: _colors[value] ?? Colors.grey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black26, width: 2)),
      child: label,
    );
  }
}

class Thinking extends StatelessWidget {
  const Thinking({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(32),
        child: Column(children: [
          CircularProgressIndicator(strokeWidth: 6),
          SizedBox(height: 16),
          Bi('നോക്കുന്നു…', 'Looking…', size: 24),
        ]),
      );
}

/// Opens the camera (a file picker on web). Returns JPEG bytes or null.
Future<List<int>?> takePhoto() async {
  final x = await ImagePicker().pickImage(
      source: ImageSource.camera, maxWidth: 1280, imageQuality: 80);
  return x?.readAsBytes();
}

/// For showing a phrase to the shopkeeper: large, high contrast.
class PhraseCard extends StatelessWidget {
  final String ml, en;
  const PhraseCard(this.ml, this.en, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: K.ink, width: 3)),
        child: Bi(ml, en, size: 28),
      );
}
