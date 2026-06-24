// Recall · StackRepository. Active stack + items. Stack creation is limited
// server-side (00003 trigger → `free_tier_stack_limit`); completion triggers
// stack XP/achievements. Returns models only.

import '../models/models.dart';
import '../services/supabase_service.dart';
import 'base_repository.dart';

class StackRepository extends BaseRepository {
  StackRepository(SupabaseService supabase) : super(supabase, 'stacks');

  /// The single active stack for the user (enforced unique by 00003), or null.
  Future<Stack?> fetchActive(String userId) => guard(() async {
        final row = await supabase
            .from('stacks')
            .select()
            .eq('user_id', userId)
            .eq('status', StackStatus.active.wire)
            .maybeSingle();
        return row == null ? null : Stack.fromJson(row);
      });

  Future<Stack> create(String userId, List<String> scopeBucketIds) =>
      guard(() async {
        final row = await supabase
            .from('stacks')
            .insert({
              'user_id': userId,
              'scope': {'bucket_ids': scopeBucketIds},
            })
            .select()
            .single();
        return Stack.fromJson(row);
      });

  Future<void> updateStatus(String stackId, StackStatus status) =>
      guard(() async {
        final changes = <String, dynamic>{'status': status.wire};
        if (status == StackStatus.completed) {
          changes['completed_at'] = DateTime.now().toUtc().toIso8601String();
        }
        await supabase.from('stacks').update(changes).eq('id', stackId);
      });

  Future<List<StackItem>> fetchItems(String stackId) => guard(() async {
        final rows = await supabase
            .from('stack_items')
            .select()
            .eq('stack_id', stackId)
            .order('position', ascending: true);
        return mapList(rows, StackItem.fromJson);
      });

  Future<List<StackItem>> addItems(List<StackItem> items) => guard(() async {
        if (items.isEmpty) return const <StackItem>[];
        final payload =
            items.map((i) => writable(i.toJson(), drop: {'id'})).toList();
        final rows = await supabase.from('stack_items').insert(payload).select();
        return mapList(rows, StackItem.fromJson);
      });

  Future<void> markItemReviewed(String itemId) => guard(() async {
        await supabase
            .from('stack_items')
            .update({'reviewed': true}).eq('id', itemId);
      });
}
