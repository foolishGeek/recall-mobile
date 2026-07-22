import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/how_it_works_copy.dart';
import '../../../core/utils/recall_haptics.dart';
import '../../../core/widgets/recall_coach_tip.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../../../core/widgets/tap_to_refresh_nudge.dart';
import '../../empty/view/widgets/empty_buckets_body.dart';
import '../controller/buckets_controller.dart';
import 'widgets/buckets_action_bar.dart';
import 'widgets/buckets_filter_row.dart';
import 'widgets/buckets_grid.dart';
import 'widgets/buckets_header.dart';
import 'widgets/buckets_search_field.dart';
import 'widgets/buckets_top_bar.dart';
import 'widgets/create_bucket_sheet.dart';

class BucketsView extends GetView<BucketsController> {
  const BucketsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return RecallStateView(
        state: controller.viewState,
        errorMessage: controller.errorMessage,
        onRetry: () => controller.reload(forceRemote: true),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!controller.hasBuckets) {
              return Column(
                children: [
                  TapToRefreshNudge(
                    onRefresh: () => controller.reload(forceRemote: true),
                  ),
                  Expanded(
                    child: EmptyBucketsBody(
                      onMakeBucket: () => _onCreateBucket(context),
                      onSearchTap: controller.toggleSearch,
                    ),
                  ),
                ],
              );
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 96),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight - 24),
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
                          if (!controller.showRevisionCoachTip.value) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(6, 10, 6, 2),
                            child: RecallCoachTip(
                              text: HowItWorksCopy.bucketsTip,
                              howItWorksTitle: HowItWorksCopy.bucketsTitle,
                              howItWorksSections: HowItWorksCopy.bucketsSections,
                              onDismiss: controller.dismissRevisionCoachTip,
                            ),
                          );
                        }),
                        Obx(() => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BucketsFilterRow(
                                  current: controller.activeFilter.value,
                                  onChanged: controller.onFilterChanged,
                                ),
                                BucketsGrid(
                                  buckets: controller.filteredBuckets,
                                  controller: controller,
                                  staggerController:
                                      controller.staggerController,
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 20,
                  child: Obx(() => BucketsActionBar(
                        bucketLocked: controller.fabLocked,
                        onCreateBucket: () => _onCreateBucket(context),
                        onCreateNote: controller.onCreateNoteTap,
                      )),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  void _onCreateBucket(BuildContext context) {
    RecallHaptics.light();
    if (controller.fabLocked) {
      controller.onBucketLimitTap();
      return;
    }
    CreateBucketSheet.show(
      context,
      onCreate: controller.createBucket,
    );
  }
}
