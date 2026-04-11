import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models.dart';
import '../../theme.dart';
import '../widgets/map_controls.dart';
import '../widgets/sheet_widgets.dart';
import 'panel_shared.dart';

/// Bottom-sheet panel showing preview and full detail for a [CampusEvent].
class EventDetailPanel extends StatelessWidget {
  final ScrollController scrollController;
  final CampusEvent event;

  // State values
  final bool isGoing;
  final bool isLiked;
  final bool isSaved;
  final bool isCommunityPin;
  final int confirmCount;
  final int outdatedCount;

  // Callbacks → map_tab.dart owns setState
  final VoidCallback onDragHandleTap;
  final VoidCallback onDismiss;
  final ValueChanged<bool> onGoingChanged;
  final VoidCallback onLikeToggle;
  final VoidCallback onSaveToggle;
  final VoidCallback onConfirm;
  final VoidCallback onOutdated;

  const EventDetailPanel({
    super.key,
    required this.scrollController,
    required this.event,
    required this.isGoing,
    required this.isLiked,
    required this.isSaved,
    required this.isCommunityPin,
    required this.confirmCount,
    required this.outdatedCount,
    required this.onDragHandleTap,
    required this.onDismiss,
    required this.onGoingChanged,
    required this.onLikeToggle,
    required this.onSaveToggle,
    required this.onConfirm,
    required this.onOutdated,
  });

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[event.category]!;

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

                // ── Category pill + close ─────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: info.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: info.color.withOpacity(0.15),
                          width: 0.5,
                        ),
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
                              fontWeight: FontWeight.w600,
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

                // ── Preview card ──────────────────────────────────────────
                Container(
                  height: 108,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: UniverseColors.borderColor,
                      width: 0.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [info.color, info.color.withOpacity(0.3)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: Image.network(
                            event.imageUrl,
                            width: 104,
                            height: 108,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 104,
                              height: 108,
                              color: info.color.withOpacity(0.06),
                              child: Icon(
                                info.icon,
                                color: info.color.withOpacity(0.3),
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    color: UniverseColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${event.location}  ·  ${event.time}',
                                  style: const TextStyle(
                                    color: UniverseColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    '↑  Swipe up for full details',
                    style: TextStyle(
                      color: UniverseColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: UniverseColors.divider,
                ),
                const SizedBox(height: 20),

                // ── Full details ──────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    event.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: info.color.withOpacity(0.1),
                      child: Icon(info.icon, size: 60, color: info.color),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  event.title,
                  style: const TextStyle(
                    color: UniverseColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hosted by ${event.subtitle}',
                  style: const TextStyle(
                    color: UniverseColors.textLight,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                DetailInfoRow(
                  icon: Icons.access_time_rounded,
                  label: event.time,
                  iconColor: UniverseColors.accent,
                ),
                const SizedBox(height: 10),
                DetailInfoRow(
                  icon: Icons.location_on_rounded,
                  label: event.location,
                  iconColor: UniverseColors.accentBlue,
                ),
                const SizedBox(height: 10),
                DetailInfoRow(
                  icon: Icons.people_rounded,
                  label: '${event.attendees} people going',
                  iconColor: UniverseColors.accentOrange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Friends Going',
                  style: TextStyle(
                    color: UniverseColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FriendAvatar(
                      initials: 'AJ',
                      name: 'Alex',
                      color: UniverseColors.accent,
                    ),
                    const SizedBox(width: 12),
                    FriendAvatar(
                      initials: 'MK',
                      name: 'Maya',
                      color: UniverseColors.accentPink,
                    ),
                    const SizedBox(width: 12),
                    FriendAvatar(
                      initials: 'RS',
                      name: 'Ryan',
                      color: UniverseColors.accentBlue,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '+${event.attendees - 3} more',
                      style: const TextStyle(
                        color: UniverseColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Community verification (crowd-reported pins) ──────────
                if (isCommunityPin) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFFE0A0),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Is this still accurate?',
                          style: TextStyle(
                            color: Color(0xFF8B6000),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: onConfirm,
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF22C55E,
                                    ).withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Color(0xFF22C55E),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Still there ($confirmCount)',
                                        style: const TextStyle(
                                          color: Color(0xFF22C55E),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: onOutdated,
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.cancel_outlined,
                                        color: Color(0xFFEF4444),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Gone ($outdatedCount)',
                                        style: const TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Like / Save / Share / Directions ─────────────────────
                Row(
                  children: [
                    ActionButton(
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isLiked
                          ? const Color(0xFFFF4D6D)
                          : UniverseColors.textMuted,
                      label: isLiked ? 'Liked' : 'Like',
                      onTap: onLikeToggle,
                    ),
                    const SizedBox(width: 8),
                    ActionButton(
                      icon: isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isSaved
                          ? UniverseColors.accent
                          : UniverseColors.textMuted,
                      label: isSaved ? 'Saved' : 'Save',
                      onTap: onSaveToggle,
                    ),
                    const SizedBox(width: 8),
                    ActionButton(
                      icon: Icons.share_rounded,
                      color: UniverseColors.textMuted,
                      label: 'Share',
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    ActionButton(
                      icon: Icons.directions_rounded,
                      color: UniverseColors.textMuted,
                      label: 'Directions',
                      onTap: () async {
                        final lat = event.position.latitude;
                        final lng = event.position.longitude;
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
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Going / Not Going ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onGoingChanged(true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: isGoing
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6C63FF),
                                      Color(0xFF3D8BFF),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: isGoing ? null : Colors.white,
                            border: isGoing
                                ? null
                                : Border.all(color: UniverseColors.accent),
                            boxShadow: isGoing
                                ? const [
                                    BoxShadow(
                                      color: Color(0x446C63FF),
                                      blurRadius: 12,
                                      offset: Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              isGoing ? '✓  Going' : 'Going',
                              style: TextStyle(
                                color: isGoing
                                    ? Colors.white
                                    : UniverseColors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onGoingChanged(false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 50,
                          decoration: BoxDecoration(
                            color: !isGoing
                                ? UniverseColors.bgPage
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: UniverseColors.borderColor,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Not Going',
                              style: TextStyle(
                                color: UniverseColors.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
