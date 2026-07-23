// Recall · SettingsController — account + subscription actions [S24].
// Part of settings_controller.dart (shares its imports + privacy). Export /
// sign-out / delete and the RevenueCat restore / manage / buy-credits I/O live
// here to keep the main controller focused on the schema-backed prefs.

part of 'settings_controller.dart';

/// Native OS subscription-management deep links (mirrors paywall/you).
const _kIosManageSubscriptions =
    'https://apps.apple.com/account/subscriptions';
const _kAndroidManageSubscriptions =
    'https://play.google.com/store/account/subscriptions';

const _kPrivacyUrl = 'https://ripplelabs.in/recall/privacy';
const _kTermsUrl = 'https://ripplelabs.in/recall/tos';
const _kHelpUrl = 'https://ripplelabs.in/recall/help';

extension SettingsActions on SettingsController {
  // ── Data export (server-built zip → short-lived signed URL) ───────────────
  Future<void> onExport() async {
    if (exporting.value || isOffline) return;
    RecallHaptics.selection();
    exporting.value = true;
    exportError.value = null;
    notice.value = null;
    try {
      final status = await _profiles.requestExport();
      exportStatus.value = status;
      _track('data_exported', const {});
      await _shareExport();
    } on RepoException catch (e, st) {
      exportError.value = e.message;
      _capture(e, st, 'export');
    } catch (e, st) {
      exportError.value = "Couldn't prepare your export — try again.";
      _capture(e, st, 'export');
    } finally {
      exporting.value = false;
    }
  }

  /// Re-share the existing export (the row's "Share" affordance once ready).
  Future<void> onShareExport() async {
    if (exportStatus.value?.hasFile == true) {
      RecallHaptics.selection();
      await _shareExport();
    }
  }

  /// Downloads the signed zip to a temp file, then opens the OS share sheet with
  /// the actual file (sharing a bare URL often shows nothing useful on mobile).
  Future<void> _shareExport() async {
    final url = exportStatus.value?.signedUrl;
    if (url == null || url.isEmpty) {
      exportError.value = 'No export file — tap to try again.';
      return;
    }
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        exportError.value = "Couldn't download your export — try again.";
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/recall-export.zip';
      final file = File(path);
      await file.writeAsBytes(res.bodyBytes, flush: true);
      await Share.shareXFiles(
        [XFile(path, mimeType: 'application/zip', name: 'recall-export.zip')],
        subject: 'Your Recall data export',
      );
      exportError.value = null;
    } catch (e, st) {
      exportError.value = "Couldn't share your export — try again.";
      _capture(e, st, 'share_export');
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> onSignOut() async {
    _track('sign_out', const {});
    try {
      await _auth.signOut();
    } catch (e, st) {
      _capture(e, st, 'sign_out');
    }
    Get.offAllNamed(Routes.signin);
  }

  // ── Delete account (server success required before sign-out) ───────────────
  Future<void> onDeleteAccount() async {
    if (deleting.value) return;
    deleting.value = true;
    notice.value = null;
    try {
      await _profiles.deleteAccount();
      _track('account_deleted', const {});
      // Only now is it safe to drop the session + local cache.
      await Get.find<LocalStore>().clearAll();
      await _auth.signOut();
      RecallHaptics.heavy();
      Get.offAllNamed(Routes.signin);
    } on RepoException catch (e, st) {
      deleting.value = false;
      _notify("We couldn't delete your account — try again.");
      _capture(e, st, 'delete_account');
    }
  }

  // ── Subscription ──────────────────────────────────────────────────────────
  Future<void> onRestore() async {
    if (restoring.value) return;
    RecallHaptics.selection();
    restoring.value = true;
    notice.value = null;
    try {
      final info = await _revenueCat.restore();
      if (_revenueCat.hasPremium(info)) {
        await _refreshEntitlement();
        _notify('Purchases restored.');
      } else {
        _notify('Nothing to restore.');
      }
      _track('restore_tapped', const {});
    } on PlatformException catch (e, st) {
      _handleStoreError(e, st, 'restore');
    } catch (e, st) {
      _handleStoreError(e, st, 'restore');
    } finally {
      restoring.value = false;
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

  /// Premium-only consumable buy; balance is granted by the webhook, so we poll
  /// the profile until it increases (mirrors paywall_controller).
  Future<void> onBuyCredits(StoreProduct product) async {
    if (buyingCredits.value || !isPremium) return;
    RecallHaptics.medium();
    buyingCredits.value = true;
    notice.value = null;
    try {
      await _revenueCat.purchaseProduct(product);
      await _waitForCredits();
      _track('credits_purchased', {'product': product.identifier});
    } on PlatformException catch (e, st) {
      _handleStoreError(e, st, 'credits');
    } catch (e, st) {
      _handleStoreError(e, st, 'credits');
    } finally {
      buyingCredits.value = false;
    }
  }

  void onUpgrade() {
    RecallHaptics.light();
    _track('upgrade_cta_tapped', {'tier': tier.value.name});
    _tier.openPaywall();
  }

  Future<void> onOpenPrivacy() => _launch(_kPrivacyUrl, 'privacy');
  Future<void> onOpenTerms() => _launch(_kTermsUrl, 'terms');
  Future<void> onOpenHelp() => _launch(_kHelpUrl, 'help');

  // ── Internals ─────────────────────────────────────────────────────────────
  Future<void> _refreshEntitlement() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    try {
      final r = await _profiles.refreshEntitlement(userId);
      subscription.value = r.subscription;
      profile.value = r.profile;
      _tier.applyEntitlement(subscription: r.subscription, profile: r.profile);
      tier.value = _tier.tier;
    } catch (_) {
      // keep last known state
    }
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

  Future<void> _launch(String url, String op) async {
    RecallHaptics.selection();
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e, st) {
      _capture(e, st, op);
    }
  }

  void _handleStoreError(Object e, StackTrace st, String kind) {
    if (e is PlatformException &&
        PurchasesErrorHelper.getErrorCode(e) ==
            PurchasesErrorCode.purchaseCancelledError) {
      return; // user backed out — calm return.
    }
    _notify('Something went wrong — please try again.');
    _track('store_action_failed', {'kind': kind});
    _capture(e, st, kind);
  }
}
