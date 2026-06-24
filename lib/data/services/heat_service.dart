// Recall · HeatService. Backend heat is source-of-truth; this service only
// exposes persisted heat summaries already returned from backend rows/views.

import 'package:get/get.dart' hide Node;

import '../models/models.dart';

class HeatService extends GetxService {
  /// Kept for S10 call sites: the backend should provide this via buckets/views.
  /// No client-side heat calculation is performed.
  HeatSummary summaryForUser(List<Node> due, int sessionSize) {
    return HeatSummary.empty;
  }

  HeatSummary summaryFromBucket(Bucket bucket) => bucket.heatSummary;
}
