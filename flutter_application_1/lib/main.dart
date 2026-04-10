import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'map_tab.dart';
import 'discover_tab.dart';
import 'activity_tab.dart';
import 'profile_tab.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const UniverseApp());
}

class UniverseApp extends StatelessWidget {
  const UniverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universe',
      debugShowCheckedModeBanner: false,
      theme: UniverseTheme.darkTheme,
      home: const UniverseShell(),
    );
  }
}

class UniverseShell extends StatefulWidget {
  const UniverseShell({super.key});

  @override
  State<UniverseShell> createState() => _UniverseShellState();
}

class _UniverseShellState extends State<UniverseShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    MapTab(),
    DiscoverTab(),
    ActivityTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withOpacity(0.95),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.map_rounded,
                  label: 'Map',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.explore_rounded,
                  label: 'Discover',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.notifications_rounded,
                  label: 'Activity',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (rect) {
                if (isActive) {
                  return UniverseColors.cosmicGradient.createShader(rect);
                }
                return const LinearGradient(
                  colors: [Colors.white38, Colors.white38],
                ).createShader(rect);
              },
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? UniverseColors.royalBlue
                    : Colors.white.withOpacity(0.35),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
