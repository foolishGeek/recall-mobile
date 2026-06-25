import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/widgets/recall_scaffold.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../../../data/models/models.dart';
import '../controller/node_controller.dart';
import 'widgets/node_ai_eval_panel.dart';
import 'widgets/node_ask_ai_bar.dart';
import 'widgets/node_body_image.dart';
import 'widgets/node_body_link_card.dart';
import 'widgets/node_body_markdown.dart';
import 'widgets/node_body_pdf.dart';
import 'widgets/node_body_youtube.dart';
import 'widgets/node_chip_row.dart';
import 'widgets/node_eyebrow.dart';
import 'widgets/node_heat_row.dart';
import 'widgets/node_tag_chips.dart';
import 'widgets/node_top_bar.dart';

class NodeView extends GetView<NodeController> {
  const NodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return RecallScaffold.bare(
      body: Column(
        children: [
          Expanded(
            child: Obx(() => RecallStateView(
                  state: controller.viewState,
                  errorMessage: controller.errorMessage,
                  onRetry: controller.reload,
                  child: _body(context),
                )),
          ),
          Obx(() {
            if (!controller.showAskAi) return const SizedBox.shrink();
            return NodeAskAiBar(
              modelLabel: controller.aiModelLabel.value,
              isLoading: controller.isAskingAi.value,
              result: controller.ragResult.value,
              error: controller.ragError.value,
              onSend: controller.onAskAiSend,
              onClear: controller.clearRagResult,
            );
          }),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final c = RecallColors.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _topSection(c)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(child: _contentSection(c)),
        ),
        if (controller.showAiPanel)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(child: _aiEvalPanel()),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _topSection(RecallColors c) {
    final n = controller.node.value;
    if (n == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => NodeTopBar(
              bucketName: controller.bucketName.value,
              onBack: () => Get.back(),
              onEdit: controller.onEditTap,
              onMore: () {},
            )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => NodeEyebrow(
                    bucketName: controller.bucketName.value ?? '',
                    typeLabel: controller.nodeTypeLabel,
                    editedAgo: controller.editedAgoLabel,
                  )),
              const SizedBox(height: 14),
              Text(
                n.title,
                style: GoogleFonts.fraunces(
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                  color: c.ink,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 18),
              Obx(() => NodeHeatRow(
                    heatPct: controller.heatPct.value,
                    dueLabel: controller.dueAgoLabel,
                  )),
              const SizedBox(height: 18),
              Obx(() {
                final n = controller.node.value;
                if (n == null) return const SizedBox.shrink();
                return NodeChipRow(
                  priority: n.priority,
                  difficulty: n.difficulty,
                  comfort: n.comfort,
                  comfortReadOnly: controller.hasReviews.value,
                  priorityLabel: controller.priorityLabel(n.priority),
                  difficultyLabel: controller.difficultyLabel(n.difficulty),
                  comfortLabel: NodeController.comfortLabel(n.comfort),
                  priorityLevel: controller.priorityLevel(n.priority),
                  difficultyLevel: controller.difficultyLevel(n.difficulty),
                  comfortLevel: controller.comfortLevelFor(n.comfort),
                  onPriorityTap: controller.onPriorityTap,
                  onDifficultyTap: controller.onDifficultyTap,
                  onComfortTap: controller.onComfortTap,
                );
              }),
              const SizedBox(height: 14),
              Obx(() => NodeTagChips(
                    tags: controller.tags.toList(),
                    onAddTap: controller.onEditTap,
                  )),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contentSection(RecallColors c) {
    return Obx(() {
      final n = controller.node.value;
      if (n == null) return const SizedBox.shrink();

      final hasMarkdown = n.markdown != null && n.markdown!.trim().isNotEmpty;

      // Combine the node's primary structured preview with any links surfaced
      // from the markdown body, splitting into web links and YouTube videos.
      final links = <LinkPreview>[];
      final videos = <LinkPreview>[];
      void classify(LinkPreview? lp) {
        if (lp == null) return;
        if (lp.videoId != null && lp.videoId!.isNotEmpty) {
          videos.add(lp);
        } else {
          links.add(lp);
        }
      }

      classify(n.linkPreview);
      for (final lp in controller.contentLinks) {
        classify(lp);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Markdown body (always show if content exists)
          if (hasMarkdown) ...[
            NodeBodyMarkdown(markdown: n.markdown!),
            const SizedBox(height: 20),
          ],

          // LINKED section (link cards — non-YouTube links)
          if (links.isNotEmpty) ...[
            _sectionLabel('LINKED', c),
            const SizedBox(height: 10),
            for (int i = 0; i < links.length; i++) ...[
              NodeBodyLinkCard(
                preview: links[i],
                onTap: () => controller.openUrl(links[i].canonicalUrl),
              ),
              if (i != links.length - 1) const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
          ],

          // WATCH section (YouTube videos)
          if (videos.isNotEmpty) ...[
            _sectionLabel('WATCH', c),
            const SizedBox(height: 10),
            for (int i = 0; i < videos.length; i++) ...[
              _videoCard(c, videos[i]),
              if (i != videos.length - 1) const SizedBox(height: 16),
            ],
            const SizedBox(height: 20),
          ],

          // ATTACHMENTS section (PDFs/images — always shown if assets exist)
          if (controller.assets.isNotEmpty) ...[
            _sectionLabel(
              'ATTACHMENTS · ${controller.assets.length}',
              c,
            ),
            const SizedBox(height: 10),
            _attachmentsThumbnails(n, c),
          ],
        ],
      );
    });
  }

  Widget _videoCard(RecallColors c, LinkPreview lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NodeBodyYoutube(
          videoId: lp.videoId!,
          durationLabel: controller.youtubeDurationLabel(lp.durationSec),
          onTap: () => controller.openYoutube(lp.videoId),
        ),
        const SizedBox(height: 10),
        if (lp.siteName != null || lp.title != null)
          Text(
            [
              if (lp.siteName != null) lp.siteName!,
              if (lp.title != null) lp.title!,
            ].join(' · '),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.ink,
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (lp.viewCount != null) ...[
          const SizedBox(height: 3),
          Text(
            _formatViewCount(lp.viewCount!),
            style: GoogleFonts.inter(fontSize: 11.5, color: c.grey500),
          ),
        ],
      ],
    );
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M views';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K views';
    return '$count views';
  }

  Widget _sectionLabel(String text, RecallColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
          color: c.grey500,
          letterSpacing: 0.18 * 9.5,
        ),
      ),
    );
  }

