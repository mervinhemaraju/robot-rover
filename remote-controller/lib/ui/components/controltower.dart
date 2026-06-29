import 'package:car_remote_controller/data/rover_connection.dart';
import 'package:car_remote_controller/providers/rover_controller.dart';
import 'package:car_remote_controller/ui/widgets/joystick.dart';
import 'package:car_remote_controller/ui/widgets/speedometer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ControlTowerWidget extends ConsumerWidget {
  const ControlTowerWidget({super.key});

  static const Color _green = Color(0xFF1E9E4F);
  static const Color _amber = Color(0xFFF0A91A);
  static const Color _red = Color(0xFFC0392B);

  static Color _statusColor(RoverConnectionStatus status) => switch (status) {
    RoverConnectionStatus.connected => _green,
    RoverConnectionStatus.connecting => _amber,
    RoverConnectionStatus.disconnected => _red,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roverControllerProvider);
    final controller = ref.read(roverControllerProvider.notifier);

    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _statusColor(state.connection),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 10, height: 10),
              ),
              const SizedBox(width: 8),
              const Text(
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
          Text(
            state.action ?? "IDLE",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: state.action == null
                  ? const Color(0xFF8B8F98)
                  : const Color(0xFFF07E1A),
            ),
          ),

          const Spacer(),

          Center(
            child: SpeedometerWidget(size: 95, speed: state.speedKmh),
          ),

          const Spacer(),

          JoystickWidget(
            size: 150,
            label: "Steer",
            // Steering-only: lock to the X axis and feed it to the controller.
            axis: JoystickAxis.horizontal,
            onChanged: (position) => controller.steer(position.x),
          ),
        ],
      ),
    );
  }
}
