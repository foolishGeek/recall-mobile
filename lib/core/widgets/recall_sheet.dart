// Recall · showRecallSheet. The one way to present a bottom sheet: card canvas,
// 20pt top corners, and the Android 15+ navigation inset paid once so content
// never sits under the nav bar.
//
//   showRecallSheet<bool>(context: context, builder: (_) => const MySheet());
//
// Call this instead of showModalBottomSheet — new sheets then inherit the
// styling and the inset for free.

import 'package:flutter/material.dart';

import '../theme/recall_colors.dart';

Future<T?> showRecallSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,

  /// Set false when the child manages its own bottom inset (e.g. a
  /// DraggableScrollableSheet that must keep the full height to draw against).
  bool safeBottom = true,
  Color? backgroundColor,
}) {
  final c = RecallColors.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor ?? c.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) =>
        safeBottom ? SafeArea(top: false, child: builder(ctx)) : builder(ctx),
  );
}
