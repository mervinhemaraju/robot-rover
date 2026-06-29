import 'dart:math' as math;

import 'package:car_remote_controller/core/drive_command.dart';

/// Translational direction the rover is currently committed to.
enum DriveDirection { idle, forward, reverse }

/// Pure control-loop logic: turns held-input state (accelerate / reverse /
/// brake + steering) into the next [DriveCommand] to stream to the Pi.
///
/// No timers, no I/O, no Flutter: [RoverController] calls [tick] every ~100 ms
/// and ships whatever it returns. Keeping it pure makes the ramp, the soft-stop
/// and the forward<->reverse interlock unit-testable in isolation.
///
/// Safety model (mirrors `arduino/rover_motors` and `pi/control`):
/// - The firmware is stream-to-drive: it stops if commands stop arriving, so a
///   held control must keep producing a command every tick.
/// - Forward and reverse are mutually exclusive at the input, and a direction
///   change emits a soft stop first, so the firmware interlock is never hit.
class DriveSequencer {
  /// PWM floor a fresh press starts at: TT motors don't turn at very low duty.
  final int startSpeed;

  /// PWM added each tick while a drive control is held (the accel ramp).
  final int accelStep;

  /// Forward speed ceiling.
  final int maxSpeed;

  /// Reverse speed ceiling, kept below [maxSpeed] for control.
  final int reverseSpeed;

  /// Full-scale speed shown on the gauge, mapped from PWM until real
  /// encoder telemetry lands (Phase 4).
  final double maxKmh;

  DriveSequencer({
    this.startSpeed = 90,
    this.accelStep = 18,
    this.maxSpeed = 255,
    this.reverseSpeed = 140,
    this.maxKmh = 20.0,
  });

  bool _accelerating = false;
  bool _reversing = false;
  bool _braking = false;
  double _steer = 0.0;

  int _spd = 0;
  DriveDirection _committed = DriveDirection.idle;

  /// Hold/release the accelerator. Ignored while reversing (mutual exclusion).
  void setAccelerating(bool held) {
    if (held && _reversing) return;
    _accelerating = held;
  }

  /// Hold/release reverse. Ignored while accelerating (mutual exclusion).
  void setReversing(bool held) {
    if (held && _accelerating) return;
    _reversing = held;
  }

  /// Hold/release the brake. Overrides everything while held.
  void setBraking(bool held) => _braking = held;

  /// Steering from the joystick X axis, clamped to [-1.0, 1.0].
  void setSteer(double steer) => _steer = steer.clamp(-1.0, 1.0).toDouble();

  /// Readout label for the UI, or null when idle.
  String? get actionLabel => _braking
      ? 'BRAKING'
      : _accelerating
      ? 'ACCELERATING'
      : _reversing
      ? 'REVERSING'
      : null;

  /// Current speed for the gauge (placeholder until encoder telemetry).
  double get speedKmh => _spd / maxSpeed * maxKmh;

  /// Compute the command for this tick, or null if nothing should be sent
  /// (idle and already stopped: stay quiet so the server watchdog rests).
  DriveCommand? tick() {
    if (_braking) {
      _spd = 0;
      _committed = DriveDirection.idle;
      return const DriveCommand.brake();
    }

    final DriveDirection desired = _accelerating
        ? DriveDirection.forward
        : _reversing
        ? DriveDirection.reverse
        : DriveDirection.idle;

    if (desired == DriveDirection.idle) {
      _spd = 0;
      // Emit a single soft stop on the transition out of driving, then go quiet.
      if (_committed != DriveDirection.idle) {
        _committed = DriveDirection.idle;
        return const DriveCommand.softStop();
      }
      return null;
    }

    // Direction reversal: stop first so the firmware interlock is never hit.
    // Input mutual-exclusion normally prevents reaching here, but this keeps
    // the sequencer correct on its own.
    if (_committed != DriveDirection.idle && _committed != desired) {
      _committed = DriveDirection.idle;
      _spd = 0;
      return const DriveCommand.softStop();
    }

    _committed = desired;
    if (desired == DriveDirection.forward) {
      _spd = _spd == 0 ? startSpeed : math.min(maxSpeed, _spd + accelStep);
      return DriveCommand.forward(spd: _spd, steer: _steer);
    }
    _spd = _spd == 0 ? startSpeed : math.min(reverseSpeed, _spd + accelStep);
    return DriveCommand.reverse(spd: _spd, steer: _steer);
  }
}
