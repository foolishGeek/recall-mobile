// Recall · LocalStore. The typed seam over the Drift cache [D-OFF-1]: it maps
// models ↔ rows (reusing each model's `fromJson`/`toJson`) and owns the
// append-only review queue. When the database failed to open at bootstrap, `_db`
// is null and every method degrades to a no-op so the app runs network-only
// (sprint §7). No product/scheduling math happens here — only mirroring backend
// rows and queued review intent.

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:get/get.dart' hide Node, Value;

import '../models/models.dart';
import 'app_database.dart';

/// A queued offline review with its durable key, ready to replay in order.
typedef PendingReviewEntry = ({
  String clientUuid,
  String idempotencyKey,
  Review review,
});

class LocalStore extends GetxService {
  LocalStore(this._db);

  final AppDatabase? _db;

  /// False when the cache DB could not be opened — repositories then run
  /// network-only and the offline queue is unavailable.
  bool get isEnabled => _db != null;

  // ---------------------------------------------------------------- buckets --
  Future<void> upsertBuckets(List<Bucket> buckets) async {
    final db = _db;
    if (db == null || buckets.isEmpty) return;
    await db.batch(
      (b) => b.insertAllOnConflictUpdate(
        db.cachedBuckets,
        buckets.map(_bucketRow).toList(growable: false),
      ),
    );
  }

  /// Authoritative full-set replace for a user's buckets (evicts rows the server
  /// no longer returns, e.g. soft-deleted ones).
  Future<void> replaceBuckets(String userId, List<Bucket> buckets) async {
    final db = _db;
    if (db == null) return;
    await db.transaction(() async {
      await (db.delete(db.cachedBuckets)..where((t) => t.userId.equals(userId)))
          .go();
      if (buckets.isNotEmpty) {
        await db.batch((b) => b.insertAll(
              db.cachedBuckets,
              buckets.map(_bucketRow).toList(growable: false),
            ));
      }
    });
  }

