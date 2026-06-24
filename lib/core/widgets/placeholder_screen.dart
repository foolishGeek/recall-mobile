// Recall · S02 placeholder building blocks. Plumbing only — feature content
// lands in each screen's own sprint (S07+). PlaceholderBody is a scaffold-less
// body for tab screens; PlaceholderScreen wraps it for pushed (non-tab) routes.

import 'package:flutter/material.dart';

import '../theme/recall_colors.dart';
import '../theme/recall_theme.dart';
import 'mono_label.dart';
import 'recall_mark.dart';
import 'recall_scaffold.dart';

class PlaceholderBody extends StatelessWidget {
  final String title;
  final String eyebrow;

  const PlaceholderBody({
    super.key,
    required this.title,
    this.eyebrow = 'S02 · placeholder',
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RecallMark(size: 44),
          const SizedBox(height: 22),
          Text(title, style: context.type.headingMd.copyWith(color: c.ink)),
          const SizedBox(height: 10),
          MonoLabel(eyebrow),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final bool showBack;

  const PlaceholderScreen({super.key, required this.title, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return RecallScaffold.bare(
      body: Stack(
        children: [
          PlaceholderBody(title: title),
          if (showBack)
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: c.ink),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
        ],
      ),
    );
  }
}
