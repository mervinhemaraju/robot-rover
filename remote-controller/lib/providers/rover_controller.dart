import 'dart:async';
import 'dart:convert';

import 'package:car_remote_controller/core/drive_sequencer.dart';
import 'package:car_remote_controller/core/rover_config.dart';
import 'package:car_remote_controller/data/rover_connection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI-facing snapshot of the rover controller.
@immutable
class RoverState {
  /// Link status to the Pi control server.
  final RoverConnectionStatus connection;

  /// Current action label ("ACCELERATING", "BRAKING", "REVERSING") or null.
  final String? action;

  /// Speed for the gauge (km/h). Placeholder until encoder telemetry (Phase 4).
  final double speedKmh;

  const RoverState({
    required this.connection,
    this.action,
    this.speedKmh = 0.0,
  });

  RoverState copyWith({
    RoverConnectionStatus? connection,
    String? action,
    double? speedKmh,
  }) => RoverState(
    connection: connection ?? this.connection,
    // action is nullable by design: pass it explicitly to clear it.
    action: action,
    speedKmh: speedKmh ?? this.speedKmh,
  );

  @override
  bool operator ==(Object other) =>
      other is RoverState &&
      other.connection == connection &&
      other.action == action &&
      other.speedKmh == speedKmh;

  @override
  int get hashCode => Object.hash(connection, action, speedKmh);
}

/// Owns the WebSocket link and the 100 ms heartbeat that streams the held
/// command to the rover. The firmware stops if commands stop arriving, so the
/// heartbeat is what keeps the rover driving while a control is held.
class RoverController extends Notifier<RoverState> {
  static const Duration _heartbeatInterval = Duration(milliseconds: 100);

  final DriveSequencer _sequencer = DriveSequencer();
  late final RoverConnection _connection;
  Timer? _heartbeat;

  @override
  RoverState build() {
    _connection = RoverConnection(
      uri: kRoverControlUri,
      onStatusChanged: _onConnectionStatus,
    );
    // Defer connecting until after build() returns: the status callback writes
    // `state`, which must not be touched before the provider is initialized.
    Future.microtask(_connection.start);
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) => _onTick());

    ref.onDispose(() {
      _heartbeat?.cancel();
      _connection.dispose();
    });

    return const RoverState(connection: RoverConnectionStatus.connecting);
  }

  // --- Input from the UI (held controls) ---

  void accelerate(bool held) => _sequencer.setAccelerating(held);

  void reverse(bool held) => _sequencer.setReversing(held);

  void brake(bool held) => _sequencer.setBraking(held);

  void steer(double value) => _sequencer.setSteer(value);

  // --- Internal loop ---

  void _onTick() {
    final command = _sequencer.tick();
    if (command != null) {
      _connection.send(jsonEncode(command.toJson()));
    }
    // Reflect the latest intent in the UI; == on RoverState suppresses
    // no-op rebuilds, so emitting every tick is cheap.
    state = state.copyWith(
      action: _sequencer.actionLabel,
      speedKmh: _sequencer.speedKmh,
    );
  }

  void _onConnectionStatus(RoverConnectionStatus status) {
    state = state.copyWith(
      connection: status,
      action: _sequencer.actionLabel,
      speedKmh: _sequencer.speedKmh,
    );
  }
}

final roverControllerProvider =
    NotifierProvider<RoverController, RoverState>(RoverController.new);
