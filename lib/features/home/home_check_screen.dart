import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/confidence.dart';
import '../../data/app_state.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../../voice/voice.dart';

/// Leaving-home check. A "yes" needs the stricter safety threshold.
class HomeCheckScreen extends StatefulWidget {
  const HomeCheckScreen({super.key});
  @override
  State<HomeCheckScreen> createState() => _HomeCheckScreenState();
}

class _HomeCheckScreenState extends State<HomeCheckScreen> {
  int step = 0;
  bool busy = false;
  Verdict? last;

  Future<void> _check() async {
    final item = app.profile.checklist[step];
    final bytes = await takePhoto();
    if (bytes == null) return;
    setState(() => busy = true);
    Verdict v;
    try {
      final r = await app.vision.checkItem(Uint8List.fromList(bytes),
          item: item.labelEn, targetState: item.targetState);
      v = r.inTargetState == null
          ? Verdict.unsure
          : gate(
              positive: r.inTargetState!,
              confidence: r.confidence,
              threshold: safetyThreshold);
    } catch (_) {
      v = Verdict.unsure;
    }
    setState(() {
      busy = false;
      last = v;
    });
    switch (v) {
      case Verdict.yes:
        voice.say('${item.labelMl} ശരിയാണ്.');
      case Verdict.no:
        voice.say('${item.labelMl} ശരിയാക്കിയിട്ട് വീണ്ടും നോക്കൂ.');
      case Verdict.unsure:
        voice.say('എനിക്ക് ഉറപ്പില്ല. അടുത്ത് നിന്ന് വീണ്ടും ഫോട്ടോ എടുക്കൂ.');
    }
  }

  void _next() {
    setState(() {
      step++;
      last = null;
    });
    if (step == app.profile.checklist.length) {
      voice.say('എല്ലാം ശരിയാണ്. വീട് സുരക്ഷിതമാണ്.');
      app.addLog('House check complete ✓');
    }
  }

  Future<void> _tellParent() async {
    final c = app.profile.contacts.firstOrNull;
    if (c == null) return;
    final msg = Uri.encodeComponent(
        '${app.profile.userName}: House check complete ✓ (Koode)');
    await launchUrl(Uri.parse('sms:${c.phone}?body=$msg'));
  }

  @override
  Widget build(BuildContext context) {
    final list = app.profile.checklist;
    final done = step >= list.length;
    return Scaffold(
      appBar: AppBar(title: const Text('വീട് നോക്കാം')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < list.length; i++)
              Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                    i < step ? Icons.check_circle : Icons.circle_outlined,
                    color: i < step ? K.yes : Colors.black38,
                    size: 36),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (done) ...[
          const ResultPanel(
              verdict: Verdict.yes,
              ml: 'വീട് സുരക്ഷിതം ✓',
              en: 'House is safe'),
          const SizedBox(height: 16),
          for (final i in list)
            ListTile(
              leading: const Icon(Icons.check, color: K.yes, size: 32),
              title: Text('${i.labelMl} · ${i.labelEn}',
                  style: const TextStyle(fontSize: 20)),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: K.home),
            onPressed: _tellParent,
            icon: const Icon(Icons.send, size: 30),
            label: const Text('അമ്മയോട് പറയൂ · Tell Amma'),
          ),
        ] else ...[
          Bi(list[step].labelMl, list[step].labelEn, size: 40),
          Text(list[step].targetState,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          if (busy) const Thinking(),
          if (!busy && last != null) ...[
            switch (last!) {
              Verdict.yes => ResultPanel(
                  verdict: Verdict.yes,
                  ml: '${list[step].labelMl} ശരി ✓',
                  en: '${list[step].labelEn}: ${list[step].targetState}'),
              Verdict.no => ResultPanel(
                  verdict: Verdict.no,
                  ml: 'ശരിയാക്കൂ',
                  en: 'Make it ${list[step].targetState}, then check again'),
              Verdict.unsure => const ResultPanel(
                  verdict: Verdict.unsure,
                  ml: 'ഉറപ്പില്ല',
                  en: 'Not sure. Take a closer photo, or ask for help.'),
            },
            const SizedBox(height: 16),
          ],
          if (!busy && last == Verdict.yes)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: K.home),
              onPressed: _next,
              child: const Text('അടുത്തത് · Next'),
            )
          else if (!busy)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: K.home),
              onPressed: _check,
              icon: const Icon(Icons.photo_camera, size: 32),
              label: const Text('ഫോട്ടോ എടുക്കൂ · Take photo'),
            ),
        ],
      ]),
    );
  }
}
