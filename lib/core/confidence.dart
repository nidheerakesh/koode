/// Turns AI confidence into a three-way answer. When unsure, Koode says so.
enum Verdict { yes, no, unsure }

const double defaultThreshold = 0.7;

/// Home safety uses a stricter bar: a wrong "yes" is worse than "not sure".
const double safetyThreshold = 0.85;

Verdict gate({
  required bool positive,
  required double confidence,
  double threshold = defaultThreshold,
}) {
  if (confidence < threshold) return Verdict.unsure;
  return positive ? Verdict.yes : Verdict.no;
}
