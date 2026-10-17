import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'vision_service.dart';

/// Gemini vision with JSON-schema structured output. Prompts ask only for
/// what is visible; Koode's own code makes every decision.
class GeminiVisionService implements VisionService {
  final String apiKey;
  final String model;
  final http.Client _client;

  GeminiVisionService(this.apiKey,
      {this.model = 'gemini-2.5-flash', http.Client? client})
      : _client = client ?? http.Client();

  @override
  String get name => 'Gemini ($model)';

  Future<Map<String, dynamic>> _ask(
      Uint8List image, String prompt, Map<String, dynamic> schema) async {
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');
    final body = {
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(image),
              }
            },
            {'text': prompt},
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0,
        'responseMimeType': 'application/json',
        'responseSchema': schema,
      },
    };
    final res = await _client
        .post(uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Gemini ${res.statusCode}: ${res.body}');
    }
    final text = jsonDecode(res.body)['candidates'][0]['content']['parts'][0]
        ['text'] as String;
    return jsonDecode(text) as Map<String, dynamic>;
  }

  static const _conf = {
    'type': 'NUMBER',
    'description': '0 to 1. Use a low value if blurry, hidden or unclear.'
  };

  static double _c(Map<String, dynamic> j) =>
      ((j['confidence'] as num?) ?? 0).toDouble().clamp(0, 1);

  @override
  Future<AmountReading> readAmount(Uint8List image) async {
    final j = await _ask(
      image,
      'This is a price tag or bill from an Indian shop. Read the total amount '
      'to pay in rupees. If several prices are visible, return the grand '
      'total. If you cannot read it, return amount 0 and low confidence.',
      {
        'type': 'OBJECT',
        'properties': {'amount': {'type': 'INTEGER'}, 'confidence': _conf},
        'required': ['amount', 'confidence'],
      },
    );
    final a = (j['amount'] as num?)?.round() ?? 0;
    return AmountReading(a > 0 ? a : null, _c(j));
  }

  @override
  Future<CurrencyReading> readCurrency(Uint8List image) async {
    final j = await _ask(
      image,
      'List every Indian rupee note and coin visible, one entry per item, '
      'as its value in rupees (1, 2, 5, 10, 20, 50, 100, 200, 500). '
      'Lower confidence if any item is folded, overlapping or unclear.',
      {
        'type': 'OBJECT',
        'properties': {
          'items': {'type': 'ARRAY', 'items': {'type': 'INTEGER'}},
          'confidence': _conf,
        },
        'required': ['items', 'confidence'],
      },
    );
    final items = (j['items'] as List? ?? []).map((e) => (e as num).round());
    return CurrencyReading(items.toList(), _c(j));
  }

  @override
  Future<BoardReading> readBusBoard(Uint8List image) async {
    final j = await _ask(
      image,
      'This is the destination board of a Kerala bus. Transcribe every place '
      'name on it exactly as written (Malayalam or English), plus an English '
      'transliteration of each Malayalam name. Do not guess hidden text.',
      {
        'type': 'OBJECT',
        'properties': {
          'place_names': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
          'confidence': _conf,
        },
        'required': ['place_names', 'confidence'],
      },
    );
    final names = (j['place_names'] as List? ?? []).cast<String>();
    return BoardReading(names, _c(j));
  }

  @override
  Future<ItemReading> checkItem(Uint8List image,
      {required String item, required String targetState}) async {
    final j = await _ask(
      image,
      'Look at the $item in this photo. Is it clearly "$targetState"? '
      'Answer state "yes", "no", or "unknown" if the $item is not visible or '
      'you cannot tell. Be conservative: this is a home safety check.',
      {
        'type': 'OBJECT',
        'properties': {
          'state': {
            'type': 'STRING',
            'enum': ['yes', 'no', 'unknown']
          },
          'confidence': _conf,
        },
        'required': ['state', 'confidence'],
      },
    );
    final s = j['state'];
    return ItemReading(
        s == 'yes' ? true : (s == 'no' ? false : null), _c(j));
  }
}
