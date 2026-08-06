// Recall · domain enums mirroring the Postgres enums in
// recall-backend/supabase/migrations/00001_initial.sql. Each carries its DB
// `wire` string and a safe `fromWire` (unknown value → safe default + breadcrumb).

import '../../core/gates/tier_gate.dart';
import 'json_utils.dart';

export '../../core/gates/tier_gate.dart' show SubscriptionTier;

/// `subscription_tier` is `free`/`premium` in the DB; the app's `downgraded`
/// state is derived (free + had_premium), never stored. Reuses the gate enum.
SubscriptionTier subscriptionTierFromWire(Object? raw) => parseEnum(
      const [SubscriptionTier.free, SubscriptionTier.premium],
      (t) => t == SubscriptionTier.premium ? 'premium' : 'free',
      raw,
      SubscriptionTier.free,
      'subscription_tier',
    );

String subscriptionTierToWire(SubscriptionTier t) =>
    t == SubscriptionTier.premium ? 'premium' : 'free';

enum NodeType {
  text('text'),
  link('link'),
  youtube('youtube'),
  pdf('pdf'),
  image('image');

  const NodeType(this.wire);
  final String wire;
  static NodeType fromWire(Object? v) =>
      parseEnum(values, (e) => e.wire, v, NodeType.text, 'node_type');
}

enum NodeState {
  newNode('new'),
  learning('learning'),
  review('review'),
  relearning('relearning'),
  leech('leech');

  const NodeState(this.wire);
  final String wire;
  static NodeState fromWire(Object? v) =>
      parseEnum(values, (e) => e.wire, v, NodeState.newNode, 'node_state');
}

enum ReviewGrade {
  again('again'),
  hard('hard'),
  good('good'),
  easy('easy');

  const ReviewGrade(this.wire);
  final String wire;
  static ReviewGrade fromWire(Object? v) =>
      parseEnum(values, (e) => e.wire, v, ReviewGrade.good, 'review_grade');
}

enum ReviewSource {
  stack('stack'),
  quiz('quiz');

  const ReviewSource(this.wire);
  final String wire;
  static ReviewSource fromWire(Object? v) =>
      parseEnum(values, (e) => e.wire, v, ReviewSource.stack, 'review_source');
}

enum StackStatus {
  active('active'),
  completed('completed'),
  abandoned('abandoned');

  const StackStatus(this.wire);
  final String wire;
  static StackStatus fromWire(Object? v) =>
      parseEnum(values, (e) => e.wire, v, StackStatus.active, 'stack_status');
}

enum QuizMode {
  freehand('freehand'),
  byBucket('by_bucket'),
  byNode('by_node');

  const QuizMode(this.wire);
  final String wire;
  static QuizMode fromWire(Object? v) =>
      parseEnum(values, (e) => e.wire, v, QuizMode.freehand, 'quiz_mode');
}

enum QuizQuestionType {
  mcq('mcq'),
  shortAnswer('short_answer'),
  flashcard('flashcard'),
  mix('mix');

  const QuizQuestionType(this.wire);
  final String wire;
  static QuizQuestionType fromWire(Object? v) => parseEnum(
      values, (e) => e.wire, v, QuizQuestionType.mcq, 'quiz_question_type');
}

enum QuizAttemptStatus {
  inProgress('in_progress'),
  completed('completed'),
  abandoned('abandoned');

  const QuizAttemptStatus(this.wire);
  final String wire;
  static QuizAttemptStatus fromWire(Object? v) => parseEnum(values,
      (e) => e.wire, v, QuizAttemptStatus.inProgress, 'quiz_attempt_status');
}

enum NotificationEventType {
  sent('sent'),
  delivered('delivered'),
  opened('opened');

  const NotificationEventType(this.wire);
  final String wire;
  static NotificationEventType fromWire(Object? v) => parseEnum(values,
      (e) => e.wire, v, NotificationEventType.sent, 'notification_event_type');
}

enum StorePlatform {
  appStore('app_store'),
  playStore('play_store');

  const StorePlatform(this.wire);
  final String wire;
  static StorePlatform? fromWire(Object? v) => v == null
      ? null
      : parseEnum<StorePlatform>(
          values, (e) => e.wire, v, StorePlatform.appStore, 'store_platform');
}

enum DevicePlatform {
  ios('ios'),
  android('android');

  const DevicePlatform(this.wire);
  final String wire;
  static DevicePlatform fromWire(Object? v) =>
      parseEnum(values, (e) => e.wire, v, DevicePlatform.ios, 'device_platform');
}
