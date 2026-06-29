/// Connection settings for the rover's Raspberry Pi.
///
/// The Pi runs the WebSocket control server on port 8765 and the (future)
/// MJPEG camera stream on port 8080. The Pi holds a DHCP-reserved address on
/// the home network. Kept as top-level constants for now; promote to a
/// user-facing setting if the address ever needs to change at runtime.
library;

/// DHCP-reserved LAN address of the rover's Pi.
const String kRoverHost = '192.168.0.4';

/// Port of the WebSocket control server (`pi/control`).
const int kRoverControlPort = 8765;

/// Port of the MJPEG camera stream (wired up in a later Phase 3 step).
const int kRoverCameraPort = 8080;

/// WebSocket endpoint the controller connects to.
/// Plain `ws://` (not `wss://`): the link is local LAN only, which is why the
/// Android manifest must allow cleartext traffic.
final Uri kRoverControlUri = Uri.parse('ws://$kRoverHost:$kRoverControlPort');
