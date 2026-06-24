// Recall · AiCreditLedgerEntry model — `ai_credit_ledger` row. Append-only
// source of truth for AI credit balance. Written server-side; read-only client.

import 'json_utils.dart';

class AiCreditLedgerEntry {
  final String id;
  final String userId;
  final int delta;
  final int balanceAfter;
  final String source; // purchase | cooldown_consume | admin_grant
  final String? revenuecatTransactionId;
  final DateTime? createdAt;

  const AiCreditLedgerEntry({
    required this.id,
    required this.userId,
    this.delta = 0,
    this.balanceAfter = 0,
    this.source = '',
    this.revenuecatTransactionId,
    this.createdAt,
  });

  factory AiCreditLedgerEntry.fromJson(Map<String, dynamic> json) =>
      AiCreditLedgerEntry(
        id: asString(json['id']),
        userId: asString(json['user_id']),
        delta: asInt(json['delta']),
        balanceAfter: asInt(json['balance_after']),
        source: asString(json['source']),
        revenuecatTransactionId:
            asStringOrNull(json['revenuecat_transaction_id']),
        createdAt: asDateTime(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'delta': delta,
        'balance_after': balanceAfter,
        'source': source,
        'revenuecat_transaction_id': revenuecatTransactionId,
        'created_at': dateToJson(createdAt),
      };

  AiCreditLedgerEntry copyWith({
    String? id,
    String? userId,
    int? delta,
    int? balanceAfter,
    String? source,
    String? revenuecatTransactionId,
    DateTime? createdAt,
  }) {
    return AiCreditLedgerEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      delta: delta ?? this.delta,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      source: source ?? this.source,
      revenuecatTransactionId:
          revenuecatTransactionId ?? this.revenuecatTransactionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
