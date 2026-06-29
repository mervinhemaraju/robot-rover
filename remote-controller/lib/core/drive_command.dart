import 'package:flutter/foundation.dart';

/// A single drive command in the wire format the Pi control server expects.
///
/// Wire format (see `pi/control/protocol.py`):
///     {"cmd": "F|R|B|S", "spd": 0-255, "steer": -1.0..1.0}
///
/// - F = forward, R = reverse, B = brake (instant stop), S = soft stop.
/// - spd / steer are ignored by the server for B and S, sent as 0 for clarity.
@immutable
class DriveCommand {
  /// Single-letter command code: 'F', 'R', 'B' or 'S'.
  final String cmd;

  /// Target speed, 0-255 (PWM duty the Pi mixer scales per wheel).
  final int spd;

  /// Steering, -1.0 (full left) to 1.0 (full right). Positive turns right.
  final double steer;

  const DriveCommand._(this.cmd, this.spd, this.steer);

  const DriveCommand.forward({required int spd, required double steer})
    : this._('F', spd, steer);

  const DriveCommand.reverse({required int spd, required double steer})
    : this._('R', spd, steer);

  /// Active braking pulse (instant stop).
  const DriveCommand.brake() : this._('B', 0, 0.0);

  /// Soft stop (coast to a halt). Sent once when a drive control is released.
  const DriveCommand.softStop() : this._('S', 0, 0.0);

  Map<String, dynamic> toJson() => {'cmd': cmd, 'spd': spd, 'steer': steer};

  @override
  bool operator ==(Object other) =>
      other is DriveCommand &&
      other.cmd == cmd &&
      other.spd == spd &&
      other.steer == steer;

  @override
  int get hashCode => Object.hash(cmd, spd, steer);

  @override
  String toString() => 'DriveCommand($cmd, spd: $spd, steer: $steer)';
}
