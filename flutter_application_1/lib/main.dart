import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'map_tab.dart';
import 'discover_tab.dart';
import 'activity_tab.dart';
import 'profile_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

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
      scrollBehavior: const _NoOverscrollBehavior(),
      home: const AuthGate(),
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
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
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

class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
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
    //check email existence
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('logged_in_email');

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => email != null
              ? const UniverseShell()  // go to app if logged in
              : const LoginPage(),     //otherwise go to login
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //loading spinner
    return const Scaffold(
      backgroundColor: UniverseColors.bgPage,
      body: Center(
        child: CircularProgressIndicator(color: UniverseColors.accent),
      ),
    );
  }
}