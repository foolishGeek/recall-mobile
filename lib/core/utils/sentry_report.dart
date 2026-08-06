// Shared Sentry capture with feature (+ optional op) tags.

import 'package:sentry_flutter/sentry_flutter.dart';

void captureFeature(
  Object e,
  StackTrace st, {
  required String feature,
  String? op,
}) {
  Sentry.captureException(
    e,
    stackTrace: st,
    withScope: (s) {
      s.setTag('feature', feature);
      if (op != null) s.setTag('op', op);
    },
  );
}
