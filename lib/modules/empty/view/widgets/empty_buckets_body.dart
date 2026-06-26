// Recall · No buckets empty state (docs/13_empty.md §A).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/theme/recall_typography.dart';
import '../../../../core/widgets/mono_label.dart';
import '../../../../core/widgets/recall_button.dart';
import '../../../buckets/view/widgets/buckets_top_bar.dart';
import 'empty_column_reveal.dart';

class EmptyBucketsBody extends StatelessWidget {
  final VoidCallback onMakeBucket;
  final VoidCallback? onSearchTap;

  const EmptyBucketsBody({
    super.key,
    required this.onMakeBucket,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final t = RecallType.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onSearchTap != null)
          BucketsTopBar(onSearchTap: onSearchTap!)
        else
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 8, 6, 0),
            child: Row(
              children: [MonoLabel('Library', size: 11, tracking: 0.16)],
            ),
          ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Buckets', style: t.displayMd),
              const SizedBox(height: 6),
              MonoLabel('Your library begins here', size: 11, tracking: 0.04),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: EmptyColumnReveal(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/illustrations/empty-seed-in-bowl.svg',
                      height: 120,
                      colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Nothing planted yet.',
                      textAlign: TextAlign.center,
                      style: t.displaySm.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 280,
                      child: Text(
                        'Make your first bucket — a class, a book, a project — '
                        'and start tucking notes inside it. Recall will remember '
                        'the rest.',
                        textAlign: TextAlign.center,
                        style: t.body.copyWith(color: c.grey600),
                      ),
                    ),
                    const SizedBox(height: 30),
                    PrimaryButton(
                      label: 'Make your first bucket',
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      onPressed: onMakeBucket,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