  Future<List<Bucket>> cachedBuckets(String userId) async {
    final db = _db;
    if (db == null) return const [];
    final rows = await (db.select(db.cachedBuckets)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull()))
        .get();
    final list = rows.map((r) => Bucket.fromJson(_decode(r.payload))).toList();
    list.sort((a, b) => _byCreated(a.createdAt, b.createdAt));
    return list;
  }

  Future<Bucket?> cachedBucketById(String id) async {
    final db = _db;
    if (db == null) return null;
    final r = await (db.select(db.cachedBuckets)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (r == null || r.deletedAt != null) return null;
    return Bucket.fromJson(_decode(r.payload));
  }

  /// Drops a soft-deleted bucket (and its cached nodes) from the cache.
  Future<void> evictBucket(String id) async {
    final db = _db;
    if (db == null) return;
    await db.transaction(() async {
      await (db.delete(db.cachedBuckets)..where((t) => t.id.equals(id))).go();
      await (db.delete(db.cachedNodes)..where((t) => t.bucketId.equals(id)))
          .go();
    });
  }

  // ------------------------------------------------------------------ nodes --
  Future<void> upsertNodes(List<Node> nodes) async {
    final db = _db;
    if (db == null || nodes.isEmpty) return;
    await db.batch(
      (b) => b.insertAllOnConflictUpdate(
        db.cachedNodes,
        nodes.map(_nodeRow).toList(growable: false),
      ),
    );
  }

  /// Authoritative full-set replace for a bucket's nodes (evicts soft-deleted).
  Future<void> replaceNodesForBucket(String bucketId, List<Node> nodes) async {
    final db = _db;
    if (db == null) return;
    await db.transaction(() async {
      await (db.delete(db.cachedNodes)
            ..where((t) => t.bucketId.equals(bucketId)))
          .go();
      if (nodes.isNotEmpty) {
        await db.batch((b) => b.insertAll(
              db.cachedNodes,
              nodes.map(_nodeRow).toList(growable: false),
            ));
      }
    });
  }

  Future<List<Node>> cachedNodesByBucket(String bucketId) async {
    final db = _db;
    if (db == null) return const [];
    final rows = await (db.select(db.cachedNodes)
          ..where((t) => t.bucketId.equals(bucketId) & t.deletedAt.isNull()))
        .get();
    final list = rows.map((r) => Node.fromJson(_decode(r.payload))).toList();
    list.sort((a, b) => _byCreated(a.createdAt, b.createdAt));
    return list;
  }

  Future<Node?> cachedNodeById(String id) async {
    final db = _db;
    if (db == null) return null;
    final r = await (db.select(db.cachedNodes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (r == null || r.deletedAt != null) return null;
    return Node.fromJson(_decode(r.payload));
  }

  /// Drops a soft-deleted node from the cache (sprint §3 — respect deleted_at).
  Future<void> evictNode(String id) async {
    final db = _db;
    if (db == null) return;
    await (db.delete(db.cachedNodes)..where((t) => t.id.equals(id))).go();
  }

  // -------------------------------------------------------------- active stack
  Future<void> upsertActiveStack(Stack stack, List<StackItem> items) async {
    final db = _db;
    if (db == null) return;
    await db.transaction(() async {
      await (db.delete(db.cachedStacks)
            ..where((t) => t.userId.equals(stack.userId)))
          .go();
      await db.into(db.cachedStacks).insertOnConflictUpdate(_stackRow(stack));
      await (db.delete(db.cachedStackItems)
            ..where((t) => t.stackId.equals(stack.id)))
          .go();
      if (items.isNotEmpty) {
        await db.batch((b) => b.insertAll(
              db.cachedStackItems,
              items.map(_stackItemRow).toList(growable: false),
            ));
      }
    });
  }

  Future<void> clearActiveStack(String userId) async {
    final db = _db;
    if (db == null) return;
    await (db.delete(db.cachedStacks)..where((t) => t.userId.equals(userId)))
        .go();
  }

  Future<Stack?> cachedActiveStack(String userId) async {
    final db = _db;
    if (db == null) return null;
    final r = await (db.select(db.cachedStacks)
          ..where((t) =>
              t.userId.equals(userId) &
              t.status.equals(StackStatus.active.wire)))
        .getSingleOrNull();
    return r == null ? null : Stack.fromJson(_decode(r.payload));
  }

  Future<void> replaceStackItems(String stackId, List<StackItem> items) async {
    final db = _db;
    if (db == null) return;
    await db.transaction(() async {
      await (db.delete(db.cachedStackItems)
            ..where((t) => t.stackId.equals(stackId)))
          .go();
      if (items.isNotEmpty) {
        await db.batch((b) => b.insertAll(
              db.cachedStackItems,
              items.map(_stackItemRow).toList(growable: false),
            ));
      }
    });
  }

  Future<void> evictStack(String stackId) async {
    final db = _db;
    if (db == null) return;
    await db.transaction(() async {
      await (db.delete(db.cachedStacks)..where((t) => t.id.equals(stackId)))
          .go();
      await (db.delete(db.cachedStackItems)
            ..where((t) => t.stackId.equals(stackId)))
          .go();
    });
  }

  Future<void> setStackItemReviewed(String itemId, bool reviewed) async {
    final db = _db;
    if (db == null) return;
    final r = await (db.select(db.cachedStackItems)
          ..where((t) => t.id.equals(itemId)))
        .getSingleOrNull();
    if (r == null) return;
    final json = _decode(r.payload)..['reviewed'] = reviewed;
    await (db.update(db.cachedStackItems)..where((t) => t.id.equals(itemId)))
        .write(CachedStackItemsCompanion(payload: Value(jsonEncode(json))));
  }

  Future<List<StackItem>> cachedStackItems(String stackId) async {
    final db = _db;
    if (db == null) return const [];
    final rows = await (db.select(db.cachedStackItems)
          ..where((t) => t.stackId.equals(stackId))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    return rows
        .map((r) => StackItem.fromJson(_decode(r.payload)))
        .toList(growable: false);
  }

  // ----------------------------------------------------- offline review queue
  /// Appends a review intent. Idempotent: a duplicate key is ignored so the
  /// same event is never queued twice (server `idempotency_key` is also UNIQUE).
  Future<void> enqueueReview(Review review) async {
    final db = _db;
    if (db == null) return;
    final ts = review.clientTimestamp ?? DateTime.now().toUtc();
    await db.into(db.pendingReviews).insert(
          PendingReviewsCompanion.insert(
            clientUuid:
                review.id.isNotEmpty ? review.id : review.idempotencyKey,
            idempotencyKey: review.idempotencyKey,
            nodeId: review.nodeId,
            stackId: Value(review.stackId),
            quizAttemptId: Value(review.quizAttemptId),
            payload:
                jsonEncode(review.copyWith(clientTimestamp: ts).toJson()),
            clientTimestamp: ts,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<List<PendingReviewEntry>> pendingInOrder() async {
    final db = _db;
    if (db == null) return const [];
    final rows = await (db.select(db.pendingReviews)
          ..orderBy([
            (t) => OrderingTerm.asc(t.clientTimestamp),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
    return rows
        .map((r) => (
              clientUuid: r.clientUuid,
              idempotencyKey: r.idempotencyKey,
              review: Review.fromJson(_decode(r.payload)),
            ))
        .toList(growable: false);
  }

  Future<void> removePending(String clientUuid) async {
    final db = _db;
    if (db == null) return;
    await (db.delete(db.pendingReviews)
          ..where((t) => t.clientUuid.equals(clientUuid)))
        .go();
  }

  Future<void> markPendingAttempt(String clientUuid, String error) async {
    final db = _db;
    if (db == null) return;
    await db.customStatement(
      'UPDATE pending_reviews SET attempts = attempts + 1, last_error = ? '
      'WHERE client_uuid = ?',
      [error, clientUuid],
    );
  }

  Future<int> pendingCount() async {
    final db = _db;
    if (db == null) return 0;
    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM pending_reviews')
        .getSingle();
    return row.read<int>('c');
  }

  // ------------------------------------------- offline profile prefs queue
  /// Last-write-wins per user for preference columns (S09 onboarding path).
  Future<void> enqueueProfilePrefs(
    String userId,
    Map<String, dynamic> changes,
  ) async {
    final db = _db;
    if (db == null) return;
    final ts = DateTime.now().toUtc();
    await db.into(db.pendingProfilePrefs).insertOnConflictUpdate(
          PendingProfilePrefsCompanion.insert(
            userId: userId,
            payload: jsonEncode(changes),
            clientTimestamp: ts,
          ),
        );
  }

  Future<List<({String userId, Map<String, dynamic> changes})>>
      pendingProfilePrefs() async {
    final db = _db;
    if (db == null) return const [];
    final rows = await (db.select(db.pendingProfilePrefs)
          ..orderBy([(t) => OrderingTerm.asc(t.clientTimestamp)]))
        .get();
    return rows
        .map((r) => (
              userId: r.userId,
              changes: Map<String, dynamic>.from(_decode(r.payload)),
            ))
        .toList(growable: false);
  }

  Future<void> removePendingProfilePrefs(String userId) async {
    final db = _db;
    if (db == null) return;
    await (db.delete(db.pendingProfilePrefs)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }

  // ---------------------------------------- onboarding_done local cache (S09)
  static String _onboardingDoneKey(String userId) => 'onboarding_done:$userId';

  /// Device-local flag so returning users skip onboarding even if the server
  /// read races the profile-prefs sync queue.
  Future<bool> cachedOnboardingDone(String userId) async {
    final db = _db;
    if (db == null) return false;
    final row = await (db.select(db.syncMeta)
          ..where((t) => t.key.equals(_onboardingDoneKey(userId))))
        .getSingleOrNull();
    return row?.value == 'true';
  }

  Future<void> setCachedOnboardingDone(String userId, bool done) async {
    final db = _db;
    if (db == null) return;
    await db.into(db.syncMeta).insertOnConflictUpdate(
          SyncMetaCompanion.insert(
            key: _onboardingDoneKey(userId),
            value: done.toString(),
          ),
        );
  }

  Future<bool> hasPendingOnboardingDone(String userId) async {
    final pending = await pendingProfilePrefs();
    return pending.any(
      (e) =>
          e.userId == userId && e.changes['onboarding_done'] == true,
    );
  }

  @override
  void onClose() {
    _db?.close();
    super.onClose();
  }

  // ----------------------------------------------------------------- helpers
  CachedBucketsCompanion _bucketRow(Bucket b) => CachedBucketsCompanion.insert(
        id: b.id,
        userId: b.userId,
        payload: jsonEncode(b.toJson()),
        updatedAt: Value(b.updatedAt),
        deletedAt: Value(b.deletedAt),
      );

  CachedNodesCompanion _nodeRow(Node n) => CachedNodesCompanion.insert(
        id: n.id,
        bucketId: n.bucketId,
        payload: jsonEncode(n.toJson()),
        updatedAt: Value(n.updatedAt),
        deletedAt: Value(n.deletedAt),
      );

  CachedStacksCompanion _stackRow(Stack s) => CachedStacksCompanion.insert(
        id: s.id,
        userId: s.userId,
        status: s.status.wire,
        payload: jsonEncode(s.toJson()),
        updatedAt: Value(s.updatedAt),
      );

  CachedStackItemsCompanion _stackItemRow(StackItem i) =>
      CachedStackItemsCompanion.insert(
        id: i.id,
        stackId: i.stackId,
        position: Value(i.position),
        payload: jsonEncode(i.toJson()),
      );

  Map<String, dynamic> _decode(String s) =>
      jsonDecode(s) as Map<String, dynamic>;

  int _byCreated(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }
}
