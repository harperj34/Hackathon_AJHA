import 'package:flutter/material.dart';
import '../../theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAP CONTROL BUTTON
// ─────────────────────────────────────────────────────────────────────────────

/// Reusable circular map control button (zoom +/–, heatmap toggle, etc.).
class MapControlButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool active;
  final Color activeColor;

  const MapControlButton({
    super.key,
    required this.onTap,
    required this.child,
    this.active = false,
    this.activeColor = UniverseColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(
            color: active
                ? activeColor.withOpacity(0.30)
                : UniverseColors.borderColor,
            width: 0.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconTheme(
          data: IconThemeData(
            color: active ? activeColor : UniverseColors.textMuted,
            size: 18,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAG HANDLE
// ─────────────────────────────────────────────────────────────────────────────

/// Drag handle pill shown at the top of the bottom sheet.
class DragHandle extends StatelessWidget {
  final VoidCallback? onTap;
  const DragHandle({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
