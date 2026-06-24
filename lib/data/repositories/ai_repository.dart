// Recall · AiRepository. Reads AI evaluations + credit ledger (both written
// server-side) and wraps AiService for `ai-forge` calls. Feature-typed returns
// land in S06; the invoke seam returns the raw EF body for now.

import '../models/models.dart';
import '../services/ai_service.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

class AiRepository extends BaseRepository {
  AiRepository(SupabaseService supabase, this._ai) : super(supabase, 'ai');

  final AiService _ai;

  /// Latest cached AI overview for a node (`node_ai_evaluations`).
  Future<AiEvaluation?> fetchLatestEvaluation(String nodeId) => guard(() async {
        final row = await supabase
            .from('node_ai_evaluations')
            .select()
            .eq('node_id', nodeId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        return row == null ? null : AiEvaluation.fromJson(row);
      });

  Future<List<AiCreditLedgerEntry>> fetchCreditLedger(String userId,
          {int limit = 50}) =>
      guard(() async {
        final rows = await supabase
            .from('ai_credit_ledger')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);
        return mapList(rows, AiCreditLedgerEntry.fromJson);
      });

  /// Calls the `ai-forge` router. Errors already map to RepoException inside
  /// SupabaseService.invokeFunction. S06 adds feature-typed wrappers.
  Future<Map<String, dynamic>> invokeForge(
    String feature, {
    Map<String, dynamic> payload = const {},
  }) =>
      guard(() => _ai.invokeForge(feature, payload: payload));
}
