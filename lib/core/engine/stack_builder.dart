// Recall · buildStack — heat-ranked weighted sampling [D-ENG-2/3/10].

import 'dart:math' as math;

import '../../../data/models/bucket.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/node.dart';
import 'params/engine_config.dart';
import 'params/scheduling_params.dart';
import 'result/stack_plan.dart';
import 'heat.dart';

StackPlan buildStack(
  List<Bucket> scope,
  List<Node> pool,
  SchedulingParams p, {
  required SubscriptionTier tier,
  bool ahead = false,
  int? seed,
  DateTime? now,
  EngineConfig config = EngineConfig.defaults,
  int? sessionSizeOverride,
  int newIntroducedToday = 0,
}) {
  final utcNow = (now ?? DateTime.now()).toUtc();
  final rng = math.Random(seed ?? utcNow.microsecondsSinceEpoch);

  var sessionN = sessionSizeOverride ?? p.sessionSize;
  if (tier != SubscriptionTier.premium) {
    sessionN = math.min(sessionN, config.sessionSizeFree);
  }

  final activeBuckets = scope.where((b) {
    if (b.deletedAt != null) return false;
    if (ahead) return true;
    final cd = b.cooldownUntil;
    return cd == null || !cd.toUtc().isAfter(utcNow);
  }).toList();

  final activeBucketIds = activeBuckets.map((b) => b.id).toSet();
  final bucketById = {for (final b in activeBuckets) b.id: b};

  final eligible = pool.where((n) {
    if (n.deletedAt != null) return false;
    if (!activeBucketIds.contains(n.bucketId)) return false;
    if (n.state == NodeState.leech) return false;
    return true;
  }).toList();

  final lookaheadEnd =
      utcNow.add(Duration(hours: p.lookaheadHours));

  final overdueForced = <Node>[];
  final duePool = <Node>[];
  final newPool = <Node>[];

  for (final n in eligible) {
    if (n.state == NodeState.newNode) {
      newPool.add(n);
      continue;
    }
    if (n.state != NodeState.review && n.state != NodeState.relearning) {
      continue;
    }
    final due = n.dueAt?.toUtc();
    if (due == null) continue;
    final isDue = ahead || !due.isAfter(lookaheadEnd);
    if (!isDue) continue;

    if (n.priority >= 5 && due.isBefore(utcNow)) {
      overdueForced.add(n);
    } else {
      duePool.add(n);
    }
  }

  final selected = <Node>[];
  final selectedIds = <String>{};

  void addNode(Node n) {
    if (selected.length >= sessionN) return;
    if (selectedIds.contains(n.id)) return;
    selected.add(n);
    selectedIds.add(n.id);
  }

  for (final n in overdueForced) {
    addNode(n);
  }

  final newBudget = math.max(
    0,
    math.min(p.newPerDay - newIntroducedToday, p.maxNewPerStack),
  );
  var newAdded = 0;
  final newSorted = List<Node>.from(newPool)
    ..sort((a, b) => heat(b, utcNow, params: p).compareTo(heat(a, utcNow, params: p)));

  for (final n in newSorted) {
    if (newAdded >= newBudget) break;
    if (selected.length >= sessionN) break;
    addNode(n);
    if (selectedIds.contains(n.id)) newAdded += 1;
  }

  final bucketCounts = <String, int>{};
  for (final n in selected) {
    bucketCounts[n.bucketId] = (bucketCounts[n.bucketId] ?? 0) + 1;
  }

  bool bucketCapReached(String bucketId) {
    final bucket = bucketById[bucketId];
    final cap = bucket?.dailyCap ?? p.maxPerBucket;
    return (bucketCounts[bucketId] ?? 0) >= cap;
  }

  final candidates = duePool.where((n) {
    if (selectedIds.contains(n.id)) return false;
    return !bucketCapReached(n.bucketId);
  }).toList();

  while (selected.length < sessionN && candidates.isNotEmpty) {
    final weights = candidates
        .map((n) => math.pow(heat(n, utcNow, params: p), p.temperature))
        .toList();
    final total = weights.fold<double>(0, (a, b) => a + b);
    if (total <= 0) break;

    var roll = rng.nextDouble() * total;
    var pick = 0;
    for (var i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll <= 0) {
        pick = i;
        break;
      }
    }

    final node = candidates.removeAt(pick);
    if (bucketCapReached(node.bucketId)) continue;
    addNode(node);
    bucketCounts[node.bucketId] = (bucketCounts[node.bucketId] ?? 0) + 1;
  }

  final backlogCapped = eligible.length > sessionN;
  final interleaved = _interleaveByBucket(selected, rng);
  final newCount =
      interleaved.where((n) => n.state == NodeState.newNode).length;

  final items = <StackSelection>[];
  for (var i = 0; i < interleaved.length; i++) {
    final n = interleaved[i];
    items.add(
      StackSelection(
        node: n,
        heatSnapshot: heat(n, utcNow, params: p),
        position: i,
      ),
    );
  }

  return StackPlan(
    items: items,
    newCount: newCount,
    backlogCapped: backlogCapped,
    cooledBucketIds: activeBuckets.map((b) => b.id).toList(growable: false),
  );
}

List<Node> _interleaveByBucket(List<Node> nodes, math.Random rng) {
  if (nodes.length <= 2) return nodes;
  final byBucket = <String, List<Node>>{};
  for (final n in nodes) {
    byBucket.putIfAbsent(n.bucketId, () => []).add(n);
  }
  for (final list in byBucket.values) {
    list.sort(
      (a, b) => b.priority.compareTo(a.priority),
    );
  }

  final buckets = byBucket.keys.toList()..shuffle(rng);
  final out = <Node>[];
  var remaining = nodes.length;
  while (remaining > 0) {
    for (final bucketId in buckets) {
      final list = byBucket[bucketId];
      if (list == null || list.isEmpty) continue;
      out.add(list.removeAt(0));
      remaining -= 1;
    }
    buckets.removeWhere((id) => byBucket[id]?.isEmpty ?? true);
    if (buckets.isEmpty) break;
  }
  return out;
}
