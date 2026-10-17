import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/models.dart';
import '../../ui/theme.dart';

/// PIN gate so the young person doesn't change setup by accident.
Future<void> openCaregiver(BuildContext context) async {
  final ctl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Caregiver PIN'),
      content: TextField(
        controller: ctl,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(helperText: 'Default PIN: 1234'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () =>
                Navigator.pop(context, ctl.text == app.profile.pin),
            child: const Text('Open')),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const CaregiverScreen()));
  }
}

class CaregiverScreen extends StatelessWidget {
  const CaregiverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Caregiver'),
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'Today'),
            Tab(text: 'Trips'),
            Tab(text: 'Home check'),
            Tab(text: 'People'),
          ]),
        ),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) => TabBarView(children: [
            const _ActivityTab(),
            _TripsTab(),
            _ChecklistTab(),
            _PeopleTab(),
          ]),
        ),
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();
  @override
  Widget build(BuildContext context) {
    if (app.log.isEmpty) {
      return const Center(child: Text('Nothing yet today.'));
    }
    return ListView(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text("${app.profile.userName}'s day",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      for (final e in app.log)
        ListTile(
          leading: Icon(
              e.text.contains('✓') ? Icons.check_circle : Icons.info_outline,
              color: e.text.contains('✓') ? K.yes : K.unsure),
          title: Text(e.text),
          subtitle: Text(
              '${e.at.hour.toString().padLeft(2, '0')}:${e.at.minute.toString().padLeft(2, '0')}'),
        ),
      TextButton(onPressed: app.clearLog, child: const Text('Clear')),
    ]);
  }
}

Future<List<String>?> _form(BuildContext context, String title,
    List<String> labels, [List<String>? initial]) {
  final ctls = [
    for (var i = 0; i < labels.length; i++)
      TextEditingController(text: initial?[i] ?? '')
  ];
  return showDialog<List<String>>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < labels.length; i++)
            TextField(
                controller: ctls[i],
                decoration: InputDecoration(labelText: labels[i])),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () =>
                Navigator.pop(context, ctls.map((c) => c.text.trim()).toList()),
            child: const Text('Save')),
      ],
    ),
  );
}

Widget _addButton(VoidCallback onTap, String label) => Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
          onPressed: onTap, icon: const Icon(Icons.add), label: Text(label)),
    );

class _TripsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final trips = app.profile.trips;
    return ListView(children: [
      for (var i = 0; i < trips.length; i++)
        ListTile(
          title: Text(trips[i].name),
          subtitle: Text('Board says: ${trips[i].destinationAliases.join(', ')}'
              '${trips[i].stopLat == null ? '' : '\nStop: ${trips[i].stopLat}, ${trips[i].stopLng}'}'),
          isThreeLine: trips[i].stopLat != null,
          trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                app.profile.trips = [...trips]..removeAt(i);
                app.saveProfile();
              }),
        ),
      _addButton(() async {
        final v = await _form(context, 'New trip', [
          'Trip name (e.g. Home → BUDS Centre)',
          'Names on the bus board, comma separated (കോട്ടയം, Kottayam)',
          'Stop latitude (optional)',
          'Stop longitude (optional)',
        ]);
        if (v == null || v[0].isEmpty || v[1].isEmpty) return;
        app.profile.trips = [
          ...trips,
          Trip(v[0], v[1].split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
              stopLat: double.tryParse(v[2]), stopLng: double.tryParse(v[3])),
        ];
        app.saveProfile();
      }, 'Add trip'),
    ]);
  }
}

class _ChecklistTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final list = app.profile.checklist;
    return ListView(children: [
      for (var i = 0; i < list.length; i++)
        ListTile(
          title: Text('${list[i].labelMl} · ${list[i].labelEn}'),
          subtitle: Text('Must be: ${list[i].targetState}'),
          trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                app.profile.checklist = [...list]..removeAt(i);
                app.saveProfile();
              }),
        ),
      _addButton(() async {
        final v = await _form(context, 'New check item', [
          'Malayalam name (ഗ്യാസ്)',
          'English name (Gas knob)',
          'Safe state (turned off)',
        ]);
        if (v == null || v.any((s) => s.isEmpty)) return;
        app.profile.checklist = [...list, CheckItem(v[0], v[1], v[2])];
        app.saveProfile();
      }, 'Add item'),
    ]);
  }
}

class _PeopleTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = app.profile;
    return ListView(children: [
      ListTile(
        leading: const Icon(Icons.badge),
        title: Text('Name: ${p.userName}'),
        subtitle: Text('PIN: ${'•' * p.pin.length}'),
        trailing: const Icon(Icons.edit),
        onTap: () async {
          final v = await _form(
              context, 'Profile', ['Name', 'Caregiver PIN'], [p.userName, p.pin]);
          if (v == null || v[0].isEmpty || v[1].length < 4) return;
          p
            ..userName = v[0]
            ..pin = v[1];
          app.saveProfile();
        },
      ),
      const Divider(),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('Safe people (first one gets alerts)'),
      ),
      for (var i = 0; i < p.contacts.length; i++)
        ListTile(
          leading: const Icon(Icons.person),
          title: Text(p.contacts[i].name),
          subtitle: Text(p.contacts[i].phone),
          trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                p.contacts = [...p.contacts]..removeAt(i);
                app.saveProfile();
              }),
        ),
      _addButton(() async {
        final v = await _form(context, 'New safe person', ['Name', 'Phone']);
        if (v == null || v.any((s) => s.isEmpty)) return;
        p.contacts = [...p.contacts, Contact(v[0], v[1])];
        app.saveProfile();
      }, 'Add person'),
    ]);
  }
}
