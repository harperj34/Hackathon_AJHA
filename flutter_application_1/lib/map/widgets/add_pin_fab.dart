import 'package:flutter/material.dart';
import '../../theme.dart';
import 'sheet_widgets.dart';

/// The floating + / × button and its expandable add-menu (Quick Signal,
/// Create Event). Renders as a full-screen [SizedBox.expand] so its internal
/// [Positioned] children can be placed at absolute coordinates.
class AddPinFab extends StatelessWidget {
  final double addPinTop;
  final bool addMenuOpen;
  final bool hideFloating;
  final bool placementMode;
  final bool signalPlacementMode;
  final bool canDropSignal;
  final Duration cooldownRemaining;
  final VoidCallback onToggleMenu;
  final VoidCallback onCreateEvent;
  final VoidCallback onQuickSignal;

  const AddPinFab({
    super.key,
    required this.addPinTop,
    required this.addMenuOpen,
    required this.hideFloating,
    required this.placementMode,
    required this.signalPlacementMode,
    required this.canDropSignal,
    required this.cooldownRemaining,
    required this.onToggleMenu,
    required this.onCreateEvent,
    required this.onQuickSignal,
  });

  bool get _isHidden => hideFloating || placementMode || signalPlacementMode;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          _buildAddMenu(context),
          _buildFabButton(),
        ],
      ),
    );
  }

  // ── Add menu (slides in above the FAB) ────────────────────────────────────

  Widget _buildAddMenu(BuildContext context) {
    return Positioned(
      left: 16,
      top: addPinTop - 130,
      child: IgnorePointer(
        ignoring: !addMenuOpen || _isHidden,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: (addMenuOpen && !_isHidden) ? 1.0 : 0.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AddMenuOption(
                  label: 'Quick Signal',
                  icon: Icons.sensors_rounded,
                  color: canDropSignal
                      ? const Color(0xFFFF7AD9)
                      : UniverseColors.iosSysGray2,
                  onTap: () {
                    onToggleMenu(); // close menu (was open)
                    if (!canDropSignal) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You can drop another signal in '
                            '${cooldownRemaining.inMinutes}m '
                            '${cooldownRemaining.inSeconds % 60}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: const Color(0xFF6C63FF),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 3),
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        ),
                      );
                      return;
                    }
                    onQuickSignal();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AddMenuOption(
                  label: 'Create Event',
                  icon: Icons.add_location_alt_rounded,
                  color: UniverseColors.accent,
                  onTap: onCreateEvent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFabButton() {
    return Positioned(
      left: 16,
      top: addPinTop,
      child: IgnorePointer(
        ignoring: _isHidden,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _isHidden ? 0 : 1,
          child: GestureDetector(
            onTap: onToggleMenu,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: addMenuOpen
                    ? const Color(0xFF2D2D2D)
                    : UniverseColors.accent,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: addMenuOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  addMenuOpen ? Icons.close_rounded : Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
