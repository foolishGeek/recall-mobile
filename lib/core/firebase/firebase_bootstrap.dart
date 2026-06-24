// Recall · Firebase bootstrap. Android uses google-services.json (staging copy
// from recall-backend/secrets/firebase/). iOS plist is deferred — init is
// best-effort so onboarding can proceed without APNs.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

bool _firebaseReady = false;

bool get isFirebaseReady => _firebaseReady;

Future<void> bootstrapFirebase() async {
  if (_firebaseReady || Firebase.apps.isNotEmpty) {
    _firebaseReady = true;
    return;
  }
  try {
    await Firebase.initializeApp();
    _firebaseReady = true;
  } catch (e, st) {
    _firebaseReady = false;
    if (kDebugMode) {
      debugPrint('[firebase] initializeApp failed: $e\n$st');
    }
  }
}
