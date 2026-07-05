"""Custom exceptions for the camera stream service."""


class CameraServiceError(Exception):
    """Base class for all camera-service errors."""


class CameraStartError(CameraServiceError):
    """The camera could not be detected or the capture pipeline failed to start."""
