import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Calm Malayalam voice out, Malayalam speech in.
/// Bhashini can replace these platform engines behind the same API.
class Voice {
  final _tts = FlutterTts();
  final _stt = SpeechToText();
  bool _ttsReady = false;

  Future<void> say(String malayalam) async {
    try {
      if (!_ttsReady) {
        await _tts.setLanguage('ml-IN');
        await _tts.setSpeechRate(0.4);
        _ttsReady = true;
      }
      await _tts.stop();
      await _tts.speak(malayalam);
    } catch (_) {
      // Voice is a helper; the screen always shows the same message.
    }
  }

  /// Listens once and returns the recognised words, or null.
  Future<String?> listenOnce() async {
    try {
      if (!await _stt.initialize()) return null;
      String? result;
      await _stt.listen(
        listenOptions: SpeechListenOptions(
            localeId: 'ml_IN', listenFor: const Duration(seconds: 6)),
        onResult: (r) {
          if (r.finalResult) result = r.recognizedWords;
        },
      );
      for (var i = 0; i < 70 && result == null && _stt.isListening; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      await _stt.stop();
      return result ?? _stt.lastRecognizedWords;
    } catch (_) {
      return null;
    }
  }
}

final voice = Voice();
