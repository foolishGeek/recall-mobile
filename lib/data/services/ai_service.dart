// Recall · AiService (stub — implemented in S06). Thin wrapper over the
// `ai-forge` Edge Function router. The real feature methods (rag_chat,
// summarize, evaluate, quiz_grade, ...) land in S06; this S03 scope only
// provides the invoke seam so repositories can wire against it.

import 'package:get/get.dart';

import 'supabase_service.dart';

class AiService extends GetxService {
  AiService(this._supabase);

  final SupabaseService _supabase;

  /// Calls the `ai-forge` router with `{ feature, payload }`. Quota/gate errors
  /// surface as RepoException via SupabaseService.invokeFunction. Feature-typed
  /// helpers (returning models) are added in S06.
  Future<Map<String, dynamic>> invokeForge(
    String feature, {
    Map<String, dynamic> payload = const {},
  }) {
    return _supabase.invokeFunction(
      'ai-forge',
      body: {'feature': feature, 'payload': payload},
    );
  }
}
