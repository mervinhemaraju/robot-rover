"""Unit tests for the differential-drive mixer."""

from mixer import to_serial
from protocol import DriveCommand


def test_soft_stop_passes_through() -> None:
    assert to_serial(DriveCommand(cmd="S")) == "S"


def test_brake_passes_through() -> None:
    assert to_serial(DriveCommand(cmd="B")) == "B"


def test_forward_straight() -> None:
    assert to_serial(DriveCommand(cmd="F", spd=150, steer=0.0)) == "D 150 150"


def test_reverse_straight() -> None:
    assert to_serial(DriveCommand(cmd="R", spd=150, steer=0.0)) == "D -150 -150"


def test_forward_steer_right_within_range() -> None:
    # turn = 100, left = 200, right = 0 (peak 200 <= 255, no scaling)
    assert to_serial(DriveCommand(cmd="F", spd=100, steer=1.0)) == "D 200 0"


def test_forward_steer_left_within_range() -> None:
    assert to_serial(DriveCommand(cmd="F", spd=100, steer=-1.0)) == "D 0 200"


def test_scales_to_preserve_turn_ratio_when_clipping() -> None:
    # left = 400, right = 0 -> scaled by 255/400 -> "D 255 0"
    assert to_serial(DriveCommand(cmd="F", spd=200, steer=1.0)) == "D 255 0"


def test_reverse_steer_mirrored_right() -> None:
    # Reverse mirrors the turn: base = -100, turn = -100 (mirrored),
    # left = -200, right = 0.
    assert to_serial(DriveCommand(cmd="R", spd=100, steer=1.0)) == "D -200 0"


def test_reverse_steer_mirrored_left() -> None:
    # base = -100, turn = +100 (mirrored from -100), left = 0, right = -200.
    assert to_serial(DriveCommand(cmd="R", spd=100, steer=-1.0)) == "D 0 -200"


def test_steer_gain_scales_turn() -> None:
    # gain 0.5 halves the turn: turn = 50, left = 150, right = 50
    assert to_serial(DriveCommand(cmd="F", spd=100, steer=1.0), steer_gain=0.5) == "D 150 50"
