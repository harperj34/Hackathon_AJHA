import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../widgets/map_controls.dart';
import 'panel_shared.dart';

/// Bottom-sheet panel showing details for a [StudySpot].
class StudySpotPanel extends StatelessWidget {
  final ScrollController scrollController;
  final StudySpot spot;
  final VoidCallback onDragHandleTap;
  final VoidCallback onDismiss;

  const StudySpotPanel({
    super.key,
    required this.scrollController,
    required this.spot,
    required this.onDragHandleTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[EventCategory.study]!;
    return CustomScrollView(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DragHandle(onTap: onDragHandleTap),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: info.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(info.icon, size: 13, color: info.color),
                          const SizedBox(width: 5),
                          Text(
                            info.label,
                            style: TextStyle(
                              color: info.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onDismiss,
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
                const SizedBox(height: 12),
                Text(
                  spot.title,
                  style: const TextStyle(
                    color: UniverseColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                MiniInfoRow(
                  icon: Icons.location_on_rounded,
                  label: spot.location,
                ),
                const SizedBox(height: 20),
                const Text(
                  'This study spot does not expire and has no attendance controls.',
                  style: TextStyle(
                    color: UniverseColors.textLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 220),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
