import 'package:car_remote_controller/ui/widgets/joystick.dart';
import 'package:car_remote_controller/ui/widgets/speedometer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ControlTowerWidget extends StatelessWidget {
  /// Action currently performed (e.g. "BRAKING"); null when idle.
  final ValueListenable<String?> currentAction;

  /// Current speed shown on the speedometer.
  final ValueListenable<double> speed;

  const ControlTowerWidget({
    super.key,
    required this.currentAction,
    required this.speed,
  });

  static const Color _green = Color(0xFF1E9E4F);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 10, height: 10),
              ),
              SizedBox(width: 8),
              Text(
                "ROVER",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: Color(0xFF14181C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<String?>(
            valueListenable: currentAction,
            builder: (context, action, _) => Text(
              action ?? "IDLE",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: action == null
                    ? const Color(0xFF8B8F98)
                    : const Color(0xFFF07E1A),
              ),
            ),
          ),

          const Spacer(),

          Center(
            child: ValueListenableBuilder<double>(
              valueListenable: speed,
              builder: (context, value, _) =>
                  SpeedometerWidget(size: 95, speed: value),
            ),
          ),

          const Spacer(),

          JoystickWidget(
            size: 150,
            label: "Steer",
            onChanged: (position) {
              print("Joystick is now in position $position");
            },
          ),
        ],
      ),
    );
  }
}
