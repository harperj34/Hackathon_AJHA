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
                    color: UniverseColors.accent,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Text('🧑‍🚀', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Text(
              'Explorer',
              style: TextStyle(
                color: UniverseColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '@universe_explorer',
              style: TextStyle(
                color: UniverseColors.textMuted,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: UniverseColors.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    value: '12',
                    label: 'Events',
                    color: UniverseColors.accentBlue,
                  ),
                  Container(width: 1, height: 32, color: UniverseColors.divider),
                  _StatItem(
                    value: '5',
                    label: 'Clubs',
                    color: UniverseColors.accent,
                  ),
                  Container(width: 1, height: 32, color: UniverseColors.divider),
                  _StatItem(
                    value: '89',
                    label: 'Friends',
                    color: UniverseColors.accentPink,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu items
            _MenuItem(
              icon: Icons.bookmark_rounded,
              iconColor: UniverseColors.accentOrange,
              title: 'Saved Events',
              subtitle: '3 saved',
            ),
            _MenuItem(
              icon: Icons.groups_rounded,
              iconColor: UniverseColors.accent,
              title: 'My Clubs',
              subtitle: '5 joined',
            ),
            _MenuItem(
              icon: Icons.calendar_today_rounded,
              iconColor: UniverseColors.accentBlue,
              title: 'My Calendar',
              subtitle: '2 upcoming',
            ),
            _MenuItem(
              icon: Icons.settings_rounded,
              iconColor: UniverseColors.textMuted,
              title: 'Settings',
              subtitle: '',
            ),

            const SizedBox(height: 32),

            // Version
            const Text(
              'Universe v1.0.0',
              style: TextStyle(
                color: UniverseColors.textLight,
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
          style: const TextStyle(color: UniverseColors.textMuted, fontSize: 14),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: UniverseColors.borderColor),
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
                  color: UniverseColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(
                  color: UniverseColors.textLight,
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: UniverseColors.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
