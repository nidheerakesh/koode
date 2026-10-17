class Trip {
  final String name; // "Home → BUDS Centre"
  final List<String> destinationAliases; // ["കോട്ടയം", "Kottayam"]
  final double? stopLat, stopLng;
  const Trip(this.name, this.destinationAliases, {this.stopLat, this.stopLng});

  Map<String, dynamic> toJson() => {
        'name': name,
        'aliases': destinationAliases,
        'lat': stopLat,
        'lng': stopLng,
      };
  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        j['name'] as String,
        (j['aliases'] as List).cast<String>(),
        stopLat: (j['lat'] as num?)?.toDouble(),
        stopLng: (j['lng'] as num?)?.toDouble(),
      );
}

class CheckItem {
  final String labelMl, labelEn; // "ഗ്യാസ്", "Gas knob"
  final String targetState; // "turned off"
  const CheckItem(this.labelMl, this.labelEn, this.targetState);

  Map<String, dynamic> toJson() =>
      {'ml': labelMl, 'en': labelEn, 'target': targetState};
  factory CheckItem.fromJson(Map<String, dynamic> j) =>
      CheckItem(j['ml'] as String, j['en'] as String, j['target'] as String);
}

class Contact {
  final String name, phone;
  const Contact(this.name, this.phone);
  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
  factory Contact.fromJson(Map<String, dynamic> j) =>
      Contact(j['name'] as String, j['phone'] as String);
}

class LogEntry {
  final DateTime at;
  final String text;
  const LogEntry(this.at, this.text);
  Map<String, dynamic> toJson() => {'at': at.toIso8601String(), 'text': text};
  factory LogEntry.fromJson(Map<String, dynamic> j) =>
      LogEntry(DateTime.parse(j['at'] as String), j['text'] as String);
}

class Profile {
  String userName;
  String pin;
  List<Trip> trips;
  List<CheckItem> checklist;
  List<Contact> contacts;

  Profile({
    required this.userName,
    required this.pin,
    required this.trips,
    required this.checklist,
    required this.contacts,
  });

  /// Anu's setup, so the app is usable straight after install.
  factory Profile.demo() => Profile(
        userName: 'Anu',
        pin: '1234',
        trips: const [
          Trip('Home → BUDS Centre', ['കോട്ടയം', 'Kottayam', 'KTM'],
              stopLat: 9.5916, stopLng: 76.5222),
        ],
        checklist: const [
          CheckItem('ഗ്യാസ്', 'Gas knob', 'turned off'),
          CheckItem('വാതിൽ', 'Door lock', 'locked'),
          CheckItem('പൈപ്പ്', 'Water tap', 'closed, no water running'),
        ],
        contacts: const [
          Contact('Amma', '+919800000001'),
          Contact('Achan', '+919800000002'),
          Contact('Teacher', '+919800000003'),
        ],
      );

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'pin': pin,
        'trips': trips.map((e) => e.toJson()).toList(),
        'checklist': checklist.map((e) => e.toJson()).toList(),
        'contacts': contacts.map((e) => e.toJson()).toList(),
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        userName: j['userName'] as String,
        pin: j['pin'] as String,
        trips: (j['trips'] as List)
            .map((e) => Trip.fromJson(e as Map<String, dynamic>))
            .toList(),
        checklist: (j['checklist'] as List)
            .map((e) => CheckItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        contacts: (j['contacts'] as List)
            .map((e) => Contact.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
