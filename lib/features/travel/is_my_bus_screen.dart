import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/confidence.dart';
import '../../core/route_match.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../../voice/voice.dart';
import 'get_off_screen.dart';

/// "Is this my bus?" — AI reads the board, fuzzy match decides.
class IsMyBusScreen extends StatefulWidget {
  const IsMyBusScreen({super.key});
  @override
  State<IsMyBusScreen> createState() => _IsMyBusScreenState();
}

class _IsMyBusScreenState extends State<IsMyBusScreen> {
  Trip? trip;
  bool busy = false;
  Verdict? verdict;
  List<String> board = [];

  @override
  void initState() {
    super.initState();
    final trips = app.profile.trips;
    if (trips.length == 1) trip = trips.first;
  }

  Future<void> _check() async {
    final t = trip!;
    final bytes = await takePhoto();
    if (bytes == null) return;
    setState(() => busy = true);
    Verdict v;
    try {
      final r = await app.vision.readBusBoard(Uint8List.fromList(bytes));
      board = r.placeNames;
      v = gate(
          positive: isMyBus(r.placeNames, t.destinationAliases),
          confidence: r.confidence);
    } catch (_) {
      v = Verdict.unsure;
    }
    setState(() {
      busy = false;
      verdict = v;
    });
    switch (v) {
      case Verdict.yes:
        voice.say('അതെ, കയറിക്കോളൂ!');
        app.addLog('Boarded the bus for ${t.name} ✓');
      case Verdict.no:
        voice.say('ഇല്ല, ഇത് അല്ല. കാത്തിരിക്കൂ.');
      case Verdict.unsure:
        voice.say('എനിക്ക് ഉറപ്പില്ല. കണ്ടക്ടറോട് ചോദിക്കൂ.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final trips = app.profile.trips;
    return Scaffold(
      appBar: AppBar(title: const Text('എന്റെ ബസ് ആണോ?')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (trip == null) ...[
          const Bi('എവിടേക്ക്?', 'Where are you going?'),
          const SizedBox(height: 16),
          for (final t in trips)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: K.travel),
                onPressed: () => setState(() => trip = t),
                child: Text(t.name),
              ),
            ),
          if (trips.isEmpty)
            const Bi('യാത്രകൾ ഇല്ല', 'No trips yet. Ask Amma to add one.'),
        ] else ...[
          Bi(trip!.destinationAliases.first, trip!.name, size: 30),
          const SizedBox(height: 20),
          if (busy) const Thinking(),
          if (!busy && verdict != null) ...[
            switch (verdict!) {
              Verdict.yes => ResultPanel(
                  verdict: Verdict.yes,
                  ml: 'അതെ, കയറൂ!',
                  en: 'Yes, get on',
                  extra: FilledButton.tonal(
                    onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GetOffScreen(trip: trip!))),
                    child: const Text('ഇറങ്ങേണ്ടത് പറയൂ · Tell me my stop'),
                  )),
              Verdict.no => const ResultPanel(
                  verdict: Verdict.no, ml: 'ഇല്ല, കാത്തിരിക്കൂ', en: 'No, wait'),
              Verdict.unsure => const ResultPanel(
                  verdict: Verdict.unsure,
                  ml: 'ഉറപ്പില്ല',
                  en: 'Not sure. Ask the conductor.'),
            },
            if (board.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('ബോർഡ്: ${board.join(' · ')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16)),
              ),
            const SizedBox(height: 24),
          ],
          if (!busy)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: K.travel),
              onPressed: _check,
              icon: const Icon(Icons.photo_camera, size: 32),
              label: const Text('ബോർഡിന്റെ ഫോട്ടോ · Photo of board'),
            ),
        ],
      ]),
    );
  }
}
