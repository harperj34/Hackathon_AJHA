import 'package:flutter/material.dart';
import 'theme.dart';
import 'models.dart';

class EventDetailPage extends StatefulWidget {
  final CampusEvent event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final Set<String> _likedItems = {};
  final Set<String> _savedItems = {};
  bool _isGoing = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final info = categoryInfo[event.category]!;
    return Scaffold(
      backgroundColor: UniverseColors.bgPage,
      body: CustomScrollView(
        slivers: [
          // Hero image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: UniverseColors.bgPage,
                  shape: BoxShape.circle,
                  border: Border.all(color: UniverseColors.borderColor),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: UniverseColors.textPrimary,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: info.color.withOpacity(0.3),
                      child: Icon(info.icon, size: 80, color: info.color),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.5),
                          Colors.white,
                        ],
                        stops: const [0.3, 0.75, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: info.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: info.color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(info.icon, size: 14, color: info.color),
                        const SizedBox(width: 6),
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
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: UniverseColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hosted by ${event.subtitle}',
                    style: const TextStyle(
                      color: UniverseColors.textMuted,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info cards
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    iconColor: UniverseColors.accentBlue,
                    title: event.location,
                    subtitle: 'On Campus',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    iconColor: UniverseColors.accent,
                    title: event.time,
                    subtitle: 'Date & Time',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.people_rounded,
                    iconColor: UniverseColors.accentPink,
                    title: '${event.attendees} going',
                    subtitle: 'Attendees',
                  ),

                  const SizedBox(height: 32),

                  // Friends going (static sample similar to map)
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
                      _FriendAvatar(initials: 'AJ', name: 'Alex', color: UniverseColors.accent),
                      const SizedBox(width: 12),
                      _FriendAvatar(initials: 'MK', name: 'Maya', color: UniverseColors.accentPink),
                      const SizedBox(width: 12),
                      _FriendAvatar(initials: 'RS', name: 'Ryan', color: UniverseColors.accentBlue),
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

                  // Like / Save / Share
                  Row(
                    children: [
                      _ActionButton(
                        icon: _likedItems.contains(event.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _likedItems.contains(event.id) ? const Color(0xFFFF4D6D) : UniverseColors.textMuted,
                        label: _likedItems.contains(event.id) ? 'Liked' : 'Like',
                        onTap: () => setState(() {
                          if (_likedItems.contains(event.id)) {
                            _likedItems.remove(event.id);
                          } else {
                            _likedItems.add(event.id);
                          }
                        }),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: _savedItems.contains(event.id) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: _savedItems.contains(event.id) ? UniverseColors.accent : UniverseColors.textMuted,
                        label: _savedItems.contains(event.id) ? 'Saved' : 'Save',
                        onTap: () => setState(() {
                          if (_savedItems.contains(event.id)) {
                            _savedItems.remove(event.id);
                          } else {
                            _savedItems.add(event.id);
                          }
                        }),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.share_rounded,
                        color: UniverseColors.textMuted,
                        label: 'Share',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Going / Not Going
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isGoing = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: _isGoing
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF6C63FF),
                                        Color(0xFF3D8BFF),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    )
                                  : null,
                              color: _isGoing ? null : Colors.white,
                              border: _isGoing ? null : Border.all(color: UniverseColors.accent),
                              boxShadow: _isGoing
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
                                _isGoing ? '✓  Going' : 'Going',
                                style: TextStyle(
                                  color: _isGoing ? Colors.white : UniverseColors.accent,
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
                          onTap: () => setState(() => _isGoing = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 50,
                            decoration: BoxDecoration(
                              color: !_isGoing ? UniverseColors.bgPage : Colors.white,
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
      ),
    );
  }
}

// Small icon + label action button used in the event detail page.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: UniverseColors.bgPage,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  final String initials;
  final String name;
  final Color color;

  const _FriendAvatar({required this.initials, required this.name, required this.color});

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
        Text(name, style: const TextStyle(color: UniverseColors.textMuted, fontSize: 10)),
      ],
    );
  }

}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UniverseColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: const TextStyle(
                  color: UniverseColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: UniverseColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
