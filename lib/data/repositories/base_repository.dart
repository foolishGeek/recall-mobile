// Recall · BaseRepository. Shared plumbing for repositories: a `guard` that maps
// any failure to RepoException [CANON §11] and reports it to Sentry tagged with
// the owning feature, plus small helpers for building insert/update payloads.
//
// Cache seam: repositories are cache-first *ready*. S05 wires a local store
// (Drift) behind these reads; for now `guard` simply executes the remote call.

import 'package:sentry_flutter/sentry_flutter.dart';

import '../services/repo_exception.dart';
import '../services/supabase_service.dart';

abstract class BaseRepository {
  const BaseRepository(this.supabase, this.feature);

  final SupabaseService supabase;

  /// Feature tag attached to Sentry scope on failure (e.g. `buckets`, `review`).
  final String feature;

  /// Runs [action], mapping any error to a [RepoException] and capturing it in
  /// Sentry with the feature tag. Plain offline errors are not sent to Sentry
  /// (expected on flaky networks) but are still surfaced as a typed exception.
  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, st) {
      final mapped = mapError(e, st);
      if (mapped.code != RepoErrorCode.offline) {
        await Sentry.captureException(
          mapped.cause ?? mapped,
          stackTrace: mapped.causeStackTrace ?? st,
          withScope: (scope) => scope.setTag('feature', feature),
        );
      }
      throw mapped;
    }
  }

  /// Builds an insert/update payload from a model's `toJson`, dropping nulls
  /// (so DB defaults apply) and any server-managed [drop] keys.
  Map<String, dynamic> writable(
    Map<String, dynamic> json, {
    Set<String> drop = const {'id', 'created_at', 'updated_at'},
  }) {
    final out = <String, dynamic>{};
    json.forEach((key, value) {
      if (value == null) return;
      if (drop.contains(key)) return;
      out[key] = value;
    });
    return out;
  }

  /// Maps a PostgREST result list into models.
  List<T> mapList<T>(
    List<dynamic> rows,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return rows
        .map((r) => fromJson(Map<String, dynamic>.from(r as Map)))
        .toList(growable: false);
  }
}
