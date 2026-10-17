/// Pulls a rupee amount out of recognised speech: "47", "൪൭",
/// "നാല്പത്തിയേഴ് രൂപ" (tens + units words), "forty seven".
library;

const _mlDigits = '൦൧൨൩൪൫൬൭൮൯';

const _mlUnits = {
  'ഒന്ന്': 1, 'ഒന്': 1, 'രണ്ട്': 2, 'മൂന്ന്': 3, 'നാല്': 4, 'അഞ്ച്': 5,
  'ആറ്': 6, 'ഏഴ്': 7, 'എട്ട്': 8, 'ഒമ്പത്': 9, 'ഒൻപത്': 9,
  // Joined after a tens word: മുപ്പത്തി-യഞ്ച്, നാല്പത്തി-യേഴ്.
  'യൊന്ന്': 1, 'യഞ്ച്': 5, 'യാറ്': 6, 'യേഴ്': 7, 'യെട്ട്': 8,
};
const _mlWhole = {
  'പത്ത്': 10, 'ഇരുപത്': 20, 'മുപ്പത്': 30, 'നാല്പത്': 40, 'നാൽപത്': 40,
  'അമ്പത്': 50, 'അൻപത്': 50, 'അറുപത്': 60, 'എഴുപത്': 70, 'എൺപത്': 80,
  'തൊണ്ണൂറ്': 90, 'നൂറ്': 100,
};
const _en = {
  'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6,
  'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'twenty': 20, 'thirty': 30,
  'forty': 40, 'fifty': 50, 'sixty': 60, 'seventy': 70, 'eighty': 80,
  'ninety': 90, 'hundred': 100,
};

int? parseSpokenAmount(String text) {
  var t = text;
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(_mlDigits[i], '$i');
  }
  final digits = RegExp(r'\d+').firstMatch(t);
  if (digits != null) return int.parse(digits.group(0)!);

  var total = 0;
  // Tens first, removed from the text so "നാല്പത്" doesn't also read as 4.
  // Longest words first: "മുപ്പത്" contains "പത്".
  final tens = _mlWhole.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));
  for (final e in tens) {
    final stem = e.key.substring(0, e.key.length - 2);
    final hit = t.contains(e.key)
        ? e.key
        : (e.value > 10 && t.contains(stem) ? stem : null);
    if (hit != null) {
      total = e.value;
      t = t.replaceFirst(hit, ' ');
      break;
    }
  }
  for (final e in _mlUnits.entries) {
    if (t.contains(e.key)) {
      total += e.value;
      break;
    }
  }
  if (total > 0) return total;

  for (final w in t.toLowerCase().split(RegExp(r'[\s-]+'))) {
    final v = _en[w];
    if (v == null) continue;
    total = v == 100 && total > 0 ? total * 100 : total + v;
  }
  return total > 0 ? total : null;
}
