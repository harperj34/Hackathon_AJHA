import 'package:flutter/material.dart';
import 'theme.dart';

class OnboardingOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingOverlay({super.key, required this.onComplete});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  int _step = 0; // 0 = welcome screen, 1 = account setup screen

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final List<String> _allInterests = [
    'Live Music',
    'Food & Drink Deals',
    'Social Activities',
    'Study Activities',
    'Careers & Networking',
    'Sports',
  ];
  final Set<String> _selectedInterests = {};
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _handleFinish() {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your first and last name');
      return;
    }
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 30,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: _step == 0 ? _buildWelcomeStep() : _buildSetupStep(),
          ),
        ),
      ),
    );
  }

  // STEP 0: Welcome screen

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: UniverseColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: UniverseColors.accent,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Welcome to Universe 🚀',
            style: TextStyle(
              color: UniverseColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),

          // Description
          const Text(
            'Your one-stop app for all things campus life! Have a look through the menus below to get acquainted with up-to-date info on campus social activities, study spots, public transport, and more!',
            style: TextStyle(
              color: UniverseColors.textMuted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: UniverseColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue to account setup →',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //STEP 1: Account setup screen

  Widget _buildSetupStep() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + title
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _step = 0),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: UniverseColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Account Setup',
                style: TextStyle(
                  color: UniverseColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // First name
          const Text(
            'First Name',
            style: TextStyle(
              color: UniverseColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _inputField(
            controller: _firstNameController,
            hint: 'e.g. Anna',
          ),
          const SizedBox(height: 16),

          // Last name
          const Text(
            'Last Name',
            style: TextStyle(
              color: UniverseColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _inputField(
            controller: _lastNameController,
            hint: 'e.g. Nguyen',
          ),
          const SizedBox(height: 24),

          // Interests
          const Text(
            'Your Interests',
            style: TextStyle(
              color: UniverseColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'This will affect your notifications',
            style: TextStyle(
              color: UniverseColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? UniverseColors.accent
                        : UniverseColors.bgPage,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? UniverseColors.accent
                          : UniverseColors.borderColor,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : UniverseColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],

          const SizedBox(height: 28),

          //Finish button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: UniverseColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Let's go! →",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: UniverseColors.bgPage,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UniverseColors.borderColor),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: UniverseColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: UniverseColors.textLight),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}