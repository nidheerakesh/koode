import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/confidence.dart';
import '../../core/money_logic.dart';
import '../../data/app_state.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../../voice/voice.dart';
import 'amount_pad.dart';

/// "Is my change right?" — the AI counts, the code compares.
class ChangeCheckScreen extends StatefulWidget {
  const ChangeCheckScreen({super.key});
  @override
  State<ChangeCheckScreen> createState() => _ChangeCheckScreenState();
}

class _ChangeCheckScreenState extends State<ChangeCheckScreen> {
  bool busy = false;
  ChangeResult? result;
  List<int> seen = [];
  bool unsure = false;

  Future<PayPlan?> _ensurePayment() async {
    if (app.lastPayment != null) return app.lastPayment;
    final price = await askAmount(context, 'വില എത്ര? · What was the price?');
    if (price == null || !mounted) return null;
    final paid = await askAmount(context, 'എത്ര കൊടുത്തു? · How much did you give?');
    if (paid == null || paid < price) return null;
    return app.lastPayment = PayPlan(price, [paid]);
  }

  Future<void> _check() async {
    final pay = await _ensurePayment();
    if (pay == null) return;
    final bytes = await takePhoto();
    if (bytes == null) return;
    setState(() => busy = true);
    try {
      final r = await app.vision.readCurrency(Uint8List.fromList(bytes));
      if (gate(positive: true, confidence: r.confidence) == Verdict.unsure) {
        return _notSure();
      }
      final c = checkChange(price: pay.price, paid: pay.paid, received: r.items);
      setState(() {
        busy = false;
        unsure = false;
        seen = r.items;
        result = c;
      });
      switch (c.status) {
        case ChangeStatus.correct:
          voice.say('ശരിയാണ്! ബാക്കി ശരിയാണ്.');
          app.addLog('Change checked: correct ✓');
        case ChangeStatus.tooLittle:
          voice.say('${c.difference} രൂപ കൂടി വിനയത്തോടെ ചോദിക്കൂ.');
          app.addLog('Change was ₹${c.difference} short — asked for it');
        case ChangeStatus.tooMuch:
          voice.say('${c.difference} രൂപ കൂടുതൽ കിട്ടി. തിരികെ കൊടുക്കൂ.');
      }
    } catch (_) {
      _notSure();
    }
  }

  void _notSure() {
    setState(() {
      busy = false;
      result = null;
      unsure = true;
    });
    voice.say('എനിക്ക് ഉറപ്പില്ല. നോട്ടുകൾ നിരത്തി വെച്ച് വീണ്ടും ഫോട്ടോ എടുക്കൂ.');
  }

  @override
  Widget build(BuildContext context) {
    final c = result;
    return Scaffold(
      appBar: AppBar(title: const Text('ബാക്കി ശരിയാണോ?')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (app.lastPayment != null && c == null && !busy)
          Bi('വേണ്ടത്: ₹${app.lastPayment!.change}',
              'You should get ₹${app.lastPayment!.change} back',
              size: 28),
        if (busy) const Thinking(),
        if (!busy && c != null) ...[
          Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: seen.map((n) => MoneyChip(n)).toList()),
          const SizedBox(height: 16),
          switch (c.status) {
            ChangeStatus.correct => const ResultPanel(
                verdict: Verdict.yes, ml: 'ശരിയാണ്!', en: 'Correct!'),
            ChangeStatus.tooLittle => ResultPanel(
                verdict: Verdict.no,
                ml: '₹${c.difference} കുറവാണ്',
                en: '₹${c.difference} short',
                extra: PhraseCard('ചേട്ടാ/ചേച്ചീ, ₹${c.difference} കൂടി തരാമോ?',
                    'Excuse me, could I have ₹${c.difference} more, please?'),
              ),
            ChangeStatus.tooMuch => ResultPanel(
                verdict: Verdict.no,
                ml: '₹${c.difference} കൂടുതലാണ്',
                en: '₹${c.difference} too much. Give it back.',
              ),
          },
          const SizedBox(height: 24),
        ],
        if (!busy && unsure) ...[
          const ResultPanel(
              verdict: Verdict.unsure,
              ml: 'എനിക്ക് ഉറപ്പില്ല',
              en: 'Spread the notes out and try again.'),
          const SizedBox(height: 24),
        ],
        if (!busy)
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: K.money),
            onPressed: _check,
            icon: const Icon(Icons.photo_camera, size: 32),
            label: const Text('ബാക്കിയുടെ ഫോട്ടോ · Photo of change'),
          ),
      ]),
    );
  }
}
