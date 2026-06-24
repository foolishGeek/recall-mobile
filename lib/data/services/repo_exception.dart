// Recall · RepoException + error mapping. Translates Supabase/Postgrest/Function/
// network failures into the canonical error taxonomy [CANON §11] so controllers
// render consistent UI and repos can branch on a typed code.

import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Canonical error codes mirroring `[CANON §11]` plus a few client-only codes
/// (`offline`, `notFound`, `conflict`, `unknown`).
enum RepoErrorCode {
  invalidInput('invalid_input'),
  unauthorized('unauthorized'),
  premiumRequired('premium_required'),
  aiQuotaExceeded('ai_quota_exceeded'),
  overviewQuotaExceeded('overview_quota_exceeded'),
  insufficientCredits('insufficient_credits'),
  freeTierBucketLimit('free_tier_bucket_limit'),
  freeTierStackLimit('free_tier_stack_limit'),
  emptyContext('empty_context'),
  aiCooldown('ai_cooldown'),
  maintenance('maintenance'),
  providerError('provider_error'),
  offline('offline'),
  notFound('not_found'),
  conflict('conflict'),
  unknown('unknown');

  const RepoErrorCode(this.wire);
  final String wire;

  static RepoErrorCode fromWire(String? code) {
    for (final c in values) {
      if (c.wire == code) return c;
    }
    return RepoErrorCode.unknown;
  }
}

/// Typed failure surfaced above [SupabaseService]. `extra` carries structured
/// payload such as `cooldown_until` for `ai_cooldown` `[D-AI-1]`.
class RepoException implements Exception {
  final RepoErrorCode code;
  final String message;
  final Map<String, dynamic>? extra;
  final Object? cause;
  final StackTrace? causeStackTrace;

  const RepoException(
    this.code,
    this.message, {
    this.extra,
    this.cause,
    this.causeStackTrace,
  });

  bool get isOffline => code == RepoErrorCode.offline;

  @override
  String toString() => 'RepoException(${code.wire}): $message';
}

/// Maps any thrown error into a [RepoException]. Idempotent: a [RepoException]
/// passes through unchanged so it can be applied at multiple layers safely.
RepoException mapError(Object error, [StackTrace? stackTrace]) {
  if (error is RepoException) return error;

  if (error is PostgrestException) {
    return _mapPostgrest(error, stackTrace);
  }

  if (error is FunctionException) {
    return _mapFunction(error, stackTrace);
  }

  if (error is AuthException) {
    return RepoException(RepoErrorCode.unauthorized, error.message,
        cause: error, causeStackTrace: stackTrace);
  }

  if (_isNetworkError(error)) {
    return RepoException(
      RepoErrorCode.offline,
      'Network unavailable. Working from cached data.',
      cause: error,
      causeStackTrace: stackTrace,
    );
  }

  return RepoException(RepoErrorCode.unknown, error.toString(),
      cause: error, causeStackTrace: stackTrace);
}

RepoException _mapPostgrest(PostgrestException e, StackTrace? st) {
  final msg = e.message;
  final lower = msg.toLowerCase();

  // DB-raised business rules (P0001) carry the rule name in the message.
  if (lower.contains('free_tier_bucket_limit')) {
    return RepoException(RepoErrorCode.freeTierBucketLimit,
        'Free plan allows up to 2 buckets.',
        cause: e, causeStackTrace: st);
  }
  if (lower.contains('free_tier_stack_limit')) {
    return RepoException(RepoErrorCode.freeTierStackLimit,
        'Free plan allows 2 stacks per month.',
        cause: e, causeStackTrace: st);
  }

  switch (e.code) {
    case '23505': // unique_violation (e.g. idempotency replay)
      return RepoException(RepoErrorCode.conflict, msg,
          cause: e, causeStackTrace: st);
    case '42501': // insufficient_privilege (RLS / column grant denial)
      return RepoException(RepoErrorCode.unauthorized, msg,
          cause: e, causeStackTrace: st);
    case 'PGRST116': // no rows for .single()
      return RepoException(RepoErrorCode.notFound, msg,
          cause: e, causeStackTrace: st);
    default:
      return RepoException(RepoErrorCode.unknown, msg,
          cause: e, causeStackTrace: st);
  }
}

RepoException _mapFunction(FunctionException e, StackTrace? st) {
  // Edge Functions return { error, message, ...extra } per [CANON §11].
  String? errorCode;
  String message = 'Edge function error';
  Map<String, dynamic>? extra;

  final details = e.details;
  if (details is Map) {
    final map = details.map((k, v) => MapEntry(k.toString(), v));
    errorCode = map['error']?.toString();
    message = map['message']?.toString() ?? message;
    extra = map;
  } else if (details is String && details.isNotEmpty) {
    message = details;
  }

  return RepoException(
    RepoErrorCode.fromWire(errorCode),
    message,
    extra: extra,
    cause: e,
    causeStackTrace: st,
  );
}

bool _isNetworkError(Object error) {
  if (error is SocketException || error is TimeoutException) return true;
  final s = error.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('connection closed') ||
      s.contains('connection refused') ||
      s.contains('network is unreachable');
}
