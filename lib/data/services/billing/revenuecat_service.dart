// Recall · RevenueCatService. Thin I/O wrapper over the RevenueCat SDK
// (purchases_flutter). No business rules: tier + credit truth lives on the
// backend (revenuecat-webhook → subscriptions/profiles). This service only
// configures the SDK, mirrors the Supabase identity (RC app_user_id =
// Supabase UUID), reads offerings/prices, and runs purchase/restore I/O.
// Spec: Roadmap/sprints/S23-paywall.md · [D-PAY-1] [D-PAY-2].

import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/utils/app_env.dart';

class RevenueCatService extends GetxService {
  // Canonical SKUs + entitlement / offering [D-PAY-1].
  // Play Billing uses `productId:basePlanId` store identifiers; App Store uses
  // the bare product id. Match both via [matchesProductId].
  static const String monthlyProductId = 'recall_premium_monthly';
  static const String yearlyProductId = 'recall_premium_yearly';
  /// Staging Play base plan for monthly (`recall_premium_monthly:recall-01`).
  static const String playMonthlyStoreId = 'recall_premium_monthly:recall-01';
  /// Staging Play base plan for yearly (`recall_premium_yearly:recall-02`).
  static const String playYearlyStoreId = 'recall_premium_yearly:recall-02';
  static const String credits100ProductId = 'ai_credits_100';
  static const String credits500ProductId = 'ai_credits_500';
  static const String premiumEntitlement = 'premium';

  /// True when [storeId] is the canonical product or a Play `product:basePlan`.
  static bool matchesProductId(String storeId, String canonicalId) =>
      storeId == canonicalId || storeId.startsWith('$canonicalId:');

  bool _configured = false;

  /// True once `Purchases.configure` succeeded. When the API key is absent
  /// (local dev / tests) the service stays a no-op so the app still boots.
  bool get isConfigured => _configured;

  Future<void> configure() async {
    if (_configured || AppEnv.revenueCatApiKey.isEmpty) return;
    await Purchases.configure(
      PurchasesConfiguration(AppEnv.revenueCatApiKey),
    );
    _configured = true;
  }

  /// Aligns the RC subscriber with the signed-in Supabase user so webhook
  /// events resolve to the right profile.
  Future<void> logIn(String userId) async {
    if (!_configured) return;
    await Purchases.logIn(userId);
  }

  Future<void> logOut() async {
    if (!_configured) return;
    await Purchases.logOut();
  }

  /// The `default` offering (monthly + yearly packages). Null when the store is
  /// unreachable or no offering is configured → paywall shows the disabled
  /// "Price unavailable" state.
  Future<Offering?> fetchOffering() async {
    if (!_configured) return null;
    final offerings = await Purchases.getOfferings();
    return offerings.current;
  }

  /// Consumable AI-credit packs (non-subscription products).
  Future<List<StoreProduct>> fetchCreditProducts() async {
    if (!_configured) return const [];
    return Purchases.getProducts(
      const [credits100ProductId, credits500ProductId],
      productCategory: ProductCategory.nonSubscription,
    );
  }

  Future<CustomerInfo> purchasePackage(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return result.customerInfo;
  }

  Future<CustomerInfo> purchaseProduct(StoreProduct product) async {
    final result =
        await Purchases.purchase(PurchaseParams.storeProduct(product));
    return result.customerInfo;
  }

  Future<CustomerInfo> restore() => Purchases.restorePurchases();

  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_configured) return null;
    return Purchases.getCustomerInfo();
  }

  /// SDK-side confirmation that the premium entitlement is active (used while
  /// the webhook catches up; the server remains the source of truth).
  bool hasPremium(CustomerInfo info) =>
      info.entitlements.active.containsKey(premiumEntitlement);
}
