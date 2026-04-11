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

  Future<void> _handleContinue() async {
    final email = _emailController.text.trim().toLowerCase();

    //some validation steps
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
      } else {
        await NeonService.createUser(email);
        setState(() => _statusMessage = '🎉 Account created!');
      }

      await Future.delayed(const Duration(milliseconds: 800));

      //locally save email
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_email', email);

      //go to actual app
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UniverseShell()),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Check your connection and try again.');
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
      backgroundColor: const Color.fromARGB(255, 213, 90, 235),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Title
              const Text(
                'Sign In to Universe',
                style: TextStyle(
                  color: UniverseColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: UniverseColors.textMuted,
                    fontSize: 15,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Welcome to Clayton Campus, you are on Boonwurrung Land. ',
                    ),
                    TextSpan(
                      text: 'Learn More →',
                      style: const TextStyle(
                        color: UniverseColors.accent,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          final url = Uri.parse('https://www.monash.edu/indigenous-students/about-us/recognition-of-traditional-owners');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter your email to get started',
                style: TextStyle(
                  color: UniverseColors.textMuted,
                  fontSize: 15,
                ),
              ),

              //Email input field
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

              //error
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              //status message
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

              //continue
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UniverseColors.accent,
                    disabledBackgroundColor: UniverseColors.accent.withValues(alpha: 0.6),
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
            ],
          ),
        ),
      ),
    );
  }
}