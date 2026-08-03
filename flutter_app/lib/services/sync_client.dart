import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart';

class SyncClient {
  static final SyncClient instance = SyncClient._internal();
  IO.Socket? _socket;
  
  int _clockOffset = 0; // Local time + offset = Server time
  bool _isConnected = false;
  String? _currentRoomId;
  Map<String, dynamic>? _roomState;
  
  final _stateController = StreamController<Map<String, dynamic>?>.broadcast();
  final _executeController = StreamController<Map<String, dynamic>>.broadcast();

  SyncClient._internal();

  Stream<Map<String, dynamic>?> get roomStateStream => _stateController.stream;
  Stream<Map<String, dynamic>> get executeStream => _executeController.stream;
  Map<String, dynamic>? get roomState => _roomState;
  bool get isConnected => _isConnected;

  Future<void> connect(String baseUrl) async {
    if (_isConnected) return;

    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;
    
    if (token == null) {
      debugPrint('SyncClient: Cannot connect without auth token');
      throw Exception('Not authenticated');
    }

    final connectCompleter = Completer<void>();

    _socket = IO.io(baseUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setAuth({'token': token})
      .build());

    _socket!.onConnect((_) {
      debugPrint('SyncClient: Connected to server');
      _isConnected = true;
      _performClockSync();
      
      // Auto-rejoin if we were in a room before disconnecting
      if (_currentRoomId != null) {
        joinRoom(_currentRoomId!).catchError((e) {
          debugPrint('SyncClient: Failed to auto-rejoin room - $e');
        });
      }

      if (!connectCompleter.isCompleted) {
        connectCompleter.complete();
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('SyncClient: Disconnected from server');
      _isConnected = false;
    });

    _socket!.onConnectError((data) {
      debugPrint('SyncClient: Connection error: $data');
      if (!connectCompleter.isCompleted) {
        connectCompleter.completeError(Exception('Connection rejected: $data'));
      }
    });

    _socket!.onError((data) {
      debugPrint('SyncClient: Socket error: $data');
      if (!connectCompleter.isCompleted) {
        connectCompleter.completeError(Exception('Network error: $data'));
      }
    });

    _socket!.on('sync_execute', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        if (_roomState != null) {
          if (map.containsKey('queue')) {
            _roomState!['queue'] = map['queue'];
          }
          if (map.containsKey('currentIndex')) {
            _roomState!['currentIndex'] = map['currentIndex'];
          }
          if (map.containsKey('currentSongId')) {
            _roomState!['currentSongId'] = map['currentSongId'];
          }
          if (map.containsKey('currentTrackUrl')) {
            _roomState!['currentTrackUrl'] = map['currentTrackUrl'];
          }
          _stateController.add(_roomState);
        }
        _executeController.add(map);
      }
    });

    _socket!.on('user_joined', (data) {
      if (_roomState != null && data is Map) {
        final parsedData = Map<String, dynamic>.from(data);
        _roomState!['totalUsers'] = parsedData['totalUsers'];
        _stateController.add(_roomState);
      }
    });

    _socket!.on('user_left', (data) {
      if (_roomState != null && data is Map) {
        final parsedData = Map<String, dynamic>.from(data);
        _roomState!['totalUsers'] = parsedData['totalUsers'];
        _stateController.add(_roomState);
      }
    });

    _socket!.on('room_ended', (_) {
      leaveRoom();
    });

    _socket!.connect();

    // Wait for connection with timeout (60s to account for Hugging Face Space wake-up)
    return connectCompleter.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw Exception('Connection timeout');
      },
    );
  }

  void _performClockSync() async {
    List<int> offsets = [];
    for (int i = 0; i < 5; i++) {
      final t0 = DateTime.now().millisecondsSinceEpoch;
      final serverTime = await _pingServer();
      final t1 = DateTime.now().millisecondsSinceEpoch;
      final latency = (t1 - t0) / 2;
      final offset = serverTime - (t0 + latency);
      offsets.add(offset.round());
      await Future.delayed(const Duration(milliseconds: 100));
    }
    offsets.sort();
    // take median
    _clockOffset = offsets[2];
    debugPrint('SyncClient: Clock synchronized. Offset: $_clockOffset ms');
  }

  Future<int> _pingServer() {
    final completer = Completer<int>();
    _socket!.emitWithAck('ping', DateTime.now().millisecondsSinceEpoch, ack: (data) {
      completer.complete(data as int);
    });
    return completer.future;
  }

  int getServerTime() {
    return DateTime.now().millisecondsSinceEpoch + _clockOffset;
  }

  Future<void> createRoom([List<Map<String, dynamic>>? initialQueue]) async {
    if (!_isConnected) return Future.error('Not connected to server');
    final completer = Completer<void>();
    
    // Add timeout to prevent hanging
    Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) completer.completeError('Connection timeout');
    });

    final payload = initialQueue != null ? {'queue': initialQueue} : null;

    _socket!.emitWithAck('create_room', payload, ack: (data) {
      if (completer.isCompleted) return;
      if (data is Map) {
        final parsedData = Map<String, dynamic>.from(data);
        if (parsedData['success'] == true) {
          _currentRoomId = parsedData['roomId'];
          _roomState = parsedData['state'] != null ? Map<String, dynamic>.from(parsedData['state']) : null;
          _stateController.add(_roomState);
          completer.complete();
        } else {
          completer.completeError('Failed to create room');
        }
      } else {
        completer.completeError('Invalid response from server');
      }
    });
    return completer.future;
  }

  Future<void> joinRoom(String roomId) async {
    if (!_isConnected) return Future.error('Not connected to server');
    final completer = Completer<void>();
    
    // Add timeout to prevent hanging
    Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) completer.completeError('Connection timeout');
    });

    _socket!.emitWithAck('join_room', roomId, ack: (data) {
      if (completer.isCompleted) return;
      if (data is Map) {
        final parsedData = Map<String, dynamic>.from(data);
        if (parsedData['success'] == true) {
          _currentRoomId = roomId;
          _roomState = parsedData['state'] != null ? Map<String, dynamic>.from(parsedData['state']) : null;
          _stateController.add(_roomState);
          completer.complete();
        } else {
          completer.completeError(parsedData['error'] ?? 'Failed to join room');
        }
      } else {
        completer.completeError('Invalid response from server');
      }
    });
    return completer.future;
  }

  void leaveRoom() {
    if (_currentRoomId != null) {
      _socket!.emit('leave_room', _currentRoomId);
      _currentRoomId = null;
      _roomState = null;
      _stateController.add(null);
    }
  }

  void sendIntent(String type, Map<String, dynamic> payload) {
    if (_currentRoomId == null || !_isConnected) return;
    _socket!.emit('sync_intent', {
      'roomId': _currentRoomId,
      'type': type,
      'payload': payload
    });
  }

  void addToQueue(Map<String, dynamic> song) {
    sendIntent('ADD_TO_QUEUE_INTENT', {'song': song});
  }

  void addSongsToQueue(List<Map<String, dynamic>> songs) {
    sendIntent('ADD_TO_QUEUE_INTENT', {'songs': songs});
  }

  void removeFromQueue(int index) {
    sendIntent('REMOVE_FROM_QUEUE_INTENT', {'index': index});
  }

  void reorderQueue(int oldIndex, int newIndex) {
    sendIntent('REORDER_QUEUE_INTENT', {'oldIndex': oldIndex, 'newIndex': newIndex});
  }

  void nextTrack() {
    sendIntent('NEXT_TRACK_INTENT', {});
  }

  void prevTrack() {
    sendIntent('PREV_TRACK_INTENT', {});
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }
}
