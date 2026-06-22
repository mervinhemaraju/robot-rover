import 'package:car_remote_controller/core/speed_simulator.dart';
import 'package:car_remote_controller/ui/components/actiontower.dart';
import 'package:car_remote_controller/ui/components/controltower.dart';
import 'package:car_remote_controller/ui/components/livefeed.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  /// Set by the action tower while a control is held, shown in the
  /// control tower readout. Null when idle.
  /// TODO: migrate to a Riverpod provider once command wiring lands.
  final ValueNotifier<String?> _currentAction = ValueNotifier<String?>(null);

  /// Drives the speedometer from the brake/accelerate buttons.
  /// TODO: replace with real speed telemetry.
  late final SpeedSimulator _speedSimulator = SpeedSimulator(_currentAction);

  @override
  void dispose() {
    _speedSimulator.dispose();
    _currentAction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No app bar: keep content clear of the system status bar / notch.
      body: Padding(
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 12.0,
          top: 48.0,
          bottom: 16.0,
        ),
        child: Row(
          children: [
            ControlTowerWidget(
              currentAction: _currentAction,
              speed: _speedSimulator.speed,
            ),
            const SizedBox(width: 16),
            const LivefeedWidget(),
            const SizedBox(width: 16),
            ActionTowerWidget(currentAction: _currentAction),
          ],
        ),
      ),
    );
  }
}
