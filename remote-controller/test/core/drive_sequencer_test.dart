import 'package:car_remote_controller/core/drive_command.dart';
import 'package:car_remote_controller/core/drive_sequencer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriveSequencer', () {
    late DriveSequencer sequencer;

    setUp(() {
      // Small, predictable tunables for assertions.
      sequencer = DriveSequencer(
        startSpeed: 100,
        accelStep: 50,
        maxSpeed: 255,
        reverseSpeed: 150,
        maxKmh: 20.0,
      );
    });

    test('emits nothing while idle and never driven', () {
      // Arrange: no controls held.
      // Act / Assert: idle ticks stay silent so the server watchdog rests.
      expect(sequencer.tick(), isNull);
      expect(sequencer.tick(), isNull);
      expect(sequencer.actionLabel, isNull);
    });

    test('accelerate starts at the floor speed then ramps up to the cap', () {
      // Arrange
      sequencer.setAccelerating(true);

      // Act / Assert: first press starts at the floor, then steps up.
      expect(sequencer.tick(), const DriveCommand.forward(spd: 100, steer: 0));
      expect(sequencer.tick(), const DriveCommand.forward(spd: 150, steer: 0));
      expect(sequencer.tick(), const DriveCommand.forward(spd: 200, steer: 0));
      expect(sequencer.tick(), const DriveCommand.forward(spd: 250, steer: 0));
      // Caps at maxSpeed and stays there.
      expect(sequencer.tick(), const DriveCommand.forward(spd: 255, steer: 0));
      expect(sequencer.tick(), const DriveCommand.forward(spd: 255, steer: 0));
      expect(sequencer.actionLabel, 'ACCELERATING');
    });

    test('forward command carries the current steering value', () {
      // Arrange
      sequencer.setAccelerating(true);
      sequencer.setSteer(0.5);

      // Act / Assert
      expect(sequencer.tick(), const DriveCommand.forward(spd: 100, steer: 0.5));
    });

    test('steering is clamped to [-1, 1]', () {
      // Arrange
      sequencer.setAccelerating(true);
      sequencer.setSteer(3.0);

      // Act / Assert
      expect(sequencer.tick(), const DriveCommand.forward(spd: 100, steer: 1.0));
    });

    test('releasing accelerate emits one soft stop then goes quiet', () {
      // Arrange: drive forward for a couple of ticks.
      sequencer.setAccelerating(true);
      sequencer.tick();
      sequencer.tick();

      // Act: release.
      sequencer.setAccelerating(false);

      // Assert: exactly one soft stop, then silence.
      expect(sequencer.tick(), const DriveCommand.softStop());
      expect(sequencer.tick(), isNull);
      expect(sequencer.actionLabel, isNull);
    });

    test('brake overrides driving and reports zero speed', () {
      // Arrange: accelerating, then brake pressed.
      sequencer.setAccelerating(true);
      sequencer.tick();
      sequencer.setBraking(true);

      // Act / Assert
      expect(sequencer.tick(), const DriveCommand.brake());
      expect(sequencer.speedKmh, 0.0);
      expect(sequencer.actionLabel, 'BRAKING');
    });

    test('reverse is ignored while accelerating (mutual exclusion)', () {
      // Arrange
      sequencer.setAccelerating(true);
      sequencer.tick();

      // Act: try to reverse without releasing accelerate.
      sequencer.setReversing(true);

      // Assert: still driving forward, not reverse.
      expect(sequencer.tick(), const DriveCommand.forward(spd: 150, steer: 0));
    });

    test('switching forward to reverse passes through a soft stop first', () {
      // Arrange: commit to forward.
      sequencer.setAccelerating(true);
      sequencer.tick();

      // Act: release forward and request reverse.
      sequencer.setAccelerating(false);
      sequencer.setReversing(true);

      // Assert: a stop is emitted before reverse engages (firmware interlock).
      expect(sequencer.tick(), const DriveCommand.softStop());
      expect(sequencer.tick(), const DriveCommand.reverse(spd: 100, steer: 0));
    });

    test('reverse ramps up to its own lower cap', () {
      // Arrange
      sequencer.setReversing(true);

      // Act / Assert: starts at floor, caps at reverseSpeed (150), not maxSpeed.
      expect(sequencer.tick(), const DriveCommand.reverse(spd: 100, steer: 0));
      expect(sequencer.tick(), const DriveCommand.reverse(spd: 150, steer: 0));
      expect(sequencer.tick(), const DriveCommand.reverse(spd: 150, steer: 0));
      expect(sequencer.actionLabel, 'REVERSING');
    });

    test('speedKmh maps PWM onto the gauge scale', () {
      // Arrange: ramp to the cap.
      sequencer.setAccelerating(true);
      for (var i = 0; i < 10; i++) {
        sequencer.tick();
      }

      // Act / Assert: at maxSpeed (255) the gauge reads full scale.
      expect(sequencer.speedKmh, 20.0);
    });
  });
}
