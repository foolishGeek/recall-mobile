import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Node;
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/recall_colors.dart';
import '../../../core/widgets/list_row.dart';
import '../../../core/widgets/recall_state_view.dart';
import '../controller/node_add_controller.dart';
import '../controller/picked_file.dart';
import 'widgets/bucket_selector_sheet.dart';
import 'widgets/node_add_attachments.dart';
import 'widgets/node_add_text_body.dart';
import 'widgets/node_chip_selector.dart';
import 'widgets/save_bar.dart';
import 'widgets/tag_input_chips.dart';

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

          // ── Bucket (first: choose where this note lives before anything else) ──
          _sectionLabel('Bucket', c),
          const SizedBox(height: 8),
          _bucketRow(context, c),
          const SizedBox(height: 12),

          // ── Spaced revision toggle ──
          _srToggleRow(c),
          const SizedBox(height: 18),

          // ── Title field ──
          _sectionLabel('Title', c),
          const SizedBox(height: 8),
          _titleField(c),
          const SizedBox(height: 18),

          // ── Content ──
          _sectionLabel('Content', c),
          const SizedBox(height: 8),
          _contentBody(c),
          const SizedBox(height: 18),

          // ── Attachments ──
          _attachmentsSection(c),

          // ── Reference links ──
          _linksSection(c),

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
            final prefix = controller.isEditMode ? 'Edit' : 'New note';
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
      controller.isEditMode ? 'Edit note' : 'Add a note',
      style: GoogleFonts.fraunces(
        fontSize: 34,
        fontWeight: FontWeight.w500,
        color: c.ink,
        height: 1.04,
        letterSpacing: -0.02 * 34,
      ),
    );
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

  Widget _contentBody(RecallColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.grey200, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: NodeAddTextBody(controller: controller.bodyCtrl),
    );
  }

  Widget _attachmentsWidget() {
    return Obx(() => NodeAddAttachments(
          existingAssets: controller.existingAssets.toList(),
          existingSignedUrls:
              Map<String, String>.from(controller.existingSignedUrls),
          pickedFiles: controller.pickedFiles.toList(),
          onRemoveExisting: controller.removeExistingAsset,
          onRemovePicked: controller.removePickedFile,
          onAddPdf: () => _pickFiles(isPdf: true),
          onAddImage: () => _pickFiles(isPdf: false),
        ));
  }

  Widget _attachmentsSection(RecallColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelWithOptional('Attachments', c),
        const SizedBox(height: 8),
        _attachmentsWidget(),
        const SizedBox(height: 18),
      ],
    );
  }

  // ── Reference links (CTAs → validated URL fields) ──

  Widget _linksSection(RecallColors c) {
    return Obx(() {
      final showLink = controller.showLinkField.value;
      final showYt = controller.showYoutubeField.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelWithOptional('Links', c),
          const SizedBox(height: 8),
          if (!showLink)
            _addCta(
              c,
              icon: Icons.link_rounded,
              label: 'Add a link',
              onTap: controller.toggleLinkField,
            )
          else
            _urlField(
              c,
              icon: Icons.link_rounded,
              hint: 'https://example.com',
              ctrl: controller.linkUrlCtrl,
              error: controller.linkError.value,
              onRemove: controller.toggleLinkField,
            ),
          const SizedBox(height: 10),
          if (!showYt)
            _addCta(
              c,
              icon: Icons.smart_display_outlined,
              label: 'Add a YouTube video',
              onTap: controller.toggleYoutubeField,
            )
          else
            _urlField(
              c,
              icon: Icons.smart_display_outlined,
              hint: 'https://youtube.com/watch?v=…',
              ctrl: controller.youtubeUrlCtrl,
              error: controller.youtubeError.value,
              onRemove: controller.toggleYoutubeField,
            ),
          const SizedBox(height: 18),
        ],
      );
    });
  }

  Widget _addCta(
    RecallColors c, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.grey200, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: c.grey600),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: c.grey600,
              ),
            ),
            const Spacer(),
            Icon(Icons.add, size: 16, color: c.grey500),
          ],
        ),
      ),
    );
  }

  Widget _urlField(
    RecallColors c, {
    required IconData icon,
    required String hint,
    required TextEditingController ctrl,
    required String? error,
    required VoidCallback onRemove,
  }) {
    final hasError = error != null && error.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 46,
          padding: const EdgeInsets.only(left: 14, right: 6),
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(
              color: hasError ? c.chipRed : c.grey200,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: c.grey600),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  style: GoogleFonts.inter(fontSize: 13.5, color: c.ink),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        GoogleFonts.inter(fontSize: 13.5, color: c.grey400),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.close, size: 15, color: c.grey500),
                ),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              error,
              style: GoogleFonts.inter(fontSize: 11.5, color: c.chipRed),
            ),
          ),
      ],
    );
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

  /// Plain-language spaced-revision switch. On = Recall will resurface this note
  /// over time; off = it stays a quiet reference note you can still open anytime.
  Widget _srToggleRow(RecallColors c) {
    return Obx(() {
      final on = controller.srEnabled.value;
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.grey200, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add to spaced revision',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    on
                        ? 'Recall will resurface this so you remember it'
                        : 'Saved as a plain note — never resurfaced',
                    style: GoogleFonts.inter(fontSize: 12, color: c.grey500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            RecallToggle(value: on, onChanged: controller.toggleSrEnabled),
          ],
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

  Widget _labelWithOptional(String text, RecallColors c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _sectionLabel(text, c),
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

  Future<void> _pickFiles({required bool isPdf}) async {
    final result = await FilePicker.platform.pickFiles(
      type: isPdf ? FileType.custom : FileType.image,
      allowedExtensions: isPdf ? ['pdf'] : null,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = <PickedFile>[];
    for (final file in result.files) {
      if (file.bytes == null) continue;
      final ext = file.extension ?? (isPdf ? 'pdf' : 'jpg');
      picked.add(PickedFile(
        bytes: file.bytes!,
        name: file.name,
        mimeType: isPdf ? 'application/pdf' : 'image/$ext',
        isPdf: isPdf,
      ));
    }
    if (picked.isNotEmpty) controller.onFilesPicked(picked);
  }
}
