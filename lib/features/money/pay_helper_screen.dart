import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/confidence.dart';
import '../../core/money_logic.dart';
import '../../core/spoken_amount.dart';
import '../../data/app_state.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../../voice/voice.dart';
import 'amount_pad.dart';
import 'change_check_screen.dart';

/// "What do I give?" — shows the exact notes using next-rupee-up.
class PayHelperScreen extends StatefulWidget {
  const PayHelperScreen({super.key});
  @override
  State<PayHelperScreen> createState() => _PayHelperScreenState();
}

class _PayHelperScreenState extends State<PayHelperScreen> {
  bool busy = false;
  PayPlan? plan;
  bool unsure = false;

  Future<void> _fromPhoto() async {
    final bytes = await takePhoto();
    if (bytes == null) return;
    setState(() => busy = true);
    try {
      final r = await app.vision.readAmount(Uint8List.fromList(bytes));
      final v = gate(positive: r.amount != null, confidence: r.confidence);
      if (v == Verdict.yes) {
        _show(r.amount!);
      } else {
        _notSure();
      }
    } catch (_) {
      _notSure();
    }
  }

  Future<void> _fromVoice() async {
    setState(() => busy = true);
    await voice.say('വില പറയൂ');
    final words = await voice.listenOnce();
    final amount = words == null ? null : parseSpokenAmount(words);
    if (amount != null && amount > 0) {
      _show(amount);
    } else {
      _notSure();
    }
  }

  Future<void> _fromPad() async {
    final a = await askAmount(context, 'വില എത്ര? · What is the price?');
    if (a != null) _show(a);
  }

  void _notSure() {
    setState(() {
      busy = false;
      plan = null;
      unsure = true;
    });
    voice.say('എനിക്ക് ഉറപ്പില്ല. വീണ്ടും ശ്രമിക്കൂ, അല്ലെങ്കിൽ സഹായം ചോദിക്കൂ.');
  }

  void _show(int price) {
    final p = nextRupeeUp(price);
    setState(() {
      busy = false;
      unsure = false;
      plan = p;
    });
    app.lastPayment = p;
    final notesMl = p.hand.map((n) => '$n').join(', ');
    voice.say('$notesMl രൂപ കൊടുക്കൂ. '
        '${p.change > 0 ? '${p.change} രൂപ തിരികെ കിട്ടും.' : 'ബാക്കി ഇല്ല.'}');
    app.addLog('Paid for something costing ₹$price');
  }

  @override
  Widget build(BuildContext context) {
    final p = plan;
    return Scaffold(
      appBar: AppBar(title: const Text('എന്ത് കൊടുക്കണം?')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (busy) const Thinking(),
        if (!busy && p != null) ...[
          Bi('വില ₹${p.price}', 'Price ₹${p.price}', size: 30),
          const SizedBox(height: 16),
          const Bi('ഇത് കൊടുക്കൂ', 'Give this', size: 24),
          const SizedBox(height: 12),
          Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: p.hand.map((n) => MoneyChip(n)).toList()),
          const SizedBox(height: 20),
          ResultPanel(
            verdict: Verdict.yes,
            ml: p.change > 0 ? '₹${p.change} തിരികെ കിട്ടും' : 'ബാക്കി ഇല്ല',
            en: p.change > 0 ? 'You will get ₹${p.change} back' : 'No change',
          ),
          const SizedBox(height: 16),
          if (p.change > 0)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: K.money),
              onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangeCheckScreen())),
              icon: const Icon(Icons.fact_check, size: 32),
              label: const Text('ബാക്കി നോക്കാം · Check change'),
            ),
          const SizedBox(height: 24),
        ],
        if (!busy && unsure) ...[
          const ResultPanel(
              verdict: Verdict.unsure,
              ml: 'എനിക്ക് ഉറപ്പില്ല',
              en: "I'm not sure. Try again or ask for help."),
          const SizedBox(height: 24),
        ],
        if (!busy) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: K.money),
            onPressed: _fromPhoto,
            icon: const Icon(Icons.photo_camera, size: 32),
            label: const Text('വിലയുടെ ഫോട്ടോ · Photo of price'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _fromVoice,
            icon: const Icon(Icons.mic, size: 30),
            label: const Text('കടക്കാരൻ പറയട്ടെ · Shopkeeper says'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _fromPad,
            icon: const Icon(Icons.dialpad, size: 30),
            label: const Text('ഞാൻ ടൈപ്പ് ചെയ്യാം · Type it'),
          ),
        ],
      ]),
    );
  }
}
