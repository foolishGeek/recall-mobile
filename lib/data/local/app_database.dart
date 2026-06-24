// Recall · Drift cache database [D-OFF-1]. Stores the offline-readable scope
// (buckets, nodes, active stack + items) plus an append-only review queue and a
// small key/value table for reconcile cursors. Each cached entity keeps the
// model's `toJson()` shape as a JSON `payload` (the model is the source of
// truth for shape, so the cache survives additive schema changes) alongside the
// key columns we actually query/order by. Server-authoritative truth is never
// computed here — the cache only mirrors backend rows and queued review intent.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Cached `buckets` rows. `deletedAt` lets sync evict soft-deleted buckets.
class CachedBuckets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Cached `nodes` rows, scoped by `bucketId` (nodes inherit the bucket owner).
class CachedNodes extends Table {
  TextColumn get id => text()();
  TextColumn get bucketId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The single active `stacks` row per user (status kept for cheap lookups).
class CachedStacks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get status => text()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Ordered `stack_items` for the cached active stack.
class CachedStackItems extends Table {
  TextColumn get id => text()();
  TextColumn get stackId => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Append-only offline review queue [D-OFF-1]. `idempotencyKey` is unique so a
/// replayed event is never double-written; `clientTimestamp` fixes replay order.
class PendingReviews extends Table {
  TextColumn get clientUuid => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get nodeId => text()();
  TextColumn get stackId => text().nullable()();
  TextColumn get quizAttemptId => text().nullable()();
  TextColumn get payload => text()();
  DateTimeColumn get clientTimestamp => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {clientUuid};
}

/// Generic key/value markers (e.g. last reconcile time per domain).
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Queued profile preference writes (last-write-wins per user). S09 offline path.
class PendingProfilePrefs extends Table {
  TextColumn get userId => text()();
  TextColumn get payload => text()();
  DateTimeColumn get clientTimestamp => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

@DriftDatabase(
  tables: [
    CachedBuckets,
    CachedNodes,
    CachedStacks,
    CachedStackItems,
    PendingReviews,
    SyncMeta,
    PendingProfilePrefs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'recall_cache'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(pendingProfilePrefs);
          }
        },
      );
}
