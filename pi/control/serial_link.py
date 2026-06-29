"""Synchronous serial wrapper for the Arduino motor controller.

Speaks the rover_motors protocol ("D <left> <right>", "S", "B", "?"). Kept small
and synchronous on purpose: the async MotorController owns one instance and runs
its blocking calls in a thread executor, so the event loop is never blocked and
the single port has exactly one owner.

This is a self-contained copy of the wrapper in pi/serial-repl so the control
service deploys independently to ~/rover/control/ with no cross-folder imports.
"""

from __future__ import annotations

import time

import serial

from exceptions import SerialConnectionError, SerialReadError, SerialWriteError


class MotorSerial:
    """Manages the serial connection to the Arduino motor controller."""

    def __init__(self, port: str, baud: int = 115200, timeout: float = 0.2) -> None:
        self._port = port
        self._baud = baud
        self._timeout = timeout
        self._ser: serial.Serial | None = None
        self._rx_buffer = ""

    def open(self) -> None:
        """Open the port and wait for the Arduino to boot.

        Raises:
            SerialConnectionError: the port could not be opened.
        """
        try:
            self._ser = serial.Serial(
                self._port, baudrate=self._baud, timeout=self._timeout
            )
        except serial.SerialException as exc:
            raise SerialConnectionError(f"could not open {self._port}: {exc}") from exc
        # The Arduino may reset when the port opens; let it boot before we drive.
        time.sleep(2.0)

    def close(self) -> None:
        if self._ser is not None and self._ser.is_open:
            self._ser.close()

    @property
    def is_open(self) -> bool:
        return self._ser is not None and self._ser.is_open

    def send(self, command: str) -> None:
        """Write a command, appending the newline the Arduino parser expects.

        Raises:
            SerialWriteError: the port is closed or the write failed.
        """
        if self._ser is None or not self._ser.is_open:
            raise SerialWriteError("serial port is not open")
        try:
            self._ser.write((command + "\n").encode("ascii"))
        except serial.SerialException as exc:
            raise SerialWriteError(f"failed to write {command!r}: {exc}") from exc

    def read_available(self) -> list[str]:
        """Return any complete lines currently buffered, without blocking.

        Partial lines are retained across calls. Returns an empty list if the
        port is closed or nothing is waiting.

        Raises:
            SerialReadError: a read failed on an open port.
        """
        if self._ser is None or not self._ser.is_open:
            return []
        try:
            waiting = self._ser.in_waiting
            if waiting:
                self._rx_buffer += self._ser.read(waiting).decode(
                    "ascii", errors="replace"
                )
        except serial.SerialException as exc:
            raise SerialReadError(f"failed to read: {exc}") from exc

        lines: list[str] = []
        while "\n" in self._rx_buffer:
            line, self._rx_buffer = self._rx_buffer.split("\n", 1)
            line = line.strip()
            if line:
                lines.append(line)
        return lines
