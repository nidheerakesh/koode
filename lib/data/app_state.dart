import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai/gemini_vision_service.dart';
import '../ai/mock_vision_service.dart';
import '../ai/vision_service.dart';
import '../core/money_logic.dart';
import 'models.dart';

const _geminiKey = String.fromEnvironment('GEMINI_API_KEY');

class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;
  late Profile profile;
  List<LogEntry> log = [];
  final VisionService vision = _geminiKey.isEmpty
      ? MockVisionService()
      : GeminiVisionService(_geminiKey);

  /// The last pay plan, so Change Check knows what change to expect.
  PayPlan? lastPayment;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs.getString('profile');
    profile = p == null
        ? Profile.demo()
        : Profile.fromJson(jsonDecode(p) as Map<String, dynamic>);
    final l = _prefs.getStringList('log') ?? [];
    log = l
        .map((e) => LogEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveProfile() async {
    await _prefs.setString('profile', jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> addLog(String text) async {
    log.insert(0, LogEntry(DateTime.now(), text));
    if (log.length > 200) log = log.sublist(0, 200);
    await _prefs.setStringList(
        'log', log.map((e) => jsonEncode(e.toJson())).toList());
    notifyListeners();
  }

  Future<void> clearLog() async {
    log = [];
    await _prefs.remove('log');
    notifyListeners();
  }
}

final app = AppState();
