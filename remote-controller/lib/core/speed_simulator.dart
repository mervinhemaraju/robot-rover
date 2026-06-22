import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fake speed source driven by the current action, until real telemetry
/// arrives: accelerating ramps the speed up, braking bleeds it off fast,
/// idling coasts it down slowly like friction.
///
/// TODO: replace with the rover's real speed telemetry and delete.
class SpeedSimulator {
  static const double _maxSpeed = 20;
  static const double _accelerationPerTick = 0.6;
  static const double _brakingPerTick = 1.6;
  static const double _coastingPerTick = 0.2;
  static const Duration _tickInterval = Duration(milliseconds: 100);

  final ValueListenable<String?> _currentAction;

  /// Simulated speed in km/h, 0 to [_maxSpeed].
  final ValueNotifier<double> speed = ValueNotifier<double>(0);

  Timer? _timer;

  SpeedSimulator(this._currentAction) {
    _timer = Timer.periodic(_tickInterval, (_) => _step());
  }

  void _step() {
    final double delta = switch (_currentAction.value) {
      "ACCELERATING" => _accelerationPerTick,
      "BRAKING" => -_brakingPerTick,
      _ => -_coastingPerTick,
    };
    final double next = (speed.value + delta).clamp(0, _maxSpeed);
    if (next != speed.value) speed.value = next;
  }

  void dispose() {
    _timer?.cancel();
    speed.dispose();
  }
}
