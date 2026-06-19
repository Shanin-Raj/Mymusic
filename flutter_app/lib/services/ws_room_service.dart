import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

enum RoomEventType { play, pause, seek, songChange }

class RoomEvent {
  final RoomEventType type;
  final String? songId;
  final double? position;
  final int targetAt;

  RoomEvent({required this.type, this.songId, this.position, required this.targetAt});
}

class WsRoomService {
  WebSocketChannel? _channel;
  final _eventController = StreamController<RoomEvent>.broadcast();
  Stream<RoomEvent> get eventStream => _eventController.stream;

  int _clockOffset = 0;
  bool _isConnected = false;
  String? _currentRoomId;

  int serverNow() {
    return DateTime.now().millisecondsSinceEpoch + _clockOffset;
  }

  Future<Map<String, dynamic>> createRoom() async {
    return await ApiService.createRoom();
  }

  Future<Map<String, dynamic>> joinRoom(String roomId) async {
    final state = await ApiService.getRoomState(roomId);
    return state;
  }

  void connect(String roomId) {
    disconnect();
    _currentRoomId = roomId;
    
    final wsUrl = ApiService.baseUrl.replaceFirst('http', 'ws');
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _isConnected = true;

    _channel!.stream.listen(
      (message) {
        try {
          final data = json.decode(message);
          _handleMessage(data);
        } catch (e) {
          debugPrint('WS Parse Error: $e');
        }
      },
      onDone: () {
        debugPrint('WS Disconnected');
        _isConnected = false;
        _reconnect();
      },
      onError: (error) {
        debugPrint('WS Error: $error');
        _isConnected = false;
      },
    );

    // Initial sequence: ping for time sync, then join room
    _sendPing();
    _channel!.sink.add(json.encode({
      'type': 'JOIN_ROOM',
      'roomId': roomId,
    }));
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'PONG') {
      final serverTime = data['serverTime'] as int;
      // Simple clock sync (ignoring half-RTT for now as we want a fast sync)
      _clockOffset = serverTime - DateTime.now().millisecondsSinceEpoch;
      debugPrint('WS Clock synced: offset is $_clockOffset ms');
      return;
    }

    if (!_eventController.isClosed) {
      if (type == 'PLAY') {
        _eventController.add(RoomEvent(
          type: RoomEventType.play,
          songId: data['songId'],
          position: (data['position'] ?? 0).toDouble(),
          targetAt: data['targetAt'] ?? serverNow(),
        ));
      } else if (type == 'PAUSE') {
        _eventController.add(RoomEvent(
          type: RoomEventType.pause,
          position: (data['position'] ?? 0).toDouble(),
          targetAt: data['targetAt'] ?? serverNow(),
        ));
      } else if (type == 'SEEK') {
        _eventController.add(RoomEvent(
          type: RoomEventType.seek,
          position: (data['position'] ?? 0).toDouble(),
          targetAt: serverNow(),
        ));
      } else if (type == 'SONG_CHANGE') {
        _eventController.add(RoomEvent(
          type: RoomEventType.songChange,
          songId: data['songId'],
          targetAt: serverNow(),
        ));
      }
    }
  }

  void _sendPing() {
    if (_isConnected) {
      _channel!.sink.add(json.encode({'type': 'PING'}));
    }
  }

  void sendPlay(String songId, double position) {
    if (_isConnected) {
      final targetAt = serverNow() + 300; // Schedule 300ms in future
      _channel!.sink.add(json.encode({
        'type': 'PLAY',
        'roomId': _currentRoomId,
        'songId': songId,
        'position': position,
        'targetAt': targetAt,
      }));
    }
  }

  void sendPause(double position) {
    if (_isConnected) {
      final targetAt = serverNow() + 100; // Small delay for pause
      _channel!.sink.add(json.encode({
        'type': 'PAUSE',
        'roomId': _currentRoomId,
        'position': position,
        'targetAt': targetAt,
      }));
    }
  }

  void sendSeek(double position) {
    if (_isConnected) {
      _channel!.sink.add(json.encode({
        'type': 'SEEK',
        'roomId': _currentRoomId,
        'position': position,
      }));
    }
  }

  void sendSongChange(String songId) {
    if (_isConnected) {
      _channel!.sink.add(json.encode({
        'type': 'SONG_CHANGE',
        'roomId': _currentRoomId,
        'songId': songId,
      }));
    }
  }

  void _reconnect() {
    if (_currentRoomId != null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (_currentRoomId != null && !_isConnected) {
          debugPrint('WS Reconnecting...');
          connect(_currentRoomId!);
        }
      });
    }
  }

  void disconnect() {
    _currentRoomId = null;
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
