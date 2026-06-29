"""Interactive REPL to drive the rover_motors Arduino sketch from the Pi.

Run on the Pi (Arduino on /dev/ttyACM0 by default):

    SERIAL_PORT=/dev/ttyACM0 python main.py

Type friendly helpers or raw protocol commands at the ``rover>`` prompt:

    forward [spd]   back [spd]   left [spd]   right [spd]   stop   brake   status
    D <left> <right>   S   B   ?            (raw protocol passthrough)
    help   quit

Every command is sent to the Arduino and its echo (``OK ...`` / ``ERR ...``) is
shown. On exit the motors are always stopped.
"""

import os

import structlog

from exceptions import (
    SerialConnectionError,
    SerialError,
    SerialReadError,
    SerialWriteError,
)
from service import MotorSerial

log = structlog.get_logger()

SERIAL_PORT = os.environ.get("SERIAL_PORT", "/dev/ttyACM0")
SERIAL_BAUD = int(os.environ.get("SERIAL_BAUD", "115200"))
DEFAULT_SPEED = 150

# Raw protocol command heads accepted as-is (any case).
PROTOCOL_HEADS = {"D", "S", "B", "?"}


def build_command(line: str) -> str | None:
    """Translate a user input line into a rover_motors protocol command.

    Returns the protocol string to send, or None if the input is unrecognised.
    Friendly helpers take an optional speed: ``forward 200`` -> ``D 200 200``.
    """
    tokens = line.split()
    if not tokens:
        return None

    head = tokens[0]
    if head.upper() in PROTOCOL_HEADS:
        # Raw passthrough; normalise the command letter to upper case.
        return " ".join([head.upper(), *tokens[1:]])

    speed = DEFAULT_SPEED
    if len(tokens) > 1:
        try:
            speed = int(tokens[1])
        except ValueError:
            speed = DEFAULT_SPEED

    helpers: dict[str, str] = {
        "forward": f"D {speed} {speed}",
        "f": f"D {speed} {speed}",
        "back": f"D {-speed} {-speed}",
        "backward": f"D {-speed} {-speed}",
        "left": f"D {-speed} {speed}",
        "l": f"D {-speed} {speed}",
        "right": f"D {speed} {-speed}",
        "r": f"D {speed} {-speed}",
        "stop": "S",
        "brake": "B",
        "status": "?",
    }
    return helpers.get(head.lower())


def _log_help() -> None:
    log.info(
        "commands",
        helpers="forward|back|left|right [spd], stop, brake, status",
        raw="D <left> <right> | S | B | ?",
        meta="help, quit",
    )


def run_repl(motor: MotorSerial) -> None:
    """Read commands from stdin, send them, and show the Arduino's replies."""
    log.info("connected", port=SERIAL_PORT, baud=SERIAL_BAUD)
    for line in motor.read_lines(window=1.0):  # startup banner
        log.info("arduino", line=line)
    _log_help()

    while True:
        try:
            raw = input("rover> ").strip()
        except (EOFError, KeyboardInterrupt):
            break
        if not raw:
            continue
        low = raw.lower()
        if low in ("quit", "exit", "q"):
            break
        if low in ("help", "h"):
            _log_help()
            continue

        command = build_command(raw)
        if command is None:
            log.warning("unknown_input", input=raw)
            continue

        try:
            motor.send(command)
            log.info("sent", cmd=command)
            for line in motor.read_lines():
                log.info("recv", line=line)
        except (SerialWriteError, SerialReadError) as exc:
            log.error("serial_error", error=str(exc))


def main() -> int:
    structlog.configure(
        processors=[
            structlog.processors.add_log_level,
            structlog.dev.ConsoleRenderer(),
        ],
    )

    motor = MotorSerial(SERIAL_PORT, baud=SERIAL_BAUD)
    try:
        motor.open()
    except SerialConnectionError as exc:
        log.error("connect_failed", error=str(exc))
        return 1

    try:
        run_repl(motor)
    finally:
        # Safety: always stop the motors and release the port on exit.
        try:
            if motor.is_open:
                motor.send("S")
        except SerialError as exc:
            log.error("stop_on_exit_failed", error=str(exc))
        motor.close()
        log.info("disconnected")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
