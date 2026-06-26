// Recall · PaywallController. Orchestrates the upgrade flow: reads the
// server-authoritative tier + the live store offering, runs purchase / restore
// / credit-pack I/O through RevenueCatService, then polls the backend
// (revenuecat-webhook → subscriptions) until the tier flips. No billing logic
// here — the server is the source of truth [D-OFF-1] [D-PAY-2].

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/gates/tier_gate.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/revenuecat_service.dart';
import '../../../data/services/tier_service.dart';

const _kMonthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Native OS subscription-management deep links (mirrors `you_controller`).
const _kIosManageSubscriptions =
    'https://apps.apple.com/account/subscriptions';
const _kAndroidManageSubscriptions =
    'https://play.google.com/store/account/subscriptions';

class PaywallController extends BaseController {
  PaywallController(
    this._revenueCat,
    this._profiles,
    this._tierService,
    this._auth,
  );

  final RevenueCatService _revenueCat;
  final ProfileRepository _profiles;
  final TierService _tierService;
  final AuthService _auth;

  // ── State (server-authoritative + store) ──────────────────────────────────
  final Rx<SubscriptionTier> tier = SubscriptionTier.free.obs;
  final Rxn<Subscription> subscription = Rxn<Subscription>();
  final Rxn<Profile> profile = Rxn<Profile>();
  final Rxn<Offering> offering = Rxn<Offering>();
  final RxList<StoreProduct> creditProducts = <StoreProduct>[].obs;

  /// False when the store/offering is unreachable → CTA disabled, "Price
  /// unavailable — try again".
  final RxBool storeReachable = true.obs;
  final RxBool yearlySelected = false.obs;
  final RxBool busy = false.obs;

  /// Quiet, transient line under the CTAs ("Nothing to restore", errors).
  final RxnString notice = RxnString();

  TierGate get gate => TierGate(tier.value);
  bool get isPremium => tier.value == SubscriptionTier.premium;

  Package? get monthlyPackage => _packageFor(
        RevenueCatService.monthlyProductId,
        offering.value?.monthly,
      );
  Package? get yearlyPackage => _packageFor(
        RevenueCatService.yearlyProductId,
        offering.value?.annual,
      );

  String? get monthlyPriceString => monthlyPackage?.storeProduct.priceString;
  String? get yearlyPriceString => yearlyPackage?.storeProduct.priceString;

  Package? get selectedPackage =>
      yearlySelected.value ? yearlyPackage : monthlyPackage;

  /// True once both store packages resolved and prices are live.
  bool get hasPricing =>
      storeReachable.value && monthlyPackage != null && yearlyPackage != null;

  int get creditBalance => profile.value?.aiCreditBalance ?? 0;

  StoreProduct? get credits100 =>
      _creditProduct(RevenueCatService.credits100ProductId);
  StoreProduct? get credits500 =>
      _creditProduct(RevenueCatService.credits500ProductId);

