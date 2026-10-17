import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_state.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../../voice/voice.dart';

/// "I'm lost" card to hand to a shopkeeper or police officer.
class ImLostScreen extends StatefulWidget {
  const ImLostScreen({super.key});
  @override
  State<ImLostScreen> createState() => _ImLostScreenState();
}

class _ImLostScreenState extends State<ImLostScreen> {
  String? sent;

  @override
  void initState() {
    super.initState();
    final p = app.profile;
    final c = p.contacts.firstOrNull;
    voice.say('എന്റെ പേര് ${p.userName}. എനിക്ക് വഴി തെറ്റി. '
        '${c == null ? '' : 'ദയവായി ${c.name}യെ വിളിക്കാമോ?'}');
    app.addLog('Used the "I\'m lost" card');
  }

  Future<void> _sendLocation() async {
    final c = app.profile.contacts.firstOrNull;
    if (c == null) return;
    var where = '';
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 10));
      where = ' https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
    } catch (_) {}
    final msg = Uri.encodeComponent(
        '${app.profile.userName} needs help (Koode).$where');
    await launchUrl(Uri.parse('sms:${c.phone}?body=$msg'));
    setState(() => sent = c.name);
  }

  @override
  Widget build(BuildContext context) {
    final p = app.profile;
    final c = p.contacts.firstOrNull;
    final trip = p.trips.firstOrNull;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('എനിക്ക് സഹായം വേണം')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              border: Border.all(color: K.safety, width: 4),
              borderRadius: BorderRadius.circular(24)),
          child: Column(children: [
            const Bi('എനിക്ക് വഴി തെറ്റി', 'I am lost. Please help me.',
                size: 34),
            const Divider(height: 32),
            Bi('പേര്: ${p.userName}', 'Name: ${p.userName}', size: 28),
            if (c != null) ...[
              const SizedBox(height: 12),
              Bi('${c.name}: ${c.phone}', 'Please call ${c.name}', size: 28),
            ],
            if (trip != null) ...[
              const SizedBox(height: 12),
              Bi('പോകുന്നത്: ${trip.destinationAliases.first}',
                  'Going to: ${trip.name}',
                  size: 24),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        if (c != null)
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: K.safety),
            onPressed: () => launchUrl(Uri.parse('tel:${c.phone}')),
            icon: const Icon(Icons.call, size: 32),
            label: Text('${c.name}യെ വിളിക്കൂ · Call ${c.name}'),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _sendLocation,
          icon: const Icon(Icons.location_on, size: 30),
          label: Text(sent == null
              ? 'സ്ഥലം അയക്കൂ · Send my location'
              : 'അയച്ചു · Sent to $sent'),
        ),
      ]),
    );
  }
}

/// Big photo-style buttons to call trusted people.
class SafePeopleScreen extends StatelessWidget {
  const SafePeopleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final people = app.profile.contacts;
    return Scaffold(
      appBar: AppBar(title: const Text('വിളിക്കാം')),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          for (final c in people)
            BigTile(
              icon: Icons.person,
              ml: c.name,
              en: c.phone,
              color: K.teal,
              onTap: () => launchUrl(Uri.parse('tel:${c.phone}')),
            ),
        ],
      ),
    );
  }
}
