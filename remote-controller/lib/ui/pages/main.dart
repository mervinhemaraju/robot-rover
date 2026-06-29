import 'package:car_remote_controller/ui/components/actiontower.dart';
import 'package:car_remote_controller/ui/components/controltower.dart';
import 'package:car_remote_controller/ui/components/livefeed.dart';
import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

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
          children: const [
            // Control tower (status, gauge, steering) and action tower
            // (accelerate / brake / reverse) both read and drive the rover
            // controller provider directly.
            ControlTowerWidget(),
            SizedBox(width: 16),
            LivefeedWidget(),
            SizedBox(width: 16),
            ActionTowerWidget(),
          ],
        ),
      ),
    );
  }
}
