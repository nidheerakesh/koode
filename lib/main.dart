import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'features/caregiver/caregiver_screen.dart';
import 'features/home/home_check_screen.dart';
import 'features/money/change_check_screen.dart';
import 'features/money/pay_helper_screen.dart';
import 'features/safety/safety_screens.dart';
import 'features/travel/is_my_bus_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load();
  runApp(const KoodeApp());
}

class KoodeApp extends StatelessWidget {
  const KoodeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Koode',
        debugShowCheckedModeBanner: false,
        theme: koodeTheme(),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _go(BuildContext c, Widget w) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('കൂടെ · Koode'),
          actions: [
            IconButton(
              tooltip: 'Caregiver',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => openCaregiver(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Bi('നമസ്കാരം, ${app.profile.userName}!',
                  'Hello, ${app.profile.userName}!',
                  size: 28),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  BigTile(
                      icon: Icons.payments_rounded,
                      ml: 'എന്ത് കൊടുക്കണം?',
                      en: 'What do I give?',
                      color: K.money,
                      onTap: () => _go(context, const PayHelperScreen())),
                  BigTile(
                      icon: Icons.fact_check_rounded,
                      ml: 'ബാക്കി ശരിയാണോ?',
                      en: 'Is my change right?',
                      color: K.money,
                      onTap: () => _go(context, const ChangeCheckScreen())),
                  BigTile(
                      icon: Icons.directions_bus_rounded,
                      ml: 'എന്റെ ബസ് ആണോ?',
                      en: 'Is this my bus?',
                      color: K.travel,
                      onTap: () => _go(context, const IsMyBusScreen())),
                  BigTile(
                      icon: Icons.home_rounded,
                      ml: 'വീട് നോക്കാം',
                      en: 'Leaving-home check',
                      color: K.home,
                      onTap: () => _go(context, const HomeCheckScreen())),
                  BigTile(
                      icon: Icons.call_rounded,
                      ml: 'വിളിക്കാം',
                      en: 'Call someone',
                      color: K.teal,
                      onTap: () => _go(context, const SafePeopleScreen())),
                  BigTile(
                      icon: Icons.front_hand_rounded,
                      ml: 'വഴി തെറ്റി',
                      en: "I'm lost",
                      color: K.safety,
                      onTap: () => _go(context, const ImLostScreen())),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(app.vision.name,
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ),
          ]),
        ),
      ),
    );
  }
}
