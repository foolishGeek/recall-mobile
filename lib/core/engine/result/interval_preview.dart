// Recall · IntervalPreview — per-grade due labels [D-ENG-4].

class GradeInterval {
  final String label;
  final double intervalDays;

  const GradeInterval({required this.label, required this.intervalDays});
}

class IntervalPreview {
  final GradeInterval again;
  final GradeInterval hard;
  final GradeInterval good;
  final GradeInterval easy;

  const IntervalPreview({
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });
}
