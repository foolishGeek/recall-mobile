// Recall · "Memory strength" — the friendly face of FSRS desired retention.
// Users pick a feel (Relaxed / Balanced / Rigorous); we translate that to a
// target-retention fraction the engine schedules against. Easy story on top,
// hard math underneath. Backend clamps to [0.80, 0.97] (00047).

/// (retention 0..1, short label, one-line plain-English description).
const List<(double, String, String)> kMemoryStrengthPresets = [
  (0.85, 'Relaxed', 'Fewer reviews · lighter load'),
  (0.90, 'Balanced', 'Recommended for most'),
  (0.95, 'Rigorous', 'More reviews · strongest recall'),
];

/// Nearest preset label for an arbitrary retention (handles legacy/custom values).
String memoryStrengthLabelFor(double retention) {
  var best = kMemoryStrengthPresets.first;
  var bestDelta = (retention - best.$1).abs();
  for (final p in kMemoryStrengthPresets) {
    final d = (retention - p.$1).abs();
    if (d < bestDelta) {
      best = p;
      bestDelta = d;
    }
  }
  return best.$2;
}

/// The retention value of the nearest preset (used to highlight the selection).
double memoryStrengthPreset(double retention) {
  var best = kMemoryStrengthPresets.first;
  var bestDelta = (retention - best.$1).abs();
  for (final p in kMemoryStrengthPresets) {
    final d = (retention - p.$1).abs();
    if (d < bestDelta) {
      best = p;
      bestDelta = d;
    }
  }
  return best.$1;
}
