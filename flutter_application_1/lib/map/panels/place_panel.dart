import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models.dart';
import '../../theme.dart';
import '../widgets/map_controls.dart';

/// Bottom-sheet panel showing details for a [CampusPlace].
class PlacePanel extends StatelessWidget {
  final ScrollController scrollController;
  final CampusPlace place;
  final VoidCallback onDragHandleTap;
  final VoidCallback onDismiss;

  const PlacePanel({
    super.key,
    required this.scrollController,
    required this.place,
    required this.onDragHandleTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
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

                // ── Header row ────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: UniverseColors.accent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            place.icon,
                            size: 13,
                            color: UniverseColors.accent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            place.category,
                            style: const TextStyle(
                              color: UniverseColors.accent,
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
                          Icons.close,
                          size: 16,
                          color: UniverseColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Place name ────────────────────────────────────────────
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: UniverseColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Rating row ────────────────────────────────────────────
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      final full = i < place.rating.floor();
                      final half =
                          !full &&
                          i < place.rating &&
                          (place.rating - i) >= 0.5;
                      return Icon(
                        full
                            ? Icons.star_rounded
                            : half
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: const Color(0xFFFFB800),
                      );
                    }),
                    const SizedBox(width: 6),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: UniverseColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── Hours ─────────────────────────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: UniverseColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      place.hours,
                      style: const TextStyle(
                        fontSize: 13,
                        color: UniverseColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Get Directions ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: GestureDetector(
                    onTap: () async {
                      final lat = place.position.latitude;
                      final lng = place.position.longitude;
                      final uri = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Container(
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
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Get Directions',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
