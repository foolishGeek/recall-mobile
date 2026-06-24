// Recall · RecallScaffold. The bottom-tabbed shell used by Today / Buckets /
// Quiz / Insights / You. Provides the canvas background, the safe-area top, and
// the calm five-tab bar with the active state in solid ink.
//
//   RecallScaffold(activeTab: RecallTab.insights, body: ...)
//
// If you don't want a tab bar (Paywall, Settings, Onboarding), use
// RecallScaffold.bare(body: ...) instead.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/recall_colors.dart';
import '../theme/recall_motion.dart';
import '../utils/recall_haptics.dart';

enum RecallTab { today, buckets, quiz, insights, you }

extension RecallTabMeta on RecallTab {
  String get label {
    switch (this) {
      case RecallTab.today:
        return 'Today';
      case RecallTab.buckets:
        return 'Buckets';
      case RecallTab.quiz:
        return 'Quiz';
      case RecallTab.insights:
        return 'Insights';
      case RecallTab.you:
        return 'You';
    }
  }

  String get asset => 'assets/icons/tabs/$name.svg';
}

class RecallScaffold extends StatelessWidget {
  final Widget body;
  final RecallTab? activeTab;
  final void Function(RecallTab)? onTabChange;
  final PreferredSizeWidget? topBar;

  const RecallScaffold({
    super.key,
    required this.body,
    this.activeTab,
    this.onTabChange,
    this.topBar,
  });

  const RecallScaffold.bare({super.key, required this.body, this.topBar})
      : activeTab = null,
        onTabChange = null;

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // Tab swap cross-fade (Block B3: RecallMotion.tabSwap 280ms); snaps under
    // reduced motion.
    final content = activeTab == null
        ? body
        : AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : RecallMotion.tabSwap,
            switchInCurve: RecallMotion.easeOut,
            switchOutCurve: RecallMotion.easeOut,
            child: KeyedSubtree(key: ValueKey(activeTab), child: body),
          );

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: topBar,
      body: SafeArea(top: topBar == null, bottom: false, child: content),
      bottomNavigationBar: activeTab == null
          ? null
          : _RecallTabBar(active: activeTab!, onChange: onTabChange),
    );
  }
}

class _RecallTabBar extends StatelessWidget {
  final RecallTab active;
  final void Function(RecallTab)? onChange;
  const _RecallTabBar({required this.active, this.onChange});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.canvas.withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: c.grey200, width: 1)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24, left: 8, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final tab in RecallTab.values)
            _TabItem(
              tab: tab,
              active: active == tab,
              onTap: () => _tap(tab),
            ),
        ],
      ),
    );
  }

  void _tap(RecallTab t) {
    RecallHaptics.selection();
    onChange?.call(t);
  }
}

class _TabItem extends StatelessWidget {
  final RecallTab tab;
  final bool active;
  final VoidCallback? onTap;
  const _TabItem({required this.tab, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final color = active ? c.ink : c.grey500;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              tab.asset,
              width: 23,
              height: 23,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 5),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
