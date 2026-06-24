// Recall · Subscription model — `subscriptions` row. `tier` is free/premium in
// the DB (downgraded is derived app-side). Server-authoritative (webhook writes).

import 'enums.dart';
import 'json_utils.dart';

class Subscription {
  final String userId;
  final SubscriptionTier tier;
  final String? revenuecatAppUserId;
  final String? productId;
  final StorePlatform? store;
  final DateTime? expiresAt;
  final bool willRenew;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Subscription({
    required this.userId,
    this.tier = SubscriptionTier.free,
    this.revenuecatAppUserId,
    this.productId,
    this.store,
    this.expiresAt,
    this.willRenew = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        userId: asString(json['user_id']),
        tier: subscriptionTierFromWire(json['tier']),
        revenuecatAppUserId: asStringOrNull(json['revenuecat_app_user_id']),
        productId: asStringOrNull(json['product_id']),
        store: StorePlatform.fromWire(json['store']),
        expiresAt: asDateTime(json['expires_at']),
        willRenew: asBool(json['will_renew']),
        createdAt: asDateTime(json['created_at']),
        updatedAt: asDateTime(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'tier': subscriptionTierToWire(tier),
        'revenuecat_app_user_id': revenuecatAppUserId,
        'product_id': productId,
        'store': store?.wire,
        'expires_at': dateToJson(expiresAt),
        'will_renew': willRenew,
        'created_at': dateToJson(createdAt),
        'updated_at': dateToJson(updatedAt),
      };

  Subscription copyWith({
    String? userId,
    SubscriptionTier? tier,
    String? revenuecatAppUserId,
    String? productId,
    StorePlatform? store,
    DateTime? expiresAt,
    bool? willRenew,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      revenuecatAppUserId: revenuecatAppUserId ?? this.revenuecatAppUserId,
      productId: productId ?? this.productId,
      store: store ?? this.store,
      expiresAt: expiresAt ?? this.expiresAt,
      willRenew: willRenew ?? this.willRenew,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