  Widget _attachmentsThumbnails(Node n, RecallColors c) {
    return Obx(() {
      if (controller.assets.isEmpty) return const SizedBox.shrink();
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: controller.assets.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3 / 4,
        ),
        itemBuilder: (_, i) {
          final asset = controller.assets[i];
          final signedUrl = controller.signedUrls[asset.id];
          final isPdf = asset.mimeType.contains('pdf');
          final sizeLabel = _fileSizeLabel(asset.fileSizeBytes);
          if (isPdf) {
            final pdfLabel = asset.pageCount != null
                ? '$sizeLabel · ${asset.pageCount}p'
                : sizeLabel;
            return NodeBodyPdf(
              signedUrl: signedUrl,
              sizeLabel: pdfLabel,
            );
          }
          return NodeBodyImage(
            signedUrl: signedUrl,
            sizeLabel: sizeLabel,
          );
        },
      );
    });
  }

  String _fileSizeLabel(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _aiEvalPanel() {
    return Obx(() {
      if (!controller.showAiPanel) return const SizedBox.shrink();
      return NodeAiEvalPanel(
        qualityScore: controller.qualityScore,
        qualityProgress: controller.qualityProgress,
        scoreDisplay: controller.qualityScoreDisplay,
        suggestedComfortLabel: controller.suggestedComfortLabel,
        suggestedComfortLevel: controller.suggestedComfortLevel,
        feedback: controller.evalFeedback,
        modelLabel: controller.aiModelLabel.value,
        isLoading: controller.isEvalLoading.value,
        overviewLocked: controller.overviewLocked,
        quotaLabel: controller.overviewQuotaLabel,
        onApply: controller.onApplySuggestion,
        onRegenerate: controller.onRegenerateTap,
      );
    });
  }
}
