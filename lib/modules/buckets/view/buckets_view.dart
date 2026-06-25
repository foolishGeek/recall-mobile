import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/recall_state_view.dart';
import '../../../core/widgets/tap_to_refresh_nudge.dart';
import '../controller/buckets_controller.dart';
import 'widgets/buckets_fab.dart';
import 'widgets/buckets_filter_row.dart';
import 'widgets/buckets_grid.dart';
import 'widgets/buckets_header.dart';
import 'widgets/buckets_search_field.dart';
import 'widgets/buckets_top_bar.dart';

class BucketsView extends GetView<BucketsController> {
  const BucketsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return RecallStateView(
        state: controller.viewState,
        errorMessage: controller.errorMessage,
        onRetry: () => controller.reload(forceRemote: true),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TapToRefreshNudge(
                    onRefresh: () => controller.reload(forceRemote: true),
                  ),
                  BucketsTopBar(onSearchTap: controller.toggleSearch),
                  Obx(() => BucketsSearchField(
                        visible: controller.isSearchVisible.value,
                        onChanged: controller.onSearchChanged,
                      )),
                  Obx(() => BucketsHeader(
                        bucketCount: controller.bucketCount.value,
                        nodeCount: controller.nodeCount.value,
                      )),
                  Obx(() => BucketsFilterRow(
                        current: controller.activeFilter.value,
                        onChanged: controller.onFilterChanged,
                      )),
                  Obx(() => BucketsGrid(
                        buckets: controller.filteredBuckets,
                        controller: controller,
                        staggerController: controller.staggerController,
                      )),
                ],
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: Obx(() => BucketsFab(
                    locked: controller.fabLocked,
                    onTap: controller.onFabTap,
                  )),
            ),
          ],
        ),
      );
    });
  }
}
