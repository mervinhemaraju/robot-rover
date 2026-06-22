import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular speed gauge: a muted ring with the current speed in the
/// center and a green progress arc sweeping clockwise from 12 o'clock,
/// proportional to `speed / maxSpeed`.
///
/// The speed is driven from outside via [speed]; when it changes, the
/// number and arc animate smoothly to the new value. [onChanged] reports
/// the *displayed* speed on every animation tick, settling on the final
/// value.
class SpeedometerWidget extends StatefulWidget {
  /// Current speed to display.
  final double speed;

  /// Speed at which the progress arc completes the full circle.
  final double maxSpeed;

  /// Unit label rendered under the speed value.
  final String unit;

  /// Outer diameter of the gauge.
  final double size;

  /// Color of the progress arc.
  final Color accentColor;

  /// Called with the displayed speed while it animates between values.
  final ValueChanged<double>? onChanged;

  const SpeedometerWidget({
    super.key,
    this.speed = 0,
    this.maxSpeed = 20,
    this.unit = 'km/h',
    this.size = 160,
    this.accentColor = const Color(0xFF2E9E5B),
    this.onChanged,
  }) : assert(maxSpeed > 0, 'maxSpeed must be positive');

  @override
  State<SpeedometerWidget> createState() => _SpeedometerWidgetState();
}

class _SpeedometerWidgetState extends State<SpeedometerWidget>
    with SingleTickerProviderStateMixin {
  static const Color _ringColor = Color(0xFFE5E0D4);
  static const Color _valueColor = Color(0xFF26221B);
  static const Color _unitColor = Color(0xFF8B8579);

  late final AnimationController _controller;
  late Animation<double> _animation;

  /// The speed currently shown (animates toward `widget.speed`).
  double _displayedSpeed = 0;

  @override
  void initState() {
    super.initState();
    _displayedSpeed = widget.speed;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = AlwaysStoppedAnimation<double>(_displayedSpeed);
    _controller.addListener(_onTick);
  }

  @override
  void didUpdateWidget(SpeedometerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.speed != oldWidget.speed) {
      _animation = Tween<double>(begin: _displayedSpeed, end: widget.speed)
          .animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTick() {
    setState(() => _displayedSpeed = _animation.value);
    widget.onChanged?.call(_displayedSpeed);
  }

  @override
  Widget build(BuildContext context) {
    final double fraction =
        (_displayedSpeed / widget.maxSpeed).clamp(0.0, 1.0);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _GaugePainter(
          fraction: fraction,
          ringColor: _ringColor,
          arcColor: widget.accentColor,
          strokeWidth: widget.size * 0.085,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _displayedSpeed.toStringAsFixed(1),
                style: TextStyle(
                  color: _valueColor,
                  fontSize: widget.size * 0.27,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                widget.unit,
                style: TextStyle(
                  color: _unitColor,
                  fontSize: widget.size * 0.105,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the muted background ring and the green progress arc
/// (12 o'clock start, clockwise, rounded ends).
class _GaugePainter extends CustomPainter {
  final double fraction;
  final Color ringColor;
  final Color arcColor;
  final double strokeWidth;

  const _GaugePainter({
    required this.fraction,
    required this.ringColor,
    required this.arcColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, ringPaint);

    if (fraction <= 0) return;

    final Paint arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, arcPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.arcColor != arcColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
