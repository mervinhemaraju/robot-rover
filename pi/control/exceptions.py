"""Custom exceptions for the control server."""


class ControlError(Exception):
    """Base class for all control-server errors."""


class InvalidCommandError(ControlError):
    """An incoming WebSocket message was not a valid drive command."""


class SerialError(ControlError):
    """Base class for Arduino serial-link errors."""


class SerialConnectionError(SerialError):
    """The serial port could not be opened."""


class SerialWriteError(SerialError):
    """A command could not be written to the serial port."""


class SerialReadError(SerialError):
    """A response could not be read from the serial port."""
