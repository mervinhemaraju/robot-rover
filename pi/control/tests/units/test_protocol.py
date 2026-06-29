"""Unit tests for command parsing and validation."""

import pytest

from exceptions import InvalidCommandError
from protocol import DriveCommand, parse


def test_parses_full_drive_command() -> None:
    # Arrange
    raw = '{"cmd": "F", "spd": 150, "steer": 0.3}'

    # Act
    command = parse(raw)

    # Assert
    assert command == DriveCommand(cmd="F", spd=150, steer=0.3)


def test_defaults_spd_and_steer_when_absent() -> None:
    # Arrange
    raw = '{"cmd": "S"}'

    # Act
    command = parse(raw)

    # Assert
    assert command == DriveCommand(cmd="S", spd=0, steer=0.0)


def test_clamps_speed_to_max() -> None:
    # Arrange
    raw = '{"cmd": "F", "spd": 500}'

    # Act
    command = parse(raw, max_speed=255)

    # Assert
    assert command.spd == 255


def test_clamps_steer_to_unit_range() -> None:
    # Arrange / Act
    high = parse('{"cmd": "F", "steer": 5}')
    low = parse('{"cmd": "F", "steer": -5}')

    # Assert
    assert high.steer == 1.0
    assert low.steer == -1.0


def test_rejects_unknown_command() -> None:
    with pytest.raises(InvalidCommandError):
        parse('{"cmd": "X"}')


def test_rejects_missing_command() -> None:
    with pytest.raises(InvalidCommandError):
        parse("{}")


def test_rejects_non_json() -> None:
    with pytest.raises(InvalidCommandError):
        parse("not json at all")


def test_rejects_non_object_payload() -> None:
    with pytest.raises(InvalidCommandError):
        parse("[1, 2, 3]")


def test_rejects_boolean_speed() -> None:
    # bool is a subclass of int; it must not be accepted as a speed.
    with pytest.raises(InvalidCommandError):
        parse('{"cmd": "F", "spd": true}')
