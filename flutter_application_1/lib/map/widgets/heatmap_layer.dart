import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../services/geo_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HEATMAP LAYER
// ─────────────────────────────────────────────────────────────────────────────

/// Full-map heatmap overlay.
///
/// Draws all heat blobs onto a single canvas inside [saveLayer] using
/// [BlendMode.screen], so overlapping blobs brighten and merge naturally —
/// identical to the merging behaviour seen on Snap Map when zooming out.
class HeatmapLayer extends StatelessWidget {
  final List<HeatPoint> points;
  final double zoom;

  const HeatmapLayer({super.key, required this.points, required this.zoom});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    return SizedBox.expand(
      child: CustomPaint(
        painter: HeatmapPainter(points: points, camera: camera, zoom: zoom),
      ),
    );
  }
}

class HeatmapPainter extends CustomPainter {
  final List<HeatPoint> points;
  final MapCamera camera;
  final double zoom;

  const HeatmapPainter({
    required this.points,
    required this.camera,
    required this.zoom,
  });

  /// Radius of each blob in logical pixels, zoom-responsive.
  double _radius(double intensity) {
    final zoomFactor = ((zoom - 15.0) / 3.0).clamp(0.0, 1.0);
    final base = ui.lerpDouble(70.0, 26.0, zoomFactor)!;
    final scale = ui.lerpDouble(38.0, 16.0, zoomFactor)!;
    return base + intensity * scale;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final layerPaint = Paint();
    canvas.saveLayer(Offset.zero & size, layerPaint);

    for (final pt in points) {
      final screenPt = camera.latLngToScreenPoint(pt.position);
      final center = Offset(screenPt.x, screenPt.y);
      final radius = _radius(pt.intensity);

      final coreColor = Color.lerp(
        const Color(0xFFFFE500),
        const Color(0xFFFF2200),
        pt.intensity,
      )!;
      const midColor = Color(0xFFFF8C00);
      const outerColor = Color(0xFF34C759);
      const haloColor = Color(0xFF00C7BE);

      final coreOpacity = (0.62 + pt.intensity * 0.33).clamp(0.0, 1.0);

      final paint = Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [
            coreColor.withOpacity(coreOpacity),
            midColor.withOpacity(coreOpacity * 0.82),
            outerColor.withOpacity(0.50),
            haloColor.withOpacity(0.22),
            haloColor.withOpacity(0.0),
          ],
          [0.0, 0.25, 0.52, 0.76, 1.0],
        );
      canvas.drawCircle(center, radius, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(HeatmapPainter old) =>
      old.points != points || old.zoom != zoom || old.camera != camera;
}
