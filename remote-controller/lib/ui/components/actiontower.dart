import 'package:car_remote_controller/ui/widgets/button_primary.dart';
import 'package:car_remote_controller/ui/widgets/button_toggle.dart';
import 'package:flutter/material.dart';

class ActionTowerWidget extends StatelessWidget {
  /// Reports the action currently performed (null when idle), shown in
  /// the control tower readout.
  final ValueNotifier<String?> currentAction;

  const ActionTowerWidget({super.key, required this.currentAction});

  void _endAction(String action) {
    // Only clear our own action: another control may have taken over
    // while this one was still held.
    if (currentAction.value == action) currentAction.value = null;
  }

  @override
  Widget build(BuildContext context) {
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
              onPressStart: () => currentAction.value = "BRAKING",
              onPressEnd: () => _endAction("BRAKING"),
            ),
          ),
          SizedBox(height: 6),
          Expanded(
            flex: 4,
            child: ButtonPrimary(
              label: "Accelerate",
              icon: Icons.electric_bolt,
              accentColor: Colors.orange,
              onPressStart: () => currentAction.value = "ACCELERATING",
              onPressEnd: () => _endAction("ACCELERATING"),
            ),
          ),

          SizedBox(height: 6),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: ButtonToggle(
                    label: "Reverse",
                    accentColor: Colors.deepPurple,
                    isActive: false,
                    onToggled: (isOn) {
                      final action = isOn ? "Reverse ON" : "Reverse OFF";
                      print("Reverse is now $action");
                    },
                    activeLabel: "ON",
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: ButtonToggle(
                    label: "Lights",
                    accentColor: const Color.fromARGB(255, 63, 220, 223),
                    isActive: false,
                    onToggled: (isOn) {
                      final action = isOn ? "Reverse ON" : "Reverse OFF";
                      print("Reverse is now $action");
                    },
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
