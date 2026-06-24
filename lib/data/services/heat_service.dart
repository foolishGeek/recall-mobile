// Recall · HeatService (stub — implemented in S04). Derives the bucket/today
// heat summary from the pure-Dart engine. S03 only declares the seam; the real
// computation (engine `heat`/ring math) lands in S04.

import 'package:get/get.dart' hide Node;

import '../models/models.dart';

class HeatService extends GetxService {
  /// Aggregates a HeatSummary across the user's due nodes for the today ring.
  /// Returns an empty summary until S04 wires the engine.
  HeatSummary summaryForUser(List<Node> due, int sessionSize) {
    // TODO(S04): compute aggregate heat, segments, hot/warm/cool counts.
    return HeatSummary.empty;
  }
}
