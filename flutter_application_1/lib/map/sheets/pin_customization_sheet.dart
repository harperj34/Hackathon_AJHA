import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models.dart';
import '../../theme.dart';
import '../widgets/sheet_widgets.dart';

/// Shows the "Drop a Pin" modal bottom sheet.
///
/// Calls [onCreate] with the user-provided data when the user confirms.
/// Returns immediately; the caller handles lifecycle side-effects.
class PinCustomizationSheet {
  PinCustomizationSheet._();

  static void show(
    BuildContext context, {
    required LatLng center,
    required String pendingAddress,
    required void Function(
      EventCategory category,
      String title,
      String location,
      LatLng position, {
      String? imageUrl,
    })
    onCreate,
  }) {
    EventCategory? selectedCategory;
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: pendingAddress);
    final imageUrlCtrl = TextEditingController();
    final Set<String> amenities = {};
    String busyLevel = 'Quiet';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.78,
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
                      Text(
                        'Drop a Pin',
                        style: UniverseTextStyles.sectionHeader,
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
                      // ── Category picker ───────────────────────────────────
                      const Text(
                        'Category',
                        style: TextStyle(
                          color: UniverseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            const [
                              EventCategory.food,
                              EventCategory.events,
                              EventCategory.study,
                              EventCategory.deals,
                            ].where((cat) => categoryInfo.containsKey(cat)).map(
                              (cat) {
                                final info = categoryInfo[cat]!;
                                final sel = selectedCategory == cat;
                                return GestureDetector(
                                  onTap: () =>
                                      setSheet(() => selectedCategory = cat),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? info.color
                                          : info.color.withOpacity(0.09),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: sel
                                            ? info.color
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          info.icon,
                                          size: 14,
                                          color: sel
                                              ? Colors.white
                                              : info.color,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          info.label,
                                          style: TextStyle(
                                            color: sel
                                                ? Colors.white
                                                : info.color,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                      ),
                      const SizedBox(height: 20),

                      // ── Title ─────────────────────────────────────────────
                      const Text(
                        'Title',
                        style: TextStyle(
                          color: UniverseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SheetTextField(
                        controller: titleCtrl,
                        hint: selectedCategory == null
                            ? "What's happening here?"
                            : categoryInfo[selectedCategory]?.label ??
                                  "What's happening here?",
                        icon: Icons.title_rounded,
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

                      // ── Study-spot extras ─────────────────────────────────
                      if (selectedCategory == EventCategory.study) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Amenities',
                          style: TextStyle(
                            color: UniverseColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final a in [
                              'Power Outlets',
                              'Whiteboard',
                              'Quiet',
                              'Aircon',
                              'Natural Light',
                            ])
                              GestureDetector(
                                onTap: () => setSheet(() {
                                  if (amenities.contains(a)) {
                                    amenities.remove(a);
                                  } else {
                                    amenities.add(a);
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 130),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: amenities.contains(a)
                                        ? UniverseColors.accent
                                        : UniverseColors.bgPage,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    a,
                                    style: TextStyle(
                                      color: amenities.contains(a)
                                          ? Colors.white
                                          : UniverseColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Busyness',
                          style: TextStyle(
                            color: UniverseColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final level in ['Quiet', 'Moderate', 'Busy'])
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setSheet(() => busyLevel = level),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 130),
                                    margin: EdgeInsets.only(
                                      right: level != 'Busy' ? 8 : 0,
                                    ),
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: busyLevel == level
                                          ? UniverseColors.accent
                                          : UniverseColors.bgPage,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        level,
                                        style: TextStyle(
                                          color: busyLevel == level
                                              ? Colors.white
                                              : UniverseColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // ── Drop Pin button ───────────────────────────────────
                      GestureDetector(
                        onTap: () {
                          final cat = selectedCategory;
                          final title = titleCtrl.text.trim();
                          if (cat == null || title.isEmpty) return;
                          Navigator.of(ctx).pop();
                          onCreate(
                            cat,
                            title,
                            locationCtrl.text.trim(),
                            center,
                            imageUrl: imageUrlCtrl.text.trim(),
                          );
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF3D8BFF)],
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
                                  Icons.add_location_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Drop Pin',
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
