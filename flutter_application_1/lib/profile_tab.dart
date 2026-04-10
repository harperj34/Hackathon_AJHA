import 'package:flutter/material.dart';
import 'theme.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: UniverseColors.cosmicGradient,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1A1A2E),
                    ),
                    child: const Center(
                      child: Text(
                        '🧑‍🚀',
                        style: TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Text(
              'Explorer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@universe_explorer',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF22223A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(value: '12', label: 'Events', color: UniverseColors.cyanBlue),
                  Container(width: 1, height: 32, color: Colors.white10),
                  _StatItem(value: '5', label: 'Clubs', color: UniverseColors.lavenderPurple),
                  Container(width: 1, height: 32, color: Colors.white10),
                  _StatItem(value: '89', label: 'Friends', color: UniverseColors.hotPink),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu items
            _MenuItem(
              icon: Icons.bookmark_rounded,
              iconColor: UniverseColors.brightYellow,
              title: 'Saved Events',
              subtitle: '3 saved',
            ),
            _MenuItem(
              icon: Icons.groups_rounded,
              iconColor: UniverseColors.lavenderPurple,
              title: 'My Clubs',
              subtitle: '5 joined',
            ),
            _MenuItem(
              icon: Icons.calendar_today_rounded,
              iconColor: UniverseColors.cyanBlue,
              title: 'My Calendar',
              subtitle: '2 upcoming',
            ),
            _MenuItem(
              icon: Icons.settings_rounded,
              iconColor: Colors.white38,
              title: 'Settings',
              subtitle: '',
            ),

            const SizedBox(height: 32),

            // Version
            Text(
              'Universe v1.0.0 ✦',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
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
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
