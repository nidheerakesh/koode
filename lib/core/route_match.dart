/// Fuzzy matching of bus-board text against a saved destination.
/// Tolerates spelling variants and partly hidden boards.
library;

import 'dart:math';

String normalise(String s) => s
    .toLowerCase()
    .replaceAll('‌', '') // ZWNJ
    .replaceAll('‍', '') // ZWJ
    .replaceAll(RegExp(r'[\s\.\-,/()]+'), '');

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = min(min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
    }
    prev = cur;
  }
  return prev[b.length];
}

double similarity(String a, String b) {
  final x = normalise(a), y = normalise(b);
  if (x.isEmpty || y.isEmpty) return 0;
  final longest = max(x.length, y.length);
  return 1 - levenshtein(x, y) / longest;
}

/// Best similarity of any [aliases] (e.g. "കോട്ടയം", "Kottayam", "KTM")
/// against any place name read from the board. Substring hits count too,
/// so "KOTTAYAM via ETTUMANOOR" still matches.
double bestMatch(List<String> boardNames, List<String> aliases) {
  var best = 0.0;
  for (final b in boardNames) {
    final nb = normalise(b);
    for (final a in aliases) {
      final na = normalise(a);
      if (na.length >= 3 && nb.contains(na)) return 1;
      best = max(best, similarity(b, a));
    }
  }
  return best;
}

const double matchThreshold = 0.75;

bool isMyBus(List<String> boardNames, List<String> aliases) =>
    bestMatch(boardNames, aliases) >= matchThreshold;
