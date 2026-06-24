// Recall · HeatRing — Home ring visual params [11-metrics §10].

class HeatRing {
  final double load;
  final double ringWeight;
  final double ringOpacity;
  final bool glow;

  const HeatRing({
    required this.load,
    required this.ringWeight,
    required this.ringOpacity,
    required this.glow,
  });

  factory HeatRing.forLoad(double load) {
    final clamped = load.clamp(0.0, 1.0);
    return HeatRing(
      load: clamped,
      ringWeight: 1 + 3 * clamped,
      ringOpacity: 0.3 + 0.7 * clamped,
      glow: clamped > 0.6,
    );
  }
}
