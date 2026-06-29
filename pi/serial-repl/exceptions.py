"""Custom exceptions for the Arduino serial link."""


class SerialError(Exception):
    """Base class for all Arduino serial-link errors."""


class SerialConnectionError(SerialError):
    """The serial port could not be opened."""


class SerialWriteError(SerialError):
    """A command could not be written to the serial port."""


class SerialReadError(SerialError):
    """A response could not be read from the serial port."""
