import 'package:flutter/material.dart';
import 'theme.dart';

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (rect) =>
                      UniverseColors.cosmicGradient.createShader(rect),
                  child: const Text(
                    'Activity ✦',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your recent campus activity',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _ActivitySection(
                  title: 'Today',
                  items: [
                    _ActivityItem(
                      icon: Icons.check_circle_rounded,
                      iconColor: UniverseColors.cyanBlue,
                      title: 'You RSVPed to BBQ on the Lawn',
                      subtitle: 'Campus Green · 12:00 PM',
                      time: '2h ago',
                    ),
                    _ActivityItem(
                      icon: Icons.favorite_rounded,
                      iconColor: UniverseColors.hotPink,
                      title: 'You saved Hackathon Kickoff 🚀',
                      subtitle: 'Learning & Teaching Building',
                      time: '5h ago',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ActivitySection(
                  title: 'Yesterday',
                  items: [
                    _ActivityItem(
                      icon: Icons.people_rounded,
                      iconColor: UniverseColors.lavenderPurple,
                      title: '3 friends are going to Dance Club Tryouts',
                      subtitle: 'Campus Centre · 4:30 PM',
                      time: '1d ago',
                    ),
                    _ActivityItem(
                      icon: Icons.star_rounded,
                      iconColor: UniverseColors.brightYellow,
                      title: 'New event near you: Free Bubble Tea 🧋',
                      subtitle: 'Sir John Monash Drive',
                      time: '1d ago',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ActivitySection(
                  title: 'This Week',
                  items: [
                    _ActivityItem(
                      icon: Icons.emoji_events_rounded,
                      iconColor: UniverseColors.brightYellow,
                      title: 'You attended 3 events this week!',
                      subtitle: 'Keep exploring your campus',
                      time: '3d ago',
                    ),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  final String title;
  final List<_ActivityItem> items;

  const _ActivitySection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: item,
            )),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF22223A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
