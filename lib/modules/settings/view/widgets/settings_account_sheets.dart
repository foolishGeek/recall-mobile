// Recall · Settings account sheets. Destructive delete confirmation (checkbox-
// gated, chipRed action) and the premium "Buy AI credits" sheet showing the live
// balance (docs/12_settings.md · [D-UI-1]). Slide up from below.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/theme/recall_colors.dart';
import '../../../../core/utils/recall_haptics.dart';
import '../../controller/settings_controller.dart';

class _Grip extends StatelessWidget {
  const _Grip();
  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return Container(
      width: 36,
      height: 4,
      decoration:
          BoxDecoration(color: c.grey400, borderRadius: BorderRadius.circular(2)),
    );
  }
}

Future<void> showSignOutSheet(
  BuildContext context, {
  required VoidCallback onConfirm,
}) {
  final c = RecallColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _Grip(),
          const SizedBox(height: 18),
          Text('Sign out?',
              style: GoogleFonts.fraunces(
                  fontSize: 22, fontWeight: FontWeight.w500, color: c.ink)),
          const SizedBox(height: 8),
          Text('You can sign back in anytime. Your data stays safe.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: c.grey600)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                RecallHaptics.selection();
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.ink,
                foregroundColor: c.inkOnInk,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Sign out',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(fontSize: 14, color: c.grey600)),
          ),
        ]),
      ),
    ),
  );
}

Future<void> showDeleteAccountSheet(
  BuildContext context, {
  required VoidCallback onConfirm,
}) {
  final c = RecallColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _DeleteConfirm(onConfirm: onConfirm),
  );
}

class _DeleteConfirm extends StatefulWidget {
  final VoidCallback onConfirm;
  const _DeleteConfirm({required this.onConfirm});
  @override
  State<_DeleteConfirm> createState() => _DeleteConfirmState();
}

class _DeleteConfirmState extends State<_DeleteConfirm> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _Grip(),
          const SizedBox(height: 18),
          Text('Delete account?',
              style: GoogleFonts.fraunces(
                  fontSize: 22, fontWeight: FontWeight.w500, color: c.ink)),
          const SizedBox(height: 8),
          Text(
            'This permanently removes your buckets, notes, reviews, and progress. '
            'It cannot be undone.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: c.grey600, height: 1.45),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              RecallHaptics.selection();
              setState(() => _acknowledged = !_acknowledged);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _acknowledged ? c.chipRed : Colors.transparent,
                    border: Border.all(
                        color: _acknowledged ? c.chipRed : c.grey400, width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _acknowledged
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('I understand this is permanent.',
                      style: GoogleFonts.inter(fontSize: 13.5, color: c.ink)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _acknowledged
                  ? () {
                      RecallHaptics.selection();
                      Navigator.pop(context);
                      widget.onConfirm();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.chipRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: c.grey300,
                disabledForegroundColor: c.grey500,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Delete my account',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(fontSize: 14, color: c.grey600)),
          ),
        ]),
      ),
    );
  }
}

Future<void> showBuyCreditsSheet(
  BuildContext context, {
  required SettingsController controller,
}) {
  final c = RecallColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _Grip(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Buy AI credits',
                style: GoogleFonts.fraunces(
                    fontSize: 22, fontWeight: FontWeight.w500, color: c.ink)),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Balance · ${controller.creditBalance} credits',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 11, color: c.grey500)),
          ),
          const SizedBox(height: 14),
          _CreditOption(
            label: '100 credits',
            product: controller.credits100,
            onTap: (p) {
              Navigator.pop(context);
              controller.onBuyCredits(p);
            },
          ),
          const SizedBox(height: 10),
          _CreditOption(
            label: '500 credits',
            product: controller.credits500,
            onTap: (p) {
              Navigator.pop(context);
              controller.onBuyCredits(p);
            },
          ),
          if (controller.credits100 == null && controller.credits500 == null) ...[
            const SizedBox(height: 12),
            Text('Credit packs are unavailable right now — try again later.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.5, color: c.grey600)),
          ],
        ]),
      ),
    ),
  );
}

class _CreditOption extends StatelessWidget {
  final String label;
  final StoreProduct? product;
  final ValueChanged<StoreProduct> onTap;
  const _CreditOption({
    required this.label,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = RecallColors.of(context);
    final p = product;
    final enabled = p != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled
            ? () {
                RecallHaptics.medium();
                onTap(p);
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: c.cardSunken,
            border: Border.all(color: c.grey200, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
            ),
            Text(p?.priceString ?? '—',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 13, fontWeight: FontWeight.w700, color: c.ink)),
          ]),
        ),
      ),
    );
  }
}
