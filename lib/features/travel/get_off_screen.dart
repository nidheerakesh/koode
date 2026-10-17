import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/confidence.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../../voice/voice.dart';

enum StopPhase { riding, next, arrived, passed }

/// Pure: decide the phase from the current and closest distances (metres).
StopPhase stopPhase(double distance, double closest) {
  if (distance <= 80) return StopPhase.arrived;
  if (closest <= 150 && distance > closest + 150) return StopPhase.passed;
  if (distance <= 500) return StopPhase.next;
  return StopPhase.riding;
}

class GetOffScreen extends StatefulWidget {
  final Trip trip;
  const GetOffScreen({super.key, required this.trip});
  @override
  State<GetOffScreen> createState() => _GetOffScreenState();
}

class _GetOffScreenState extends State<GetOffScreen> {
  StreamSubscription<dynamic>? _sub;
  double? distance;
  double closest = double.infinity;
  StopPhase phase = StopPhase.riding;
  bool simulated = false;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _update(double d) {
    closest = d < closest ? d : closest;
    final p = stopPhase(d, closest);
    if (p != phase) {
      HapticFeedback.heavyImpact();
      switch (p) {
        case StopPhase.next:
          voice.say('അടുത്ത സ്റ്റോപ്പ് നിങ്ങളുടേതാണ്. തയ്യാറാകൂ.');
        case StopPhase.arrived:
          voice.say('ഇവിടെ ഇറങ്ങൂ.');
          app.addLog('Reached ${widget.trip.name} ✓');
        case StopPhase.passed:
          voice.say('സ്റ്റോപ്പ് കഴിഞ്ഞു. അടുത്ത സ്റ്റോപ്പിൽ ഇറങ്ങി അമ്മയെ വിളിക്കൂ.');
          app.addLog('Missed the stop for ${widget.trip.name} — told to call');
        case StopPhase.riding:
          break;
      }
    }
    setState(() {
      distance = d;
      phase = p;
    });
  }

  Future<void> _startGps() async {
    final t = widget.trip;
    if (t.stopLat == null) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 20),
    ).listen((pos) => _update(Geolocator.distanceBetween(
        pos.latitude, pos.longitude, t.stopLat!, t.stopLng!)));
  }

  /// Demo: the bus approaches the stop and arrives.
  void _simulate() {
    _sub?.cancel();
    closest = double.infinity;
    phase = StopPhase.riding;
    simulated = true;
    const path = <double>[2400, 1600, 900, 450, 250, 60];
    var i = 0;
    _sub = Stream.periodic(const Duration(seconds: 2), (_) => path[i++])
        .take(path.length)
        .listen(_update);
  }

  @override
  Widget build(BuildContext context) {
    final d = distance;
    return Scaffold(
      appBar: AppBar(title: const Text('എവിടെ ഇറങ്ങണം')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Bi(widget.trip.destinationAliases.first, widget.trip.name, size: 28),
        const SizedBox(height: 20),
        if (d != null)
          switch (phase) {
            StopPhase.riding => ResultPanel(
                verdict: Verdict.yes,
                ml: 'ഇരിക്കൂ. ${(d / 1000).toStringAsFixed(1)} km',
                en: 'Stay seated. I will tell you.'),
            StopPhase.next => const ResultPanel(
                verdict: Verdict.unsure,
                ml: 'അടുത്ത സ്റ്റോപ്പ്!',
                en: 'Your stop is next. Get ready.'),
            StopPhase.arrived => const ResultPanel(
                verdict: Verdict.yes, ml: 'ഇവിടെ ഇറങ്ങൂ', en: 'Get off here'),
            StopPhase.passed => const ResultPanel(
                verdict: Verdict.no,
                ml: 'സ്റ്റോപ്പ് കഴിഞ്ഞു',
                en: 'Stop passed. Get off at the next stop and call Amma.'),
          }
        else
          const Bi('യാത്ര തുടങ്ങാം', 'Start when you are on the bus'),
        const SizedBox(height: 24),
        if (_sub == null) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: K.travel),
            onPressed: widget.trip.stopLat == null ? null : _startGps,
            icon: const Icon(Icons.directions_bus, size: 32),
            label: const Text('ഞാൻ ബസിൽ ആണ് · I am on the bus'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
              onPressed: _simulate,
              child: const Text('ഡെമോ യാത്ര · Demo journey')),
        ],
        if (simulated)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Demo journey (simulated GPS)',
                textAlign: TextAlign.center),
          ),
      ]),
    );
  }
}
