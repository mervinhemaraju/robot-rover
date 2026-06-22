import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Axis lock for [JoystickWidget].
enum JoystickAxis { all, horizontal, vertical }

/// Normalized joystick position reported by [JoystickWidget.onChanged].
@immutable
class JoystickPosition {
  /// Horizontal axis, -1.0 (full left) to 1.0 (full right).
  final double x;

  /// Vertical axis, -1.0 (full up) to 1.0 (full down) — screen convention.
  final double y;

  const JoystickPosition({required this.x, required this.y});

  static const JoystickPosition center = JoystickPosition(x: 0, y: 0);

  /// Magnitude from center, 0.0 to 1.0.
  double get distance => math.min(math.sqrt(x * x + y * y), 1.0);

  /// Direction in radians, 0 pointing right, positive clockwise.
  double get angle => math.atan2(y, x);

  @override
  bool operator ==(Object other) =>
      other is JoystickPosition && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() =>
      'JoystickPosition(x: ${x.toStringAsFixed(3)}, y: ${y.toStringAsFixed(3)})';
}

/// A soft, neumorphic analog joystick.
///
/// The knob travels inside the dashed boundary circle and springs back to
/// center on release. While dragged, the knob highlights in [accentColor]
/// and [onChanged] reports the normalized position continuously, ending
/// with [JoystickPosition.center] once the knob settles.
class JoystickWidget extends StatefulWidget {
  /// Outer diameter of the dial.
  final double size;

  /// Optional caption rendered under the dial (e.g. "STEER").
  final String? label;

  /// Restricts knob travel to a single axis if not [JoystickAxis.all].
  final JoystickAxis axis;

  /// Highlight color used while the knob is being dragged.
  final Color accentColor;

  /// Called with the normalized position while dragging and during the
  /// spring-back animation after release.
  final ValueChanged<JoystickPosition>? onChanged;

  const JoystickWidget({
    super.key,
    this.size = 280,
    this.label,
    this.axis = JoystickAxis.all,
    this.accentColor = const Color(0xFFF07E1A),
    this.onChanged,
  });

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget>
    with SingleTickerProviderStateMixin {
  static const Color _dialTop = Color(0xFF3F444D);
  static const Color _dialBottom = Color(0xFF2F343C);
  static const Color _muted = Color(0xFF7A818C);
  static const Color _labelColor = Color(0xFF8B8579);

  late final AnimationController _returnController;
  Animation<Offset>? _returnAnimation;

  /// Knob offset from center, in logical pixels, clamped to travel radius.
  Offset _knobOffset = Offset.zero;
  bool _dragging = false;

  /// The knob center may travel up to the dashed boundary circle.
  double get _travelRadius => widget.size * 0.29;

  double get _knobDiameter => widget.size * 0.34;

  @override
  void initState() {
    super.initState();
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _returnController.addListener(_onReturnTick);
  }

  @override
  void dispose() {
    _returnController.dispose();
    super.dispose();
  }

  void _onReturnTick() {
    final Animation<Offset>? animation = _returnAnimation;
    if (animation == null) return;
    setState(() => _knobOffset = animation.value);
    _emit();
  }

  void _emit() {
    widget.onChanged?.call(
      JoystickPosition(
        x: _knobOffset.dx / _travelRadius,
        y: _knobOffset.dy / _travelRadius,
      ),
    );
  }

  Offset _clampToTravel(Offset raw) {
    final Offset constrained = switch (widget.axis) {
      JoystickAxis.all => raw,
      JoystickAxis.horizontal => Offset(raw.dx, 0),
      JoystickAxis.vertical => Offset(0, raw.dy),
    };
    final double distance = constrained.distance;
    if (distance <= _travelRadius) return constrained;
    return constrained * (_travelRadius / distance);
  }

  void _onPanStart(DragStartDetails details) {
    _returnController.stop();
    final Offset center = Offset(widget.size / 2, widget.size / 2);
    setState(() {
      _dragging = true;
      _knobOffset = _clampToTravel(details.localPosition - center);
    });
    _emit();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final Offset center = Offset(widget.size / 2, widget.size / 2);
    setState(() => _knobOffset = _clampToTravel(details.localPosition - center));
    _emit();
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _dragging = false);
    _returnAnimation = Tween<Offset>(begin: _knobOffset, end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _returnController,
      curve: Curves.easeOutCubic,
    ));
    _returnController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final dial = GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft raised dial base.
            Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_dialTop, _dialBottom],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x59000000),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Color(0x1FFFFFFF),
                    blurRadius: 18,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: Size.square(widget.size),
              painter: _DialMarkingsPainter(
                boundaryRadius: _travelRadius,
                color: _muted,
              ),
            ),
            Transform.translate(
              offset: _knobOffset,
              child: _Knob(
                diameter: _knobDiameter,
                active: _dragging,
                accentColor: widget.accentColor,
                idleGlyphColor: _muted,
              ),
            ),
          ],
        ),
      ),
    );

    final String? label = widget.label;
    if (label == null) return dial;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dial,
        SizedBox(height: widget.size * 0.09),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: _labelColor,
            fontSize: widget.size * 0.058,
            fontWeight: FontWeight.w700,
            letterSpacing: widget.size * 0.012,
          ),
        ),
      ],
    );
  }
}

/// The draggable knob: a raised dark grey circle with a "pause" glyph that
/// lights up in the accent color while active.
class _Knob extends StatelessWidget {
  final double diameter;
  final bool active;
  final Color accentColor;
  final Color idleGlyphColor;

  const _Knob({
    required this.diameter,
    required this.active,
    required this.accentColor,
    required this.idleGlyphColor,
  });

  @override
  Widget build(BuildContext context) {
    final double barWidth = diameter * 0.055;
    final double barHeight = diameter * 0.26;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4C525C), Color(0xFF3A3F48)],
        ),
        border: Border.all(
          color: active ? accentColor : const Color(0xFF565D68),
          width: active ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? accentColor.withValues(alpha: 0.35)
                : const Color(0x66000000),
            blurRadius: active ? 26 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _glyphBar(barWidth, barHeight),
          SizedBox(width: barWidth * 1.4),
          _glyphBar(barWidth, barHeight),
        ],
      ),
    );
  }

  Widget _glyphBar(double width, double height) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: active ? accentColor : idleGlyphColor,
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}

/// Paints the dashed travel-boundary circle and the four cardinal ticks.
class _DialMarkingsPainter extends CustomPainter {
  final double boundaryRadius;
  final Color color;

  const _DialMarkingsPainter({
    required this.boundaryRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);

    final Paint dashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Dashed circle approximated with short arcs.
    const double dashLength = 5;
    const double gapLength = 5;
    final double circumference = 2 * math.pi * boundaryRadius;
    final int dashCount = (circumference / (dashLength + gapLength)).floor();
    final double dashAngle = dashLength / boundaryRadius;
    final double stepAngle = 2 * math.pi / dashCount;
    final Rect boundaryRect =
        Rect.fromCircle(center: center, radius: boundaryRadius);
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(boundaryRect, i * stepAngle, dashAngle, false, dashPaint);
    }

    // Cardinal ticks just inside the dial edge.
    final Paint tickPaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.012
      ..strokeCap = StrokeCap.round;
    final double tickOuter = size.width * 0.44;
    final double tickInner = size.width * 0.40;
    for (int i = 0; i < 4; i++) {
      final double angle = i * math.pi / 2;
      final Offset direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * tickInner,
        center + direction * tickOuter,
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DialMarkingsPainter oldDelegate) =>
      oldDelegate.boundaryRadius != boundaryRadius ||
      oldDelegate.color != color;
}