  /// "renews 14 Jul" / "expires 14 Jul" depending on auto-renew. Null when the
  /// date is unknown.
  String? get renewsLabel {
    final d = subscription.value?.expiresAt?.toLocal();
    if (d == null) return null;
    final day = d.day;
    final mon = _kMonthAbbr[(d.month - 1).clamp(0, 11)];
    final verb = subscription.value?.willRenew == true ? 'renews' : 'expires';
    return '$verb $day $mon';
  }

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    setLoading();
    await _refreshTier();
    await _loadStore();
    setSuccess();
    _track('paywall_viewed', {'tier': tier.value.name});
  }

  /// Pulls the offering (and, for premium, the consumable credit packs). A store
  /// failure or missing offering flips [storeReachable] off rather than erroring.
  Future<void> _loadStore() async {
    try {
      offering.value = await _revenueCat.fetchOffering();
      storeReachable.value = offering.value != null;
      if (isPremium) {
        creditProducts.assignAll(await _revenueCat.fetchCreditProducts());
      }
    } catch (e, st) {
      storeReachable.value = false;
      _capture(e, st, 'load_store');
    }
  }

  Future<void> _refreshTier() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    try {
      final r = await _profiles.refreshEntitlement(userId);
      subscription.value = r.subscription;
      profile.value = r.profile;
      _tierService.applyEntitlement(subscription: r.subscription, profile: r.profile);
      tier.value = _tierService.tier;
    } catch (_) {
      // Keep the last known tier; the screen still renders.
    }
  }

  // ── Intents ────────────────────────────────────────────────────────────────
  void toggleYearly(bool yearly) {
    if (yearlySelected.value == yearly) return;
    RecallHaptics.selection();
    yearlySelected.value = yearly;
  }

  /// Go Premium → medium haptic BEFORE the store sheet, purchase the selected
  /// package, then wait for the webhook to flip the tier (server truth).
  Future<void> onPurchase() async {
    final pkg = selectedPackage;
    if (pkg == null || busy.value) return;

    RecallHaptics.medium();
    _track('purchase_started', {'product': pkg.storeProduct.identifier});
    busy.value = true;
    notice.value = null;
    try {
      final info = await _revenueCat.purchasePackage(pkg);
      final flipped = await _waitForPremium();
      if (!flipped && _revenueCat.hasPremium(info)) {
        // Entitlement is active per RC; let the UI advance while the webhook
        // catches up (server remains authoritative on next read).
        tier.value = SubscriptionTier.premium;
        _tierService.setTier(SubscriptionTier.premium);
      }
      _track('purchase_succeeded', {'product': pkg.storeProduct.identifier});
      if (!isClosed) Get.back<bool>(result: true);
    } on PlatformException catch (e, st) {
      _handlePurchaseError(e, st, kind: 'purchase');
    } catch (e, st) {
      _handlePurchaseError(e, st, kind: 'purchase');
    } finally {
      busy.value = false;
    }
  }

  Future<void> onRestore() async {
    if (busy.value) return;
    RecallHaptics.selection();
    _track('restore_tapped', const {});
    busy.value = true;
    notice.value = null;
    try {
      final info = await _revenueCat.restore();
      if (_revenueCat.hasPremium(info)) {
        await _waitForPremium();
        await _refreshTier();
        if (!isClosed) Get.back<bool>(result: true);
      } else {
        notice.value = 'Nothing to restore.';
        _scheduleNoticeClear();
      }
    } on PlatformException catch (e, st) {
      _handlePurchaseError(e, st, kind: 'restore');
    } catch (e, st) {
      _handlePurchaseError(e, st, kind: 'restore');
    } finally {
      busy.value = false;
    }
  }

  /// Premium-only consumable buy (`ai_credits_100`/`ai_credits_500`). Balance is
  /// granted by the webhook; we re-read the profile after.
  Future<void> onBuyCredits(StoreProduct product) async {
    if (busy.value || !isPremium) return;
    RecallHaptics.medium();
    busy.value = true;
    notice.value = null;
    try {
      await _revenueCat.purchaseProduct(product);
      await _waitForCredits();
      _track('credits_purchased', {'product': product.identifier});
    } on PlatformException catch (e, st) {
      _handlePurchaseError(e, st, kind: 'credits');
    } catch (e, st) {
      _handlePurchaseError(e, st, kind: 'credits');
    } finally {
      busy.value = false;
    }
  }

  Future<void> onManageStore() async {
    RecallHaptics.selection();
    _track('manage_subscription_tapped', {'tier': tier.value.name});
    final url = Platform.isIOS || Platform.isMacOS
        ? _kIosManageSubscriptions
        : _kAndroidManageSubscriptions;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e, st) {
      _capture(e, st, 'manage_store');
    }
  }

  void onCloseTapped() => Get.back<bool>(result: isPremium);

  // ── Polling (server truth; webhook may lag the purchase up to ~60s) ─────────
  Future<bool> _waitForPremium() async {
    final userId = _auth.currentUserId;
    if (userId == null) return false;
    for (var attempt = 0; attempt < 12; attempt++) {
      try {
        final r = await _profiles.refreshEntitlement(userId);
        subscription.value = r.subscription;
        profile.value = r.profile;
        if (r.subscription?.tier == SubscriptionTier.premium) {
          tier.value = SubscriptionTier.premium;
          _tierService.setTier(SubscriptionTier.premium);
          return true;
        }
      } catch (_) {
        // transient — keep polling
      }
      if (isClosed) return false;
      await Future<void>.delayed(const Duration(seconds: 5));
    }
    return false;
  }

  Future<void> _waitForCredits() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    final before = creditBalance;
    for (var attempt = 0; attempt < 12; attempt++) {
      try {
        final p = await _profiles.fetchProfile(userId);
        profile.value = p;
        if ((p?.aiCreditBalance ?? 0) > before) return;
      } catch (_) {/* transient */}
      if (isClosed) return;
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  // ── Errors / analytics ──────────────────────────────────────────────────────
  void _handlePurchaseError(Object e, StackTrace st, {required String kind}) {
    if (e is PlatformException &&
        PurchasesErrorHelper.getErrorCode(e) ==
            PurchasesErrorCode.purchaseCancelledError) {
      return; // user backed out — calm return, no error.
    }
    notice.value = 'Something went wrong — please try again.';
    _scheduleNoticeClear();
    _track('purchase_failed', {'kind': kind});
    _capture(e, st, kind);
  }

  void _scheduleNoticeClear() {
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (!isClosed) notice.value = null;
    });
  }

  void _capture(Object e, StackTrace st, String op) {
    Sentry.captureException(
      e,
      stackTrace: st,
      withScope: (s) {
        s.setTag('feature', 'paywall');
        s.setTag('op', op);
      },
    );
  }

  void _track(String name, Map<String, dynamic> params) {
    if (!_auth.analyticsOptIn) return;
    Sentry.addBreadcrumb(
      Breadcrumb(category: 'analytics', message: name, data: params),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Package? _packageFor(String productId, Package? fallback) {
    for (final p in offering.value?.availablePackages ?? const <Package>[]) {
      if (p.storeProduct.identifier == productId) return p;
    }
    return fallback;
  }

  StoreProduct? _creditProduct(String id) {
    for (final p in creditProducts) {
      if (p.identifier == id) return p;
    }
    return null;
  }
}
