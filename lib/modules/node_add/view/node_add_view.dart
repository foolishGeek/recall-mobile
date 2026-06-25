import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../../../data/models/enums.dart';
import '../controller/node_add_controller.dart';
import 'widgets/bucket_selector_sheet.dart';
import 'widgets/node_add_file_drop_zone.dart';
import 'widgets/node_add_link_body.dart';
import 'widgets/node_add_text_body.dart';
import 'widgets/node_add_youtube_body.dart';
import 'widgets/node_chip_selector.dart';
import 'widgets/save_bar.dart';
import 'widgets/smart_paste_chip.dart';
import 'widgets/tag_input_chips.dart';
import 'widgets/type_segmented_control.dart';

class NodeAddView extends GetView<NodeAddController> {
  const NodeAddView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Obx(() => RecallStateView(
                    state: controller.viewState,
                    errorMessage: controller.errorMessage,
                    onRetry: () {},
                    child: _scrollBody(context, c),
                  )),
            ),
            Obx(() => SaveBar(
                  isEditMode: controller.isEditMode,
                  isSaving: controller.isSaving.value,
                  canSave: controller.canSave,
                  onSave: controller.onSave,
                  onDelete:
                      controller.isEditMode ? controller.onDeleteNode : null,
                )),
          ],
        ),
      ),
    );
  }

  Widget _scrollBody(BuildContext context, RecallColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(c),
          const SizedBox(height: 18),
          _displayTitle(c),
          const SizedBox(height: 22),

          // ── Type segmented ──
          _sectionLabel('Type', c),
          const SizedBox(height: 8),
          _typeSegment(),
          const SizedBox(height: 22),

          // ── Title field ──
          _sectionLabel('Title', c),
          const SizedBox(height: 8),
          _titleField(c),
          const SizedBox(height: 18),

          // ── Content / Smart paste ──
          _contentSectionHeader(c),
          const SizedBox(height: 8),
          _contentBody(c),
          const SizedBox(height: 18),

          // ── Notes (text mode only) ──
          _notesField(c),

          // ── Bucket ──
          _sectionLabel('Bucket', c),
          const SizedBox(height: 8),
          _bucketRow(context, c),
          const SizedBox(height: 18),

          // ── Tags ──
          _sectionLabel('Tags', c),
          const SizedBox(height: 8),
          _tagInput(c),
          _tagHint(c),
          const SizedBox(height: 22),

          // ── Chip selector ──
          _sectionLabel('Tap to cycle', c),
          const SizedBox(height: 10),
          _chipSelector(),
          const SizedBox(height: 12),
          _chipLegend(c),
          _validationError(c),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  Widget _topBar(RecallColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, size: 16, color: c.grey600),
                const SizedBox(width: 5),
                Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: c.grey600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Obx(() {
            final bucketName = controller.selectedBucket.value?.name ?? '';
            final prefix =
                controller.isEditMode ? 'Edit' : 'New node';
            return Text(
              bucketName.isEmpty ? prefix : '$prefix · $bucketName',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: c.grey500,
                letterSpacing: 0.18 * 11,
              ),
            );
          }),
          const Spacer(),
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  Widget _displayTitle(RecallColors c) {
    return Text(
      controller.isEditMode ? 'Edit node' : 'Add a node',
      style: GoogleFonts.fraunces(
        fontSize: 34,
        fontWeight: FontWeight.w500,
        color: c.ink,
        height: 1.04,
        letterSpacing: -0.02 * 34,
      ),
    );
  }

  Widget _typeSegment() {
    return Obx(() => TypeSegmentedControl(
          selected: controller.selectedType.value,
          onChanged: controller.onTypeChanged,
        ));
  }

  Widget _titleField(RecallColors c) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.grey200, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller.titleCtrl,
        style: GoogleFonts.fraunces(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: c.ink,
        ),
        decoration: InputDecoration(
          hintText: 'Give it a title…',
          hintStyle: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: c.grey400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }

  Widget _contentSectionHeader(RecallColors c) {
    return Obx(() {
      final type = controller.selectedType.value;
      final showDetected = controller.showDetectedChip.value;
      final label = type == NodeType.link || type == NodeType.youtube
          ? 'Paste anything'
          : type == NodeType.text
              ? 'Content'
              : 'Upload';

      return Row(
        children: [
          _sectionLabelWidget(label, c),
          const Spacer(),
          SmartPasteChip(
            detectedType: controller.detectedType.value,
            visible: showDetected,
          ),
        ],
      );
    });
  }

  Widget _contentBody(RecallColors c) {
    return Obx(() {
      switch (controller.selectedType.value) {
        case NodeType.text:
          return Container(
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.grey200, width: 1),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(14),
            child: NodeAddTextBody(
              controller: controller.bodyCtrl,
              onChanged: controller.onBodyOrUrlChanged,
            ),
          );
        case NodeType.link:
          return NodeAddLinkBody(
            urlCtrl: controller.urlCtrl,
            preview: controller.linkPreview.value,
            isLoading: controller.isPreviewLoading.value,
            errorText: controller.previewError.value,
            onSubmitted: controller.onUrlSubmitted,
            onChanged: controller.onBodyOrUrlChanged,
            onClearPreview: controller.clearLinkPreview,
          );
        case NodeType.youtube:
          return NodeAddYoutubeBody(
            urlCtrl: controller.urlCtrl,
            preview: controller.linkPreview.value,
            isLoading: controller.isPreviewLoading.value,
            errorText: controller.previewError.value,
            onSubmitted: controller.onUrlSubmitted,
            onChanged: controller.onBodyOrUrlChanged,
          );
        case NodeType.pdf:
          return NodeAddFileDropZone(
            isPdf: true,
            fileName: controller.pickedFileName.value,
            fileSizeBytes: controller.pickedFileSizeBytes.value,
            isUploading: controller.isUploadingFile.value,
            errorText: controller.validationError.value != null &&
                    controller.validationError.value!.contains('PDF')
                ? controller.validationError.value
                : null,
            onTap: () => _pickFile(isPdf: true),
            onClear: controller.clearPickedFile,
          );
        case NodeType.image:
          return NodeAddFileDropZone(
            isPdf: false,
            fileName: controller.pickedFileName.value,
            fileSizeBytes: controller.pickedFileSizeBytes.value,
            isUploading: controller.isUploadingFile.value,
            onTap: () => _pickFile(isPdf: false),
            onClear: controller.clearPickedFile,
          );
      }
    });
  }

  Widget _notesField(RecallColors c) {
    return Obx(() {
      final type = controller.selectedType.value;
      if (type == NodeType.text) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabelWidget('Notes', c),
              const SizedBox(width: 6),
              Text(
                '· optional',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  color: c.grey400,
                  letterSpacing: 0.18 * 9.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 78),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.grey200, width: 1),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: controller.bodyCtrl,
              maxLines: null,
              minLines: 3,
              style: GoogleFonts.fraunces(
                fontSize: 14.5,
                color: c.ink,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Add notes…',
                hintStyle: GoogleFonts.fraunces(
                  fontSize: 14.5,
                  color: c.grey400,
                  height: 1.5,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      );
    });
  }

  Widget _bucketRow(BuildContext context, RecallColors c) {
    return Obx(() {
      final bucket = controller.selectedBucket.value;
      return GestureDetector(
        onTap: () => BucketSelectorSheet.show(
          context,
          buckets: controller.writableBuckets.toList(),
          selected: bucket,
          onSelected: controller.onBucketSelected,
          onCreateBucket: controller.onCreateBucket,
        ),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(color: c.grey200, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.ink.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bucket?.name ?? 'Select bucket',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: bucket != null ? c.ink : c.grey400,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down, size: 14, color: c.grey500),
            ],
          ),
        ),
      );
    });
  }

  Widget _tagInput(RecallColors c) {
    return Obx(() => Container(
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(color: c.grey200, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(10),
          child: TagInputChips(
            tags: controller.selectedTags.toList(),
            controller: controller.tagInputCtrl,
            onCommit: controller.onTagCommit,
            onRemove: controller.onTagRemoved,
          ),
        ));
  }

  Widget _tagHint(RecallColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 18),
      child: Text(
        'Press space or comma to add',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          color: c.grey400,
        ),
      ),
    );
  }

  Widget _chipSelector() {
    return Obx(() => NodeChipSelector(
          priority: controller.priority.value,
          difficulty: controller.difficulty.value,
          comfort: controller.comfort.value,
          priorityLabel: controller.priorityLabel(controller.priority.value),
          difficultyLabel:
              controller.difficultyLabel(controller.difficulty.value),
          comfortLabel:
              NodeAddController.comfortLabel(controller.comfort.value),
          priorityLevel: controller.priorityLevel(controller.priority.value),
          difficultyLevel:
              controller.difficultyLevel(controller.difficulty.value),
          comfortLevel: controller.comfortLevel(controller.comfort.value),
          comfortReadOnly: controller.comfortReadOnly.value,
          onPriorityTap: controller.onPriorityCycle,
          onDifficultyTap: controller.onDifficultyCycle,
          onComfortTap: controller.onComfortCycle,
        ));
  }

  Widget _chipLegend(RecallColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendSquare(c.chipRed),
        const SizedBox(width: 4),
        _legendSquare(c.chipAmber),
        const SizedBox(width: 4),
        _legendSquare(c.chipGreen),
        const SizedBox(width: 6),
        Text(
          'TAP TO CYCLE · LIGHT HAPTIC',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: c.grey500,
            letterSpacing: 0.16 * 10,
          ),
        ),
      ],
    );
  }

  Widget _legendSquare(Color color) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: const Color(0xFF111111), width: 1.2),
        boxShadow: const [
          BoxShadow(
              color: Color(0xFF111111), offset: Offset(1.5, 1.5), blurRadius: 0),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, RecallColors c) {
    return _sectionLabelWidget(text, c);
  }

  Widget _sectionLabelWidget(String text, RecallColors c) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.jetBrainsMono(
        fontSize: 9.5,
        fontWeight: FontWeight.w500,
        color: c.grey500,
        letterSpacing: 0.18 * 9.5,
      ),
    );
  }

  Widget _validationError(RecallColors c) {
    return Obx(() {
      final error = controller.validationError.value;
      if (error == null || error.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          error,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: c.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    });
  }

  Future<void> _pickFile({required bool isPdf}) async {
    final result = await FilePicker.platform.pickFiles(
      type: isPdf ? FileType.custom : FileType.image,
      allowedExtensions: isPdf ? ['pdf'] : null,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    controller.onFilePicked(
      file.bytes!,
      file.name,
      isPdf ? 'application/pdf' : 'image/${file.extension ?? 'jpg'}',
    );
  }
}
