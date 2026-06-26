import os
import time
import serial
import structlog

log = structlog.get_logger()

SERIAL_PORT = os.environ.get("SERIAL_PORT", "/dev/ttyACM0")

ser = serial.Serial(SERIAL_PORT, baudrate=115200, timeout=1.0)

try:
    if not ser.is_open:
        log.error("serial_port_not_open", port=SERIAL_PORT)
    else:
        ser.write(b"F\n")
        log.info("command_sent", command="F")
        time.sleep(1)
        ser.write(b"S\n")
        log.info("command_sent", command="S")
finally:
    ser.close()
