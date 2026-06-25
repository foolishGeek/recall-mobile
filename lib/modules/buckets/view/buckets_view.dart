import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/recall_colors.dart';
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
                  Obx(() {
                    if (!controller.hasBuckets) {
                      return _EmptyBucketsBody();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BucketsFilterRow(
                          current: controller.activeFilter.value,
                          onChanged: controller.onFilterChanged,
                        ),
                        BucketsGrid(
                          buckets: controller.filteredBuckets,
                          controller: controller,
                          staggerController: controller.staggerController,
                        ),
                      ],
                    );
                  }),
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

class _EmptyBucketsBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_outlined, size: 48, color: c.grey400),
            const SizedBox(height: 16),
            Text(
              'No buckets yet',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first bucket',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: c.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
