import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models.dart';
import '../../theme.dart';
import '../widgets/sheet_widgets.dart';

/// Shows the "Drop a Signal" modal bottom sheet.
///
/// Calls [onDrop] with the user-provided data when the user confirms.
/// Returns immediately; the caller handles lifecycle side-effects.
class SignalCustomizationSheet {
  SignalCustomizationSheet._();

  static void show(
    BuildContext context, {
    required LatLng position,
    required String pendingAddress,
    required void Function(
      String message,
      SignalCategory category,
      LatLng position, {
      String? imageUrl,
      String? notes,
    })
    onDrop,
  }) {
    SignalCategory selectedCategory = SignalCategory.freeFood;
    final msgCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: pendingAddress);
    final notesCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: UniverseColors.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFFFF7AD9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.sensors_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Drop a Signal',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: UniverseColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Broadcasts for 30 minutes',
                            style: TextStyle(
                              fontSize: 12,
                              color: UniverseColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: UniverseColors.bgPage,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: UniverseColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: sc,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    children: [
                      // ── Category ──────────────────────────────────────────
                      const Text(
                        'Category',
                        style: TextStyle(
                          color: UniverseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: SignalCategory.values
                              .where(
                                (cat) => signalCategoryMeta.containsKey(cat),
                              )
                              .where((cat) => cat != SignalCategory.study)
                              .map((cat) {
                                final meta = signalCategoryMeta[cat]!;
                                final sel = selectedCategory == cat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () =>
                                        setSheet(() => selectedCategory = cat),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? meta.color
                                            : meta.color.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: sel
                                              ? meta.color
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            meta.icon,
                                            size: 14,
                                            color: sel
                                                ? Colors.white
                                                : meta.color,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            meta.label,
                                            style: TextStyle(
                                              color: sel
                                                  ? Colors.white
                                                  : meta.color,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Message ───────────────────────────────────────────
                      const Text(
                        'Message',
                        style: TextStyle(
                          color: UniverseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: UniverseColors.bgPage,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: UniverseColors.borderColor),
                        ),
                        child: TextField(
                          controller: msgCtrl,
                          maxLength: 80,
                          maxLines: 3,
                          minLines: 2,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(
                            fontSize: 15,
                            color: UniverseColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: "What's happening here?",
                            hintStyle: TextStyle(
                              color: UniverseColors.textMuted,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                            counterStyle: TextStyle(
                              color: UniverseColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Location ──────────────────────────────────────────
                      const Text(
                        'Location',
                        style: TextStyle(
                          color: UniverseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SheetTextField(
                        controller: locationCtrl,
                        hint: 'Building, room or area',
                        icon: Icons.location_on_rounded,
                      ),
                      const SizedBox(height: 14),

                      // ── Notes (optional) ──────────────────────────────────
                      const Text(
                        'Notes (optional)',
                        style: TextStyle(
                          color: UniverseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: UniverseColors.bgPage,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: UniverseColors.borderColor),
                        ),
                        child: TextField(
                          controller: notesCtrl,
                          maxLines: 3,
                          minLines: 2,
                          style: const TextStyle(
                            fontSize: 14,
                            color: UniverseColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Any extra details...',
                            hintStyle: TextStyle(
                              color: UniverseColors.textMuted,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Photo URL (optional) ──────────────────────────────
                      const Text(
                        'Photo URL (optional)',
                        style: TextStyle(
                          color: UniverseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SheetTextField(
                        controller: imageUrlCtrl,
                        hint: 'https://...',
                        icon: Icons.image_rounded,
                      ),
                      const SizedBox(height: 24),

                      // ── Send Signal button ────────────────────────────────
                      GestureDetector(
                        onTap: () {
                          final msg = msgCtrl.text.trim();
                          if (msg.isEmpty) return;
                          final imageUrl = imageUrlCtrl.text.trim();
                          final notes = notesCtrl.text.trim();
                          Navigator.of(ctx).pop();
                          onDrop(
                            msg,
                            selectedCategory,
                            position,
                            imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                            notes: notes.isNotEmpty ? notes : null,
                          );
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFFFF7AD9)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x446C63FF),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sensors_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Send Signal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
