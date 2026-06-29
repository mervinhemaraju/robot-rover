import 'package:car_remote_controller/providers/rover_controller.dart';
import 'package:car_remote_controller/ui/widgets/button_primary.dart';
import 'package:car_remote_controller/ui/widgets/button_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActionTowerWidget extends ConsumerWidget {
  const ActionTowerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(roverControllerProvider.notifier);

    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: ButtonPrimary(
              label: "Brake",
              icon: Icons.gas_meter,
              accentColor: Colors.red,
              onPressStart: () => controller.brake(true),
              onPressEnd: () => controller.brake(false),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 4,
            child: ButtonPrimary(
              label: "Accelerate",
              icon: Icons.electric_bolt,
              accentColor: Colors.orange,
              onPressStart: () => controller.accelerate(true),
              onPressEnd: () => controller.accelerate(false),
            ),
          ),

          const SizedBox(height: 6),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  // Hold-to-reverse: matches the firmware (stream-to-drive) and
                  // releases to a soft stop, so it's never left latched.
                  child: ButtonPrimary(
                    label: "Reverse",
                    icon: Icons.fast_rewind,
                    accentColor: Colors.deepPurple,
                    fontSize: 12,
                    compact: true,
                    onPressStart: () => controller.reverse(true),
                    onPressEnd: () => controller.reverse(false),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ButtonToggle(
                    label: "Lights",
                    accentColor: const Color.fromARGB(255, 63, 220, 223),
                    isActive: false,
                    // TODO: no lights command in the protocol yet (F/R/B/S only);
                    // wire to an Arduino lights command in a later step.
                    onToggled: (isOn) {},
                    activeLabel: "ON",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
