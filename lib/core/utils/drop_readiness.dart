// Recall · Drop readiness helpers. Maps Reminder style (profiles.drop_frequency)
// to the backend drop_intensity() thresholds so Settings + Today can speak in
// plain numbers ("waits for 5 cards") instead of opaque wire values.

/// Product default Reminder style — Standard. Backend `drop_intensity('3xwk')`
/// uses threshold 5. Shown as "Default (5)" in Settings; other styles show the
/// bare number only.
const String kDefaultDropFrequency = '3xwk';

/// Wire value → cards-before-a-Drop (must match `drop_intensity` in SQL).
int dropThresholdFor(String dropFrequency) {
  switch (dropFrequency) {
    case 'weekly':
      return 8;
    case '3xwk':
      return 5;
    case 'daily':
      return 3;
    default:
      return 5;
  }
}

/// Collapsed Settings / Today readout.
/// Default style → "Default (5)"; anything else → just the number ("3", "8").
String dropReadinessShortLabel(String dropFrequency) {
  final n = dropThresholdFor(dropFrequency);
  if (dropFrequency == kDefaultDropFrequency) return 'Default ($n)';
  return '$n';
}

String dropReadinessStyleName(String dropFrequency) {
  switch (dropFrequency) {
    case 'weekly':
      return 'Gentle';
    case '3xwk':
      return 'Standard';
    case 'daily':
      return 'Persistent';
    default:
      return 'Standard';
  }
}
