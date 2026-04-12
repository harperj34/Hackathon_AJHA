import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'models.dart';
import 'event_detail.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Cosmic gradient header ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, topPad + 24, 20, 36),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6C63FF),
                  Color(0xFF9B79FF),
                  Color(0xFFFF7AD9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    // Avatar — white circle on gradient
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 24,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 44,
                        color: UniverseColors.accent,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Explorer',
                      style: UniverseTextStyles.displayMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@universe_explorer',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SavedEventsPage()),
                );
              },
            ),
            _MenuItem(
              icon: Icons.groups_rounded,
              iconColor: UniverseColors.accent,
              title: 'My Clubs',
              subtitle: '5 joined',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyClubsPage()),
                );
              },
            ),
            _MenuItem(
              icon: Icons.calendar_today_rounded,
              iconColor: UniverseColors.accentBlue,
              title: 'My Calendar',
              subtitle: '2 upcoming',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyCalendarPage()),
                );
              },
            ),
            _MenuItem(
              icon: Icons.settings_rounded,
              iconColor: UniverseColors.textMuted,
              title: 'Settings',
              subtitle: '',
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Friends',
                style: TextStyle(
                  color: UniverseColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
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
                      color: UniverseColors.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people_rounded,
                      color: UniverseColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Add Friends',
                      style: TextStyle(
                        color: UniverseColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: UniverseColors.textLight,
                    size: 20,
                  ),
                ],
              ),
            ),
            _MenuItem(
              icon: Icons.logout_rounded,
              iconColor: Colors.red,
              title: 'Sign Out',
              subtitle: '',
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('logged_in_email');
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
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
        ],
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
  final VoidCallback? onTap; // add this

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap, // add this
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap, // add this
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
                  color: iconColor.withValues(alpha: 0.12),
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
      ),
    );
  }
}

// ---------------------- New pages with dummy content ----------------------

class SavedEventsPage extends StatelessWidget {
  const SavedEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<CampusEvent> events = sampleEvents.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Events')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final e = events[index];
          final info = categoryInfo[e.category];
          if (info == null) return const SizedBox();

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EventDetailPage(event: e)),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: UniverseColors.borderColor),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      e.imageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: info.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(info.icon, color: info.color, size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: const TextStyle(
                            color: UniverseColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.location,
                          style: const TextStyle(
                            color: UniverseColors.textLight,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: info.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      '${e.attendees} going',
                      style: TextStyle(
                        color: info.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MyClubsPage extends StatelessWidget {
  const MyClubsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final clubs = [
      {'name': 'City Hikers', 'members': '128'},
      {'name': 'Late Night Coders', 'members': '54'},
      {'name': 'Planetarium Volunteers', 'members': '32'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Clubs')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: clubs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final c = clubs[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.group, color: UniverseColors.accent),
              title: Text(c['name']!),
              subtitle: Text('${c['members']} members'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
                onPressed: () {
                  // placeholder for join/leave flow
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Manage ${c['name']} (TODO)')),
                  );
                },
                child: const Text('Manage'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MyCalendarPage extends StatelessWidget {
  const MyCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<CampusEvent> calendar = sampleEvents.take(2).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Calendar')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: calendar.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final e = calendar[index];
          final info = categoryInfo[e.category];
          if (info == null) return const SizedBox();

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EventDetailPage(event: e)),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: UniverseColors.borderColor),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      e.imageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: info.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(info.icon, color: info.color, size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: const TextStyle(
                            color: UniverseColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.location,
                          style: const TextStyle(
                            color: UniverseColors.textLight,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.time,
                          style: const TextStyle(
                            color: UniverseColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: info.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      '${e.attendees} going',
                      style: TextStyle(
                        color: info.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// (No placeholder) Event details use `EventDetailPage` from event_detail.dart