import 'package:flutter/material.dart';
import '../../theme.dart';
import 'map_markers.dart';
import 'sheet_widgets.dart';

/// Fullscreen overlay shown when the user is positioning a pin or signal.
/// Returns [SizedBox.shrink] when neither mode is active.
class PlacementModeOverlay extends StatelessWidget {
  final bool placementMode;
  final bool signalPlacementMode;
  final bool pinLifted;
  final double confirmBarBottom;
  final VoidCallback onCancelPin;
  final VoidCallback onConfirmPin;
  final VoidCallback onCancelSignal;
  final VoidCallback onConfirmSignal;

  const PlacementModeOverlay({
    super.key,
    required this.placementMode,
    required this.signalPlacementMode,
    required this.pinLifted,
    required this.confirmBarBottom,
    required this.onCancelPin,
    required this.onConfirmPin,
    required this.onCancelSignal,
    required this.onConfirmSignal,
  });

  @override
  Widget build(BuildContext context) {
    if (!placementMode && !signalPlacementMode) return const SizedBox.shrink();
    return SizedBox.expand(
      child: Stack(
        children: [
          if (placementMode) ..._buildPinPlacementWidgets(context),
          if (signalPlacementMode) ..._buildSignalPlacementWidgets(context),
        ],
      ),
    );
  }

  // ── Pin placement ─────────────────────────────────────────────────────────

  List<Widget> _buildPinPlacementWidgets(BuildContext context) {
    return [
      const IgnorePointer(
        child: ColoredBox(
          color: Color(0x14000000),
          child: SizedBox.expand(),
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).padding.top + 70,
        left: 24,
        right: 24,
        child: const IgnorePointer(
          child: Center(child: PlacementBanner()),
        ),
      ),
      IgnorePointer(
        child: Center(child: PlacementPin(lifted: pinLifted)),
      ),
      Positioned(
        bottom: confirmBarBottom,
        left: 20,
        right: 20,
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(child: _cancelButton(onCancelPin)),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _confirmButton(
                  label: 'Confirm Location',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3D8BFF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  shadowColor: const Color(0x446C63FF),
                  onTap: onConfirmPin,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // ── Signal placement ──────────────────────────────────────────────────────

  List<Widget> _buildSignalPlacementWidgets(BuildContext context) {
    return [
      const IgnorePointer(
        child: ColoredBox(
          color: Color(0x14000000),
          child: SizedBox.expand(),
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).padding.top + 70,
        left: 24,
        right: 24,
        child: const IgnorePointer(
          child: Center(
            child: PlacementBanner(
              text: 'Move the map to position your signal',
            ),
          ),
        ),
      ),
      IgnorePointer(
        child: Center(
          child: PlacementPin(
            lifted: pinLifted,
            color: const Color(0xFFFF7AD9),
            icon: Icons.sensors_rounded,
          ),
        ),
      ),
      Positioned(
        bottom: confirmBarBottom,
        left: 20,
        right: 20,
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(child: _cancelButton(onCancelSignal)),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _confirmButton(
                  label: 'Set Signal Location',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFFFF7AD9)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  shadowColor: const Color(0x44FF7AD9),
                  onTap: onConfirmSignal,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // ── Shared button builders ────────────────────────────────────────────────

  Widget _cancelButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: UniverseColors.borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Cancel',
            style: TextStyle(
              color: UniverseColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _confirmButton({
    required String label,
    required LinearGradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
