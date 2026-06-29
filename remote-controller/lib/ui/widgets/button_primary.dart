import 'package:flutter/material.dart';

class ButtonPrimary extends StatefulWidget {
  /// Fires on release (tap-up), like a regular button.
  final VoidCallback? onPressed;

  /// Fires the moment the finger goes down.
  final VoidCallback? onPressStart;

  /// Fires on release or when the gesture is cancelled (finger slides off).
  final VoidCallback? onPressEnd;

  final String label;
  final IconData icon;
  final Color accentColor;
  final double fontSize;

  /// Tightens the layout (smaller icon, less spacing) so the button fits a
  /// short slot, e.g. the Reverse hold-button beside the Lights toggle.
  final bool compact;

  const ButtonPrimary({
    super.key,
    this.onPressed,
    this.onPressStart,
    this.onPressEnd,
    required this.label,
    required this.icon,
    required this.accentColor,
    this.fontSize = 18,
    this.compact = false,
  });

  @override
  State<ButtonPrimary> createState() => _ButtonPrimaryState();
}

class _ButtonPrimaryState extends State<ButtonPrimary> {
  final WidgetStatesController _statesController = WidgetStatesController();
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _statesController.addListener(_handlePressedChanged);
  }

  void _handlePressedChanged() {
    final bool pressed = _statesController.value.contains(WidgetState.pressed);
    if (pressed == _isPressed) return;
    _isPressed = pressed;
    pressed ? widget.onPressStart?.call() : widget.onPressEnd?.call();
  }

  @override
  void dispose() {
    _statesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      statesController: _statesController,
      // Must be non-null even when only the press callbacks are used,
      // otherwise the button renders disabled and never reports pressed.
      onPressed: widget.onPressed ?? () {},
      style: ButtonStyle(
        // OutlinedButton ignores the shape's own side; the outline must be
        // set via `side`.
        side: WidgetStatePropertyAll(
          BorderSide(
            color: widget.accentColor.withValues(alpha: 0.8),
            width: 3,
          ),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(100)),
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return widget.accentColor;
          }
          return widget.accentColor.withValues(alpha: 0.15);
        }),
        // Icon and Text below inherit this via the button's IconTheme /
        // DefaultTextStyle, so they flip to white together with the press.
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white;
          }
          return widget.accentColor;
        }),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: widget.fontSize * (widget.compact ? 1.4 : 2.8)),
            SizedBox(height: widget.compact ? 4 : 8),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
