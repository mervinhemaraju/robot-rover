import asyncio
import json
import websockets

URL = "ws://192.168.0.4:8765"


async def drive(ws, cmd, spd=150, steer=0.0, seconds=2.0, hz=10):

    for _ in range(int(seconds * hz)):
        await ws.send(json.dumps({"cmd": cmd, "spd": spd, "steer": steer}))

        await ws.recv()  # read the {"ok":true}

        await asyncio.sleep(1 / hz)


async def main():

    async with websockets.connect(URL) as ws:
        await drive(ws, "F", 150, 0.0, 2)  # forward 2s

        await drive(ws, "F", 150, 0.5, 1)  # forward + steer right 1s

        await drive(ws, "R", 150, 0.0, 1)  # this should be REJECTED by the

        # interlock until a stop is sent...

        await ws.send(json.dumps({"cmd": "S"}))
        await ws.recv()


asyncio.run(main())
