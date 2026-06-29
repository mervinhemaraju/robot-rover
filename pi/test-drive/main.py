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
        # while(True):

        #     # Request input from user
        #     command = input("What's your next command:")

        #     # Format the command to be sent over serial
        #     command = f"{command.strip().upper()}\n"

        #     # Convert to bytes
        #     ser.write(command.encode())

        #     # Log the command sent
        #     log.info("command_sent", command=command)

        ser.write(b"D 150 150\n")
        log.info("command_sent", command="S")
        time.sleep(1.5)

        ser.write(b"D -150 150\n")
        log.info("command_sent", command="S")
        time.sleep(1.5)

        ser.write(b"D 150 150\n")
        log.info("command_sent", command="S")
        time.sleep(1.5)

        ser.write(b"B\n")
        log.info("command_sent", command="S")
finally:
    ser.close()
