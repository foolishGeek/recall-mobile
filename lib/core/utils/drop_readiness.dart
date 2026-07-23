// Recall · Reminder style helpers. profiles.drop_frequency maps via
// drop_intensity() to an *intensity / nudge pattern* (D-ENG-9): batch threshold,
// min interval, max per day, and re-nudge hours — not a single "card count" dial.
// Card threshold is one supporting detail of that pattern, shown in explainers.

/// Product default Reminder style — Standard (`3xwk`).
const String kDefaultDropFrequency = '3xwk';

/// Wire value for ASAO — Drop as soon as one note is ready.
const String kAsapDropFrequency = 'asap';

/// Wire value → cards-before-a-fresh-Drop (one of four intensity knobs).
int dropThresholdFor(String dropFrequency) {
  switch (dropFrequency) {
    case 'weekly':
      return 8;
    case '3xwk':
      return 5;
    case 'daily':
      return 3;
    case 'asap':
      return 1;
    default:
      return 5;
  }
}

String dropStyleName(String dropFrequency) {
  switch (dropFrequency) {
    case 'weekly':
      return 'Gentle';
    case '3xwk':
      return 'Standard';
    case 'daily':
      return 'Persistent';
    case 'asap':
      return 'ASAO';
    default:
      return 'Standard';
  }
}

/// Collapsed Settings row: Default for Standard; style name only otherwise.
String dropStyleShortLabel(String dropFrequency) {
  if (dropFrequency == kDefaultDropFrequency) return 'Default';
  return dropStyleName(dropFrequency);
}

/// One-line intensity summary for sheets / Today (nudge pattern first).
String dropStyleIntensityLine(String dropFrequency) {
  switch (dropFrequency) {
    case 'weekly':
      return 'Occasional nudge · larger batches · no re-nudge';
    case '3xwk':
      return 'Balanced nudge · re-nudges every ~2h if unseen';
    case 'daily':
      return 'Keeps nudging · smaller batches · re-nudges every ~2h';
    case 'asap':
      return 'As soon as one note is ready';
    default:
      return 'Balanced nudge · re-nudges every ~2h if unseen';
  }
}
