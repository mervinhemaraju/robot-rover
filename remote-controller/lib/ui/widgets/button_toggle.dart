import 'package:flutter/material.dart';

class ButtonToggle extends StatefulWidget {
  final ValueChanged<bool>? onToggled;
  final String label;
  final bool isActive;
  final Color accentColor;
  final String? activeLabel;
  final double fontSize;

  const ButtonToggle({
    super.key,
    this.onToggled,
    required this.label,
    required this.accentColor,
    required this.isActive,
    this.activeLabel,
    this.fontSize = 12,
  });

  @override
  State<ButtonToggle> createState() => _ButtonToggleState();
}

class _ButtonToggleState extends State<ButtonToggle> {
  late bool _isOn = widget.isActive;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: widget.onToggled != null
          ? () {
              setState(() => _isOn = !_isOn);
              widget.onToggled?.call(_isOn);
            }
          : null,
      style: ButtonStyle(
        // OutlinedButton ignores the shape's own side; the outline must be
        // set via `side`.
        side: WidgetStatePropertyAll(
          BorderSide(
            color: _isOn
                ? widget.accentColor.withValues(alpha: 0.8)
                : Colors.black,
            width: 3,
          ),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
        backgroundColor: WidgetStatePropertyAll(
          _isOn ? widget.accentColor : Colors.transparent,
        ),
        // Icon and Text below inherit this via the button's IconTheme /
        // DefaultTextStyle, so they flip to white together with the toggle.
        foregroundColor: WidgetStatePropertyAll(
          _isOn ? Colors.white : Colors.black,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),

            Visibility(
              visible: _isOn,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    widget.activeLabel ?? "",
                    style: TextStyle(
                      fontSize: widget.fontSize * 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
