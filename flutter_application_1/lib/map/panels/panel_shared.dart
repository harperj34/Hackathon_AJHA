import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HAPPENING CARD  (horizontal carousel item)
// ─────────────────────────────────────────────────────────────────────────────

/// Compact card shown in the "Happening Now" horizontal carousel.
class HappeningCard extends StatelessWidget {
  final CampusEvent event;
  final VoidCallback onTap;

  const HappeningCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[event.category]!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UniverseColors.borderColor, width: 0.5),
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
                    colors: [info.color, info.color.withOpacity(0.4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Image.network(
                  event.imageUrl,
                  width: 88,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 88,
                    color: info.color.withOpacity(0.06),
                    child: Icon(
                      info.icon,
                      color: info.color.withOpacity(0.3),
                      size: 28,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: UniverseColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.subtitle,
                        style: const TextStyle(
                          color: UniverseColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${event.location}  ·  ${event.time.split(', ').last}',
                        style: const TextStyle(
                          color: UniverseColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: info.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${event.attendees}',
                      style: TextStyle(
                        color: info.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENT LIST ROW
// ─────────────────────────────────────────────────────────────────────────────

/// List row shown in the expanded "All Events" section.
class EventListRow extends StatelessWidget {
  final CampusEvent event;
  final VoidCallback onTap;

  const EventListRow({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[event.category]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: UniverseColors.borderColor, width: 0.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 2),
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            event.imageUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              color: info.color.withOpacity(0.06),
                              child: Icon(
                                info.icon,
                                color: info.color.withOpacity(0.3),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  color: UniverseColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${event.location}  ·  ${event.time}',
                                style: const TextStyle(
                                  color: UniverseColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: info.color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${event.attendees}',
                            style: TextStyle(
                              color: info.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// MINI INFO ROW
// ─────────────────────────────────────────────────────────────────────────────

/// Compact icon + text row for small meta-data in panels.
class MiniInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const MiniInfoRow({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: UniverseColors.textLight),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: UniverseColors.textLight,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL INFO ROW
// ─────────────────────────────────────────────────────────────────────────────

/// Card-style row with icon and label for the event detail panel.
class DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const DetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: UniverseColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FRIEND AVATAR
// ─────────────────────────────────────────────────────────────────────────────

/// Circular avatar with initials and a name caption.
class FriendAvatar extends StatelessWidget {
  final String initials;
  final String name;
  final Color color;

  const FriendAvatar({
    super.key,
    required this.initials,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(color: UniverseColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}
