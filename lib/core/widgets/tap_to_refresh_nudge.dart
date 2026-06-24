// Recall · TapToRefreshNudge. The quiet, dismissible "Updates available — tap to
// refresh" banner + an offline indicator, both bound to SyncStatusService
// [D-OFF-1]. It never auto-refreshes: tapping calls [onRefresh] (the screen's
// cache-first reload with forceRemote), which clears the flag on success. Drop
// it at the top of any server-truth screen's body.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/sync_status_service.dart';
import '../theme/recall_colors.dart';
import '../theme/recall_motion.dart';
import '../theme/recall_shape.dart';
import 'mono_label.dart';

class TapToRefreshNudge extends StatelessWidget {
  /// The screen's reload (typically a controller method calling a repository
  /// with `forceRemote: true`). When null, tapping just dismisses the nudge.
  final Future<void> Function()? onRefresh;
  final EdgeInsets margin;

  const TapToRefreshNudge({
    super.key,
    this.onRefresh,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final status = Get.find<SyncStatusService>();
    return Obx(() {
      final Widget child;
      if (status.isOffline.value) {
        child = const _OfflinePill();
      } else if (status.hasUpdates.value) {
        child = _UpdatesBanner(onRefresh: () => _refresh(status));
      } else {
        child = const SizedBox.shrink();
      }
      return AnimatedSize(
        duration: RecallMotion.normal,
        curve: RecallMotion.easeOut,
        child: child is SizedBox
            ? child
            : Padding(padding: margin, child: child),
      );
    });
  }

  Future<void> _refresh(SyncStatusService status) async {
    if (onRefresh == null) {
      status.clearUpdates();
      return;
    }
    await onRefresh!();
  }
}

class _UpdatesBanner extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _UpdatesBanner({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return GestureDetector(
      onTap: onRefresh,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.cardSunken,
          borderRadius: BorderRadius.circular(RecallShape.radiusSm),
          border: Border.all(color: c.grey200, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.refresh, size: 16, color: c.grey600),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Updates available — tap to refresh',
                style: TextStyle(fontSize: 13, height: 1.3, color: c.grey600),
              ),
            ),
            const MonoLabel('REFRESH'),
          ],
        ),
      ),
    );
  }
}

class _OfflinePill extends StatelessWidget {
  const _OfflinePill();

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: c.cardSunken,
        borderRadius: BorderRadius.circular(RecallShape.radiusSm),
        border: Border.all(color: c.grey200, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 15, color: c.grey500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline — showing saved data',
              style: TextStyle(fontSize: 13, height: 1.3, color: c.grey500),
            ),
          ),
        ],
      ),
    );
  }
}
