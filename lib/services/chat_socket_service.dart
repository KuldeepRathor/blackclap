import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_url.dart';
import '../models/chat_socket_event.dart';
import 'token_storage.dart';

enum SocketStatus { disconnected, connecting, connected }

/// Standalone WebSocket transport for realtime chat. Independent of the REST
/// ApiService — they share only the JWT in TokenStorage. Exposes a broadcast
/// stream of parsed [ChatEvent]s; handles auto-reconnect with backoff and an
/// app-level heartbeat.
class ChatSocketService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  final StreamController<ChatEvent> _events =
      StreamController<ChatEvent>.broadcast();
  final StreamController<SocketStatus> _statusController =
      StreamController<SocketStatus>.broadcast();

  SocketStatus _status = SocketStatus.disconnected;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _retry = 0;
  bool _intentionalClose = false;

  final Random _random = Random();

  Stream<ChatEvent> get events => _events.stream;
  Stream<SocketStatus> get status => _statusController.stream;
  SocketStatus get currentStatus => _status;

  void _setStatus(SocketStatus value) {
    _status = value;
    if (!_statusController.isClosed) _statusController.add(value);
  }

  Future<void> connect() async {
    if (_status == SocketStatus.connected ||
        _status == SocketStatus.connecting) {
      return;
    }
    _intentionalClose = false;
    _reconnectTimer?.cancel();
    _setStatus(SocketStatus.connecting);

    final token = await TokenStorage.getAccessToken();
    if (token == null) {
      _setStatus(SocketStatus.disconnected);
      return;
    }

    final uri = Uri.parse('${AppUrl.chatSocket}?token=$token');
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready; // throws if the handshake fails
      _setStatus(SocketStatus.connected);
      _retry = 0;
      _startHeartbeat();
      _sub = channel.stream.listen(
        _onData,
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final event = ChatEvent.fromJson(decoded);
        if (event is PongEvent) return; // heartbeat ack, nothing to surface
        if (!_events.isClosed) _events.add(event);
      }
    } catch (_) {
      // Ignore malformed frames.
    }
  }

  void _handleDisconnect() {
    _stopHeartbeat();
    _sub?.cancel();
    _sub = null;
    _channel = null;
    _setStatus(SocketStatus.disconnected);
    if (!_intentionalClose) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    // Exponential backoff with jitter: 1,2,4,8,16,30s (capped).
    final base = (1 << _retry).clamp(1, 30);
    _retry = (_retry + 1).clamp(0, 5);
    final jitterMs = _random.nextInt(1000);
    _reconnectTimer = Timer(
      Duration(seconds: base, milliseconds: jitterMs),
      connect,
    );
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      send({'type': 'ping'});
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void send(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null || _status != SocketStatus.connected) return;
    try {
      channel.sink.add(jsonEncode(payload));
    } catch (_) {
      // Drop on a broken sink; REST remains the source of truth for sends.
    }
  }

  void sendTyping(String conversationId, bool isTyping) {
    send({
      'type': 'typing',
      'data': {'conversation_id': conversationId, 'is_typing': isTyping},
    });
  }

  void sendReadReceipt(String conversationId, String lastReadMessageId) {
    send({
      'type': 'message.read',
      'data': {
        'conversation_id': conversationId,
        'last_read_message_id': lastReadMessageId,
      },
    });
  }

  Future<void> disconnect() async {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _setStatus(SocketStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _events.close();
    _statusController.close();
  }
}
