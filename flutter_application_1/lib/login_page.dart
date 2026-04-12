import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'neon_service.dart';
import 'main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
 
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
 
  @override
  State<LoginPage> createState() => _LoginPageState();
}
 
class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;
 
  // ── Typewriter animation ───────────────────────────────────────────────────
  String _animatedWord = '';
  bool _showCursor = true;
 
  final List<String> _sequence = [
    'UNItersity',  // type to here
    'UNI',         // backspace to here
    'UNIty',       // type to here
    'U',           // backspace to here
    'UNIverse',    // type to here — final
  ];
 
  static const _typeSpeed   = Duration(milliseconds: 80);
  static const _deleteSpeed = Duration(milliseconds: 50);
  static const _pauseSpeed  = Duration(milliseconds: 700);
 
  @override
  void initState() {
    super.initState();
    _startAnimation();
    _startCursorBlink();
  }
 
  void _startCursorBlink() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return false;
      setState(() => _showCursor = !_showCursor);
      return true;
    });
  }
 
  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
 
    for (int i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      final target = _sequence[i];
 
      if (target.length > _animatedWord.length) {
        // Type forward
        while (_animatedWord.length < target.length) {
          await Future.delayed(_typeSpeed);
          if (!mounted) return;
          setState(() =>
              _animatedWord = target.substring(0, _animatedWord.length + 1));
        }
      } else {
        // Backspace
        while (_animatedWord.length > target.length) {
          await Future.delayed(_deleteSpeed);
          if (!mounted) return;
          setState(() => _animatedWord =
              _animatedWord.substring(0, _animatedWord.length - 1));
        }
      }
 
      // Pause between words, longer at the final word
      final isLast = i == _sequence.length - 1;
      await Future.delayed(
          isLast ? const Duration(milliseconds: 1200) : _pauseSpeed);
    }
  }
 
  // ── Login logic ────────────────────────────────────────────────────────────
  Future<void> _handleContinue() async {
    final email = _emailController.text.trim().toLowerCase();
 
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }
 
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });
 
    try {
      final exists = await NeonService.emailExists(email);
 
      if (exists) {
        setState(() => _statusMessage = '👋 Welcome back!');
        await Future.delayed(const Duration(milliseconds: 800));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_in_email', email);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const UniverseShell(showOnboarding: false),
            ),
          );
        }
      } else {
        await NeonService.createUser(email);
        setState(() => _statusMessage = '🎉 Account created!');
        await Future.delayed(const Duration(milliseconds: 800));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_in_email', email);
        await prefs.setBool('needs_onboarding', true);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const UniverseShell(showOnboarding: true),
            ),
          );
        }
      }
 
      await Future.delayed(const Duration(milliseconds: 800));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_email', email);
 
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UniverseShell()),
        );
      }
    } catch (e) {
      setState(() => _errorMessage =
          'Something went wrong. Check your connection and try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }
 
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF5D5CFE),
              Color(0xFF9B79FF),
              Color(0xFF97E7FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
 
                // Animated title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                          children: [
                            const TextSpan(text: 'Sign In to '),
                            TextSpan(text: _animatedWord),
                            TextSpan(
                              text: _showCursor ? '|' : ' ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      'fonts/images/universe.png',
                      width: 100,
                      height: 100,
                    ),
                  ],
                ),
 
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    children: [
                      const TextSpan(text: 'You are on Boonwurrung Land. '),
                      TextSpan(
                        text: 'Learn More →',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final url = Uri.parse(
                                'https://www.monash.edu/indigenous-students/about-us/recognition-of-traditional-owners');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter your email to get started',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 20),
 
                // Email input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: UniverseColors.borderColor),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: const TextStyle(color: UniverseColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'your@email.com',
                      hintStyle: TextStyle(color: UniverseColors.textLight),
                      prefixIcon: Icon(
                        Icons.email_rounded,
                        color: UniverseColors.textMuted,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
 
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(_errorMessage!,
                      style:
                          const TextStyle(color: Colors.red, fontSize: 13)),
                ],
 
                if (_statusMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _statusMessage!,
                    style: const TextStyle(
                      color: UniverseColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
 
                const SizedBox(height: 20),
 
                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UniverseColors.accent,
                      disabledBackgroundColor:
                          UniverseColors.accent.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
 
                // Dev bypass
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                          'logged_in_email', 'dev@bypass.com');
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const UniverseShell()),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white60,
                    ),
                    child: const Text(
                      '🛠️ Dev Bypass',
                      style: TextStyle(fontSize: 13),
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
 