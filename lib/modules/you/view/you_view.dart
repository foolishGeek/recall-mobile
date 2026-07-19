// Recall · YouView. A profile written like an essay, not a scoreboard. Renders
// one of two variants inside the You tab: premium (memory-simulation hero +
// curve, level ring, achievements, lifetime, Settings + Manage subscription) or
// free (upgrade-CTA hero, 3-up stats, level, Settings). Pure UI — every number
// comes from the controller's server-authoritative loads.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/recall_state_view.dart';
import '../../../core/widgets/staggered_reveal.dart';
import '../controller/you_controller.dart';
import 'widgets/you_achievements_card.dart';
import 'widgets/you_chrome.dart';
import 'widgets/you_free_stats.dart';
import 'widgets/you_hero_card.dart';
import 'widgets/you_level_card.dart';
import 'widgets/you_lifetime_card.dart';
import 'widgets/you_rows_card.dart';
import 'widgets/you_upgrade_hero.dart';

class YouView extends GetView<YouController> {
  const YouView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => RecallStateView(
        state: controller.viewState,
        errorMessage: controller.errorMessage,
        onRetry: controller.reload,
        child: Obx(
          () => controller.showSimulation
              ? _PremiumBody(controller: controller)
              : _FreeBody(controller: controller),
        ),
      ),
    );
  }
}

/// Identity (top bar + avatar) shared by both variants.
class _Identity extends StatelessWidget {
  final YouController controller;
  final bool premium;
  const _Identity({required this.controller, required this.premium});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YouTopBar(premium: premium),
        const SizedBox(height: 14),
        YouIdentityRow(
          initial: controller.avatarInitial,
          name: controller.displayName,
          email: controller.email,
        ),
      ],
    );
  }
}

class _Scroll extends StatelessWidget {
  final List<Widget> children;
  const _Scroll({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _PremiumBody extends StatelessWidget {
  final YouController controller;
  const _PremiumBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final stagger = controller.staggerController;
    final retention = controller.retention.value;
    return _Scroll(
      children: [
        StaggeredReveal(
          index: 0,
          controller: stagger,
          child: _Identity(
            controller: controller,
            premium: controller.isPremium,
          ),
        ),
        const SizedBox(height: 18),
        // The hero owns its 360ms fade + 8px lift, so it is not wrapped in the
        // card-arrival stagger (which would double the motion).
        if (retention != null)
          YouHeroCard(
            retention: retention,
            firstReveal: controller.firstHeroReveal,
          ),
        if (retention != null) const SizedBox(height: 12),
        StaggeredReveal(
          index: 2,
          controller: stagger,
          child: YouLevelCard(
            band: controller.levelBand,
            title: controller.levelTitle,
            premium: true,
          ),
        ),
        const SizedBox(height: 10),
        StaggeredReveal(
          index: 3,
          controller: stagger,
          child: YouAchievementsCard(
            earned: controller.earnedAchievements,
            unlockedCount: controller.unlockedCount,
            newlyUnlocked: controller.newlyUnlocked,
          ),
        ),
        const SizedBox(height: 10),
        StaggeredReveal(
          index: 4,
          controller: stagger,
          child: YouLifetimeCard(
            memoriesSaved: controller.memoriesSaved,
            totalReviews: controller.totalReviews,
            totalNodes: controller.lifetime.value?.totalNodes ?? 0,
            adherencePct: controller.lifetime.value?.lifetimeAdherencePct,
            sinceLabel: controller.memberSinceLabel,
          ),
        ),
        const SizedBox(height: 10),
        StaggeredReveal(
          index: 5,
          controller: stagger,
          child: YouRowsCard(
            premium: controller.isPremium,
            onSettings: controller.onSettings,
            onManageSubscription: controller.onManageSubscription,
          ),
        ),
      ],
    );
  }
}

class _FreeBody extends StatelessWidget {
  final YouController controller;
  const _FreeBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final stagger = controller.staggerController;
    return _Scroll(
      children: [
        StaggeredReveal(
          index: 0,
          controller: stagger,
          child: _Identity(controller: controller, premium: false),
        ),
        const SizedBox(height: 18),
        StaggeredReveal(
          index: 1,
          controller: stagger,
          child: YouUpgradeHero(
            onUnlock: controller.onUpgrade,
            subtitle: controller.isDowngraded
                ? 'Subscription expired — unlock to continue'
                : null,
          ),
        ),
        const SizedBox(height: 12),
        StaggeredReveal(
          index: 2,
          controller: stagger,
          child: YouFreeStats(
            xp: controller.xp,
            streak: controller.currentStreak,
            reviews: controller.totalReviews,
          ),
        ),
        const SizedBox(height: 10),
        StaggeredReveal(
          index: 3,
          controller: stagger,
          child: YouLevelCard(
            band: controller.levelBand,
            title: controller.levelTitle,
            premium: false,
          ),
        ),
        const SizedBox(height: 10),
        StaggeredReveal(
          index: 4,
          controller: stagger,
          child: YouRowsCard(
            premium: false,
            onSettings: controller.onSettings,
            onManageSubscription: controller.onManageSubscription,
          ),
        ),
      ],
    );
  }
}
