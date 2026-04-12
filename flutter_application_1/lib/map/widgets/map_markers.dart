import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAP EVENT PIN
// ─────────────────────────────────────────────────────────────────────────────

/// Google Maps-style teardrop pin drawn with [CustomPaint].
class MapEventPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isSelected;
  final double width;
  final double height;

  const MapEventPin({
    super.key,
    required this.color,
    required this.icon,
    required this.width,
    required this.height,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: MapPinPainter(color: color, isSelected: isSelected),
      child: SizedBox(
        width: width,
        height: height,
        child: Align(
          alignment: const Alignment(0, -0.24),
          child: Icon(icon, color: Colors.white, size: width * 0.44),
        ),
      ),
    );
  }
}

class MapPinPainter extends CustomPainter {
  final Color color;
  final bool isSelected;

  const MapPinPainter({required this.color, this.isSelected = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final headR = w * 0.42;
    final headCY = w * 0.06 + headR;

    final stemHW = w * 0.09;
    final stemTopY = headCY + headR * 0.80;
    final stemPath = ui.Path()
      ..moveTo(cx - stemHW, stemTopY)
      ..quadraticBezierTo(cx, h + 1, cx + stemHW, stemTopY)
      ..close();

    canvas.drawShadow(
      ui.Path()
        ..addOval(Rect.fromCircle(center: Offset(cx, headCY), radius: headR)),
      color.withOpacity(0.30),
      isSelected ? 6 : 3,
      false,
    );

    canvas.drawPath(
      stemPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(cx, headCY),
      headR,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(cx - w * 0.10, headCY - headR * 0.28),
      w * 0.10,
      Paint()
        ..color = Colors.white.withOpacity(isSelected ? 0.20 : 0.12)
        ..style = PaintingStyle.fill,
    );

    if (isSelected) {
      canvas.drawCircle(
        Offset(cx, headCY),
        headR,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(MapPinPainter old) =>
      old.color != color || old.isSelected != isSelected;
}

// ─────────────────────────────────────────────────────────────────────────────
// PIN LABEL & COUNTDOWN BADGE
// ─────────────────────────────────────────────────────────────────────────────

/// Small label bubble shown above a pin when zoom ≥ 16.5.
class PinLabel extends StatelessWidget {
  final String text;
  final Color color;

  const PinLabel({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 86),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: UniverseColors.borderColor, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Small countdown badge shown above a pin for today's upcoming events.
class CountdownBadge extends StatelessWidget {
  final String text;
  final Color color;

  const CountdownBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 9, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIGNAL PIN
// ─────────────────────────────────────────────────────────────────────────────

/// Animated broadcast pin used for user-dropped signals.
class SignalPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isSelected;
  final AnimationController pulseController;
  final String? imageUrl;

  const SignalPin({
    super.key,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.pulseController,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final double circleSize = isSelected ? 32.0 : 26.0;
    return SizedBox(
      width: 50,
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, child) {
              final t = pulseController.value;
              final pulseRadius = circleSize / 2 + t * 14.0;
              final pulseOpacity = (1.0 - t) * 0.25;
              return SizedBox(
                width: circleSize,
                height: circleSize,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: circleSize / 2 - pulseRadius,
                      top: circleSize / 2 - pulseRadius,
                      child: Container(
                        width: pulseRadius * 2,
                        height: pulseRadius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: UniverseColors.accent.withOpacity(
                              pulseOpacity,
                            ),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    child!,
                  ],
                ),
              );
            },
            child: Container(
              width: circleSize,
              height: circleSize,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: hasImage ? null : color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.20),
                    blurRadius: isSelected ? 10 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: hasImage
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        icon,
                        color: Colors.white,
                        size: isSelected ? 20 : 16,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: isSelected ? 20 : 16),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: UniverseColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIGNAL COUNTDOWN
// ─────────────────────────────────────────────────────────────────────────────

/// Live countdown widget showing time remaining on a [CampusSignal].
class SignalCountdown extends StatefulWidget {
  final CampusSignal signal;
  const SignalCountdown({super.key, required this.signal});

  @override
  State<SignalCountdown> createState() => _SignalCountdownState();
}

class _SignalCountdownState extends State<SignalCountdown> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rem = widget.signal.timeRemaining;
    if (rem.isNegative) {
      return const Text(
        'Expired',
        style: TextStyle(fontSize: 13, color: UniverseColors.textMuted),
      );
    }
    return Text(
      'Expires in ${rem.inMinutes}m',
      style: const TextStyle(fontSize: 13, color: UniverseColors.textMuted),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUS STOP PIN
// ─────────────────────────────────────────────────────────────────────────────

/// Bus stop pin for the public transport layer.
class BusStopPin extends StatelessWidget {
  final BusStop stop;
  final bool showLabel;

  const BusStopPin({super.key, required this.stop, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF009688);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                stop.nextArrival,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: teal,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACEMENT PIN
// ─────────────────────────────────────────────────────────────────────────────

/// Animated pin fixed at the centre of the map during placement mode.
class PlacementPin extends StatelessWidget {
  final bool lifted;
  final Color color;
  final IconData icon;

  const PlacementPin({
    super.key,
    required this.lifted,
    this.color = UniverseColors.accent,
    this.icon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(bottom: lifted ? 14 : 0),
          child: MapEventPin(color: color, icon: icon, width: 36, height: 46),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: lifted ? 22 : 14,
          height: lifted ? 6 : 4,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.22),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
