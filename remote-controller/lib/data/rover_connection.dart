import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Lifecycle state of the WebSocket link to the rover.
enum RoverConnectionStatus { connecting, connected, disconnected }

/// Thin WebSocket transport to the Pi control server.
///
/// Connects, sends already-encoded command strings, and reconnects on its own
/// after a drop so the link heals without the UI doing anything. Server replies
/// (`{"ok":...}`) are not consumed yet; they only matter for diagnostics.
class RoverConnection {
  final Uri uri;
  final Duration reconnectDelay;
  final ValueChanged<RoverConnectionStatus>? onStatusChanged;

  RoverConnection({
    required this.uri,
    this.reconnectDelay = const Duration(seconds: 2),
    this.onStatusChanged,
  });

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _closed = false;
  RoverConnectionStatus _status = RoverConnectionStatus.disconnected;

  RoverConnectionStatus get status => _status;

  bool get isConnected => _status == RoverConnectionStatus.connected;

  /// Open the connection and keep it open (reconnecting on drops).
  void start() {
    _closed = false;
    _connect();
  }

  Future<void> _connect() async {
    if (_closed) return;
    _setStatus(RoverConnectionStatus.connecting);
    try {
      final WebSocketChannel channel = WebSocketChannel.connect(uri);
      // `ready` completes once the socket is actually established, or throws.
      await channel.ready;
      if (_closed) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _setStatus(RoverConnectionStatus.connected);
      _subscription = channel.stream.listen(
        (_) {}, // Replies ignored for now.
        onDone: _handleDrop,
        onError: (Object _) => _handleDrop(),
        cancelOnError: true,
      );
    } on Exception {
      // Server not up yet, wrong host, LAN unreachable: back off and retry.
      _handleDrop();
    }
  }

  void _handleDrop() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    if (_closed) return;
    _setStatus(RoverConnectionStatus.disconnected);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, _connect);
  }

  /// Send one command line. No-op while disconnected: the heartbeat simply
  /// resumes streaming once the link is back, so a dropped tick is harmless.
  void send(String data) {
    final WebSocketChannel? channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(data);
    } on StateError {
      // Sink closed underneath us; treat as a drop and reconnect.
      _handleDrop();
    }
  }

  void _setStatus(RoverConnectionStatus status) {
    if (status == _status) return;
    _status = status;
    onStatusChanged?.call(status);
  }

  /// Permanently close the connection (call from the owner's dispose).
  Future<void> dispose() async {
    _closed = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
  }
}
