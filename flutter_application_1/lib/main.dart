import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'map_tab.dart';
import 'discover_tab.dart';
import 'activity_tab.dart';
import 'profile_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'onboarding_overlay.dart';
import 'events_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
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
      theme: UniverseTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class UniverseShell extends StatefulWidget {
  final bool showOnboarding;
  const UniverseShell({super.key, this.showOnboarding = false});

  @override
  State<UniverseShell> createState() => _UniverseShellState();
}

class _UniverseShellState extends State<UniverseShell> {
  int _currentIndex = 0;
  bool _showOnboarding = false;

  final List<Widget> _tabs = const [
    MapTab(),
    DiscoverTab(),
    ActivityTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final needs = prefs.getBool('needs_onboarding') ?? false;
    if (needs && mounted) {
      setState(() => _showOnboarding = true);
    }
  }

  // update onComplete to also clear the flag
  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('needs_onboarding'); // clear the flag
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Main app content
          IndexedStack(index: _currentIndex, children: _tabs),

          // Onboarding overlay shown on top if new user
                    if (_showOnboarding)
            OnboardingOverlay(
              onComplete: _completeOnboarding,
            ),
        ],
      ),
      bottomNavigationBar: _showOnboarding
          ? null // hide nav bar during onboarding
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: UniverseColors.borderColor, width: 0.5),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 20,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.map_outlined,
                        label: 'Map',
                        isActive: _currentIndex == 0,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                      _NavItem(
                        icon: Icons.explore_outlined,
                        label: 'Discover',
                        isActive: _currentIndex == 1,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      _NavItem(
                        icon: Icons.notifications_none,
                        label: 'Activity',
                        isActive: _currentIndex == 2,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                      _NavItem(
                        icon: Icons.person_outline,
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
    final color = isActive ? UniverseColors.accent : const Color(0xFFBBC0CF);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: UniverseTextStyles.tabLabel.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('logged_in_email');

    // Load events from DB in parallel with login check
    await EventsService.loadEvents();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => email != null
              ? const UniverseShell()   // already logged in, no onboarding
              : const LoginPage(),      // not logged in, go to login
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: UniverseColors.bgPage,
      body: Center(
        child: CircularProgressIndicator(color: UniverseColors.accent),
      ),
    );
  }
}