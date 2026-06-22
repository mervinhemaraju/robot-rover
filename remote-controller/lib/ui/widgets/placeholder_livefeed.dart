import 'package:flutter/material.dart';

/// Temporary stand-in for the camera stream, styled like a camera
/// viewfinder. Swap out once the real live feed is available.
class PlaceholderLiveFeedWidget extends StatelessWidget {
  const PlaceholderLiveFeedWidget({super.key});

  static const Color _background = Color(0xFF262B36);
  static const Color _stripe = Color(0xFF202531);
  static const Color _accent = Color(0xFFE8821E);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: CustomPaint(
        painter: const _StripesPainter(
          background: _background,
          stripe: _stripe,
        ),
        foregroundPainter: const _ViewfinderPainter(accent: _accent),
        child: const SizedBox.expand(
          child: Align(
            // Just below the crosshair, like the mock.
            alignment: Alignment(0, 0.35),
            child: Text(
              "CAM_01 · 1280×720 · drop live feed here",
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                letterSpacing: 1.2,
                color: Color(0xFF8A919E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  final Color background;
  final Color stripe;

  const _StripesPainter({required this.background, required this.stripe});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    const double bandWidth = 18;
    const double spacing = bandWidth * 2;
    final Paint stripePaint = Paint()
      ..color = stripe
      ..strokeWidth = bandWidth;

    // 45-degree bands; start off-canvas so stripes cover the left edge.
    for (double x = -size.height; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter oldDelegate) =>
      background != oldDelegate.background || stripe != oldDelegate.stripe;
}

class _ViewfinderPainter extends CustomPainter {
  final Color accent;

  const _ViewfinderPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawCornerBrackets(canvas, size, paint);
    _drawCrosshair(canvas, size.center(Offset.zero), paint);
  }

  void _drawCornerBrackets(Canvas canvas, Size size, Paint paint) {
    const double inset = 18;
    const double arm = 24;

    for (final (double sx, double sy) in [(1, 1), (-1, 1), (1, -1), (-1, -1)]) {
      // Anchor each bracket in its corner; sx/sy flip toward the center.
      final Offset corner = Offset(
        sx > 0 ? inset : size.width - inset,
        sy > 0 ? inset : size.height - inset,
      );
      canvas.drawLine(corner, corner + Offset(sx * arm, 0), paint);
      canvas.drawLine(corner, corner + Offset(0, sy * arm), paint);
    }
  }

  void _drawCrosshair(Canvas canvas, Offset center, Paint paint) {
    const double gap = 5;
    const double arm = 12;

    for (final Offset direction in const [
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, 1),
      Offset(0, -1),
    ]) {
      canvas.drawLine(
        center + direction * gap,
        center + direction * (gap + arm),
        paint,
      );
    }
    canvas.drawCircle(center, 3, paint);
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) =>
      accent != oldDelegate.accent;
}
